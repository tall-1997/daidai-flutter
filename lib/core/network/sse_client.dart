import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../auth/auth_token_snapshot.dart';
import 'app_user_agent.dart';
import '../network/dio_client.dart';
import '../storage/secure_storage.dart';
import '../auth/token_refresh_coordinator.dart';
import 'sse_protocol.dart';

class SseEvent {
  final String? event;
  final String data;
  SseEvent({this.event, required this.data});
}

class SseClient {
  http.Client? _client;
  StreamSubscription? _subscription;
  Timer? _reconnectTimer;
  bool _closed = false;
  int _generation = 0;

  Future<void> connect({
    required String path,
    required void Function(SseEvent event) onEvent,
    void Function()? onDone,
    void Function(dynamic error)? onError,
    void Function()? onReconnecting,
    bool autoReconnect = false,
  }) async {
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
    _disposeConnection();
    _closed = false;
    final generation = ++_generation;
    await _doConnect(
      path: path,
      onEvent: onEvent,
      onDone: onDone,
      onError: onError,
      onReconnecting: onReconnecting,
      autoReconnect: autoReconnect,
      authRefreshAttempts: 0,
      generation: generation,
    );
  }

  Future<void> _doConnect({
    required String path,
    required void Function(SseEvent event) onEvent,
    void Function()? onDone,
    void Function(dynamic error)? onError,
    void Function()? onReconnecting,
    bool autoReconnect = false,
    int authRefreshAttempts = 0,
    required int generation,
  }) async {
    if (_closed || generation != _generation) return;

    final baseUrl = DioClient.instance.baseUrl;
    final token = AuthTokenSnapshot.accessToken;
    if (_closed || generation != _generation) return;
    final url = Uri.parse('$baseUrl$path');

    final client = http.Client();
    final request = http.Request('GET', url);
    request.headers.addAll(AppUserAgent.defaultHeaders);
    request.headers['Accept'] = 'text/event-stream';
    request.headers['Cache-Control'] = 'no-cache';
    if (token != null) {
      request.headers['Authorization'] = 'Bearer $token';
    }

    try {
      final response = await client.send(request);
      if (_closed || generation != _generation) {
        client.close();
        return;
      }
      _client = client;

      if (response.statusCode == 401 && !_closed) {
        if (authRefreshAttempts >= 1) {
          _disposeConnection();
          onError?.call('认证刷新后仍无法建立连接，请重新登录');
          return;
        }
        final refreshed = await _refreshAccessToken();
        if (refreshed && !_closed) {
          _disposeConnection();
          await _doConnect(
            path: path,
            onEvent: onEvent,
            onDone: onDone,
            onError: onError,
            onReconnecting: onReconnecting,
            autoReconnect: autoReconnect,
            authRefreshAttempts: authRefreshAttempts + 1,
            generation: generation,
          );
          return;
        }
        _disposeConnection();
        onError?.call('认证失败，请重新登录');
        return;
      }

      if (response.statusCode < 200 || response.statusCode >= 300) {
        _disposeConnection();
        onError?.call('SSE 连接失败（HTTP ${response.statusCode}）');
        return;
      }

      String buffer = '';
      String? currentEvent;
      final dataLines = <String>[];
      var reconnectScheduled = false;
      var terminalEventReceived = false;

      void scheduleReconnect() {
        if (!autoReconnect ||
            _closed ||
            generation != _generation ||
            reconnectScheduled) return;
        reconnectScheduled = true;
        onReconnecting?.call();
        _disposeConnection();
        _reconnectTimer?.cancel();
        _reconnectTimer = Timer(const Duration(seconds: 1), () {
          _doConnect(
            path: path,
            onEvent: onEvent,
            onDone: onDone,
            onError: onError,
            onReconnecting: onReconnecting,
            autoReconnect: autoReconnect,
            authRefreshAttempts: 0,
            generation: generation,
          );
        });
      }

      void emitEvent() {
        if (terminalEventReceived || dataLines.isEmpty) {
          currentEvent = null;
          dataLines.clear();
          return;
        }
        final data = dataLines.join('\n');
        final event = SseEvent(event: currentEvent, data: data);
        if (generation != _generation) {
          return;
        }
        final terminal = isTerminalSseEvent(currentEvent, data);
        final reconnect = isReconnectSseEvent(currentEvent, data);
        if (terminal) {
          terminalEventReceived = true;
        }
        currentEvent = null;
        dataLines.clear();
        onEvent(event);

        if (terminal) {
          _disposeConnection();
        } else if (reconnect && autoReconnect && !_closed) {
          scheduleReconnect();
        }
      }

      final subscription = response.stream
          .transform(utf8.decoder)
          .listen(
            (chunk) {
              if (generation != _generation) return;
              buffer += chunk;
              final lines = buffer.split('\n');
              buffer = lines.removeLast(); // 保留不完整的行

              for (final rawLine in lines) {
                if (terminalEventReceived) break;
                final line = _normalizeSseLine(rawLine);
                if (line.isEmpty) {
                  emitEvent();
                  continue;
                }
                final field = parseSseField(line);
                if (field?.name == 'event') {
                  currentEvent = field!.value.trim();
                } else if (field?.name == 'data') {
                  dataLines.add(field!.value);
                }
              }
            },
            onDone: () {
              if (generation != _generation) return;
              if (buffer.isNotEmpty) {
                final line = _normalizeSseLine(buffer);
                final field = parseSseField(line);
                if (field?.name == 'data') {
                  dataLines.add(field!.value);
                } else if (field?.name == 'event') {
                  currentEvent = field!.value.trim();
                }
                buffer = '';
              }
              emitEvent();
              if (_closed) return;
              if (terminalEventReceived) {
                _disposeConnection();
              } else if (autoReconnect) {
                scheduleReconnect();
              } else {
                _disposeConnection();
                onDone?.call();
              }
            },
            onError: (error) {
              if (_closed || generation != _generation) return;
              if (autoReconnect) {
                scheduleReconnect();
              } else {
                _disposeConnection();
                onError?.call(error);
              }
            },
            cancelOnError: true,
          );
      if (generation == _generation &&
          !terminalEventReceived &&
          !reconnectScheduled) {
        _subscription = subscription;
      } else {
        await subscription.cancel();
        client.close();
      }
    } catch (e) {
      client.close();
      if (_closed || generation != _generation) return;
      _disposeConnection();
      if (autoReconnect) {
        onReconnecting?.call();
        _reconnectTimer?.cancel();
        _reconnectTimer = Timer(const Duration(seconds: 2), () {
          _doConnect(
            path: path,
            onEvent: onEvent,
            onDone: onDone,
            onError: onError,
            onReconnecting: onReconnecting,
            autoReconnect: autoReconnect,
            authRefreshAttempts: 0,
            generation: generation,
          );
        });
      } else {
        onError?.call(e);
      }
    }
  }

  void _disposeConnection() {
    _subscription?.cancel();
    _subscription = null;
    _client?.close();
    _client = null;
  }

  String _normalizeSseLine(String line) {
    return line.endsWith('\r') ? line.substring(0, line.length - 1) : line;
  }

  Future<bool> _refreshAccessToken() async {
    try {
      await TokenRefreshCoordinator.refresh();
      return true;
    } catch (_) {
      await SecureStorage.clearAuthSession();
      return false;
    }
  }

  void close() {
    _closed = true;
    _generation++;
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
    _disposeConnection();
  }

}
