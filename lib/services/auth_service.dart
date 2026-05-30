import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'api_service.dart';

class AuthService extends ChangeNotifier {
  final ApiService _apiService = ApiService();
  bool _isAuthenticated = false;
  String? _username;
  String? _error;

  bool get isAuthenticated => _isAuthenticated;
  String? get username => _username;
  String? get error => _error;
  ApiService get apiService => _apiService;

  AuthService() {
    _init();
  }

  Future<void> _init() async {
    await _apiService.init();
    final prefs = await SharedPreferences.getInstance();
    final accessToken = prefs.getString('access_token');
    _username = prefs.getString('username');
    
    if (accessToken != null) {
      _isAuthenticated = true;
      notifyListeners();
    }
  }

  Future<bool> login(String username, String password) async {
    try {
      _error = null;
      final result = await _apiService.login(username, password);
      
      if (result['data'] != null) {
        final data = result['data'];
        await _apiService.setTokens(
          data['access_token'],
          data['refresh_token'],
        );
        
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('username', username);
        
        _isAuthenticated = true;
        _username = username;
        notifyListeners();
        return true;
      } else {
        _error = result['message'] ?? '登录失败';
        notifyListeners();
        return false;
      }
    } catch (e) {
      _error = '网络错误: $e';
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    await _apiService.clearTokens();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('username');
    
    _isAuthenticated = false;
    _username = null;
    notifyListeners();
  }

  Future<void> setServerUrl(String url) async {
    await _apiService.setServerUrl(url);
    notifyListeners();
  }

  String get serverUrl => _apiService.baseUrl;
}
