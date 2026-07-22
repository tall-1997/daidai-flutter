import 'dart:async';
import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:http/http.dart' as http;
import 'app_user_agent.dart';
import 'api_endpoints.dart';
import '../network/dio_client.dart';
import '../storage/secure_storage.dart';

class SseEvent {
  final String? event;
  final String data;
  SseEvent({this.event, required this.data});
}

class SseClient {
  http.Client? _client;
  StreamSubscription? _subscription;
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
    );
  }

  Future<void> _doConnect({
    required String path,
    required void Function(SseEvent event) onEvent,
    void Function()? onDone,
    void Function(dynamic error)? onError,
    bool autoReconnect = false,
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
        final refreshed = await _refreshAccessToken();
        if (refreshed && !_closed) {
          _disposeConnection();
          await _doConnect(
            path: path,
            onEvent: onEvent,
            onDone: onDone,
            onError: onError,
            autoReconnect: autoReconnect,
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
          _disposeConnection();
          Future.delayed(const Duration(seconds: 1), () {
            _doConnect(
              path: path,
              onEvent: onEvent,
              onDone: onDone,
              onError: onError,
              autoReconnect: autoReconnect,
            );
          });
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
              if (!_closed) onDone?.call();
            },
            onError: (error) {
              if (!_closed) onError?.call(error);
            },
            cancelOnError: true,
          );
    } catch (e) {
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
    final refreshToken = await SecureStorage.getRefreshToken();
    if (refreshToken == null || refreshToken.isEmpty) {
      await SecureStorage.clearAuthSession();
      return false;
    }
    try {
      final response = await DioClient.instance.rawDio.post(
        ApiEndpoints.refresh,
        options: Options(headers: {'Authorization': 'Bearer $refreshToken'}),
      );
      final token = _extractAccessToken(response.data);
      await SecureStorage.saveAccessToken(token);
      return true;
    } catch (_) {
      await SecureStorage.clearAuthSession();
      return false;
    }
  }

  String _extractAccessToken(dynamic responseData) {
    if (responseData is Map) {
      final directToken = responseData['access_token']?.toString();
      if (directToken != null && directToken.isNotEmpty) {
        return directToken;
      }
      final nestedData = responseData['data'];
      if (nestedData is Map) {
        final nestedToken = nestedData['access_token']?.toString();
        if (nestedToken != null && nestedToken.isNotEmpty) {
          return nestedToken;
        }
      }
    }
    throw StateError('Missing access_token in refresh response');
  }

  void close() {
    _closed = true;
    _disposeConnection();
  }
}
