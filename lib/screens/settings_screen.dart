import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../main.dart';
import '../services/auth_service.dart';
import '../services/notification_service.dart';
import '../services/root/magisk_helper.dart';
import '../theme/miuix_theme.dart';
import '../widgets/miuix_widgets.dart';
import 'home_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> with RefreshableScreen {
  bool _isRooted = false;
  MagiskModuleInfo? _moduleInfo;
  String _appVersion = '';
  bool _notificationEnabled = false;
  String _notificationChannel = 'app'; // 'app', 'server', 'both'

  @override
  void initState() {
    super.initState();
    _checkRootStatus();
    _loadAppVersion();
    _loadNotificationSetting();
  }

  @override
  void refresh() {
    _checkRootStatus();
  }

  Future<void> _loadNotificationSetting() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _notificationEnabled = prefs.getBool('notification_enabled') ?? false;
      _notificationChannel = prefs.getString('notification_channel') ?? 'app';
    });
  }

  Future<void> _toggleNotification(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('notification_enabled', value);
    setState(() {
      _notificationEnabled = value;
    });
    if (value) {
      await NotificationService().showSimpleNotification(
        id: 0,
        title: '通知已开启',
        body: '您将收到任务执行状态的通知',
      );
    }
  }

  Future<void> _setNotificationChannel(String channel) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('notification_channel', channel);
    setState(() {
      _notificationChannel = channel;
    });
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('通知渠道已切换为: ${_getChannelName(channel)}'), backgroundColor: Colors.green),
      );
    }
  }

  String _getChannelName(String channel) {
    switch (channel) {
      case 'app':
        return 'App 推送';
      case 'server':
        return '服务器通知';
      case 'both':
        return '全部渠道';
      default:
        return 'App 推送';
    }
  }

  Future<void> _loadAppVersion() async {
    final packageInfo = await PackageInfo.fromPlatform();
    if (mounted) {
      setState(() {
        _appVersion = '${packageInfo.version}+${packageInfo.buildNumber}';
      });
    }
  }

  Future<void> _checkRootStatus() async {
    final isRooted = await MagiskHelper.isDaidaiModuleInstalled();
    MagiskModuleInfo? moduleInfo;

    if (isRooted) {
      moduleInfo = await MagiskHelper.getModuleInfo();
    }

    if (mounted) {
      setState(() {
        _isRooted = isRooted;
        _moduleInfo = moduleInfo;
      });
    }
  }

  void _showChangeUsernameDialog() {
    final usernameController = TextEditingController();
    
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
                  const SnackBar(content: Text('请输入新用户名'), backgroundColor: Colors.red),
                );
                return;
              }
              
              try {
                final authService = context.read<AuthService>();
                final result = await authService.apiService.changeUsername(usernameController.text);
                
                if (result['code'] == 0 || result['code'] == 200 || result['success'] == true) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('用户名修改成功'), backgroundColor: Colors.green),
                  );
                } else {
                  throw Exception(result['message'] ?? '修改失败');
                }
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('修改失败: $e'), backgroundColor: Colors.red),
                );
              }
            },
            child: const Text('确认'),
          ),
        ],
      ),
    );
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
              if (oldPasswordController.text.isEmpty || 
                  newPasswordController.text.isEmpty ||
                  confirmPasswordController.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('请填写所有密码字段'), backgroundColor: Colors.red),
                );
                return;
              }
              
              if (newPasswordController.text != confirmPasswordController.text) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('两次输入的新密码不一致'), backgroundColor: Colors.red),
                );
                return;
              }
              
              try {
                final authService = context.read<AuthService>();
                final result = await authService.apiService.changePassword(
                  oldPasswordController.text,
                  newPasswordController.text,
                );
                
                if (result['code'] == 0 || result['code'] == 200 || result['success'] == true) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('密码修改成功'), backgroundColor: Colors.green),
                  );
                } else {
                  throw Exception(result['message'] ?? '修改失败');
                }
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('修改失败: $e'), backgroundColor: Colors.red),
                );
              }
            },
            child: const Text('确认'),
          ),
        ],
      ),
    );
  }

  Future<void> _exportAppLogs() async {
    try {
      final authService = context.read<AuthService>();
      final result = await authService.apiService.getSystemLogs(page: 1, pageSize: 1000);
      
      // 兼容多种 API 返回格式
      final logs = result['data'] ?? result['logs'] ?? result['items'] ?? [];
      
      if (logs is List && logs.isNotEmpty) {
        final StringBuffer logBuffer = StringBuffer();
        
        logBuffer.writeln('=== 呆呆面板应用日志 ===');
        logBuffer.writeln('导出时间: ${DateTime.now().toIso8601String()}');
        logBuffer.writeln('用户: ${authService.username}');
        logBuffer.writeln('服务器: ${authService.serverUrl}');
        logBuffer.writeln('========================\n');
        
        for (var log in logs) {
          logBuffer.writeln('[${log['created_at'] ?? ''}] ${log['task_name'] ?? '未知任务'}');
          logBuffer.writeln('状态: ${log['status'] == 0 ? '成功' : log['status'] == 1 ? '失败' : '运行中'}');
          if (log['content'] != null && log['content'].toString().isNotEmpty) {
            logBuffer.writeln('内容: ${log['content']}');
          }
          if (log['error'] != null && log['error'].toString().isNotEmpty) {
            logBuffer.writeln('错误: ${log['error']}');
          }
          logBuffer.writeln('---');
        }
        
        if (mounted) {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('导出应用日志'),
              content: SingleChildScrollView(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: SelectableText(
                    logBuffer.toString(),
                    style: const TextStyle(fontFamily: 'monospace', fontSize: 11),
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('关闭'),
                ),
                FilledButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    Clipboard.setData(ClipboardData(text: logBuffer.toString()));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('日志已复制到剪贴板'), backgroundColor: Colors.green),
                    );
                  },
                  icon: const Icon(Icons.copy),
                  label: const Text('复制'),
                ),
              ],
            ),
          );
        }
      } else {
        // 如果没有日志数据，显示提示
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('暂无日志数据'), backgroundColor: Colors.orange),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('导出日志失败: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _exportBackupData() async {
    try {
      final authService = context.read<AuthService>();
      final api = authService.apiService;

      final results = await Future.wait([
        api.get('/tasks?page=1&page_size=1000'),
        api.get('/envs?page=1&page_size=1000'),
        api.get('/notifications'),
      ]);

      final tasksData = jsonDecode(results[0].body);
      final envsData = jsonDecode(results[1].body);
      final notifsData = jsonDecode(results[2].body);

      if (mounted) {
        final backup = {
          'version': '1.0',
          'timestamp': DateTime.now().toIso8601String(),
          'tasks': tasksData['data'] ?? [],
          'envs': envsData['data'] ?? [],
          'notifications': notifsData['data'] ?? [],
        };

        final backupJson = const JsonEncoder.withIndent('  ').convert(backup);

        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('导出备份数据'),
            content: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('任务: ${(backup['tasks'] as List).length} 个'),
                  Text('环境变量: ${(backup['envs'] as List).length} 个'),
                  Text('通知: ${(backup['notifications'] as List).length} 个'),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      backupJson,
                      style: const TextStyle(fontFamily: 'monospace', fontSize: 10),
                      maxLines: 10,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('关闭'),
              ),
              FilledButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  Clipboard.setData(ClipboardData(text: backupJson));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('备份数据已复制到剪贴板'), backgroundColor: Colors.green),
                  );
                },
                icon: const Icon(Icons.copy),
                label: const Text('复制'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('导出备份失败: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _importBackupData() async {
    final controller = TextEditingController();

    if (mounted) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('导入备份数据'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('请粘贴备份数据（JSON格式）'),
                const SizedBox(height: 16),
                TextField(
                  controller: controller,
                  maxLines: 10,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    hintText: '粘贴备份数据...',
                  ),
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
                Navigator.pop(context);
                await _processImport(controller.text);
              },
              child: const Text('导入'),
            ),
          ],
        ),
      );
    }
  }

  Future<void> _processImport(String data) async {
    if (data.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('请输入备份数据'), backgroundColor: Colors.red),
        );
      }
      return;
    }

    try {
      final backup = jsonDecode(data);
      final authService = context.read<AuthService>();
      final api = authService.apiService;

      int importedTasks = 0;
      int importedEnvs = 0;

      if (backup['tasks'] != null) {
        for (final task in backup['tasks']) {
          try {
            await api.post('/tasks', body: {
              'name': task['name'],
              'task_type': task['task_type'],
              'command': task['command'],
              'cron_expression': task['cron_expression'],
              'timeout': task['timeout'] ?? 0,
            });
            importedTasks++;
          } catch (e) {
            // Skip failed imports
          }
        }
      }

      if (backup['envs'] != null) {
        for (final env in backup['envs']) {
          try {
            await api.post('/envs', body: {
              'name': env['name'],
              'value': env['value'],
              'remarks': env['remarks'],
            });
            importedEnvs++;
          } catch (e) {
            // Skip failed imports
          }
        }
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('导入完成: $importedTasks 个任务, $importedEnvs 个环境变量'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('导入失败: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authService = context.watch<AuthService>();
    final themeProvider = context.watch<ThemeProvider>();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Account switching
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('账户管理', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                ListTile(
                  leading: const Icon(Icons.person),
                  title: const Text('当前用户'),
                  subtitle: Text(authService.username ?? '未登录'),
                ),
                ListTile(
                  leading: const Icon(Icons.dns),
                  title: const Text('服务器地址'),
                  subtitle: Text(authService.serverUrl),
                ),
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.edit),
                  title: const Text('修改用户名'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _showChangeUsernameDialog(),
                ),
                ListTile(
                  leading: const Icon(Icons.lock),
                  title: const Text('修改密码'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _showChangePasswordDialog(),
                ),
                if (authService.savedAccounts.length > 1) ...[
                  const Divider(),
                  const Text('切换账户', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  ...authService.savedAccounts.map((account) => ListTile(
                    dense: true,
                    leading: CircleAvatar(
                      radius: 16,
                      backgroundColor: account.username == authService.username
                          ? Theme.of(context).colorScheme.primary
                          : Colors.grey,
                      child: Text(account.username[0].toUpperCase(),
                        style: TextStyle(color: Theme.of(context).colorScheme.onPrimary, fontSize: 14)),
                    ),
                    title: Text(account.username),
                    subtitle: Text(account.serverUrl, style: const TextStyle(fontSize: 12)),
                    trailing: account.username == authService.username
                        ? Icon(Icons.check, color: Theme.of(context).colorScheme.primary)
                        : null,
                    onTap: account.username == authService.username
                        ? null
                        : () async {
                            await authService.switchAccount(account);
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('已切换到 ${account.username}')),
                              );
                            }
                          },
                  )),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Root status
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(_isRooted ? Icons.check_circle : Icons.cancel,
                      color: _isRooted ? Colors.green : Colors.orange),
                    const SizedBox(width: 8),
                    Text('Root 状态', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 16),
                ListTile(
                  leading: const Icon(Icons.security),
                  title: const Text('Root 权限'),
                  subtitle: Text(_isRooted ? '已获取' : '未获取'),
                  trailing: Icon(_isRooted ? Icons.check : Icons.close,
                    color: _isRooted ? Colors.green : Colors.red),
                ),
                if (_isRooted && _moduleInfo != null) ...[
                  const Divider(),
                  ListTile(
                    leading: const Icon(Icons.extension, color: Colors.purple),
                    title: const Text('Magisk 模块'),
                    subtitle: Text('${_moduleInfo!.name} v${_moduleInfo!.version}'),
                  ),
                  ListTile(
                    leading: const Icon(Icons.person),
                    title: const Text('模块作者'),
                    subtitle: Text(_moduleInfo!.author),
                  ),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        // App settings
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('应用设置', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                ListTile(
                  leading: const Icon(Icons.dark_mode),
                  title: const Text('深色模式'),
                  subtitle: Text(_getThemeModeText(themeProvider.themeMode)),
                  trailing: DropdownButton<ThemeMode>(
                    value: themeProvider.themeMode,
                    onChanged: (mode) {
                      if (mode != null) {
                        themeProvider.setThemeMode(mode);
                      }
                    },
                    items: const [
                      DropdownMenuItem(
                        value: ThemeMode.system,
                        child: Text('跟随系统'),
                      ),
                      DropdownMenuItem(
                        value: ThemeMode.light,
                        child: Text('浅色模式'),
                      ),
                      DropdownMenuItem(
                        value: ThemeMode.dark,
                        child: Text('深色模式'),
                      ),
                    ],
                  ),
                ),
                SwitchListTile(
                  secondary: const Icon(Icons.notifications_active),
                  title: const Text('App 通知推送'),
                  subtitle: const Text('通过 App 通道接收任务通知'),
                  value: _notificationEnabled,
                  onChanged: _toggleNotification,
                ),
                if (_notificationEnabled) ...[
                  const Divider(),
                  ListTile(
                    leading: const Icon(Icons.notifications),
                    title: const Text('通知渠道'),
                    subtitle: Text(_getChannelName(_notificationChannel)),
                    trailing: DropdownButton<String>(
                      value: _notificationChannel,
                      onChanged: (value) {
                        if (value != null) {
                          _setNotificationChannel(value);
                        }
                      },
                      items: const [
                        DropdownMenuItem(
                          value: 'app',
                          child: Text('App 推送'),
                        ),
                        DropdownMenuItem(
                          value: 'server',
                          child: Text('服务器通知'),
                        ),
                        DropdownMenuItem(
                          value: 'both',
                          child: Text('全部渠道'),
                        ),
                      ],
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      'App 推送: 通过 App 本地推送通知\n服务器通知: 通过服务器发送的通知\n全部渠道: 同时使用两种通知方式',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Panel Customization
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('面板自定义', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                ListTile(
                  leading: const Icon(Icons.title),
                  title: const Text('面板标题'),
                  subtitle: const Text('自定义面板显示标题'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _showPanelTitleDialog(),
                ),
                ListTile(
                  leading: const Icon(Icons.image),
                  title: const Text('面板图标'),
                  subtitle: const Text('自定义面板图标'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _showPanelIconDialog(),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Backup and restore
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('备份与恢复', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                ListTile(
                  leading: const Icon(Icons.upload),
                  title: const Text('导出备份'),
                  subtitle: const Text('导出任务、环境变量和通知配置'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _exportBackupData(),
                ),
                ListTile(
                  leading: const Icon(Icons.download),
                  title: const Text('导入备份'),
                  subtitle: const Text('从 JSON 数据导入配置'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _importBackupData(),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        // About
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('关于', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                ListTile(
                  leading: const Icon(Icons.info),
                  title: const Text('版本'),
                  subtitle: Text('v$_appVersion-flutter'),
                ),
                const ListTile(
                  leading: Icon(Icons.code),
                  title: Text('技术栈'),
                  subtitle: Text('Flutter + Dart + Provider'),
                ),
                const ListTile(
                  leading: Icon(Icons.phone_android),
                  title: Text('支持平台'),
                  subtitle: Text('Android, iOS'),
                ),
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.bug_report),
                  title: const Text('导出应用日志'),
                  subtitle: const Text('导出日志用于问题排查'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _exportAppLogs(),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),
        FilledButton.tonal(
          onPressed: () => authService.logout(),
          style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
          child: const Text('退出登录'),
        ),
      ],
    );
  }

  String _getThemeModeText(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.system:
        return '跟随系统设置';
      case ThemeMode.light:
        return '浅色模式';
      case ThemeMode.dark:
        return '深色模式';
    }
  }

  void _showPanelTitleDialog() {
    final titleController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('设置面板标题'),
        content: TextField(
          controller: titleController,
          decoration: const InputDecoration(
            labelText: '面板标题',
            border: OutlineInputBorder(),
            hintText: '呆呆面板',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () async {
              try {
                final authService = context.read<AuthService>();
                await authService.apiService.updateSystemConfig({
                  'panel_title': titleController.text,
                });
                Navigator.pop(context);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('面板标题已更新'), backgroundColor: Colors.green),
                  );
                }
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('更新失败: $e'), backgroundColor: Colors.red),
                );
              }
            },
            child: const Text('保存'),
          ),
        ],
      ),
    );
  }

  void _showPanelIconDialog() {
    final iconController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('设置面板图标'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('输入图标URL或Base64编码'),
            const SizedBox(height: 16),
            TextField(
              controller: iconController,
              decoration: const InputDecoration(
                labelText: '图标URL',
                border: OutlineInputBorder(),
                hintText: 'https://example.com/icon.png',
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () async {
              try {
                final authService = context.read<AuthService>();
                await authService.apiService.updateSystemConfig({
                  'panel_icon': iconController.text,
                });
                Navigator.pop(context);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('面板图标已更新'), backgroundColor: Colors.green),
                  );
                }
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('更新失败: $e'), backgroundColor: Colors.red),
                );
              }
            },
            child: const Text('保存'),
          ),
        ],
      ),
    );
  }
}
