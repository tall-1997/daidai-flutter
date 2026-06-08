import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:convert';
import 'dart:io';
import '../services/auth_service.dart';
import 'home_screen.dart';

class BackupScreen extends StatefulWidget {
  const BackupScreen({super.key});

  @override
  State<BackupScreen> createState() => _BackupScreenState();
}

class _BackupScreenState extends State<BackupScreen> with RefreshableScreen {
  bool _isLoading = false;
  String? _message;

  @override
  void refresh() {
    setState(() {
      _message = null;
    });
  }

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

        final backupJson = const JsonEncoder.withIndent('  ').convert(backup);
        final timestamp = DateTime.now().toString().replaceAll(RegExp(r'[: ]'), '-').substring(0, 19);
        final fileName = 'daidai-backup-$timestamp.json';

        // Let user choose save location
        final outputPath = await FilePicker.platform.saveFile(
          dialogTitle: '保存备份文件',
          fileName: fileName,
          type: FileType.custom,
          allowedExtensions: ['json'],
        );

        if (outputPath != null) {
          final file = File(outputPath);
          await file.writeAsString(backupJson);
          
          setState(() {
            _isLoading = false;
            _message = '备份成功: ${(backup['tasks'] as List).length} 个任务, ${(backup['envs'] as List).length} 个环境变量\n已保存到: $outputPath';
          });
        } else {
          setState(() {
            _isLoading = false;
            _message = '已取消导出';
          });
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
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
        dialogTitle: '选择备份文件',
      );

      if (result != null && result.files.single.path != null) {
        final file = File(result.files.single.path!);
        final content = await file.readAsString();
        await _processImport(content);
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _message = '读取文件失败: $e';
      });
    }
  }

  Future<void> _processImport(String data) async {
    if (data.isEmpty) {
      setState(() { _message = '备份文件为空'; });
      return;
    }

    setState(() { _isLoading = true; _message = null; });

    try {
      final backup = jsonDecode(data);
      final authService = context.read<AuthService>();
      final api = authService.apiService;

      int importedTasks = 0;
      int importedEnvs = 0;
      int skippedTasks = 0;
      int skippedEnvs = 0;

      // Import tasks
      if (backup['tasks'] != null) {
        for (final task in backup['tasks']) {
          try {
            await api.post('/tasks', body: {
              'name': task['name'],
              'task_type': task['task_type'] ?? 'manual',
              'command': task['command'],
              'cron_expression': task['cron_expression'] ?? '',
              'timeout': task['timeout'] ?? 0,
              if (task['group'] != null) 'group': task['group'],
              if (task['python_version'] != null) 'python_version': task['python_version'],
            });
            importedTasks++;
          } catch (e) {
            skippedTasks++;
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
            skippedEnvs++;
          }
        }
      }

      setState(() {
        _isLoading = false;
        _message = '导入完成: $importedTasks 个任务, $importedEnvs 个环境变量'
            '${skippedTasks > 0 ? '\n跳过 $skippedTasks 个重复任务' : ''}'
            '${skippedEnvs > 0 ? '\n跳过 $skippedEnvs 个重复环境变量' : ''}';
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
                  const Text('导出所有任务、环境变量和通知配置为 JSON 文件'),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: _isLoading ? null : _exportData,
                      icon: const Icon(Icons.download),
                      label: const Text('导出备份文件'),
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
                  const Text('从备份 JSON 文件恢复任务和环境变量'),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _isLoading ? null : _importData,
                      icon: const Icon(Icons.upload),
                      label: const Text('选择备份文件导入'),
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
                    '• 备份文件为 JSON 格式，可用文本编辑器查看\n'
                    '• 导入时会创建新的任务和环境变量\n'
                    '• 已存在的数据会被跳过，不会覆盖\n'
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
