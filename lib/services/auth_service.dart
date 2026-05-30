import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'api_service.dart';

class SavedAccount {
  final String serverUrl;
  final String username;
  final String? accessToken;
  final String? refreshToken;

  SavedAccount({
    required this.serverUrl,
    required this.username,
    this.accessToken,
    this.refreshToken,
  });

  Map<String, dynamic> toJson() => {
    'serverUrl': serverUrl,
    'username': username,
    'accessToken': accessToken,
    'refreshToken': refreshToken,
  };

  factory SavedAccount.fromJson(Map<String, dynamic> json) => SavedAccount(
    serverUrl: json['serverUrl'] ?? '',
    username: json['username'] ?? '',
    accessToken: json['accessToken'],
    refreshToken: json['refreshToken'],
  );

  String get displayTitle => '$username@$serverUrl';
}

class AuthService extends ChangeNotifier {
  final ApiService _apiService = ApiService();
  bool _isAuthenticated = false;
  bool _isInitialized = false;
  String? _username;
  String? _error;
  List<SavedAccount> _savedAccounts = [];

  bool get isAuthenticated => _isAuthenticated;
  bool get isInitialized => _isInitialized;
  String? get username => _username;
  String? get error => _error;
  ApiService get apiService => _apiService;
  List<SavedAccount> get savedAccounts => _savedAccounts;

  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      await _apiService.init();
      final prefs = await SharedPreferences.getInstance();
      final accessToken = prefs.getString('access_token');
      _username = prefs.getString('username');

      // Load saved accounts
      final accountsJson = prefs.getString('saved_accounts');
      if (accountsJson != null) {
        final List<dynamic> accountsList = jsonDecode(accountsJson);
        _savedAccounts = accountsList.map((a) => SavedAccount.fromJson(a)).toList();
      }

      if (accessToken != null) {
        _isAuthenticated = true;
      }
    } catch (e) {
      // Initialization error
    }
    _isInitialized = true;
    notifyListeners();
  }

  Future<bool> login(String username, String password) async {
    try {
      _error = null;
      final result = await _apiService.login(username, password);

      // API returns tokens at top level, not in 'data'
      final accessToken = result['access_token'] ?? result['data']?['access_token'];
      final refreshToken = result['refresh_token'] ?? result['data']?['refresh_token'];

      if (accessToken != null) {
        await _apiService.setTokens(accessToken, refreshToken ?? '');

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('username', username);

        // Save account
        final account = SavedAccount(
          serverUrl: _apiService.baseUrl,
          username: username,
          accessToken: accessToken,
          refreshToken: refreshToken,
        );
        await _saveAccount(account);

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

  Future<void> _saveAccount(SavedAccount account) async {
    // Remove existing account with same server+username
    _savedAccounts.removeWhere((a) =>
        a.serverUrl == account.serverUrl && a.username == account.username);
    // Add new account at the beginning
    _savedAccounts.insert(0, account);
    // Keep only last 10 accounts
    if (_savedAccounts.length > 10) {
      _savedAccounts = _savedAccounts.sublist(0, 10);
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('saved_accounts', jsonEncode(_savedAccounts.map((a) => a.toJson()).toList()));
  }

  Future<void> switchAccount(SavedAccount account) async {
    await _apiService.setServerUrl(account.serverUrl);
    if (account.accessToken != null && account.refreshToken != null) {
      await _apiService.setTokens(account.accessToken!, account.refreshToken!);
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('username', account.username);
    await prefs.setString('server_url', account.serverUrl);

    _isAuthenticated = true;
    _username = account.username;
    notifyListeners();
  }

  Future<void> removeAccount(SavedAccount account) async {
    _savedAccounts.removeWhere((a) =>
        a.serverUrl == account.serverUrl && a.username == account.username);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('saved_accounts', jsonEncode(_savedAccounts.map((a) => a.toJson()).toList()));
    notifyListeners();
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
