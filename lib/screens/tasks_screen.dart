import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import 'dart:convert';
import '../services/auth_service.dart';
import 'home_screen.dart';

class TasksScreen extends StatefulWidget {
  const TasksScreen({super.key});

  @override
  State<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends State<TasksScreen> with RefreshableScreen {
  List<Map<String, dynamic>> _tasks = [];
  bool _isLoading = true;
  String? _error;
  String _searchQuery = '';
  Timer? _refreshTimer;
  bool _isSelectionMode = false;
  final Set<int> _selectedTasks = {};

  @override
  void initState() {
    super.initState();
    _loadTasks();
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  @override
  void refresh() {
    _loadTasks();
  }

  void _toggleSelectionMode() {
    setState(() {
      _isSelectionMode = !_isSelectionMode;
      if (!_isSelectionMode) {
        _selectedTasks.clear();
      }
    });
  }

  void _toggleTaskSelection(int taskId) {
    setState(() {
      if (_selectedTasks.contains(taskId)) {
        _selectedTasks.remove(taskId);
      } else {
        _selectedTasks.add(taskId);
      }
    });
  }

  void _selectAllTasks() {
    setState(() {
      _selectedTasks.clear();
      for (var task in _tasks) {
        _selectedTasks.add(task['id']);
      }
    });
  }

  Future<void> _batchRunTasks() async {
    if (_selectedTasks.isEmpty) return;
    
    try {
      final authService = context.read<AuthService>();
      int successCount = 0;
      
      for (var taskId in _selectedTasks) {
        try {
          await authService.apiService.runTask(taskId);
          successCount++;
        } catch (e) {
          // 继续运行其他任务
        }
      }
      
      setState(() {
        _isSelectionMode = false;
        _selectedTasks.clear();
      });
      
      _loadTasks();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('成功运行 $successCount 个任务'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('批量运行失败: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _batchStopTasks() async {
    if (_selectedTasks.isEmpty) return;
    
    try {
      final authService = context.read<AuthService>();
      int successCount = 0;
      
      for (var taskId in _selectedTasks) {
        try {
          await authService.apiService.stopTask(taskId);
          successCount++;
        } catch (e) {
          // 继续停止其他任务
        }
      }
      
      setState(() {
        _isSelectionMode = false;
        _selectedTasks.clear();
      });
      
      _loadTasks();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('成功停止 $successCount 个任务'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('批量停止失败: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _batchDeleteTasks() async {
    if (_selectedTasks.isEmpty) return;
    
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('批量删除'),
        content: Text('确定要删除选中的 ${_selectedTasks.length} 个任务吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('删除'),
          ),
        ],
      ),
    );
    
    if (confirmed != true) return;
    
    try {
      final authService = context.read<AuthService>();
      int successCount = 0;
      
      for (var taskId in _selectedTasks) {
        try {
          await authService.apiService.deleteTask(taskId);
          successCount++;
        } catch (e) {
          // 继续删除其他任务
        }
      }
      
      setState(() {
        _isSelectionMode = false;
        _selectedTasks.clear();
      });
      
      _loadTasks();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('成功删除 $successCount 个任务'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('批量删除失败: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _startAutoRefresh() {
    _refreshTimer?.cancel();
    _refreshTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      if (_tasks.any((t) => t['status'] == 2)) {
        _loadTasks(silent: true);
      } else {
        timer.cancel();
      }
    });
  }

  Future<void> _loadTasks({bool silent = false}) async {
    if (!silent) {
      setState(() {
        _isLoading = true;
        _error = null;
      });
    }

    try {
      final authService = context.read<AuthService>();
      final result = await authService.apiService.getTasks(
        search: _searchQuery.isNotEmpty ? _searchQuery : null,
      );

      if (result['data'] != null) {
        setState(() {
          _tasks = List<Map<String, dynamic>>.from(result['data'] ?? []);
          _isLoading = false;
        });
        // Start auto refresh if any task is running
        if (_tasks.any((t) => t['status'] == 2)) {
          _startAutoRefresh();
        }
      } else {
        if (!silent) {
          setState(() {
            _error = result['message'] ?? '获取任务失败';
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (!silent) {
        setState(() {
          _error = '网络错误: $e';
          _isLoading = false;
        });
      }
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

  Future<void> _exportTasks() async {
    try {
      final authService = context.read<AuthService>();
      final result = await authService.apiService.exportTasks();
      
      if (result['code'] == 0 || result['code'] == 200 || result['success'] == true) {
        final data = result['data'] ?? result['tasks'] ?? [];
        final jsonStr = const JsonEncoder.withIndent('  ').convert(data);
        
        if (mounted) {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('导出任务'),
              content: SingleChildScrollView(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: SelectableText(
                    jsonStr,
                    style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('关闭'),
                ),
                FilledButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    _copyToClipboard(jsonStr);
                  },
                  icon: const Icon(Icons.copy),
                  label: const Text('复制'),
                ),
              ],
            ),
          );
        }
      } else {
        throw Exception(result['message'] ?? '导出失败');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('导出失败: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _copyToClipboard(String content) {
    Clipboard.setData(ClipboardData(text: content));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('已复制到剪贴板'), backgroundColor: Colors.green),
    );
  }

  Future<void> _importTasks() async {
    final controller = TextEditingController();
    
    final jsonStr = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('导入任务'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('请粘贴任务 JSON 数据:'),
              const SizedBox(height: 16),
              TextField(
                controller: controller,
                decoration: const InputDecoration(
                  hintText: '[{"name": "任务名称", "command": "echo hello", "task_type": "cron", "cron_expression": "* * * * *"}]',
                  border: OutlineInputBorder(),
                ),
                maxLines: 10,
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
            onPressed: () => Navigator.pop(context, controller.text),
            child: const Text('导入'),
          ),
        ],
      ),
    );
    
    if (jsonStr == null || jsonStr.isEmpty) return;
    
    try {
      final List<dynamic> data = jsonDecode(jsonStr);
      final tasks = List<Map<String, dynamic>>.from(data);
      
      final authService = context.read<AuthService>();
      final result = await authService.apiService.importTasks(tasks);
      
      if (result['code'] == 0 || result['code'] == 200 || result['success'] == true) {
        _loadTasks();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('成功导入 ${tasks.length} 个任务'), backgroundColor: Colors.green),
          );
        }
      } else {
        throw Exception(result['message'] ?? '导入失败');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('导入失败: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: _isSelectionMode 
          ? Text('已选择 ${_selectedTasks.length} 项')
          : const Text('任务管理'),
        leading: _isSelectionMode
          ? IconButton(
              icon: const Icon(Icons.close),
              onPressed: _toggleSelectionMode,
            )
          : null,
        actions: [
          if (_isSelectionMode) ...[
            IconButton(
              icon: const Icon(Icons.select_all),
              onPressed: _selectAllTasks,
              tooltip: '全选',
            ),
            IconButton(
              icon: const Icon(Icons.play_arrow),
              onPressed: _selectedTasks.isNotEmpty ? _batchRunTasks : null,
              tooltip: '批量运行',
            ),
            IconButton(
              icon: const Icon(Icons.stop),
              onPressed: _selectedTasks.isNotEmpty ? _batchStopTasks : null,
              tooltip: '批量停止',
            ),
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: _selectedTasks.isNotEmpty ? _batchDeleteTasks : null,
              tooltip: '批量删除',
            ),
          ] else ...[
            PopupMenuButton(
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'export',
                  child: ListTile(
                    leading: Icon(Icons.upload),
                    title: Text('导出备份'),
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
                const PopupMenuItem(
                  value: 'import',
                  child: ListTile(
                    leading: Icon(Icons.download),
                    title: Text('导入备份'),
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ],
              onSelected: (value) {
                if (value == 'export') {
                  _exportTasks();
                } else if (value == 'import') {
                  _importTasks();
                }
              },
            ),
            IconButton(
              icon: const Icon(Icons.checklist),
              onPressed: _toggleSelectionMode,
              tooltip: '批量操作',
            ),
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _loadTasks,
            ),
          ],
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
      floatingActionButton: _isSelectionMode
        ? null
        : FloatingActionButton(
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
          final isSelected = _selectedTasks.contains(task['id']);
          
          return _TaskCard(
            task: task,
            isSelectionMode: _isSelectionMode,
            isSelected: isSelected,
            onSelectionChanged: () => _toggleTaskSelection(task['id']),
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
    final timeoutController = TextEditingController(text: '0');
    String taskType = 'cron';

    // Common cron expressions
    final cronPresets = [
      {'label': '每分钟', 'value': '* * * * *'},
      {'label': '每小时', 'value': '0 * * * *'},
      {'label': '每天0点', 'value': '0 0 * * *'},
      {'label': '每天8点', 'value': '0 8 * * *'},
      {'label': '每天12点', 'value': '0 12 * * *'},
      {'label': '每天20点', 'value': '0 20 * * *'},
      {'label': '每周一', 'value': '0 0 * * 1'},
      {'label': '每月1号', 'value': '0 0 1 * *'},
    ];

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
                if (taskType == 'cron') ...[
                  TextField(
                    controller: cronController,
                    decoration: const InputDecoration(
                      labelText: 'Cron 表达式',
                      hintText: '* * * * *',
                      border: OutlineInputBorder(),
                      helperText: '格式: 分 时 日 月 周',
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Cron presets
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: cronPresets.map((preset) => ActionChip(
                      label: Text(preset['label']!, style: const TextStyle(fontSize: 12)),
                      onPressed: () {
                        setDialogState(() {
                          cronController.text = preset['value']!;
                        });
                      },
                    )).toList(),
                  ),
                  const SizedBox(height: 16),
                ],
                TextField(
                  controller: commandController,
                  decoration: const InputDecoration(
                    labelText: '执行命令',
                    border: OutlineInputBorder(),
                    hintText: 'node task.js',
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: timeoutController,
                  decoration: const InputDecoration(
                    labelText: '超时时间（秒）',
                    hintText: '0 表示不限制',
                    border: OutlineInputBorder(),
                    helperText: '任务执行超时时间，0表示不限制',
                  ),
                  keyboardType: TextInputType.number,
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
                    'timeout': int.tryParse(timeoutController.text) ?? 0,
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
  final bool isSelectionMode;
  final bool isSelected;
  final VoidCallback? onSelectionChanged;
  final VoidCallback onTap;
  final VoidCallback onRun;
  final VoidCallback onStop;
  final VoidCallback onEnable;
  final VoidCallback onDisable;
  final VoidCallback onDelete;

  const _TaskCard({
    required this.task,
    this.isSelectionMode = false,
    this.isSelected = false,
    this.onSelectionChanged,
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
        onTap: isSelectionMode ? onSelectionChanged : onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  if (isSelectionMode)
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: Icon(
                        isSelected ? Icons.check_circle : Icons.circle_outlined,
                        color: isSelected ? Theme.of(context).colorScheme.primary : Colors.grey,
                      ),
                    ),
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

class _TaskDetailSheet extends StatefulWidget {
  final Map<String, dynamic> task;
  final ScrollController scrollController;

  const _TaskDetailSheet({
    required this.task,
    required this.scrollController,
  });

  @override
  State<_TaskDetailSheet> createState() => _TaskDetailSheetState();
}

class _TaskDetailSheetState extends State<_TaskDetailSheet> {
  List<Map<String, dynamic>> _taskLogs = [];
  bool _isLoadingLogs = false;
  Map<String, dynamic>? _selectedLog;

  @override
  void initState() {
    super.initState();
    _loadTaskLogs();
  }

  Future<void> _loadTaskLogs() async {
    setState(() => _isLoadingLogs = true);
    try {
      final authService = context.read<AuthService>();
      final result = await authService.apiService.getLogs(
        taskId: widget.task['id'],
        pageSize: 20,
      );
      if (mounted) {
        setState(() {
          _taskLogs = List<Map<String, dynamic>>.from(result['data'] ?? result['logs'] ?? []);
          _isLoadingLogs = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingLogs = false);
      }
    }
  }

  String _cleanLogContent(dynamic content) {
    if (content == null) return '';
    String str = content.toString();
    // Remove ANSI escape sequences (with ESC prefix)
    str = str.replaceAll(RegExp(r'\x1B\[[0-9;]*[a-zA-Z]'), '');
    str = str.replaceAll(RegExp(r'\x1B\][^\x07]*\x07'), '');
    str = str.replaceAll(RegExp(r'\x1B\[[\d;]*[HfABCDEFGJKSTsu]'), '');
    // Remove ANSI codes without ESC prefix (e.g. [32m, [0m from stored logs)
    str = str.replaceAll(RegExp(r'\[(?:\d+;)*\d+m'), '');
    // Remove other control characters but keep newlines and tabs
    str = str.replaceAll(RegExp(r'[\x00-\x08\x0B\x0C\x0E-\x1F\x7F]'), '');
    return str.trim();
  }

  @override
  Widget build(BuildContext context) {
    final name = widget.task['name'] ?? '未命名任务';
    final taskType = widget.task['task_type'] ?? 'cron';
    final status = widget.task['status'] ?? 0;
    final cronExpression = widget.task['cron_expression'] ?? '';
    final command = widget.task['command'] ?? '';
    final createdAt = widget.task['created_at'] ?? '';
    final updatedAt = widget.task['updated_at'] ?? '';
    final lastRunAt = widget.task['last_run_at'] ?? '';
    final nextRunAt = widget.task['next_run_at'] ?? '';
    final timeout = widget.task['timeout'] ?? 0;

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
        controller: widget.scrollController,
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
          const Divider(height: 32),
          _buildDetailRow('创建时间', createdAt),
          _buildDetailRow('更新时间', updatedAt),
          _buildDetailRow('上次运行', lastRunAt.isEmpty ? '未运行' : lastRunAt),
          _buildDetailRow('下次运行', nextRunAt.isEmpty ? '无' : nextRunAt),
          // History logs section
          const Divider(height: 32),
          Row(
            children: [
              const Icon(Icons.history, color: Colors.blue),
              const SizedBox(width: 8),
              Text(
                '历史运行日志',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: _loadTaskLogs,
              ),
            ],
          ),
          const SizedBox(height: 8),
          _isLoadingLogs
              ? const Center(child: CircularProgressIndicator())
              : _taskLogs.isEmpty
                  ? Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Center(child: Text('暂无历史日志', style: TextStyle(color: Colors.grey))),
                    )
                  : Column(
                      children: _taskLogs.map((log) => _buildLogItem(log)).toList(),
                    ),
          // Selected log detail
          if (_selectedLog != null) ...[
            const SizedBox(height: 16),
            _buildLogDetail(_selectedLog!),
          ],
        ],
      ),
    );
  }

  Widget _buildLogItem(Map<String, dynamic> log) {
    final logId = log['id'] ?? 0;
    final status = log['status'] ?? 0;
    final createdAt = log['created_at'] ?? '';
    final duration = log['duration'] ?? 0;
    final isSelected = _selectedLog?['id'] == logId;

    Color statusColor;
    String statusText;
    IconData statusIcon;
    switch (status) {
      case 0:
        statusColor = Colors.green;
        statusText = '成功';
        statusIcon = Icons.check_circle;
        break;
      case 1:
        statusColor = Colors.red;
        statusText = '失败';
        statusIcon = Icons.error;
        break;
      case 2:
        statusColor = Colors.orange;
        statusText = '运行中';
        statusIcon = Icons.hourglass_empty;
        break;
      default:
        statusColor = Colors.grey;
        statusText = '未知';
        statusIcon = Icons.help;
    }

    String durationText = '';
    if (duration > 0) {
      if (duration < 1000) {
        durationText = '${duration}ms';
      } else if (duration < 60000) {
        durationText = '${(duration / 1000).toStringAsFixed(1)}s';
      } else {
        durationText = '${(duration / 60000).toStringAsFixed(1)}min';
      }
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      color: isSelected ? Colors.blue.withOpacity(0.1) : null,
      child: InkWell(
        onTap: () {
          setState(() {
            _selectedLog = isSelected ? null : log;
          });
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Icon(statusIcon, size: 18, color: statusColor),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      createdAt,
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                    if (durationText.isNotEmpty)
                      Text(
                        '耗时: $durationText',
                        style: const TextStyle(fontSize: 11, color: Colors.grey),
                      ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  statusText,
                  style: TextStyle(fontSize: 11, color: statusColor),
                ),
              ),
              Icon(
                isSelected ? Icons.expand_less : Icons.expand_more,
                size: 20,
                color: Colors.grey,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLogDetail(Map<String, dynamic> log) {
    final content = log['content'] ?? log['output'] ?? '';
    final error = log['error'] ?? '';
    final startedAt = log['started_at'] ?? '';
    final endedAt = log['ended_at'] ?? '';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.article, size: 16, color: Colors.blue),
              const SizedBox(width: 4),
              const Text('日志详情', style: TextStyle(fontWeight: FontWeight.bold)),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.copy, size: 16),
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: _cleanLogContent(content)));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('日志已复制'), backgroundColor: Colors.green),
                  );
                },
              ),
            ],
          ),
          if (startedAt.isNotEmpty)
            Text('开始: $startedAt', style: const TextStyle(fontSize: 11, color: Colors.grey)),
          if (endedAt.isNotEmpty)
            Text('结束: $endedAt', style: const TextStyle(fontSize: 11, color: Colors.grey)),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(4),
            ),
            child: SelectableText(
              _cleanLogContent(content).isEmpty ? '无日志内容' : _cleanLogContent(content),
              style: const TextStyle(fontFamily: 'monospace', fontSize: 11),
            ),
          ),
          if (error.isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: SelectableText(
                _cleanLogContent(error),
                style: const TextStyle(fontFamily: 'monospace', fontSize: 11, color: Colors.red),
              ),
            ),
          ],
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
