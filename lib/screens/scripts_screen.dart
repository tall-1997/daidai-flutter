import 'package:flutter/material.dart';

class ScriptsScreen extends StatelessWidget {
  const ScriptsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.code,
            size: 64,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: 16),
          const Text('脚本管理'),
          const SizedBox(height: 8),
          const Text(
            '在此管理您的脚本文件',
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }
}
