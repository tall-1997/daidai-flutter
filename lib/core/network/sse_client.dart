import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'app_user_agent.dart';
import '../network/dio_client.dart';
import '../storage/secure_storage.dart';
import '../auth/token_refresh_coordinator.dart';

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

  Future<void> connect({
    required String path,
    required void Function(SseEvent event) onEvent,
    void Function()? onDone,
    void Function(dynamic error)? onError,
    bool autoReconnect = false,
  }) async {
    _closed = false;
    await _doConnect(
      path: path,
      onEvent: onEvent,
      onDone: onDone,
      onError: onError,
      autoReconnect: autoReconnect,
      authRefreshAttempts: 0,
    );
  }

  Future<void> _doConnect({
    required String path,
    required void Function(SseEvent event) onEvent,
    void Function()? onDone,
    void Function(dynamic error)? onError,
    bool autoReconnect = false,
    int authRefreshAttempts = 0,
  }) async {
    if (_closed) return;

    final baseUrl = DioClient.instance.baseUrl;
    final token = await SecureStorage.getAccessToken();
    final url = Uri.parse('$baseUrl$path');

    _client = http.Client();
    final request = http.Request('GET', url);
    request.headers.addAll(AppUserAgent.defaultHeaders);
    request.headers['Accept'] = 'text/event-stream';
    request.headers['Cache-Control'] = 'no-cache';
    if (token != null) {
      request.headers['Authorization'] = 'Bearer $token';
    }

    try {
      final response = await _client!.send(request);

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
            autoReconnect: autoReconnect,
            authRefreshAttempts: authRefreshAttempts + 1,
          );
          return;
        }
        _disposeConnection();
        onError?.call('认证失败，请重新登录');
        return;
      }

      String buffer = '';
      String? currentEvent;
      final dataLines = <String>[];
      var reconnectScheduled = false;

      void scheduleReconnect() {
        if (!autoReconnect || _closed || reconnectScheduled) return;
        reconnectScheduled = true;
        _disposeConnection();
        _reconnectTimer?.cancel();
        _reconnectTimer = Timer(const Duration(seconds: 1), () {
          _doConnect(
            path: path,
            onEvent: onEvent,
            onDone: onDone,
            onError: onError,
            autoReconnect: autoReconnect,
            authRefreshAttempts: 0,
          );
        });
      }

      void emitEvent() {
        if (dataLines.isEmpty) {
          currentEvent = null;
          return;
        }
        final data = dataLines.join('\n');
        final event = SseEvent(event: currentEvent, data: data);
        onEvent(event);

        if (currentEvent == 'done' &&
            data == 'reconnect' &&
            autoReconnect &&
            !_closed) {
          scheduleReconnect();
        }

        currentEvent = null;
        dataLines.clear();
      }

      _subscription = response.stream
          .transform(utf8.decoder)
          .listen(
            (chunk) {
              buffer += chunk;
              final lines = buffer.split('\n');
              buffer = lines.removeLast(); // 保留不完整的行

              for (final rawLine in lines) {
                final line = _normalizeSseLine(rawLine);
                if (line.startsWith('event: ')) {
                  currentEvent = line.substring(7).trim();
                } else if (line.startsWith('data: ')) {
                  dataLines.add(line.substring(6));
                } else if (line.isEmpty) {
                  emitEvent();
                }
              }
            },
            onDone: () {
              if (buffer.isNotEmpty) {
                final line = _normalizeSseLine(buffer);
                if (line.startsWith('data: ')) {
                  dataLines.add(line.substring(6));
                } else if (line.startsWith('event: ')) {
                  currentEvent = line.substring(7).trim();
                }
                buffer = '';
              }
              emitEvent();
              if (_closed) return;
              if (autoReconnect) {
                scheduleReconnect();
              } else {
                _disposeConnection();
                onDone?.call();
              }
            },
            onError: (error) {
              if (_closed) return;
              if (autoReconnect) {
                scheduleReconnect();
              } else {
                _disposeConnection();
                onError?.call(error);
              }
            },
            cancelOnError: true,
          );
    } catch (e) {
      _disposeConnection();
      if (!_closed) onError?.call(e);
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
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
    _disposeConnection();
  }

}
