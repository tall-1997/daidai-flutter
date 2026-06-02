import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../services/auth_service.dart';
import '../theme/miuix_theme.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _serverController = TextEditingController();
  final _totpController = TextEditingController();
  final _clientIdController = TextEditingController();
  final _clientSecretController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureClientSecret = true;
  String? _loginError;
  String? _errorDetail;
  bool _showSavedAccounts = false;
  bool _rememberPassword = true;
  bool _autoLogin = false;
  
  // Login mode: 'normal', 'client', '2fa'
  String _loginMode = 'normal';

  @override
  void initState() {
    super.initState();
    final authService = context.read<AuthService>();
    _serverController.text = authService.serverUrl;
    _autoLogin = authService.autoLogin;

    // Auto-fill from last login info
    if (authService.lastServerUrl != null && authService.lastServerUrl!.isNotEmpty) {
      _serverController.text = authService.lastServerUrl!;
    }
    if (authService.lastUsername != null && authService.lastUsername!.isNotEmpty) {
      _usernameController.text = authService.lastUsername!;
    }

    // Try to find saved account and fill password
    _fillFromSavedAccount();

    // If there are saved accounts, show them
    if (authService.savedAccounts.isNotEmpty) {
      _showSavedAccounts = true;
    }

    // Auto login if enabled and credentials exist
    if (_autoLogin && _usernameController.text.isNotEmpty && _passwordController.text.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _login());
    }
  }

  void _fillFromSavedAccount() {
    final authService = context.read<AuthService>();
    final serverUrl = _serverController.text.trim();
    final username = _usernameController.text.trim();
    
    if (serverUrl.isNotEmpty && username.isNotEmpty) {
      final account = authService.savedAccounts.where(
        (a) => a.serverUrl == serverUrl && a.username == username
      ).firstOrNull;
      
      if (account?.password != null && account!.password!.isNotEmpty) {
        _passwordController.text = account.password!;
      }
    }
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    _serverController.dispose();
    _totpController.dispose();
    _clientIdController.dispose();
    _clientSecretController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _loginError = null;
      _errorDetail = null;
    });

    try {
      final authService = context.read<AuthService>();

      if (_loginMode == 'client') {
        // Client login
        final success = await authService.clientLogin(
          _clientIdController.text.trim(),
          _clientSecretController.text,
          serverUrl: _serverController.text.trim(),
        );

        if (mounted) {
          setState(() => _isLoading = false);

          if (success) {
            // Login success
          } else {
            final error = authService.error ?? 'Client登录失败';
            setState(() {
              _loginError = error;
              _errorDetail = _buildErrorDetail(error);
            });
          }
        }
      } else if (_loginMode == '2fa') {
        // 2FA login
        final success = await authService.login(
          _usernameController.text.trim(),
          _passwordController.text,
          serverUrl: _serverController.text.trim(),
          totpCode: _totpController.text.trim(),
        );

        if (mounted) {
          setState(() => _isLoading = false);

          if (success) {
            // Login success
          } else {
            final error = authService.error ?? '验证失败';
            if (error == '2FA_REQUIRED') {
              // Stay in 2FA mode
              setState(() {
                _loginError = null;
              });
            } else {
              setState(() {
                _loginError = error;
                _errorDetail = _buildErrorDetail(error);
              });
            }
          }
        }
      } else {
        // Normal login
        final success = await authService.login(
          _usernameController.text.trim(),
          _passwordController.text,
          serverUrl: _serverController.text.trim(),
        );

        if (mounted) {
          setState(() => _isLoading = false);

          if (success) {
            // Login success - update password in saved account if rememberPassword is true
            if (_rememberPassword) {
              // Password was already saved by AuthService.login()
            } else {
              // Clear password from saved account
              final prefs = await SharedPreferences.getInstance();
              final accountsJson = prefs.getString('saved_accounts');
              if (accountsJson != null) {
                final List<dynamic> accountsList = jsonDecode(accountsJson);
                final accounts = accountsList.map((a) => SavedAccount.fromJson(a)).toList();
                final serverUrl = _serverController.text.trim();
                final username = _usernameController.text.trim();
                final index = accounts.indexWhere(
                  (a) => a.serverUrl == serverUrl && a.username == username
                );
                if (index >= 0) {
                  accounts[index] = SavedAccount(
                    serverUrl: accounts[index].serverUrl,
                    username: accounts[index].username,
                    accessToken: accounts[index].accessToken,
                    refreshToken: accounts[index].refreshToken,
                  );
                  await prefs.setString('saved_accounts', jsonEncode(accounts.map((a) => a.toJson()).toList()));
                }
              }
            }
          } else {
            final error = authService.error ?? '登录失败';
            if (error == '2FA_REQUIRED') {
              // Switch to 2FA mode
              setState(() {
                _loginMode = '2fa';
                _loginError = null;
              });
            } else {
              setState(() {
                _loginError = error;
                _errorDetail = _buildErrorDetail(error);
              });
            }
          }
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _loginError = '登录异常: $e';
          _errorDetail = _buildErrorDetail('登录异常: $e');
        });
      }
    }
  }

  String _buildErrorDetail(String error) {
    final buffer = StringBuffer();
    buffer.writeln('=== 登录错误报告 ===');
    buffer.writeln('时间: ${DateTime.now().toLocal()}');
    buffer.writeln('服务器: ${_serverController.text.trim()}');
    buffer.writeln('用户名: ${_usernameController.text.trim()}');
    buffer.writeln('登录模式: $_loginMode');
    buffer.writeln('错误: $error');
    buffer.writeln('==================');
    return buffer.toString();
  }

  void _showErrorReport() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('登录错误报告'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(_loginError ?? '未知错误', style: const TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: SelectableText(
                  _errorDetail ?? '',
                  style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('关闭')),
          FilledButton.icon(
            onPressed: () {
              Clipboard.setData(ClipboardData(text: _errorDetail ?? ''));
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('错误报告已复制到剪贴板')),
              );
            },
            icon: const Icon(Icons.copy),
            label: const Text('复制'),
          ),
        ],
      ),
    );
  }

  void _selectAccount(SavedAccount account) {
    _serverController.text = account.serverUrl;
    _usernameController.text = account.username;
    _passwordController.text = account.password ?? '';
    setState(() => _showSavedAccounts = false);
  }

  void _switchLoginMode(String mode) {
    setState(() {
      _loginMode = mode;
      _loginError = null;
      _errorDetail = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final authService = context.watch<AuthService>();

    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Icon(Icons.dashboard_customize, size: 80, color: Theme.of(context).colorScheme.primary),
                  const SizedBox(height: 16),
                  Text('呆呆面板', textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text('任务调度管理平台', textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant)),
                  const SizedBox(height: 32),

                  // Login mode selector
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(8),
                      child: Row(
                        children: [
                          _buildLoginModeChip('普通登录', 'normal', Icons.person),
                          _buildLoginModeChip('Client登录', 'client', Icons.vpn_key),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Saved accounts
                  if (_showSavedAccounts && authService.savedAccounts.isNotEmpty && _loginMode != 'client') ...[
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.history, size: 20),
                                const SizedBox(width: 8),
                                const Text('历史账户', style: TextStyle(fontWeight: FontWeight.bold)),
                                const Spacer(),
                                TextButton(
                                  onPressed: () => setState(() => _showSavedAccounts = false),
                                  child: const Text('隐藏'),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            ...authService.savedAccounts.take(5).map((account) => ListTile(
                              dense: true,
                              leading: CircleAvatar(
                                radius: 16,
                                child: Text(account.username[0].toUpperCase()),
                              ),
                              title: Text(account.username),
                              subtitle: Text(account.serverUrl, style: const TextStyle(fontSize: 12)),
                              trailing: IconButton(
                                icon: const Icon(Icons.delete, size: 18),
                                onPressed: () => authService.removeAccount(account),
                              ),
                              onTap: () => _selectAccount(account),
                            )),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Server URL field (always visible)
                  TextFormField(
                    controller: _serverController,
                    decoration: InputDecoration(
                      labelText: '服务器地址',
                      hintText: 'http://127.0.0.1:5700',
                      prefixIcon: const Icon(Icons.dns),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    keyboardType: TextInputType.url,
                    validator: (value) {
                      if (value == null || value.isEmpty) return '请输入服务器地址';
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Normal login fields
                  if (_loginMode == 'normal' || _loginMode == '2fa') ...[
                    if (_loginMode == '2fa') ...[
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.blue.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.blue),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.security, color: Colors.blue, size: 20),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                '需要两步验证，请输入验证码',
                                style: TextStyle(color: Colors.blue[700]),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                    TextFormField(
                      controller: _usernameController,
                      decoration: InputDecoration(
                        labelText: '用户名',
                        prefixIcon: const Icon(Icons.person),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) return '请输入用户名';
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _passwordController,
                      decoration: InputDecoration(
                        labelText: '密码',
                        prefixIcon: const Icon(Icons.lock),
                        suffixIcon: IconButton(
                          icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility),
                          onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                        ),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      obscureText: _obscurePassword,
                      validator: (value) {
                        if (value == null || value.isEmpty) return '请输入密码';
                        return null;
                      },
                      onFieldSubmitted: _loginMode == 'normal' ? (_) => _login() : null,
                    ),
                    if (_loginMode == '2fa') ...[
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _totpController,
                        decoration: InputDecoration(
                          labelText: '验证码 (TOTP)',
                          hintText: '6位数字验证码',
                          prefixIcon: const Icon(Icons.pin),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(6),
                        ],
                        validator: (value) {
                          if (value == null || value.isEmpty) return '请输入验证码';
                          if (value.length != 6) return '验证码必须是6位数字';
                          return null;
                        },
                        onFieldSubmitted: (_) => _login(),
                      ),
                    ],
                  ],

                  // Client login fields
                  if (_loginMode == 'client') ...[
                    TextFormField(
                      controller: _clientIdController,
                      decoration: InputDecoration(
                        labelText: 'Client ID',
                        prefixIcon: const Icon(Icons.vpn_key),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) return '请输入Client ID';
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _clientSecretController,
                      decoration: InputDecoration(
                        labelText: 'Client Secret',
                        prefixIcon: const Icon(Icons.lock),
                        suffixIcon: IconButton(
                          icon: Icon(_obscureClientSecret ? Icons.visibility_off : Icons.visibility),
                          onPressed: () => setState(() => _obscureClientSecret = !_obscureClientSecret),
                        ),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      obscureText: _obscureClientSecret,
                      validator: (value) {
                        if (value == null || value.isEmpty) return '请输入Client Secret';
                        return null;
                      },
                      onFieldSubmitted: (_) => _login(),
                    ),
                  ],

                  const SizedBox(height: 24),

                  // Remember password and auto-login
                  if (_loginMode != 'client') ...[
                    Row(
                      children: [
                        Expanded(
                          child: CheckboxListTile(
                            value: _rememberPassword,
                            onChanged: (value) => setState(() => _rememberPassword = value ?? true),
                            title: const Text('记住密码', style: TextStyle(fontSize: 13)),
                            controlAffinity: ListTileControlAffinity.leading,
                            contentPadding: EdgeInsets.zero,
                            dense: true,
                            visualDensity: VisualDensity.compact,
                          ),
                        ),
                        Expanded(
                          child: CheckboxListTile(
                            value: _autoLogin,
                            onChanged: (value) {
                              setState(() => _autoLogin = value ?? false);
                              context.read<AuthService>().setAutoLogin(_autoLogin);
                            },
                            title: const Text('自动登录', style: TextStyle(fontSize: 13)),
                            controlAffinity: ListTileControlAffinity.leading,
                            contentPadding: EdgeInsets.zero,
                            dense: true,
                            visualDensity: VisualDensity.compact,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                  ],

                  FilledButton(
                    onPressed: _isLoading ? null : _login,
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      foregroundColor: Theme.of(context).colorScheme.onPrimary,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: _isLoading
                        ? SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Theme.of(context).colorScheme.onPrimary))
                        : Text(_loginMode == '2fa' ? '验证' : '登录', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                  if (_loginMode == '2fa') ...[
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: () => _switchLoginMode('normal'),
                      child: const Text('返回普通登录'),
                    ),
                  ],
                  if (_loginError != null) ...[
                    const SizedBox(height: 16),
                    OutlinedButton.icon(
                      onPressed: _showErrorReport,
                      icon: const Icon(Icons.bug_report, color: Colors.red),
                      label: const Text('查看错误报告', style: TextStyle(color: Colors.red)),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        side: const BorderSide(color: Colors.red),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ],
                  if (!_showSavedAccounts && authService.savedAccounts.isNotEmpty && _loginMode != 'client') ...[
                    const SizedBox(height: 12),
                    TextButton.icon(
                      onPressed: () => setState(() => _showSavedAccounts = true),
                      icon: const Icon(Icons.history),
                      label: const Text('显示历史账户'),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoginModeChip(String label, String mode, IconData icon) {
    final isSelected = _loginMode == mode || (mode == 'normal' && _loginMode == '2fa');
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: InkWell(
          onTap: () => _switchLoginMode(mode),
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              color: isSelected ? Theme.of(context).colorScheme.primaryContainer : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 16, color: isSelected ? Theme.of(context).colorScheme.primary : Colors.grey),
                const SizedBox(width: 4),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: isSelected ? Theme.of(context).colorScheme.primary : Colors.grey,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
