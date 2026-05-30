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
  String _searchQuery = '';

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
      final result = await authService.apiService.getTasks(
        search: _searchQuery.isNotEmpty ? _searchQuery : null,
      );
      
      // API returns {data: [...], page: 1, page_size: 20, total: 1}
      if (result['data'] != null) {
        setState(() {
          _tasks = List<Map<String, dynamic>>.from(result['data'] ?? []);
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

  Future<void> _runTask(int id) async {
    try {
      final authService = context.read<AuthService>();
      await authService.apiService.runTask(id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('任务已运行')),
        );
      }
      // Wait a moment for the task to start, then refresh
      await Future.delayed(const Duration(milliseconds: 500));
      _loadTasks();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('运行失败: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _stopTask(int id) async {
    try {
      final authService = context.read<AuthService>();
      await authService.apiService.stopTask(id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('任务已停止')),
        );
      }
      // Wait a moment for the task to stop, then refresh
      await Future.delayed(const Duration(milliseconds: 500));
      _loadTasks();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('停止失败: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _enableTask(int id) async {
    try {
      final authService = context.read<AuthService>();
      await authService.apiService.enableTask(id);
      _loadTasks();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('启用失败: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _disableTask(int id) async {
    try {
      final authService = context.read<AuthService>();
      await authService.apiService.disableTask(id);
      _loadTasks();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('禁用失败: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _deleteTask(int id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认删除'),
        content: const Text('确定要删除这个任务吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('删除'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final authService = context.read<AuthService>();
        await authService.apiService.deleteTask(id);
        _loadTasks();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('任务已删除')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('删除失败: $e'), backgroundColor: Colors.red),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('任务管理'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadTasks,
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              decoration: InputDecoration(
                hintText: '搜索任务...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          setState(() => _searchQuery = '');
                          _loadTasks();
                        },
                      )
                    : null,
              ),
              onSubmitted: (value) {
                setState(() => _searchQuery = value);
                _loadTasks();
              },
            ),
          ),
          Expanded(
            child: _buildBody(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showCreateTaskDialog(),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildBody() {
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
              onPressed: () => _showCreateTaskDialog(),
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
            onRun: () => _runTask(task['id']),
            onStop: () => _stopTask(task['id']),
            onEnable: () => _enableTask(task['id']),
            onDisable: () => _disableTask(task['id']),
            onDelete: () => _deleteTask(task['id']),
            onTap: () => _showTaskDetail(task),
          );
        },
      ),
    );
  }

  void _showTaskDetail(Map<String, dynamic> task) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) => _TaskDetailSheet(
          task: task,
          scrollController: scrollController,
        ),
      ),
    );
  }

  void _showCreateTaskDialog() {
    final nameController = TextEditingController();
    final commandController = TextEditingController();
    final cronController = TextEditingController();
    String taskType = 'cron';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('创建任务'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: '任务名称',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: taskType,
                  decoration: const InputDecoration(
                    labelText: '任务类型',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'cron', child: Text('定时任务')),
                    DropdownMenuItem(value: 'manual', child: Text('手动任务')),
                  ],
                  onChanged: (value) {
                    setDialogState(() => taskType = value!);
                  },
                ),
                const SizedBox(height: 16),
                if (taskType == 'cron')
                  TextField(
                    controller: cronController,
                    decoration: const InputDecoration(
                      labelText: 'Cron 表达式',
                      hintText: '0 * * * *',
                      border: OutlineInputBorder(),
                    ),
                  ),
                if (taskType == 'cron') const SizedBox(height: 16),
                TextField(
                  controller: commandController,
                  decoration: const InputDecoration(
                    labelText: '执行命令',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
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
                if (nameController.text.isEmpty || commandController.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('请填写必填项'), backgroundColor: Colors.red),
                  );
                  return;
                }

                try {
                  final authService = context.read<AuthService>();
                  await authService.apiService.createTask({
                    'name': nameController.text,
                    'task_type': taskType,
                    'command': commandController.text,
                    if (taskType == 'cron') 'cron_expression': cronController.text,
                  });
                  Navigator.pop(context);
                  _loadTasks();
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('创建失败: $e'), backgroundColor: Colors.red),
                  );
                }
              },
              child: const Text('创建'),
            ),
          ],
        ),
      ),
    );
  }
}

