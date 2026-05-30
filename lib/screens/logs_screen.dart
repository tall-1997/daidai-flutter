import 'package:flutter/material.dart';

class LogsScreen extends StatelessWidget {
  const LogsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.article,
            size: 64,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: 16),
          const Text('日志查看'),
          const SizedBox(height: 8),
          const Text(
            '在此查看任务执行日志',
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }
}
