import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/api_service.dart';
import 'package:provider/provider.dart';

class QuickActionsScreen extends StatefulWidget {
  const QuickActionsScreen({super.key});

  @override
  State<QuickActionsScreen> createState() => _QuickActionsScreenState();
}

class _QuickActionsScreenState extends State<QuickActionsScreen> {
  final _cronController = TextEditingController();
  final _importController = TextEditingController();
  List<String>? _cronResults;
  String? _exportedData;
  String? _message;
  bool _isLoading = false;

  @override
  void dispose() {
    _cronController.dispose();
    _importController.dispose();
    super.dispose();
  }

  Future<void> _batchRunTasks() async {
    final api = context.read<ApiService>();
    setState(() { _isLoading = true; _message = null; });
    try {
      final tasks = await api.getTasks(pageSize: 1000);
      final ids = (tasks['data'] as List?)?.map((t) => t['id'] as int).toList() ?? [];
      if (ids.isEmpty) {
        setState(() { _message = '没有任务可运行'; _isLoading = false; });
        return;
      }
      for (final id in ids) {
        await api.runTask(id);
      }
      setState(() { _message = '批量运行 ${ids.length} 个任务成功'; _isLoading = false; });
    } catch (e) {
      setState(() { _message = '批量运行失败: $e'; _isLoading = false; });
    }
  }

  Future<void> _batchEnableTasks() async {
    final api = context.read<ApiService>();
    setState(() { _isLoading = true; _message = null; });
    try {
      final tasks = await api.getTasks(pageSize: 1000);
      final ids = (tasks['data'] as List?)?.map((t) => t['id'] as int).toList() ?? [];
      for (final id in ids) {
        await api.enableTask(id);
      }
      setState(() { _message = '批量启用 ${ids.length} 个任务成功'; _isLoading = false; });
    } catch (e) {
      setState(() { _message = '批量启用失败: $e'; _isLoading = false; });
    }
  }

  Future<void> _batchDisableTasks() async {
    final api = context.read<ApiService>();
    setState(() { _isLoading = true; _message = null; });
    try {
      final tasks = await api.getTasks(pageSize: 1000);
      final ids = (tasks['data'] as List?)?.map((t) => t['id'] as int).toList() ?? [];
      for (final id in ids) {
        await api.disableTask(id);
      }
      setState(() { _message = '批量禁用 ${ids.length} 个任务成功'; _isLoading = false; });
    } catch (e) {
      setState(() { _message = '批量禁用失败: $e'; _isLoading = false; });
    }
  }