class _TaskCard extends StatelessWidget {
  final Map<String, dynamic> task;
  final VoidCallback onTap;
  final VoidCallback onRun;
  final VoidCallback onStop;
  final VoidCallback onEnable;
  final VoidCallback onDisable;
  final VoidCallback onDelete;

  const _TaskCard({
    required this.task,
    required this.onTap,
    required this.onRun,
    required this.onStop,
    required this.onEnable,
    required this.onDisable,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final name = task['name'] ?? '未命名任务';
    final taskType = task['task_type'] ?? 'cron';
    final status = task['status'] ?? 0;
    final cronExpression = task['cron_expression'] ?? '';
    final command = task['command'] ?? '';
    final lastRunAt = task['last_run_at'] ?? '';
    final nextRunAt = task['next_run_at'] ?? '';
    final isPinned = task['is_pinned'] ?? false;
    
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
                  if (isPinned)
                    Icon(Icons.push_pin, size: 16, color: Colors.orange),
                  if (isPinned) const SizedBox(width: 4),
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
                    taskType == 'cron' ? cronExpression : '手动触发',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                '命令: $command',
                style: Theme.of(context).textTheme.bodySmall,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              if (lastRunAt.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  '上次运行: $lastRunAt',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey,
                  ),
                ),
              ],
              const SizedBox(height: 12),
                Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  // Run button - show for enabled (1) and disabled (0) tasks
                  if (status != 2)
                    IconButton(
                      icon: const Icon(Icons.play_arrow, color: Colors.green),
                      onPressed: onRun,
                      tooltip: '运行',
                    ),
                  // Stop button - only show for running tasks
                  if (status == 2)
                    IconButton(
                      icon: const Icon(Icons.stop, color: Colors.red),
                      onPressed: onStop,
                      tooltip: '停止',
                    ),
                  // Enable button - only show for disabled tasks
                  if (status == 0)
                    IconButton(
                      icon: const Icon(Icons.check_circle, color: Colors.blue),
                      onPressed: onEnable,
                      tooltip: '启用',
                    ),
                  // Disable button - only show for enabled tasks
                  if (status == 1)
                    IconButton(
                      icon: const Icon(Icons.pause, color: Colors.orange),
                      onPressed: onDisable,
                      tooltip: '禁用',
                    ),
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: onDelete,
                    tooltip: '删除',
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

class _TaskDetailSheet extends StatelessWidget {
  final Map<String, dynamic> task;
  final ScrollController scrollController;

  const _TaskDetailSheet({
    required this.task,
    required this.scrollController,
  });

  @override
  Widget build(BuildContext context) {
    final name = task['name'] ?? '未命名任务';
    final taskType = task['task_type'] ?? 'cron';
    final status = task['status'] ?? 0;
    final cronExpression = task['cron_expression'] ?? '';
    final command = task['command'] ?? '';
    final createdAt = task['created_at'] ?? '';
    final updatedAt = task['updated_at'] ?? '';
    final lastRunAt = task['last_run_at'] ?? '';
    final nextRunAt = task['next_run_at'] ?? '';
    final timeout = task['timeout'] ?? 0;
    final maxRetries = task['max_retries'] ?? 0;
    final retryInterval = task['retry_interval'] ?? 0;
    
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

    return Container(
      padding: const EdgeInsets.all(16),
      child: ListView(
        controller: scrollController,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Text(
                  name,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: statusColor),
                ),
                child: Text(
                  statusText,
                  style: TextStyle(color: statusColor, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          _buildDetailRow('任务类型', taskType == 'cron' ? '定时任务' : '手动任务'),
          _buildDetailRow('Cron 表达式', cronExpression.isEmpty ? '无' : cronExpression),
          _buildDetailRow('执行命令', command),
          _buildDetailRow('超时时间', '${timeout}秒'),
          _buildDetailRow('最大重试', '$maxRetries次'),
          _buildDetailRow('重试间隔', '${retryInterval}秒'),
          const Divider(height: 32),
          _buildDetailRow('创建时间', createdAt),
          _buildDetailRow('更新时间', updatedAt),
          _buildDetailRow('上次运行', lastRunAt.isEmpty ? '未运行' : lastRunAt),
          _buildDetailRow('下次运行', nextRunAt.isEmpty ? '无' : nextRunAt),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}
