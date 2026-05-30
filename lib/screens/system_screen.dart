import 'package:flutter/material.dart';

class SystemScreen extends StatelessWidget {
  const SystemScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.computer,
            size: 64,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: 16),
          const Text('系统信息'),
          const SizedBox(height: 8),
          const Text(
            '在此查看系统状态和信息',
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }
}
