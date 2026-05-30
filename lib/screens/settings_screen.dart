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
  bool _isDaidaiModuleInstalled = false;
  MagiskModuleInfo? _moduleInfo;

  @override
  void initState() {
    super.initState();
    _checkRootStatus();
  }

  Future<void> _checkRootStatus() async {
    final isRooted = await MagiskHelper.isDaidaiModuleInstalled();
    MagiskModuleInfo? moduleInfo;
    bool isDaidaiModuleInstalled = false;
    
    if (isRooted) {
      isDaidaiModuleInstalled = true;
      moduleInfo = await MagiskHelper.getModuleInfo();
    }
    
    if (mounted) {
      setState(() {
        _isRooted = isRooted;
        _isDaidaiModuleInstalled = isDaidaiModuleInstalled;
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
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '服务器设置',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                ListTile(
                  leading: const Icon(Icons.dns),
                  title: const Text('服务器地址'),
                  subtitle: Text(authService.serverUrl),
                  trailing: const Icon(Icons.edit),
                  onTap: () {
                    _showEditServerDialog(context, authService);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.person),
                  title: const Text('当前用户'),
                  subtitle: Text(authService.username ?? '未登录'),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      _isRooted ? Icons.check_circle : Icons.cancel,
                      color: _isRooted ? Colors.green : Colors.orange,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Root 状态',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                ListTile(
                  leading: const Icon(Icons.security),
                  title: const Text('Root 权限'),
                  subtitle: Text(_isRooted ? '已获取' : '未获取'),
                  trailing: Icon(
                    _isRooted ? Icons.check : Icons.close,
                    color: _isRooted ? Colors.green : Colors.red,
                  ),
                ),
                if (_isDaidaiModuleInstalled && _moduleInfo != null) ...[
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
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '应用设置',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
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
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '关于',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                const ListTile(
                  leading: Icon(Icons.info),
                  title: Text('版本'),
                  subtitle: Text('v0.0.13-flutter'),
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
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),
        FilledButton.tonal(
          onPressed: () {
            authService.logout();
          },
          style: FilledButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
          ),
          child: const Text('退出登录'),
        ),
      ],
    );
  }

  void _showEditServerDialog(BuildContext context, AuthService authService) {
    final controller = TextEditingController(text: authService.serverUrl);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('修改服务器地址'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: '服务器地址',
            hintText: 'http://127.0.0.1:5700',
            border: OutlineInputBorder(),
          ),
          keyboardType: TextInputType.url,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () {
              authService.setServerUrl(controller.text.trim());
              Navigator.pop(context);
            },
            child: const Text('保存'),
          ),
        ],
      ),
    );
  }
}
