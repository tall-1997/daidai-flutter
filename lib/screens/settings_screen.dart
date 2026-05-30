import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

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
                    // TODO: Edit server URL
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
                  subtitle: Text('v0.0.12'),
                ),
                const ListTile(
                  leading: Icon(Icons.code),
                  title: Text('技术栈'),
                  subtitle: Text('Flutter + Dart'),
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
}
