import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../services/root/magisk_helper.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _isRooted = false;
  MagiskModuleInfo? _moduleInfo;

  @override
  void initState() {
    super.initState();
    _checkRootStatus();
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

  @override
  Widget build(BuildContext context) {
    final authService = context.watch<AuthService>();

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
                SwitchListTile(
                  secondary: const Icon(Icons.dark_mode),
                  title: const Text('深色模式'),
                  subtitle: const Text('跟随系统设置'),
                  value: Theme.of(context).brightness == Brightness.dark,
                  onChanged: (value) {
                    // TODO: Implement theme switching
                  },
                ),
                SwitchListTile(
                  secondary: const Icon(Icons.notifications_active),
                  title: const Text('App 通知推送'),
                  subtitle: const Text('通过 App 通道接收任务通知'),
                  value: false,
                  onChanged: (value) {
                    // TODO: Implement notification push
                  },
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
                const ListTile(
                  leading: Icon(Icons.info),
                  title: Text('版本'),
                  subtitle: Text('v0.0.15-flutter'),
                ),
                const ListTile(
                  leading: Icon(Icons.code),
                  title: Text('技术栈'),
                  subtitle: Text('Flutter + Dart + Provider'),
                ),
                const ListTile(
                  leading: Icon(Icons.phone_android),
                  title: Text('支持平台'),
                  subtitle: Text('Android, iOS, Web'),
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
}
