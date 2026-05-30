import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';

class TasksScreen extends StatefulWidget {
  const TasksScreen({super.key});

  @override
  State<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends State<TasksScreen> {
  List<Map<String, dynamic>> _tasks = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadTasks();
  }

  Future<void> _loadTasks() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final authService = context.read<AuthService>();
      final result = await authService.apiService.getTasks();
      
      if (result['data'] != null) {
        setState(() {
          _tasks = List<Map<String, dynamic>>.from(result['data']['tasks'] ?? []);
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = result['message'] ?? '获取任务失败';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = '网络错误: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(_error!),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: _loadTasks,
              child: const Text('重试'),
            ),
          ],
        ),
      );
    }

    if (_tasks.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.task_alt,
              size: 64,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 16),
            const Text('暂无任务'),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: () {
                // TODO: Create task
              },
              icon: const Icon(Icons.add),
              label: const Text('创建任务'),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadTasks,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _tasks.length,
        itemBuilder: (context, index) {
          final task = _tasks[index];
          return _TaskCard(
            task: task,
            onTap: () {
              // TODO: Navigate to task detail
            },
          );
        },
      ),
    );
  }
}

class _TaskCard extends StatelessWidget {
  final Map<String, dynamic> task;
  final VoidCallback onTap;

  const _TaskCard({
    required this.task,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final name = task['name'] ?? '未命名任务';
    final type = task['type'] ?? 'cron';
    final status = task['status'] ?? 0;
    final cron = task['cron'] ?? '';
    
    Color statusColor;
    String statusText;
    switch (status) {
      case 0:
        statusColor = Colors.grey;
        statusText = '禁用';
        break;
      case 1:
        statusColor = Colors.green;
        statusText = '启用';
        break;
      case 2:
        statusColor = Colors.blue;
        statusText = '运行中';
        break;
      default:
        statusColor = Colors.grey;
        statusText = '未知';
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      name,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: statusColor),
                    ),
                    child: Text(
                      statusText,
                      style: TextStyle(
                        color: statusColor,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(
                    Icons.schedule,
                    size: 16,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    type == 'cron' ? cron : '手动触发',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  IconButton(
                    icon: const Icon(Icons.play_arrow),
                    onPressed: () {
                      // TODO: Run task
                    },
                    tooltip: '运行',
                  ),
                  IconButton(
                    icon: const Icon(Icons.stop),
                    onPressed: () {
                      // TODO: Stop task
                    },
                    tooltip: '停止',
                  ),
                  IconButton(
                    icon: const Icon(Icons.edit),
                    onPressed: () {
                      // TODO: Edit task
                    },
                    tooltip: '编辑',
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
