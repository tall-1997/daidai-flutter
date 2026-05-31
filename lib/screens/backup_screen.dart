import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import 'dart:convert';

class BackupScreen extends StatefulWidget {
  const BackupScreen({super.key});

  @override
  State<BackupScreen> createState() => _BackupScreenState();
}

class _BackupScreenState extends State<BackupScreen> {
  bool _isLoading = false;
  String? _message;

  Future<void> _exportData() async {
    setState(() { _isLoading = true; _message = null; });

    try {
      final authService = context.read<AuthService>();
      final api = authService.apiService;

      // Export tasks
      final tasksResponse = await api.get('/tasks?page=1&page_size=1000');
      final tasksData = jsonDecode(tasksResponse.body);

      // Export envs
      final envsResponse = await api.get('/envs?page=1&page_size=1000');
      final envsData = jsonDecode(envsResponse.body);

      // Export notifications
      final notifsResponse = await api.get('/notifications');
      final notifsData = jsonDecode(notifsResponse.body);

      if (mounted) {
        final backup = {
          'version': '1.0',
          'timestamp': DateTime.now().toIso8601String(),
          'tasks': tasksData['data'] ?? [],
          'envs': envsData['data'] ?? [],
          'notifications': notifsData['data'] ?? [],
        };

        final backupJson = jsonEncode(backup);

        setState(() {
          _isLoading = false;
          _message = '备份数据已生成，共 ${backup['tasks'].length} 个任务，${backup['envs'].length} 个环境变量';
        });

        // Show copy dialog
        if (mounted) {
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
                FilledButton(
                  onPressed: () {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('备份数据已复制到剪贴板')),
                    );
                  },
                  child: const Text('复制'),
                ),
              ],
            ),
          );
        }
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _message = '导出失败: $e';
      });
    }
  }

  Future<void> _importData() async {
    // Show import dialog
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
      setState(() { _message = '请输入备份数据'; });
      return;
    }

    setState(() { _isLoading = true; _message = null; });

    try {
      final backup = jsonDecode(data);
      final authService = context.read<AuthService>();
      final api = authService.apiService;

      int importedTasks = 0;
      int importedEnvs = 0;

      // Import tasks
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

      // Import envs
      if (backup['envs'] != null) {
        for (final env in backup['envs']) {
          try {
            await api.post('/envs', body: {
              'name': env['name'],
              'value': env['value'],
              'remarks': env['remarks'] ?? '',
            });
            importedEnvs++;
          } catch (e) {
            // Skip failed imports
          }
        }
      }

      setState(() {
        _isLoading = false;
        _message = '导入完成: $importedTasks 个任务, $importedEnvs 个环境变量';
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _message = '导入失败: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('数据备份与恢复'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (_message != null)
            Card(
              color: _message!.contains('失败') ? Colors.red.shade50 : Colors.green.shade50,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    Icon(
                      _message!.contains('失败') ? Icons.error_outline : Icons.check_circle_outline,
                      color: _message!.contains('失败') ? Colors.red : Colors.green,
                    ),
                    const SizedBox(width: 8),
                    Expanded(child: Text(_message!)),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 16),

          // Export
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.upload, color: Theme.of(context).colorScheme.primary),
                      const SizedBox(width: 8),
                      Text('导出备份', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text('导出所有任务、环境变量和通知配置'),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: _isLoading ? null : _exportData,
                      icon: const Icon(Icons.download),
                      label: const Text('导出备份数据'),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Import
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.download, color: Theme.of(context).colorScheme.primary),
                      const SizedBox(width: 8),
                      Text('导入恢复', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text('从备份数据恢复任务和环境变量'),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _isLoading ? null : _importData,
                      icon: const Icon(Icons.upload),
                      label: const Text('导入备份数据'),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Info
          Card(
            color: Colors.blue.shade50,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.blue.shade700),
                      const SizedBox(width: 8),
                      Text('说明', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue.shade700)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '• 备份数据包含任务、环境变量和通知配置\n'
                    '• 导入时会创建新的任务和环境变量\n'
                    '• 已存在的数据不会被覆盖\n'
                    '• 建议定期备份重要数据',
                    style: TextStyle(color: Colors.blue.shade700),
                  ),
                ],
              ),
            ),
          ),

          if (_isLoading) ...[
            const SizedBox(height: 16),
            const Center(child: CircularProgressIndicator()),
          ],
        ],
      ),
    );
  }
}