  Future<void> _batchDeleteTasks() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('确认删除'),
        content: const Text('确定要删除所有任务吗？此操作不可恢复。'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('取消')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('确定', style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (confirm != true) return;

    final api = context.read<ApiService>();
    setState(() { _isLoading = true; _message = null; });
    try {
      final tasks = await api.getTasks(pageSize: 1000);
      final ids = (tasks['data'] as List?)?.map((t) => t['id'] as int).toList() ?? [];
      await api.batchDeleteTasks(ids);
      setState(() { _message = '批量删除 ${ids.length} 个任务成功'; _isLoading = false; });
    } catch (e) {
      setState(() { _message = '批量删除失败: $e'; _isLoading = false; });
    }
  }

  Future<void> _exportTasks() async {
    final api = context.read<ApiService>();
    setState(() { _isLoading = true; _message = null; });
    try {
      final tasks = await api.getTasks(pageSize: 1000);
      final data = tasks['data'] ?? [];
      setState(() {
        _exportedData = data.toString();
        _message = '导出任务成功';
        _isLoading = false;
      });
    } catch (e) {
      setState(() { _message = '导出失败: $e'; _isLoading = false; });
    }
  }

  Future<void> _importTasks() async {
    if (_importController.text.isEmpty) {
      setState(() { _message = '请输入导入数据'; });
      return;
    }
    final api = context.read<ApiService>();
    setState(() { _isLoading = true; _message = null; });
    try {
      // Parse and import tasks
      setState(() { _message = '导入功能开发中'; _isLoading = false; });
    } catch (e) {
      setState(() { _message = '导入失败: $e'; _isLoading = false; });
    }
  }

  void _parseCron() {
    final expr = _cronController.text.trim();
    if (expr.isEmpty) {
      setState(() { _message = '请输入Cron表达式'; });
      return;
    }
    // Simple cron parser for display
    setState(() {
      _cronResults = [
        '表达式: $expr',
        '格式: 秒 分 时 日 月 周',
        '示例: 0 0 9 * * ? (每天9点)',
      ];
      _message = 'Cron表达式解析成功';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('快捷操作'),
        actions: [
          if (_isLoading)
            const Center(child: Padding(
              padding: EdgeInsets.all(16.0),
              child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)),
            )),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (_message != null)
            Card(
              color: _message!.contains('失败') || _message!.contains('错误')
                  ? Colors.red.shade50
                  : Colors.green.shade50,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    Icon(
                      _message!.contains('失败') || _message!.contains('错误')
                          ? Icons.error_outline
                          : Icons.check_circle_outline,
                      color: _message!.contains('失败') || _message!.contains('错误')
                          ? Colors.red
                          : Colors.green,
                    ),
                    const SizedBox(width: 8),
                    Expanded(child: Text(_message!)),
                    IconButton(
                      icon: const Icon(Icons.close, size: 16),
                      onPressed: () => setState(() { _message = null; }),
                    ),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 16),
          
          // Batch operations
          _buildSectionTitle('批量任务操作'),
          _buildActionButton('批量运行所有任务', Icons.play_arrow, Colors.green, _batchRunTasks),
          _buildActionButton('批量启用所有任务', Icons.check_circle, Colors.blue, _batchEnableTasks),
          _buildActionButton('批量禁用所有任务', Icons.pause_circle, Colors.orange, _batchDisableTasks),
          _buildActionButton('批量删除所有任务', Icons.delete_forever, Colors.red, _batchDeleteTasks),
          
          const SizedBox(height: 24),
          
          // Import/Export
          _buildSectionTitle('导入导出'),
          _buildActionButton('导出所有任务', Icons.upload, Colors.teal, _exportTasks),
          if (_exportedData != null) ...[
            const SizedBox(height: 8),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Text('导出数据', style: TextStyle(fontWeight: FontWeight.bold)),
                        const Spacer(),
                        IconButton(
                          icon: const Icon(Icons.copy, size: 20),
                          onPressed: () {
                            Clipboard.setData(ClipboardData(text: _exportedData!));
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('已复制到剪贴板')),
                            );
                          },
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        _exportedData!,
                        style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
                        maxLines: 10,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
          const SizedBox(height: 8),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('导入任务', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _importController,
                    maxLines: 5,
                    decoration: const InputDecoration(
                      hintText: '粘贴任务JSON数据...',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton.icon(
                    onPressed: _importTasks,
                    icon: const Icon(Icons.download),
                    label: const Text('导入'),
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Cron parser
          _buildSectionTitle('Cron表达式解析'),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: _cronController,
                    decoration: const InputDecoration(
                      hintText: '输入Cron表达式，如: 0 0 9 * * ?',
                      border: OutlineInputBorder(),
                      labelText: 'Cron表达式',
                    ),
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton.icon(
                    onPressed: _parseCron,
                    icon: const Icon(Icons.schedule),
                    label: const Text('解析'),
                  ),
                  if (_cronResults != null) ...[
                    const SizedBox(height: 12),
                    ...(_cronResults!.map((r) => Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Text(r, style: const TextStyle(fontSize: 13)),
                    ))),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildActionButton(String label, IconData icon, Color color, VoidCallback onPressed) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: _isLoading ? null : onPressed,
          icon: Icon(icon, color: color),
          label: Text(label),
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 12),
            alignment: Alignment.centerLeft,
          ),
        ),
      ),
    );
  }
}
