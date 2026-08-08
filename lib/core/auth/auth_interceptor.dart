import 'package:dio/dio.dart';
import '../network/api_endpoints.dart';
import '../network/dio_client.dart';
import '../network/panel_capability_registry.dart';
import '../storage/secure_storage.dart';
import 'auth_token_snapshot.dart';
import 'token_refresh_coordinator.dart';

class AuthInterceptor extends Interceptor {
  static const _retryMarker = 'auth_retry_attempted';
  static const _requestScopeMarker = 'auth_request_scope';
  static const _refreshCycleMarker = 'auth_refresh_cycle';
  static const _publicAuthPaths = {
    ApiEndpoints.checkInit,
    ApiEndpoints.init,
    ApiEndpoints.login,
    ApiEndpoints.captchaConfig,
  };

  bool _isRefreshing = false;
  Future<void>? _authFailureInFlight;
  int _refreshCycle = 0;
  final Set<int> _failedRefreshCycles = {};
  final List<({RequestOptions options, ErrorInterceptorHandler handler})>
  _pendingRequests = [];

  final void Function()? onAuthFailed;

  AuthInterceptor({this.onAuthFailed});

  static bool isPublicAuthPath(String path) {
    final normalizedPath = Uri.tryParse(path)?.path ?? path;
    return _publicAuthPaths.contains(normalizedPath);
  }

  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) {
    options.extra.putIfAbsent(
      _requestScopeMarker,
      () => PanelCapabilityRegistry.currentScope,
    );
    if (isPublicAuthPath(options.path)) {
      options.headers.removeWhere(
        (name, _) => name.toLowerCase() == 'authorization',
      );
      handler.next(options);
      return;
    }
    final token = AuthTokenSnapshot.accessToken;
    if (token != null && token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    if (err.requestOptions.extra[_requestScopeMarker] !=
        PanelCapabilityRegistry.currentScope) {
      handler.next(err);
      return;
    }
    if (err.response?.statusCode != 401 ||
        isPublicAuthPath(err.requestOptions.path)) {
      handler.next(err);
      return;
    }

    if (err.requestOptions.extra[_retryMarker] == true) {
      await _clearSessionAndRejectPending(
        refreshCycle: err.requestOptions.extra[_refreshCycleMarker] as int?,
      );
      handler.next(err);
      return;
    }

    if (_isRefreshing) {
      _pendingRequests.add((options: err.requestOptions, handler: handler));
      return;
    }

    _isRefreshing = true;
    final refreshCycle = ++_refreshCycle;
    _failedRefreshCycles.removeWhere((cycle) => cycle < refreshCycle - 2);
    var currentRequestCompleted = false;

    try {
      final refreshToken = await SecureStorage.getRefreshToken();
      if (refreshToken == null || refreshToken.isEmpty) {
        await _clearSessionAndRejectPending();
        handler.next(err);
        currentRequestCompleted = true;
        return;
      }

      late final String newAccessToken;
      try {
        newAccessToken = await TokenRefreshCoordinator.refresh();
      } catch (_) {
        await _clearSessionAndRejectPending();
        handler.next(err);
        currentRequestCompleted = true;
        return;
      }

      if (err.requestOptions.extra[_requestScopeMarker] !=
          PanelCapabilityRegistry.currentScope) {
        handler.next(err);
        currentRequestCompleted = true;
        return;
      }

      err.requestOptions.extra[_retryMarker] = true;
      err.requestOptions.extra[_refreshCycleMarker] = refreshCycle;
      err.requestOptions.headers['Authorization'] = 'Bearer $newAccessToken';
      try {
        final retryResponse = await DioClient.instance.dio.fetch(
          err.requestOptions,
        );
        handler.resolve(retryResponse);
        currentRequestCompleted = true;
      } catch (retryError) {
        handler.reject(_retryException(err.requestOptions, retryError));
        currentRequestCompleted = true;
      }

      while (_pendingRequests.isNotEmpty) {
        final pendingRequests = List.of(_pendingRequests);
        _pendingRequests.clear();
        await Future.wait(
          pendingRequests.map((pending) async {
            pending.options.extra[_retryMarker] = true;
            pending.options.extra[_refreshCycleMarker] = refreshCycle;
            pending.options.headers['Authorization'] =
                'Bearer $newAccessToken';
            if (pending.options.extra[_requestScopeMarker] !=
                PanelCapabilityRegistry.currentScope) {
              pending.handler.reject(
                DioException(requestOptions: pending.options),
              );
              return;
            }
            try {
              final response = await DioClient.instance.dio.fetch(
                pending.options,
              );
              pending.handler.resolve(response);
            } catch (retryError) {
              pending.handler.reject(
                _retryException(pending.options, retryError),
              );
            }
          }),
        );
      }
    } catch (_) {
      await _clearSessionAndRejectPending();
      if (!currentRequestCompleted) {
        handler.next(err);
      }
    } finally {
      _isRefreshing = false;
      _pendingRequests.clear();
    }
  }

  Future<void> _clearSessionAndRejectPending({int? refreshCycle}) async {
    if (refreshCycle != null && _failedRefreshCycles.contains(refreshCycle)) {
      return;
    }
    if (refreshCycle != null) _failedRefreshCycles.add(refreshCycle);
    final existing = _authFailureInFlight;
    if (existing != null) {
      await existing;
      return;
    }
    final operation = _clearSessionAndRejectPendingOnce();
    _authFailureInFlight = operation;
    try {
      await operation;
    } finally {
      if (identical(_authFailureInFlight, operation)) {
        _authFailureInFlight = null;
      }
    }
  }

  Future<void> _clearSessionAndRejectPendingOnce() async {
    try {
      await SecureStorage.clearAuthSession();
    } catch (_) {}
    try {
      onAuthFailed?.call();
    } catch (_) {}

    final pendingRequests = List.of(_pendingRequests);
    _pendingRequests.clear();
    for (final pending in pendingRequests) {
      pending.handler.reject(
        DioException(
          requestOptions: pending.options,
          response: Response(
            requestOptions: pending.options,
            statusCode: 401,
          ),
          type: DioExceptionType.badResponse,
          error: 'Authentication expired',
        ),
      );
    }
  }

  DioException _retryException(RequestOptions options, Object error) {
    if (error is DioException) return error;
    return DioException(requestOptions: options, error: error);
  }
}
