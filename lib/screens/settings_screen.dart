import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:convert';
import '../services/auth_service.dart';
import '../services/log_service.dart';
import '../theme/miuix_theme.dart';
import '../widgets/miuix_widgets.dart';
import 'home_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> with RefreshableScreen {
  Map<String, dynamic>? _user;
  List<Map<String, dynamic>> _users = [];
  bool _isLoading = true;
  String? _error;
  bool _is2FAEnabled = false;
  bool _showUserManagement = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void refresh() {
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final authService = context.read<AuthService>();
      
      // 获取当前用户信息
      final userResponse = await authService.apiService.getCurrentUser();
      final userData = userResponse['data'] ?? userResponse;
      
      // 获取2FA状态
      final tfaResponse = await authService.apiService.get2FAStatus();
      final tfaEnabled = tfaResponse['data']?['enabled'] ?? false;

      // 如果是管理员，获取用户列表
      List<Map<String, dynamic>> users = [];
      if (userData['role'] == 'admin') {
        try {
          final usersResponse = await authService.apiService.get('/users');
          final usersResult = jsonDecode(usersResponse.body);
          users = List<Map<String, dynamic>>.from(usersResult['data'] ?? []);
        } catch (e) {
          // 忽略错误
        }
      }

      if (mounted) {
        setState(() {
          _user = userData;
          _is2FAEnabled = tfaEnabled;
          _users = users;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = '加载失败: $e';
          _isLoading = false;
        });
      }
    }
  }

  void _showChangePasswordDialog() {
    final oldPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('修改密码'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: oldPasswordController,
                decoration: const InputDecoration(
                  labelText: '当前密码',
                  border: OutlineInputBorder(),
                ),
                obscureText: true,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: newPasswordController,
                decoration: const InputDecoration(
                  labelText: '新密码',
                  border: OutlineInputBorder(),
                ),
                obscureText: true,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: confirmPasswordController,
                decoration: const InputDecoration(
                  labelText: '确认新密码',
                  border: OutlineInputBorder(),
                ),
                obscureText: true,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () async {
              if (newPasswordController.text != confirmPasswordController.text) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('两次密码不一致'), backgroundColor: Colors.red),
                );
                return;
              }

              try {
                final authService = context.read<AuthService>();
                await authService.apiService.changePassword(
                  oldPasswordController.text,
                  newPasswordController.text,
                );
                Navigator.pop(context);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('密码已修改'), backgroundColor: Colors.green),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('修改失败: $e'), backgroundColor: Colors.red),
                  );
                }
              }
            },
            child: const Text('确认'),
          ),
        ],
      ),
    );
  }

  void _showChangeUsernameDialog() {
    final usernameController = TextEditingController(text: _user?['username'] ?? '');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('修改用户名'),
        content: TextField(
          controller: usernameController,
          decoration: const InputDecoration(
            labelText: '新用户名',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () async {
              if (usernameController.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('请输入用户名'), backgroundColor: Colors.red),
                );
                return;
              }

              try {
                final authService = context.read<AuthService>();
                await authService.apiService.changeUsername(usernameController.text);
                Navigator.pop(context);
                _loadData();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('用户名已修改'), backgroundColor: Colors.green),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('修改失败: $e'), backgroundColor: Colors.red),
                  );
                }
              }
            },
            child: const Text('确认'),
          ),
        ],
      ),
    );
  }

  void _showCreateUserDialog() {
    _showEditUserDialog(null);
  }

  void _showEditUserDialog(Map<String, dynamic>? user) {
    final isCreate = user == null;
    final usernameController = TextEditingController(text: user?['username'] ?? '');
    final passwordController = TextEditingController();
    String role = user?['role'] ?? 'user';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(isCreate ? '创建用户' : '编辑用户'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: usernameController,
                  decoration: const InputDecoration(
                    labelText: '用户名',
                    border: OutlineInputBorder(),
                  ),
                  enabled: isCreate,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: passwordController,
                  decoration: InputDecoration(
                    labelText: isCreate ? '密码' : '新密码（留空不修改）',
                    border: const OutlineInputBorder(),
                  ),
                  obscureText: true,
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: role,
                  decoration: const InputDecoration(
                    labelText: '角色',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'user', child: Text('普通用户')),
                    DropdownMenuItem(value: 'admin', child: Text('管理员')),
                  ],
                  onChanged: (value) {
                    setDialogState(() => role = value!);
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('取消'),
            ),
            FilledButton(
              onPressed: () async {
                if (usernameController.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('请输入用户名'), backgroundColor: Colors.red),
                  );
                  return;
                }

                try {
                  final authService = context.read<AuthService>();
                  final body = <String, dynamic>{
                    'username': usernameController.text,
                    'role': role,
                    if (passwordController.text.isNotEmpty) 'password': passwordController.text,
                  };

                  if (isCreate) {
                    await authService.apiService.post('/users', body: body);
                  } else {
                    await authService.apiService.put('/users/${user['id']}', body: body);
                  }

                  Navigator.pop(context);
                  _loadData();
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(isCreate ? '用户已创建' : '用户已更新'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('操作失败: $e'), backgroundColor: Colors.red),
                    );
                  }
                }
              },
              child: Text(isCreate ? '创建' : '保存'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _deleteUser(int id, String username) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认删除'),
        content: Text('确定要删除用户 "$username" 吗？'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('取消')),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('删除'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final authService = context.read<AuthService>();
        await authService.apiService.delete('/users/$id');
        _loadData();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('用户已删除'), backgroundColor: Colors.green),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('删除失败: $e'), backgroundColor: Colors.red),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final authService = context.watch<AuthService>();
    final isAdmin = _user?['role'] == 'admin';

    return Scaffold(
      appBar: AppBar(
        title: const Text('设置'),
      ),
      body: _isLoading
          ? const MiuixLoadingState()
          : _error != null
              ? MiuixErrorState(message: _error!, onRetry: _loadData)
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    _buildProfileCard(isDark, authService),
                    if (isAdmin) ...[
                      const SizedBox(height: 16),
                      _buildUserManagementCard(isDark),
                    ],
                    const SizedBox(height: 16),
                    _buildAboutCard(isDark),
                  ],
                ),
    );
  }

  Widget _buildProfileCard(bool isDark, AuthService authService) {
    final username = _user?['username'] ?? authService.username ?? '未知用户';
    final role = _user?['role'] ?? 'user';
    final createdAt = _user?['created_at'] ?? '';

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '个人信息',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: isDark ? MiuixColors.darkOnSurface : MiuixColors.onSurface,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: MiuixColors.primary,
                  child: Text(
                    username[0].toUpperCase(),
                    style: const TextStyle(color: Colors.white, fontSize: 24),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        username,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: isDark ? MiuixColors.darkOnSurface : MiuixColors.onSurface,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: role == 'admin' ? Colors.orange.withOpacity(0.1) : Colors.blue.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          role == 'admin' ? '管理员' : '普通用户',
                          style: TextStyle(
                            fontSize: 12,
                            color: role == 'admin' ? Colors.orange : Colors.blue,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (createdAt.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                '注册时间: $createdAt',
                style: TextStyle(
                  fontSize: 12,
                  color: isDark ? MiuixColors.darkOnSurfaceVariantSummary : MiuixColors.onSurfaceVariantSummary,
                ),
              ),
            ],
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _showChangeUsernameDialog,
                    icon: const Icon(Icons.edit, size: 18),
                    label: const Text('修改用户名'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _showChangePasswordDialog,
                    icon: const Icon(Icons.lock, size: 18),
                    label: const Text('修改密码'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUserManagementCard(bool isDark) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '用户管理',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: isDark ? MiuixColors.darkOnSurface : MiuixColors.onSurface,
                  ),
                ),
                TextButton.icon(
                  onPressed: _showCreateUserDialog,
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('添加用户'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (_users.isEmpty)
              const Padding(
                padding: EdgeInsets.all(16),
                child: Text('暂无其他用户'),
              )
            else
              ..._users.map((user) => _buildUserItem(user, isDark)),
          ],
        ),
      ),
    );
  }

  Widget _buildUserItem(Map<String, dynamic> user, bool isDark) {
    final id = user['id'] ?? 0;
    final username = user['username'] ?? '未知';
    final role = user?['role'] ?? 'user';

    return ListTile(
      leading: CircleAvatar(
        backgroundColor: role == 'admin' ? Colors.orange : MiuixColors.primary,
        child: Text(
          username[0].toUpperCase(),
          style: const TextStyle(color: Colors.white),
        ),
      ),
      title: Text(username),
      subtitle: Text(role == 'admin' ? '管理员' : '普通用户'),
      trailing: PopupMenuButton<String>(
        onSelected: (value) {
          if (value == 'edit') {
            _showEditUserDialog(user);
          } else if (value == 'delete') {
            _deleteUser(id, username);
          }
        },
        itemBuilder: (context) => [
          const PopupMenuItem(value: 'edit', child: Text('编辑')),
          const PopupMenuItem(
            value: 'delete',
            child: Text('删除', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Widget _buildAboutCard(bool isDark) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '关于',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: isDark ? MiuixColors.darkOnSurface : MiuixColors.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            ListTile(
              leading: const Icon(Icons.info_outline),
              title: const Text('版本'),
              subtitle: const Text('v0.0.45'),
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.bug_report),
              title: const Text('导出调试日志'),
              subtitle: const Text('导出 App 运行日志用于问题排查'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => _showExportLogDialog(),
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline),
              title: const Text('清除日志'),
              subtitle: const Text('清除本地缓存的调试日志'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => _showClearLogDialog(),
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('退出登录'),
              onTap: () async {
                final confirmed = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('确认退出'),
                    content: const Text('确定要退出登录吗？'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text('取消'),
                      ),
                      FilledButton(
                        onPressed: () => Navigator.pop(context, true),
                        child: const Text('确认'),
                      ),
                    ],
                  ),
                );

                if (confirmed == true) {
                  final authService = context.read<AuthService>();
                  await authService.logout();
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showExportLogDialog() {
    final logService = context.read<LogService>();
    final logCount = logService.logs.length;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('导出调试日志'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('当前共有 $logCount 条日志记录'),
            const SizedBox(height: 16),
            const Text('选择导出格式：'),
            const SizedBox(height: 8),
            ListTile(
              leading: const Icon(Icons.code),
              title: const Text('JSON 格式'),
              subtitle: const Text('结构化数据，便于程序分析'),
              onTap: () {
                Navigator.pop(context);
                _exportLogs(json: true);
              },
            ),
            ListTile(
              leading: const Icon(Icons.text_snippet),
              title: const Text('文本格式'),
              subtitle: const Text('可读性好，便于人工查看'),
              onTap: () {
                Navigator.pop(context);
                _exportLogs(json: false);
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
        ],
      ),
    );
  }

  Future<void> _exportLogs({required bool json}) async {
    try {
      final logService = context.read<LogService>();
      await logService.copyLogsToClipboard(json: json);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('日志已复制到剪贴板，可粘贴到文本编辑器保存'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('导出失败: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _showClearLogDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('清除日志'),
        content: const Text('确定要清除所有本地调试日志吗？此操作不可撤销。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () {
              final logService = context.read<LogService>();
              logService.clear();
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('日志已清除'), backgroundColor: Colors.green),
              );
            },
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('清除'),
          ),
        ],
      ),
    );
  }
}
