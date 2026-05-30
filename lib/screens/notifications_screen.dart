import 'package:flutter/material.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.notifications,
            size: 64,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: 16),
          const Text('通知管理'),
          const SizedBox(height: 8),
          const Text(
            '在此管理您的通知配置',
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }
}
