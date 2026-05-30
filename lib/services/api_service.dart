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
    _baseUrl = prefs.getString('server_url') ?? _defaultBaseUrl;
    _accessToken = prefs.getString('access_token');
    _refreshToken = prefs.getString('refresh_token');
  }

  Future<void> setServerUrl(String url) async {
    _baseUrl = url;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('server_url', url);
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

  Future<http.Response> post(String path, {Map<String, dynamic>? body}) async {
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

  Future<http.Response> put(String path, {Map<String, dynamic>? body}) async {
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

  Future<http.Response> delete(String path) async {
    final uri = Uri.parse('$baseUrl/api/v1$path');
    final response = await http.delete(uri, headers: _headers);
    
    if (response.statusCode == 401 && _refreshToken != null) {
      final refreshed = await _tryRefreshToken();
      if (refreshed) {
        return http.delete(uri, headers: _headers);
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
        if (data['data'] != null) {
          await setTokens(
            data['data']['access_token'],
            data['data']['refresh_token'] ?? _refreshToken!,
          );
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

  // Task APIs
  Future<Map<String, dynamic>> getTasks({int page = 1, int pageSize = 20, String? search}) async {
    String path = '/tasks?page=$page&page_size=$pageSize';
    if (search != null && search.isNotEmpty) {
      path += '&search=$search';
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
    final response = await post('/tasks/$id/run');
    return jsonDecode(response.body);
  }

  Future<Map<String, dynamic>> stopTask(int id) async {
    final response = await post('/tasks/$id/stop');
    return jsonDecode(response.body);
  }

  Future<Map<String, dynamic>> enableTask(int id) async {
    final response = await post('/tasks/$id/enable');
    return jsonDecode(response.body);
  }

  Future<Map<String, dynamic>> disableTask(int id) async {
    final response = await post('/tasks/$id/disable');
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
  Future<Map<String, dynamic>> getLogs({int page = 1, int pageSize = 50}) async {
    final response = await get('/logs?page=$page&page_size=$pageSize');
    return jsonDecode(response.body);
  }

  // Env APIs
  Future<Map<String, dynamic>> getEnvs() async {
    final response = await get('/envs');
    return jsonDecode(response.body);
  }

  Future<Map<String, dynamic>> createEnv(Map<String, dynamic> env) async {
    final response = await post('/envs', body: env);
    return jsonDecode(response.body);
  }

  Future<Map<String, dynamic>> deleteEnv(int id) async {
    final response = await delete('/envs/$id');
    return jsonDecode(response.body);
  }

  // Dependency APIs
  Future<Map<String, dynamic>> getDependencies() async {
    final response = await get('/dependencies');
    return jsonDecode(response.body);
  }

  Future<Map<String, dynamic>> installDependency(Map<String, dynamic> dep) async {
    final response = await post('/dependencies/install', body: dep);
    return jsonDecode(response.body);
  }

  // Script APIs
  Future<Map<String, dynamic>> getScripts() async {
    final response = await get('/scripts');
    return jsonDecode(response.body);
  }

  Future<Map<String, dynamic>> createScript(Map<String, dynamic> script) async {
    final response = await post('/scripts', body: script);
    return jsonDecode(response.body);
  }

  // Notification APIs
  Future<Map<String, dynamic>> getNotifications() async {
    final response = await get('/notifications');
    return jsonDecode(response.body);
  }

  // Config APIs
  Future<Map<String, dynamic>> getConfig() async {
    final response = await get('/config');
    return jsonDecode(response.body);
  }

  Future<Map<String, dynamic>> updateConfig(Map<String, dynamic> config) async {
    final response = await put('/config', body: config);
    return jsonDecode(response.body);
  }

  // Stats APIs
  Future<Map<String, dynamic>> getStats() async {
    final response = await get('/stats');
    return jsonDecode(response.body);
  }
}
