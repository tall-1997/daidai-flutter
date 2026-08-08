import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../shared/models/user.dart';
import '../storage/secure_storage.dart';
import 'auth_service.dart';
import 'auth_token_snapshot.dart';

enum AuthStatus { unknown, unauthenticated, authenticated }

const Object _authFieldUnset = Object();

class AuthState {
  final AuthStatus status;
  final User? user;
  final bool needsInit;
  final String? error;

  const AuthState({
    this.status = AuthStatus.unknown,
    this.user,
    this.needsInit = false,
    this.error,
  });

  AuthState copyWith({
    AuthStatus? status,
    Object? user = _authFieldUnset,
    bool? needsInit,
    Object? error = _authFieldUnset,
  }) {
    return AuthState(
      status: status ?? this.status,
      user: identical(user, _authFieldUnset) ? this.user : user as User?,
      needsInit: needsInit ?? this.needsInit,
      error: identical(error, _authFieldUnset) ? this.error : error as String?,
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  final AuthService _authService;

  AuthNotifier(this._authService) : super(const AuthState());

  void clearError() {
    state = state.copyWith(error: null);
  }

  String errorMessageFor(Object error) => _extractErrorMessage(error);

  Future<void> restoreTrustedLocalSession() async {
    // 启动时先恢复本地可信登录态，避免每次打开 APP 都重新打登录日志。
    final token = await SecureStorage.getAccessToken();
    final serverUrl = await SecureStorage.getServerUrl();
    if (token == null ||
        token.isEmpty ||
        serverUrl == null ||
        serverUrl.isEmpty) {
      AuthTokenSnapshot.clear();
      state = const AuthState(status: AuthStatus.unauthenticated);
      return;
    }

    final trusted = await SecureStorage.hasValidTrustedLogin(
      serverUrl: serverUrl,
    );
    if (!trusted) {
      AuthTokenSnapshot.clear();
      state = const AuthState(status: AuthStatus.unauthenticated);
      return;
    }

    AuthTokenSnapshot.setAccessToken(token);
    final user = await SecureStorage.getUser();
    state = state.copyWith(
      status: AuthStatus.authenticated,
      user: user,
      error: null,
    );
  }

  Future<void> restoreSession() async {
    final token = await SecureStorage.getAccessToken();
    AuthTokenSnapshot.setAccessToken(token);
    if (token == null || token.isEmpty) {
      state = const AuthState(status: AuthStatus.unauthenticated);
      return;
    }
    state = state.copyWith(status: AuthStatus.unknown, error: null);
  }

  Future<void> checkAuthStatus({bool verifyRemote = true}) async {
    await restoreSession();
    if (!verifyRemote) {
      return;
    }

    final token = await SecureStorage.getAccessToken();
    if (token == null || token.isEmpty) {
      state = const AuthState(status: AuthStatus.unauthenticated);
      return;
    }

    try {
      final user = await _authService.getUser();
      state = state.copyWith(
        status: AuthStatus.authenticated,
        user: user,
        error: null,
      );

      final serverUrl = await SecureStorage.getServerUrl();
      if (serverUrl != null && serverUrl.isNotEmpty) {
        await SecureStorage.saveTrustedLoginSession(
          serverUrl: serverUrl,
          expiresAt: DateTime.now().toUtc().add(const Duration(days: 7)),
        );
      }
    } catch (_) {
      await SecureStorage.clearAuthSession();
      state = state.copyWith(
        status: AuthStatus.unauthenticated,
        user: null,
        error: '登录状态已失效，请重新登录',
      );
    }
  }

  Future<void> checkInit({bool rethrowErrors = false}) async {
    try {
      final needsInit = await _authService.needsInitialization();
      state = state.copyWith(needsInit: needsInit);
    } catch (_) {
      // 出错时默认不需要初始化，直接显示登录
      state = state.copyWith(needsInit: false);
      if (rethrowErrors) rethrow;
    }
  }

  Future<Map<String, dynamic>> login({
    required String username,
    required String password,
    String? totpCode,
    Map<String, dynamic>? captcha,
  }) async {
    state = state.copyWith(error: null);
    try {
      final result = await _authService.login(
        username: username,
        password: password,
        totpCode: totpCode,
        captcha: captcha,
      );

      if (result.containsKey('access_token')) {
        // 直接用登录响应中的 user 数据，避免额外请求
        if (result.containsKey('user') && result['user'] != null) {
          final user = User.fromJson(result['user'] as Map<String, dynamic>);
          await SecureStorage.saveUser(user);
          state = state.copyWith(status: AuthStatus.authenticated, user: user);
        } else {
          final user = await _authService.getUser();
          state = state.copyWith(status: AuthStatus.authenticated, user: user);
        }

        final serverUrl = await SecureStorage.getServerUrl();
        if (serverUrl != null && serverUrl.isNotEmpty) {
          await SecureStorage.saveTrustedLoginSession(
            serverUrl: serverUrl,
            expiresAt: DateTime.now().toUtc().add(const Duration(days: 7)),
          );
        }
      }
      return result;
    } catch (e) {
      final msg = _extractErrorMessage(e);
      state = state.copyWith(error: msg);
      rethrow;
    }
  }

  Future<void> initAdmin(String username, String password) async {
    await _authService.initAdmin(username, password);
    state = state.copyWith(needsInit: false);
  }

  Future<Map<String, dynamic>> captchaConfig({String? username}) {
    return _authService.captchaConfig(username: username);
  }

  Future<void> logout() async {
    await _authService.logout();
    state = const AuthState(status: AuthStatus.unauthenticated);
  }

  Future<void> refreshUser() async {
    try {
      final user = await _authService.getUser();
      state = state.copyWith(user: user);
    } catch (_) {}
  }

  Future<void> changeUsername(String username) async {
    await _authService.changeUsername(username);
    state = const AuthState(status: AuthStatus.unauthenticated);
  }

  Future<void> changePassword(String oldPassword, String newPassword) async {
    await _authService.changePassword(oldPassword, newPassword);
    state = const AuthState(status: AuthStatus.unauthenticated);
  }

  Future<void> uploadAvatar(MultipartFile avatar) async {
    await _authService.uploadAvatar(avatar);
    final user = await _authService.getUser();
    state = state.copyWith(user: user);
  }

  Future<void> deleteAvatar() async {
    await _authService.deleteAvatar();
    final user = await _authService.getUser();
    state = state.copyWith(user: user);
  }

  void setUnauthenticated() {
    state = const AuthState(status: AuthStatus.unauthenticated);
  }

  String _extractErrorMessage(dynamic e) {
    if (e is DioException) {
      final data = e.response?.data;
      var backendMessage = '';
      if (data is Map) {
        backendMessage =
            (data['error'] ?? data['message'])?.toString().trim() ?? '';
      }

      // NAS / Nginx Proxy Manager 反代旧面板时，登录接口可能因为 CORS 来源端口不一致返回 403。
      if (e.response?.statusCode == 403) {
        final extra = backendMessage.isEmpty ? '' : '\n后端提示：$backendMessage';
        return '登录请求被面板拒绝（403）。如果你是在群晖、飞牛等 NAS 中使用 Nginx Proxy Manager 或公网域名反代访问，请优先升级面板到 v2.3.0 及以上；升级前可临时在 config.yaml 的 cors.origins 中加入完整公网地址，例如 https://域名:端口。$extra';
      }

      // 登录接口返回 4xx 时优先显示后端明确原因
      if (backendMessage.isNotEmpty) {
        return backendMessage;
      }

      final statusCode = e.response?.statusCode;
      if (statusCode != null && statusCode >= 400) {
        return '请求失败 (HTTP $statusCode)，请检查服务器配置';
      }

      final detail = '${e.message ?? ''} ${e.error ?? ''}'.toLowerCase();
      if (detail.contains('certificate') ||
          detail.contains('hostname mismatch')) {
        return 'HTTPS 证书校验失败，请检查证书有效期、域名匹配和证书链';
      }
      if (detail.contains('handshake')) {
        return 'TLS 握手失败，请检查协议、证书和反向代理 TLS 配置';
      }
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.sendTimeout ||
          e.type == DioExceptionType.receiveTimeout) {
        return '登录请求超时，请检查 HTTPS 反向代理和面板服务状态';
      }
      if (detail.contains('failed host lookup') ||
          detail.contains('name or service not known')) {
        return '域名解析失败，请检查域名和 DNS 配置';
      }
      if (e.type == DioExceptionType.connectionError) {
        return '无法连接服务器，请检查域名、端口和反向代理配置';
      }
    }

    if (e is Exception) {
      try {
        final dioError = e as dynamic;
        if (dioError.response?.data != null) {
          return dioError.response.data['message']?.toString() ?? '操作失败';
        }
      } catch (_) {}
    }
    return '网络错误，请检查连接';
  }
}

final authServiceProvider = Provider<AuthService>((ref) => AuthService());

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(ref.read(authServiceProvider));
});
