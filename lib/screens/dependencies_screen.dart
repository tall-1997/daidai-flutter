import 'package:flutter/material.dart';

class DependenciesScreen extends StatelessWidget {
  const DependenciesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.extension,
            size: 64,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: 16),
          const Text('依赖管理'),
          const SizedBox(height: 8),
          const Text(
            '在此管理您的依赖包',
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }
}
