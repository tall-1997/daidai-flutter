import 'package:dio/dio.dart';
import '../network/app_user_agent.dart';
import '../network/api_endpoints.dart';
import '../network/dio_client.dart';
import '../storage/secure_storage.dart';
import '../../shared/models/user.dart';

/// 从响应中提取 data 字段，兼容 {code, data: {...}} 和直接 {...} 两种格式
dynamic _extractData(dynamic responseData) {
  if (responseData is Map<String, dynamic> &&
      responseData.containsKey('data')) {
    return responseData['data'];
  }
  return responseData;
}

class AuthService {
  final Dio _dio = DioClient.instance.dio;

  /// 返回 true 表示需要初始化，false 表示已初始化
  Future<bool> needsInitialization() async {
    try {
      final response = await _dio.get(ApiEndpoints.checkInit);
      final raw = response.data;
      if (raw is Map<String, dynamic>) {
        // 后端实际返回: {"need_init": false}
        if (raw.containsKey('need_init')) {
          return raw['need_init'] == true;
        }
        // 兼容: {data: {need_init: true}}
        if (raw['data'] is Map<String, dynamic>) {
          final data = raw['data'] as Map<String, dynamic>;
          if (data.containsKey('need_init')) {
            return data['need_init'] == true;
          }
          if (data.containsKey('initialized')) {
            return data['initialized'] == false;
          }
        }
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  Future<void> initAdmin(String username, String password) async {
    await _dio.post(
      ApiEndpoints.init,
      data: {'username': username, 'password': password},
    );
  }

  Future<Map<String, dynamic>> login({
    required String username,
    required String password,
    String? totpCode,
    Map<String, dynamic>? captcha,
  }) async {
    final data = <String, dynamic>{'username': username, 'password': password};
    if (totpCode != null && totpCode.isNotEmpty) {
      data['totp_code'] = totpCode;
    }
    if (captcha != null && captcha.isNotEmpty) {
      data['captcha'] = captcha;
    }

    final response = await _dio.post(
      ApiEndpoints.login,
      data: data,
      options: Options(
        validateStatus: (status) => status != null && status < 500,
      ),
    );

    // 登录接口只要返回 4xx，就先交给上层显示明确原因，避免后续误进入首页再变成“网络错误”。
    final statusCode = response.statusCode ?? 0;
    if (statusCode >= 400) {
      throw DioException.badResponse(
        statusCode: statusCode,
        requestOptions: response.requestOptions,
        response: response,
      );
    }

    final result = _extractData(response.data);
    final Map<String, dynamic> map = result is Map<String, dynamic>
        ? result
        : {};

    if (map.containsKey('access_token')) {
      await SecureStorage.saveTokens(
        accessToken: map['access_token'] as String,
        refreshToken: map['refresh_token'] as String,
      );
    }

    return map;
  }

  Future<Map<String, dynamic>> captchaConfig({String? username}) async {
    final response = await _dio.get(
      ApiEndpoints.captchaConfig,
      queryParameters: username != null && username.trim().isNotEmpty
          ? {'username': username.trim()}
          : null,
      options: Options(
        validateStatus: (status) => status != null && status < 500,
      ),
    );
    final result = _extractData(response.data);
    if (result is Map<String, dynamic>) {
      return result;
    }
    if (result is Map) {
      return Map<String, dynamic>.from(result);
    }
    return <String, dynamic>{};
  }

  Future<void> logout() async {
    try {
      await _dio.post(ApiEndpoints.logout);
    } finally {
      await SecureStorage.clearAuthSession();
    }
  }

  Future<User> getUser() async {
    final response = await _dio.get(ApiEndpoints.user);
    final data = _extractData(response.data);
    final user = User.fromJson(data as Map<String, dynamic>);
    await SecureStorage.saveUser(user);
    return user;
  }

  Future<void> changePassword(String oldPassword, String newPassword) async {
    await _dio.put(
      ApiEndpoints.password,
      data: {'old_password': oldPassword, 'new_password': newPassword},
    );
  }

  Future<bool> checkHealth(String serverUrl) async {
    try {
      final dio = Dio(
        BaseOptions(
          baseUrl: serverUrl,
          connectTimeout: const Duration(seconds: 5),
          receiveTimeout: const Duration(seconds: 5),
          headers: AppUserAgent.defaultHeaders,
        ),
      );
      final response = await dio.get(ApiEndpoints.health);
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  // Legacy feature API wrappers.
  //
  // The active code path uses feature-specific providers/notifiers with
  // DioClient + ApiEndpoints directly. Keep the following wrappers only for
  // historical compatibility. New feature code should not call these methods,
  // because several of them preserve older endpoint paths or HTTP methods.
  // Before reusing any method below, verify it against ApiEndpoints and the
  // current backend route implementation.

  // Dashboard API
  Future<Map<String, dynamic>> getDashboard() async {
    final response = await _dio.get(ApiEndpoints.dashboard);
    return _extractData(response.data) as Map<String, dynamic>? ?? {};
  }

  Future<Map<String, dynamic>> getSystemInfo() async {
    final response = await _dio.get(ApiEndpoints.systemInfo);
    return _extractData(response.data) as Map<String, dynamic>? ?? {};
  }

  // Envs API
  Future<Map<String, dynamic>> getEnvs() async {
    final response = await _dio.get(ApiEndpoints.envs);
    return _extractData(response.data) as Map<String, dynamic>? ?? {};
  }

  Future<void> createEnv(Map<String, dynamic> env) async {
    await _dio.post(ApiEndpoints.envs, data: env);
  }

  Future<void> updateEnv(int id, Map<String, dynamic> env) async {
    await _dio.put('${ApiEndpoints.envs}/$id', data: env);
  }

  Future<void> deleteEnv(int id) async {
    await _dio.delete('${ApiEndpoints.envs}/$id');
  }

  Future<void> enableEnv(int id) async {
    await _dio.post('${ApiEndpoints.envs}/$id/enable');
  }

  Future<void> disableEnv(int id) async {
    await _dio.post('${ApiEndpoints.envs}/$id/disable');
  }

  Future<void> sortEnvs(List<int> ids) async {
    await _dio.post('${ApiEndpoints.envs}/sort', data: {'ids': ids});
  }

  Future<Map<String, dynamic>> exportEnvs() async {
    final response = await _dio.get('${ApiEndpoints.envs}/export');
    return _extractData(response.data) as Map<String, dynamic>? ?? {};
  }

  Future<Map<String, dynamic>> importEnvs(List<Map<String, dynamic>> envs) async {
    final response = await _dio.post('${ApiEndpoints.envs}/import', data: {'envs': envs});
    return _extractData(response.data) as Map<String, dynamic>? ?? {};
  }

  // Dependencies API
  Future<Map<String, dynamic>> getDependencies({required String type, String? pythonVersion}) async {
    final queryParameters = <String, dynamic>{'type': type};
    if (pythonVersion != null) {
      queryParameters['python_version'] = pythonVersion;
    }
    final response = await _dio.get(ApiEndpoints.deps, queryParameters: queryParameters);
    return _extractData(response.data) as Map<String, dynamic>? ?? {};
  }

  Future<void> installDependency(String type, List<String> names) async {
    await _dio.post('${ApiEndpoints.deps}/install', data: {'type': type, 'names': names});
  }

  Future<void> uninstallDependency(int id) async {
    await _dio.delete('${ApiEndpoints.deps}/$id');
  }

  Future<void> reinstallDependency(int id) async {
    await _dio.post('${ApiEndpoints.deps}/$id/reinstall');
  }

  Future<void> cancelDepOperation(int id) async {
    await _dio.post('${ApiEndpoints.deps}/$id/cancel');
  }

  Future<Map<String, dynamic>> getDepStatus(int id) async {
    final response = await _dio.get('${ApiEndpoints.deps}/$id/status');
    return _extractData(response.data) as Map<String, dynamic>? ?? {};
  }

  // Tasks API
  Future<Map<String, dynamic>> getTasks() async {
    final response = await _dio.get(ApiEndpoints.tasks);
    return _extractData(response.data) as Map<String, dynamic>? ?? {};
  }

  Future<Map<String, dynamic>> getTask(int id) async {
    final response = await _dio.get('${ApiEndpoints.tasks}/$id');
    return _extractData(response.data) as Map<String, dynamic>? ?? {};
  }

  Future<void> createTask(Map<String, dynamic> task) async {
    await _dio.post(ApiEndpoints.tasks, data: task);
  }

  Future<void> updateTask(int id, Map<String, dynamic> task) async {
    await _dio.put('${ApiEndpoints.tasks}/$id', data: task);
  }

  Future<void> deleteTask(int id) async {
    await _dio.delete('${ApiEndpoints.tasks}/$id');
  }

  Future<void> enableTask(int id) async {
    await _dio.post('${ApiEndpoints.tasks}/$id/enable');
  }

  Future<void> disableTask(int id) async {
    await _dio.post('${ApiEndpoints.tasks}/$id/disable');
  }

  Future<void> runTask(int id) async {
    await _dio.post('${ApiEndpoints.tasks}/$id/run');
  }

  // Logs API
  Future<Map<String, dynamic>> getLogs({int? taskId, int? limit, int? offset}) async {
    final queryParameters = <String, dynamic>{};
    if (taskId != null) queryParameters['task_id'] = taskId;
    if (limit != null) queryParameters['limit'] = limit;
    if (offset != null) queryParameters['offset'] = offset;
    final response = await _dio.get(ApiEndpoints.logs, queryParameters: queryParameters);
    return _extractData(response.data) as Map<String, dynamic>? ?? {};
  }

  Future<void> clearLogs({int? taskId}) async {
    final queryParameters = <String, dynamic>{};
    if (taskId != null) queryParameters['task_id'] = taskId;
    await _dio.delete(ApiEndpoints.logs, queryParameters: queryParameters);
  }

  // Scripts API
  Future<Map<String, dynamic>> getScripts() async {
    final response = await _dio.get(ApiEndpoints.scripts);
    return _extractData(response.data) as Map<String, dynamic>? ?? {};
  }

  Future<Map<String, dynamic>> getScript(String path) async {
    final response = await _dio.get('${ApiEndpoints.scripts}/$path');
    return _extractData(response.data) as Map<String, dynamic>? ?? {};
  }

  Future<void> saveScript(String path, String content) async {
    await _dio.post('${ApiEndpoints.scripts}/$path', data: {'content': content});
  }

  Future<void> deleteScript(String path) async {
    await _dio.delete('${ApiEndpoints.scripts}/$path');
  }

  // Notifications API
  Future<Map<String, dynamic>> getNotifications() async {
    final response = await _dio.get(ApiEndpoints.notifications);
    return _extractData(response.data) as Map<String, dynamic>? ?? {};
  }

  Future<void> createNotification(Map<String, dynamic> notification) async {
    await _dio.post(ApiEndpoints.notifications, data: notification);
  }

  Future<void> updateNotification(int id, Map<String, dynamic> notification) async {
    await _dio.put('${ApiEndpoints.notifications}/$id', data: notification);
  }

  Future<void> deleteNotification(int id) async {
    await _dio.delete('${ApiEndpoints.notifications}/$id');
  }

  Future<void> testNotification(int id) async {
    await _dio.post('${ApiEndpoints.notifications}/$id/test');
  }

  // Subscriptions API
  Future<Map<String, dynamic>> getSubscriptions() async {
    final response = await _dio.get(ApiEndpoints.subscriptions);
    return _extractData(response.data) as Map<String, dynamic>? ?? {};
  }

  Future<void> syncSubscription(int id) async {
    await _dio.post('${ApiEndpoints.subscriptions}/$id/sync');
  }

  // Security API
  Future<Map<String, dynamic>> getSecurityInfo() async {
    final response = await _dio.get(ApiEndpoints.security);
    return _extractData(response.data) as Map<String, dynamic>? ?? {};
  }

  Future<Map<String, dynamic>> get2FAStatus() async {
    final response = await _dio.get('${ApiEndpoints.security}/2fa');
    return _extractData(response.data) as Map<String, dynamic>? ?? {};
  }

  Future<void> enable2FA(String code) async {
    await _dio.post('${ApiEndpoints.security}/2fa/enable', data: {'code': code});
  }

  Future<void> disable2FA() async {
    await _dio.post('${ApiEndpoints.security}/2fa/disable');
  }

  // Open API
  Future<Map<String, dynamic>> getOpenApiTokens() async {
    final response = await _dio.get(ApiEndpoints.openapi);
    return _extractData(response.data) as Map<String, dynamic>? ?? {};
  }

  Future<void> createOpenApiToken(Map<String, dynamic> token) async {
    await _dio.post(ApiEndpoints.openapi, data: token);
  }

  Future<void> deleteOpenApiToken(int id) async {
    await _dio.delete('${ApiEndpoints.openapi}/$id');
  }

  // Users API
  Future<Map<String, dynamic>> getCurrentUser() async {
    final response = await _dio.get(ApiEndpoints.user);
    return _extractData(response.data) as Map<String, dynamic>? ?? {};
  }

  Future<void> changeUsername(String username) async {
    await _dio.put('${ApiEndpoints.user}/username', data: {'username': username});
  }

  // System API
  Future<Map<String, dynamic>> getSystemSettings() async {
    final response = await _dio.get(ApiEndpoints.systemSettings);
    return _extractData(response.data) as Map<String, dynamic>? ?? {};
  }

  Future<void> updateSystemSettings(Map<String, dynamic> settings) async {
    await _dio.put(ApiEndpoints.systemSettings, data: settings);
  }

  Future<Map<String, dynamic>> getPanelLogs({int? limit, int? offset}) async {
    final queryParameters = <String, dynamic>{};
    if (limit != null) queryParameters['limit'] = limit;
    if (offset != null) queryParameters['offset'] = offset;
    final response = await _dio.get(ApiEndpoints.panelLogs, queryParameters: queryParameters);
    return _extractData(response.data) as Map<String, dynamic>? ?? {};
  }

  Future<Map<String, dynamic>> getBackupInfo() async {
    final response = await _dio.get(ApiEndpoints.backup);
    return _extractData(response.data) as Map<String, dynamic>? ?? {};
  }

  Future<Map<String, dynamic>> createBackup() async {
    final response = await _dio.post(ApiEndpoints.backup);
    return _extractData(response.data) as Map<String, dynamic>? ?? {};
  }

  Future<Map<String, dynamic>> restoreBackup(Map<String, dynamic> backup) async {
    final response = await _dio.post('${ApiEndpoints.backup}/restore', data: backup);
    return _extractData(response.data) as Map<String, dynamic>? ?? {};
  }

  String? get username => _dio.options.headers['X-Username'] as String?;

  String get serverUrl => _dio.options.baseUrl;
}
