import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  static const String _defaultBaseUrl = 'http://127.0.0.1:5700';
  String? _baseUrl;
  String? _accessToken;
  String? _refreshToken;

  String get baseUrl => _baseUrl ?? _defaultBaseUrl;

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _baseUrl = _normalizeUrl(prefs.getString('server_url') ?? _defaultBaseUrl);
    _accessToken = prefs.getString('access_token');
    _refreshToken = prefs.getString('refresh_token');
  }

  Future<void> setServerUrl(String url) async {
    _baseUrl = _normalizeUrl(url);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('server_url', _baseUrl!);
  }

  // Normalize URL: handle various formats for NAT traversal (花生壳 etc.)
  String _normalizeUrl(String url) {
    url = url.trim();
    if (url.isEmpty) return _defaultBaseUrl;
    // Add http:// if no protocol specified
    if (!url.startsWith('http://') && !url.startsWith('https://')) {
      url = 'http://$url';
    }
    // Remove trailing slash
    if (url.endsWith('/')) {
      url = url.substring(0, url.length - 1);
    }
    return url;
  }

  Future<void> setTokens(String accessToken, String refreshToken) async {
    _accessToken = accessToken;
    _refreshToken = refreshToken;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('access_token', accessToken);
    await prefs.setString('refresh_token', refreshToken);
  }

  Future<void> clearTokens() async {
    _accessToken = null;
    _refreshToken = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('access_token');
    await prefs.remove('refresh_token');
  }

  Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    if (_accessToken != null) 'Authorization': 'Bearer $_accessToken',
  };

  Future<http.Response> get(String path) async {
    final uri = Uri.parse('$baseUrl/api/v1$path');
    final response = await http.get(uri, headers: _headers);
    
    if (response.statusCode == 401 && _refreshToken != null) {
      final refreshed = await _tryRefreshToken();
      if (refreshed) {
        return http.get(uri, headers: _headers);
      }
    }
    
    return response;
  }

  Future<http.Response> post(String path, {dynamic body}) async {
    final uri = Uri.parse('$baseUrl/api/v1$path');
    final response = await http.post(
      uri,
      headers: _headers,
      body: body != null ? jsonEncode(body) : null,
    );
    
    if (response.statusCode == 401 && _refreshToken != null) {
      final refreshed = await _tryRefreshToken();
      if (refreshed) {
        return http.post(
          uri,
          headers: _headers,
          body: body != null ? jsonEncode(body) : null,
        );
      }
    }
    
    return response;
  }

  Future<http.Response> put(String path, {dynamic body}) async {
    final uri = Uri.parse('$baseUrl/api/v1$path');
    final response = await http.put(
      uri,
      headers: _headers,
      body: body != null ? jsonEncode(body) : null,
    );
    
    if (response.statusCode == 401 && _refreshToken != null) {
      final refreshed = await _tryRefreshToken();
      if (refreshed) {
        return http.put(
          uri,
          headers: _headers,
          body: body != null ? jsonEncode(body) : null,
        );
      }
    }
    
    return response;
  }

  Future<http.Response> delete(String path, {Map<String, dynamic>? body}) async {
    final uri = Uri.parse('$baseUrl/api/v1$path');
    final request = http.Request('DELETE', uri);
    request.headers.addAll(_headers);
    if (body != null) {
      request.body = jsonEncode(body);
      request.headers['Content-Type'] = 'application/json';
    }
    final streamedResponse = await http.Client().send(request);
    final response = await http.Response.fromStream(streamedResponse);
    
    if (response.statusCode == 401 && _refreshToken != null) {
      final refreshed = await _tryRefreshToken();
      if (refreshed) {
        final retryRequest = http.Request('DELETE', uri);
        retryRequest.headers.addAll(_headers);
        if (body != null) {
          retryRequest.body = jsonEncode(body);
          retryRequest.headers['Content-Type'] = 'application/json';
        }
        final retryStreamed = await http.Client().send(retryRequest);
        return await http.Response.fromStream(retryStreamed);
      }
    }
    
    return response;
  }

  Future<bool> _tryRefreshToken() async {
    try {
      final uri = Uri.parse('$baseUrl/api/v1/auth/refresh');
      final response = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'refresh_token': _refreshToken}),
      );
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        // API returns tokens at top level
        final accessToken = data['access_token'] ?? data['data']?['access_token'];
        final refreshToken = data['refresh_token'] ?? data['data']?['refresh_token'];
        
        if (accessToken != null) {
          await setTokens(accessToken, refreshToken ?? _refreshToken!);
          return true;
        }
      }
    } catch (e) {
      // Refresh failed
    }
    
    await clearTokens();
    return false;
  }

  // Auth APIs
  Future<Map<String, dynamic>> login(String username, String password) async {
    final response = await post('/auth/login', body: {
      'username': username,
      'password': password,
    });
    return jsonDecode(response.body);
  }

  // Client login (client_id + client_secret)
  Future<Map<String, dynamic>> clientLogin(String clientId, String clientSecret) async {
    final response = await post('/auth/client-login', body: {
      'client_id': clientId,
      'client_secret': clientSecret,
    });
    return jsonDecode(response.body);
  }

  // Two-factor authentication login
  Future<Map<String, dynamic>> loginWith2FA(String username, String password, String totpCode) async {
    final response = await post('/auth/login', body: {
      'username': username,
      'password': password,
      'totp_code': totpCode,
    });
    return jsonDecode(response.body);
  }

  // Get TOTP setup info (for enabling 2FA)
  Future<Map<String, dynamic>> getTOTPSetup() async {
    final response = await get('/auth/totp/setup');
    return jsonDecode(response.body);
  }

  // Verify and enable TOTP
  Future<Map<String, dynamic>> verifyAndEnableTOTP(String code) async {
    final response = await post('/auth/totp/verify', body: {'code': code});
    return jsonDecode(response.body);
  }

  // Disable TOTP
  Future<Map<String, dynamic>> disableTOTP(String code) async {
    final response = await post('/auth/totp/disable', body: {'code': code});
    return jsonDecode(response.body);
  }

  // Task APIs
  Future<Map<String, dynamic>> getTasks({int page = 1, int pageSize = 20, String? search, String? status}) async {
    String path = '/tasks?page=$page&page_size=$pageSize';
    if (search != null && search.isNotEmpty) {
      path += '&search=$search';
    }
    if (status != null && status.isNotEmpty) {
      path += '&status=$status';
    }
    final response = await get(path);
    return jsonDecode(response.body);
  }

  Future<Map<String, dynamic>> getTaskDetail(int id) async {
    final response = await get('/tasks/$id');
    return jsonDecode(response.body);
  }

  Future<Map<String, dynamic>> createTask(Map<String, dynamic> task) async {
    final response = await post('/tasks', body: task);
    return jsonDecode(response.body);
  }

  Future<Map<String, dynamic>> updateTask(int id, Map<String, dynamic> task) async {
    final response = await put('/tasks/$id', body: task);
    return jsonDecode(response.body);
  }

  Future<Map<String, dynamic>> deleteTask(int id) async {
    final response = await delete('/tasks/$id');
    return jsonDecode(response.body);
  }

  Future<Map<String, dynamic>> runTask(int id) async {
    final response = await put('/tasks/$id/run');
    return jsonDecode(response.body);
  }

  Future<Map<String, dynamic>> stopTask(int id) async {
    final response = await put('/tasks/$id/stop');
    return jsonDecode(response.body);
  }

  Future<Map<String, dynamic>> enableTask(int id) async {
    final response = await put('/tasks/$id/enable');
    return jsonDecode(response.body);
  }

  Future<Map<String, dynamic>> disableTask(int id) async {
    final response = await put('/tasks/$id/disable');
    return jsonDecode(response.body);
  }

  Future<Map<String, dynamic>> pinTask(int id) async {
    final response = await put('/tasks/$id/pin');
    return jsonDecode(response.body);
  }

  Future<Map<String, dynamic>> unpinTask(int id) async {
    final response = await put('/tasks/$id/unpin');
    return jsonDecode(response.body);
  }

  Future<Map<String, dynamic>> copyTask(int id) async {
    final response = await post('/tasks/$id/copy');
    return jsonDecode(response.body);
  }

  Future<Map<String, dynamic>> getTaskLatestLog(int id) async {
    final response = await get('/tasks/$id/latest-log');
    return jsonDecode(response.body);
  }

  Future<Map<String, dynamic>> getTaskLiveLogs(int id) async {
    // daidai-panel: GET /tasks/:id/live-logs returns {logs: [], done: bool, status: float}
    final response = await get('/tasks/$id/live-logs');
    return jsonDecode(response.body);
  }

  Future<Map<String, dynamic>> getLogById(int id) async {
    // daidai-panel: GET /logs/:id returns full log with decompressed content
    final response = await get('/logs/$id');
    return jsonDecode(response.body);
  }

  Future<Map<String, dynamic>> getTaskStats(int id) async {
    final response = await get('/tasks/$id/stats');
    return jsonDecode(response.body);
  }

  Future<Map<String, dynamic>> batchDeleteTasks(List<int> ids) async {
    final response = await post('/tasks/batch/delete', body: {'ids': ids});
    return jsonDecode(response.body);
  }

  Future<Map<String, dynamic>> batchEnableTasks(List<int> ids) async {
    final response = await post('/tasks/batch/enable', body: {'ids': ids});
    return jsonDecode(response.body);
  }

  Future<Map<String, dynamic>> batchDisableTasks(List<int> ids) async {
    final response = await post('/tasks/batch/disable', body: {'ids': ids});
    return jsonDecode(response.body);
  }

  // System APIs
  Future<Map<String, dynamic>> getSystemInfo() async {
    final response = await get('/system/info');
    return jsonDecode(response.body);
  }

  Future<Map<String, dynamic>> getDashboard() async {
    final response = await get('/system/dashboard');
    return jsonDecode(response.body);
  }

  Future<Map<String, dynamic>> getHealthCheck() async {
    final response = await get('/system/health');
    return jsonDecode(response.body);
  }

  // Log APIs
  Future<Map<String, dynamic>> getLogs({int page = 1, int pageSize = 50, int? taskId, String? status}) async {
    String path = '/logs?page=$page&page_size=$pageSize';
    if (taskId != null) {
      path += '&task_id=$taskId';
    }
    if (status != null && status.isNotEmpty) {
      path += '&status=$status';
    }
    final response = await get(path);
    return jsonDecode(response.body);
  }

  Future<Map<String, dynamic>> deleteLog(int id) async {
    final response = await delete('/logs/$id');
    return jsonDecode(response.body);
  }

  Future<Map<String, dynamic>> clearLogs() async {
    final response = await delete('/logs/clear');
    return jsonDecode(response.body);
  }

  // Env APIs
  Future<Map<String, dynamic>> getEnvs({int page = 1, int pageSize = 20}) async {
    final response = await get('/envs?page=$page&page_size=$pageSize');
    return jsonDecode(response.body);
  }

  Future<Map<String, dynamic>> createEnv(Map<String, dynamic> env) async {
    final response = await post('/envs', body: env);
    return jsonDecode(response.body);
  }

  Future<Map<String, dynamic>> updateEnv(int id, Map<String, dynamic> env) async {
    final response = await put('/envs/$id', body: env);
    return jsonDecode(response.body);
  }

  Future<Map<String, dynamic>> deleteEnv(int id) async {
    final response = await delete('/envs/$id');
    return jsonDecode(response.body);
  }

  Future<Map<String, dynamic>> batchDeleteEnvs(List<int> ids) async {
    final response = await post('/envs/batch/delete', body: {'ids': ids});
    return jsonDecode(response.body);
  }

  Future<Map<String, dynamic>> enableEnv(int id) async {
    final response = await put('/envs/$id/enable');
    return jsonDecode(response.body);
  }

  Future<Map<String, dynamic>> disableEnv(int id) async {
    final response = await put('/envs/$id/disable');
    return jsonDecode(response.body);
  }

  Future<Map<String, dynamic>> sortEnvs(List<int> ids) async {
    final response = await put('/envs/sort', body: {'ids': ids});
    return jsonDecode(response.body);
  }

  Future<Map<String, dynamic>> clearLogsByDays(int days) async {
    final response = await post('/logs/clear', body: {'days': days});
    return jsonDecode(response.body);
  }

  // Script APIs
  Future<Map<String, dynamic>> getScripts() async {
    final response = await get('/scripts');
    return jsonDecode(response.body);
  }

  Future<Map<String, dynamic>> getScriptContent(String path) async {
    final response = await get('/scripts/content?path=$path');
    return jsonDecode(response.body);
  }

  Future<Map<String, dynamic>> createScript(Map<String, dynamic> script) async {
    final response = await post('/scripts', body: script);
    return jsonDecode(response.body);
  }

  Future<Map<String, dynamic>> updateScript(String path, Map<String, dynamic> script) async {
    // daidai-panel: PUT /scripts/content with body {path, content}
    final body = Map<String, dynamic>.from(script);
    body['path'] = path;
    final response = await put('/scripts/content', body: body);
    return jsonDecode(response.body);
  }

  Future<Map<String, dynamic>> deleteScript(String path) async {
    final response = await delete('/scripts?path=$path');
    return jsonDecode(response.body);
  }

  Future<Map<String, dynamic>> batchDeleteScripts(List<String> paths) async {
    final response = await post('/scripts/batch/delete', body: {'paths': paths});
    return jsonDecode(response.body);
  }

  // Notification APIs
  Future<Map<String, dynamic>> getNotifications() async {
    final response = await get('/notifications');
    return jsonDecode(response.body);
  }

  Future<Map<String, dynamic>> createNotification(Map<String, dynamic> notification) async {
    final response = await post('/notifications', body: notification);
    return jsonDecode(response.body);
  }

  Future<Map<String, dynamic>> updateNotification(int id, Map<String, dynamic> notification) async {
    final response = await put('/notifications/$id', body: notification);
    return jsonDecode(response.body);
  }

  Future<Map<String, dynamic>> deleteNotification(int id) async {
    final response = await delete('/notifications/$id');
    return jsonDecode(response.body);
  }

  Future<Map<String, dynamic>> testNotification(int id) async {
    final response = await post('/notifications/$id/test');
    return jsonDecode(response.body);
  }

  // Dependency APIs (daidai-panel: /deps)
  Future<Map<String, dynamic>> getDependencies({String? type, String? pythonVersion}) async {
    String path = '/deps';
    final params = <String, String>{};
    if (type != null && type.isNotEmpty && type != 'all') {
      params['type'] = type;
    }
    if (pythonVersion != null && pythonVersion.isNotEmpty) {
      params['python_version'] = pythonVersion;
    }
    if (params.isNotEmpty) {
      path += '?' + params.entries.map((e) => '${e.key}=${e.value}').join('&');
    }
    final response = await get(path);
    return jsonDecode(response.body);
  }

  Future<Map<String, dynamic>> installDependency(String type, List<String> names) async {
    // daidai-panel format: POST /deps with body {type, names}
    final response = await post('/deps', body: {
      'type': type,
      'names': names,
    });
    return jsonDecode(response.body);
  }

  Future<Map<String, dynamic>> uninstallDependency(int id) async {
    final response = await delete('/deps/$id');
    return jsonDecode(response.body);
  }

  Future<Map<String, dynamic>> reinstallDependency(int id) async {
    final response = await put('/deps/$id/reinstall');
    return jsonDecode(response.body);
  }

  Future<Map<String, dynamic>> getDepStatus(int id) async {
    // daidai-panel: GET /deps/:id/status returns {data: {status, log, ...}}
    final response = await get('/deps/$id/status');
    return jsonDecode(response.body);
  }

  Future<Map<String, dynamic>> cancelDepOperation(int id) async {
    final response = await put('/deps/$id/cancel');
    return jsonDecode(response.body);
  }

  Future<Map<String, dynamic>> batchDeleteDeps(List<int> ids) async {
    final response = await post('/deps/batch-delete', body: {'ids': ids});
    return jsonDecode(response.body);
  }

  Future<Map<String, dynamic>> batchReinstallDeps(List<int> ids) async {
    final response = await post('/deps/batch-reinstall', body: {'ids': ids});
    return jsonDecode(response.body);
  }

  // Config APIs (daidai-panel: /configs)
  Future<Map<String, dynamic>> getConfig() async {
    final response = await get('/configs');
    return jsonDecode(response.body);
  }

  Future<Map<String, dynamic>> updateConfig(Map<String, dynamic> config) async {
    // daidai-panel: PUT /configs/batch with body {configs: {key: value}}
    final response = await put('/configs/batch', body: {'configs': config});
    return jsonDecode(response.body);
  }

  // Stats APIs
  Future<Map<String, dynamic>> getStats() async {
    final response = await get('/stats');
    return jsonDecode(response.body);
  }

  // User APIs
  Future<Map<String, dynamic>> getCurrentUser() async {
    final response = await get('/auth/user');
    return jsonDecode(response.body);
  }

  Future<Map<String, dynamic>> changePassword(String oldPassword, String newPassword) async {
    final response = await put('/auth/password', body: {
      'old_password': oldPassword,
      'new_password': newPassword,
    });
    return jsonDecode(response.body);
  }

  Future<Map<String, dynamic>> changeUsername(String newUsername) async {
    final response = await put('/auth/username', body: {
      'username': newUsername,
    });
    return jsonDecode(response.body);
  }

  // Backup and Restore APIs
  Future<Map<String, dynamic>> exportTasks() async {
    final response = await get('/tasks/export');
    return jsonDecode(response.body);
  }

  Future<Map<String, dynamic>> importTasks(List<Map<String, dynamic>> tasks) async {
    final response = await post('/tasks/import', body: {'tasks': tasks});
    return jsonDecode(response.body);
  }

  Future<Map<String, dynamic>> exportEnvs() async {
    final response = await get('/envs/export');
    return jsonDecode(response.body);
  }

  Future<Map<String, dynamic>> importEnvs(List<Map<String, dynamic>> envs) async {
    final response = await post('/envs/import', body: {'envs': envs});
    return jsonDecode(response.body);
  }

  Future<Map<String, dynamic>> exportScripts() async {
    final response = await get('/scripts/export');
    return jsonDecode(response.body);
  }

  Future<Map<String, dynamic>> importScripts(List<Map<String, dynamic>> scripts) async {
    final response = await post('/scripts/import', body: {'scripts': scripts});
    return jsonDecode(response.body);
  }

  // Script subscription APIs
  Future<Map<String, dynamic>> getScriptSubscriptions() async {
    final response = await get('/scripts/subscriptions');
    return jsonDecode(response.body);
  }

  Future<Map<String, dynamic>> addScriptSubscription(Map<String, dynamic> subscription) async {
    // Apply GitHub mirror acceleration for raw URLs
    if (subscription.containsKey('url')) {
      final url = subscription['url'] as String;
      if (url.contains('github.com') || url.contains('raw.githubusercontent.com')) {
        String mirrorUrl = url;
        if (url.contains('github.com') && url.contains('/raw/')) {
          mirrorUrl = url.replaceAll('github.com', 'raw.githubusercontent.com').replaceAll('/raw/', '/');
        }
        if (mirrorUrl.contains('raw.githubusercontent.com') || mirrorUrl.contains('github.com')) {
          mirrorUrl = 'https://ghproxy.com/$mirrorUrl';
        }
        subscription = Map.from(subscription)..['url'] = mirrorUrl;
      }
    }
    final response = await post('/scripts/subscriptions', body: subscription);
    return jsonDecode(response.body);
  }

  Future<Map<String, dynamic>> updateScriptSubscription(int id, Map<String, dynamic> subscription) async {
    final response = await put('/scripts/subscriptions/$id', body: subscription);
    return jsonDecode(response.body);
  }

  Future<Map<String, dynamic>> deleteScriptSubscription(int id) async {
    final response = await delete('/scripts/subscriptions/$id');
    return jsonDecode(response.body);
  }

  Future<Map<String, dynamic>> syncScriptSubscription(int id) async {
    final response = await post('/scripts/subscriptions/$id/sync');
    return jsonDecode(response.body);
  }

  // Task logs API
  Future<Map<String, dynamic>> getTaskLogs(int taskId, {int page = 1, int pageSize = 50}) async {
    final response = await get('/tasks/$taskId/logs?page=$page&page_size=$pageSize');
    return jsonDecode(response.body);
  }

  // System logs API
  Future<Map<String, dynamic>> getSystemLogs({int page = 1, int pageSize = 50}) async {
    final response = await get('/system/logs?page=$page&page_size=$pageSize');
    return jsonDecode(response.body);
  }

  // Login logs API
  Future<Map<String, dynamic>> getLoginLogs({int page = 1, int pageSize = 50}) async {
    final response = await get('/auth/login-logs?page=$page&page_size=$pageSize');
    return jsonDecode(response.body);
  }

  // ==================== Security API ====================

  // Sessions
  Future<Map<String, dynamic>> getSessions() async {
    final response = await get('/security/sessions');
    return jsonDecode(response.body);
  }

  Future<Map<String, dynamic>> revokeSession(int id) async {
    final response = await delete('/security/sessions/$id');
    return jsonDecode(response.body);
  }

  Future<Map<String, dynamic>> revokeAllSessions(int userId) async {
    final response = await delete('/security/sessions/user/$userId');
    return jsonDecode(response.body);
  }

  Future<Map<String, dynamic>> revokeOtherSessions() async {
    final response = await delete('/security/sessions/others');
    return jsonDecode(response.body);
  }

  // IP Whitelist
  Future<Map<String, dynamic>> getIPWhitelist() async {
    final response = await get('/security/ip-whitelist');
    return jsonDecode(response.body);
  }

  Future<Map<String, dynamic>> addIPWhitelist(String ip, {String? remarks}) async {
    final response = await post('/security/ip-whitelist', body: {'ip': ip, if (remarks != null) 'remarks': remarks});
    return jsonDecode(response.body);
  }

  Future<Map<String, dynamic>> removeIPWhitelist(int id) async {
    final response = await delete('/security/ip-whitelist/$id');
    return jsonDecode(response.body);
  }

  // 2FA
  Future<Map<String, dynamic>> setup2FA() async {
    final response = await post('/security/2fa/setup');
    return jsonDecode(response.body);
  }

  Future<Map<String, dynamic>> verify2FA(String code) async {
    final response = await post('/security/2fa/verify', body: {'code': code});
    return jsonDecode(response.body);
  }

  Future<Map<String, dynamic>> disable2FA(String code) async {
    final response = await delete('/security/2fa', body: {'code': code});
    return jsonDecode(response.body);
  }

  Future<Map<String, dynamic>> get2FAStatus() async {
    final response = await get('/security/2fa/status');
    return jsonDecode(response.body);
  }

  // Login stats
  Future<Map<String, dynamic>> getLoginStats({int days = 7}) async {
    final response = await get('/security/login-stats?days=$days');
    return jsonDecode(response.body);
  }

  // Audit logs
  Future<Map<String, dynamic>> getAuditLogs({int page = 1, int pageSize = 20}) async {
    final response = await get('/security/audit-logs?page=$page&page_size=$pageSize');
    return jsonDecode(response.body);
  }

  // Clear login logs
  Future<Map<String, dynamic>> clearLoginLogs() async {
    final response = await delete('/security/login-logs');
    return jsonDecode(response.body);
  }

  // ==================== Notification Types API ====================

  Future<Map<String, dynamic>> getNotificationTypes() async {
    final response = await get('/notifications/types');
    return jsonDecode(response.body);
  }

  Future<Map<String, dynamic>> enableNotification(int id) async {
    final response = await put('/notifications/$id/enable');
    return jsonDecode(response.body);
  }

  Future<Map<String, dynamic>> disableNotification(int id) async {
    final response = await put('/notifications/$id/disable');
    return jsonDecode(response.body);
  }

  Future<Map<String, dynamic>> sendNotification(String title, String content, {List<int>? channelIds}) async {
    final body = <String, dynamic>{
      'title': title,
      'content': content,
      if (channelIds != null && channelIds.isNotEmpty) 'channel_ids': channelIds,
    };
    final response = await post('/notifications/send', body: body);
    return jsonDecode(response.body);
  }

  // ==================== Config API ====================

  Future<Map<String, dynamic>> getConfigs() async {
    final response = await get('/configs');
    return jsonDecode(response.body);
  }

  Future<Map<String, dynamic>> updateConfigs(Map<String, dynamic> configs) async {
    final response = await put('/configs/batch', body: {'configs': configs});
    return jsonDecode(response.body);
  }

  // ==================== Backup API ====================

  Future<Map<String, dynamic>> getBackupConfig() async {
    final response = await get('/configs');
    return jsonDecode(response.body);
  }

  Future<Map<String, dynamic>> updateBackupConfig(Map<String, dynamic> config) async {
    final response = await put('/configs/batch', body: {'configs': config});
    return jsonDecode(response.body);
  }

  // ==================== Task Concurrency & Dependencies ====================

  Future<Map<String, dynamic>> updateTaskConcurrency(int id, int concurrency) async {
    final response = await put('/tasks/$id', body: {'task_concurrency': concurrency});
    return jsonDecode(response.body);
  }

  Future<Map<String, dynamic>> updateTaskDependencies(int id, String dependsOn) async {
    final response = await put('/tasks/$id', body: {'depends_on': dependsOn});
    return jsonDecode(response.body);
  }

  // ==================== Script Debug & Versions ====================

  Future<Map<String, dynamic>> debugScript(String path, {String? content, String? args}) async {
    final body = <String, dynamic>{
      'path': path,
      if (content != null) 'content': content,
      if (args != null) 'args': args,
    };
    final response = await post('/scripts/debug', body: body);
    return jsonDecode(response.body);
  }

  Future<Map<String, dynamic>> runScript(String path, {String? args}) async {
    final body = <String, dynamic>{
      'path': path,
      if (args != null) 'args': args,
    };
    final response = await post('/scripts/run', body: body);
    return jsonDecode(response.body);
  }

  Future<Map<String, dynamic>> getScriptVersions(String path) async {
    final response = await get('/scripts/versions?path=$path');
    return jsonDecode(response.body);
  }

  Future<Map<String, dynamic>> restoreScriptVersion(String path, int versionId) async {
    final response = await post('/scripts/versions/$versionId/restore', body: {'path': path});
    return jsonDecode(response.body);
  }

  Future<Map<String, dynamic>> renameScript(String oldPath, String newPath) async {
    final response = await put('/scripts/rename', body: {
      'old_path': oldPath,
      'new_path': newPath,
    });
    return jsonDecode(response.body);
  }

  Future<Map<String, dynamic>> moveScript(String sourcePath, String destPath) async {
    final response = await put('/scripts/move', body: {
      'source_path': sourcePath,
      'dest_path': destPath,
    });
    return jsonDecode(response.body);
  }

  // ==================== Log Cleanup Strategy ====================

  Future<Map<String, dynamic>> getLogCleanupConfig() async {
    final response = await get('/configs');
    return jsonDecode(response.body);
  }

  Future<Map<String, dynamic>> updateLogCleanupConfig(Map<String, dynamic> config) async {
    final response = await put('/configs/batch', body: {'configs': config});
    return jsonDecode(response.body);
  }

  Future<Map<String, dynamic>> cleanupLogs(int days) async {
    final response = await post('/logs/cleanup', body: {'days': days});
    return jsonDecode(response.body);
  }

  // ==================== Env Groups & Import/Export ====================

  Future<Map<String, dynamic>> getEnvGroups() async {
    final response = await get('/envs/groups');
    return jsonDecode(response.body);
  }

  Future<Map<String, dynamic>> exportEnvsQinglong() async {
    final response = await get('/envs/export?qinglong=true');
    return jsonDecode(response.body);
  }

  Future<Map<String, dynamic>> importEnvsQinglong(List<Map<String, dynamic>> envs) async {
    final response = await post('/envs/import', body: {'envs': envs, 'format': 'qinglong'});
    return jsonDecode(response.body);
  }

  // ==================== Subscription Enhancements ====================

  Future<Map<String, dynamic>> getSubscriptionSSHKeys() async {
    final response = await get('/ssh-keys');
    return jsonDecode(response.body);
  }

  Future<Map<String, dynamic>> addSubscriptionSSHKey(Map<String, dynamic> key) async {
    final response = await post('/ssh-keys', body: key);
    return jsonDecode(response.body);
  }

  Future<Map<String, dynamic>> deleteSubscriptionSSHKey(int id) async {
    final response = await delete('/ssh-keys/$id');
    return jsonDecode(response.body);
  }

  Future<Map<String, dynamic>> updateSubscriptionFilter(int id, Map<String, dynamic> filter) async {
    final response = await put('/scripts/subscriptions/$id', body: filter);
    return jsonDecode(response.body);
  }

  // ==================== Notification Templates ====================

  Future<Map<String, dynamic>> getNotificationTemplates() async {
    final response = await get('/notifications/templates');
    return jsonDecode(response.body);
  }

  Future<Map<String, dynamic>> createNotificationTemplate(Map<String, dynamic> template) async {
    final response = await post('/notifications/templates', body: template);
    return jsonDecode(response.body);
  }

  Future<Map<String, dynamic>> updateNotificationTemplate(int id, Map<String, dynamic> template) async {
    final response = await put('/notifications/templates/$id', body: template);
    return jsonDecode(response.body);
  }

  Future<Map<String, dynamic>> deleteNotificationTemplate(int id) async {
    final response = await delete('/notifications/templates/$id');
    return jsonDecode(response.body);
  }

  // ==================== System Config (Panel Title/Icon) ====================

  Future<Map<String, dynamic>> getSystemConfig() async {
    final response = await get('/configs');
    return jsonDecode(response.body);
  }

  Future<Map<String, dynamic>> updateSystemConfig(Map<String, dynamic> config) async {
    final response = await put('/configs/batch', body: {'configs': config});
    return jsonDecode(response.body);
  }

  // ==================== Backup Operations ====================

  Future<Map<String, dynamic>> createBackup({String? name}) async {
    final response = await post('/system/backup', body: {
      if (name != null) 'name': name,
    });
    return jsonDecode(response.body);
  }

  Future<Map<String, dynamic>> getBackups() async {
    final response = await get('/system/backups');
    return jsonDecode(response.body);
  }

  Future<Map<String, dynamic>> restoreBackup(String name) async {
    final response = await post('/system/backup/$name/restore');
    return jsonDecode(response.body);
  }

  Future<Map<String, dynamic>> deleteBackup(String name) async {
    final response = await delete('/system/backup/$name');
    return jsonDecode(response.body);
  }

  Future<Map<String, dynamic>> downloadBackup(String name) async {
    final response = await get('/system/backup/$name/download');
    return jsonDecode(response.body);
  }

  // ==================== Task Views ====================

  Future<Map<String, dynamic>> getTaskViews() async {
    final response = await get('/tasks/views');
    return jsonDecode(response.body);
  }

  Future<Map<String, dynamic>> createTaskView(Map<String, dynamic> view) async {
    final response = await post('/tasks/views', body: view);
    return jsonDecode(response.body);
  }

  Future<Map<String, dynamic>> updateTaskView(int id, Map<String, dynamic> view) async {
    final response = await put('/tasks/views/$id', body: view);
    return jsonDecode(response.body);
  }

  Future<Map<String, dynamic>> deleteTaskView(int id) async {
    final response = await delete('/tasks/views/$id');
    return jsonDecode(response.body);
  }

  // ==================== Log Stats ====================

  Future<Map<String, dynamic>> getLogStats({int days = 7}) async {
    final response = await get('/logs/stats?days=$days');
    return jsonDecode(response.body);
  }

  Future<Map<String, dynamic>> getTaskLogStats(int taskId, {int days = 7}) async {
    final response = await get('/tasks/$taskId/stats?days=$days');
    return jsonDecode(response.body);
  }
}
