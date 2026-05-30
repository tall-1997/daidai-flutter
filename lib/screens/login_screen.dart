import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';

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
  bool _isLoading = false;
  bool _obscurePassword = true;
  String? _loginError;
  String? _errorDetail;
  bool _showSavedAccounts = false;

  @override
  void initState() {
    super.initState();
    final authService = context.read<AuthService>();
    _serverController.text = authService.serverUrl;

    // If there are saved accounts, show them
    if (authService.savedAccounts.isNotEmpty) {
      _showSavedAccounts = true;
    }
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    _serverController.dispose();
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
      await authService.setServerUrl(_serverController.text.trim());

      final success = await authService.login(
        _usernameController.text.trim(),
        _passwordController.text,
      );

      if (mounted) {
        setState(() => _isLoading = false);

        if (success) {
          // Login success
        } else {
          final error = authService.error ?? '登录失败';
          setState(() {
            _loginError = error;
            _errorDetail = _buildErrorDetail(error);
          });
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
    _passwordController.text = '';
    setState(() => _showSavedAccounts = false);
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

                  // Saved accounts
                  if (_showSavedAccounts && authService.savedAccounts.isNotEmpty) ...[
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
                    onFieldSubmitted: (_) => _login(),
                  ),
                  const SizedBox(height: 24),
                  FilledButton(
                    onPressed: _isLoading ? null : _login,
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: _isLoading
                        ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Text('登录'),
                  ),
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
                  if (!_showSavedAccounts && authService.savedAccounts.isNotEmpty) ...[
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
}
