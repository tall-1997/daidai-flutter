import 'package:dio/dio.dart';
import '../network/dio_client.dart';
import '../storage/secure_storage.dart';
import 'token_refresh_coordinator.dart';

class AuthInterceptor extends Interceptor {
  static const _retryMarker = 'auth_retry_attempted';

  bool _isRefreshing = false;
  final List<({RequestOptions options, ErrorInterceptorHandler handler})>
  _pendingRequests = [];

  final void Function()? onAuthFailed;

  AuthInterceptor({this.onAuthFailed});

  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final token = await SecureStorage.getAccessToken();
    if (token != null && token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    if (err.response?.statusCode != 401) {
      handler.next(err);
      return;
    }

    if (err.requestOptions.extra[_retryMarker] == true) {
      await _clearSessionAndRejectPending();
      handler.next(err);
      return;
    }

    if (_isRefreshing) {
      _pendingRequests.add((options: err.requestOptions, handler: handler));
      return;
    }

    _isRefreshing = true;
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

      err.requestOptions.extra[_retryMarker] = true;
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
        final pending = _pendingRequests.removeAt(0);
        pending.options.extra[_retryMarker] = true;
        pending.options.headers['Authorization'] = 'Bearer $newAccessToken';
        try {
          final r = await DioClient.instance.dio.fetch(pending.options);
          pending.handler.resolve(r);
        } catch (retryError) {
          pending.handler.reject(
            _retryException(pending.options, retryError),
          );
        }
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

  Future<void> _clearSessionAndRejectPending() async {
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
