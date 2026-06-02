import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';
import 'dart:convert';
import '../services/auth_service.dart';
import '../theme/miuix_theme.dart';
import '../widgets/miuix_widgets.dart';
import 'home_screen.dart';

const String _ungroupedLabel = '未分组';
const String _prefsGroupOrderKey = 'task_group_order';

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

  final Map<String, bool> _groupCollapsed = {};
  List<String> _groupOrder = [];
  bool _isGroupSortMode = false;

  @override
  void initState() {
    super.initState();
    _loadGroupOrder();
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

  String _getTaskGroup(Map<String, dynamic> task) {
    final group = task['group'];
    if (group != null && group.toString().isNotEmpty) {
      return group.toString();
    }
    final taskType = task['task_type'] ?? 'manual';
    return taskType == 'cron' ? '定时任务' : '手动任务';
  }

  List<String> _getSortedGroupNames() {
    final groups = <String>{};
    for (final task in _tasks) {
      groups.add(_getTaskGroup(task));
    }

    final knownGroups = _groupOrder.where(groups.contains).toList();
    final newGroups = groups.where((g) => !knownGroups.contains(g)).toList();

    if (_ungroupedLabel == '未分组' && newGroups.contains(_ungroupedLabel)) {
      newGroups.remove(_ungroupedLabel);
      return [...knownGroups, ...newGroups, _ungroupedLabel];
    }

    return [...knownGroups, ...newGroups];
  }

  List<Map<String, dynamic>> _getTasksInGroup(String groupName) {
    return _tasks.where((t) => _getTaskGroup(t) == groupName).toList();
  }

  Future<void> _loadGroupOrder() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getStringList(_prefsGroupOrderKey);
      if (saved != null) {
        _groupOrder = saved;
      }
    } catch (_) {}
  }

  Future<void> _saveGroupOrder() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(_prefsGroupOrderKey, _groupOrder);
    } catch (_) {}
  }

  void _ensureGroupCollapseState(List<String> groupNames) {
    for (final name in groupNames) {
      _groupCollapsed.putIfAbsent(name, () => name == _ungroupedLabel);
    }
    final currentGroups = groupNames.toSet();
    _groupCollapsed.removeWhere((key, _) => !currentGroups.contains(key));
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
          // continue
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
          // continue
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
          // continue
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
          final groupNames = _getSortedGroupNames();
          _ensureGroupCollapseState(groupNames);
        });
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
                    style: MiuixTextStyles.monospace,
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

  void _showRenameGroupDialog(String groupName) {
    final controller = TextEditingController(text: groupName);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('重命名分组'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: '分组名称',
            border: OutlineInputBorder(),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () async {
              final newName = controller.text.trim();
              if (newName.isEmpty || newName == groupName) {
                Navigator.pop(context);
                return;
              }

              Navigator.pop(context);

              final tasksInGroup = _getTasksInGroup(groupName);
              final authService = context.read<AuthService>();
              int successCount = 0;

              for (final task in tasksInGroup) {
                try {
                  await authService.apiService.updateTask(task['id'], {'group': newName});
                  successCount++;
                } catch (_) {}
              }

              setState(() {
                final idx = _groupOrder.indexOf(groupName);
                if (idx >= 0) {
                  _groupOrder[idx] = newName;
                }
                final collapsed = _groupCollapsed.remove(groupName);
                if (collapsed != null) {
                  _groupCollapsed[newName] = collapsed;
                }
              });
              _saveGroupOrder();
              _loadTasks();

              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('已重命名 $successCount 个任务'), backgroundColor: Colors.green),
                );
              }
            },
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteGroup(String groupName) async {
    final tasksInGroup = _getTasksInGroup(groupName);

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('删除分组'),
        content: Text('确定要删除分组「$groupName」及其包含的 ${tasksInGroup.length} 个任务吗？'),
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

    final authService = context.read<AuthService>();
    int successCount = 0;

    for (final task in tasksInGroup) {
      try {
        await authService.apiService.deleteTask(task['id']);
        successCount++;
      } catch (_) {}
    }

    setState(() {
      _groupOrder.remove(groupName);
      _groupCollapsed.remove(groupName);
    });
    _saveGroupOrder();
    _loadTasks();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('已删除 $successCount 个任务'), backgroundColor: Colors.green),
      );
    }
  }

  void _showCreateTaskInGroupDialog(String groupName) {
    _showCreateTaskDialog(prefilledGroup: groupName);
  }

  void _toggleGroupSortMode() {
    setState(() {
      _isGroupSortMode = !_isGroupSortMode;
    });
  }

  void _onGroupReorder(int oldIndex, int newIndex) {
    setState(() {
      final groupNames = _getSortedGroupNames();
      if (oldIndex < groupNames.length && newIndex < groupNames.length) {
        final movedGroup = groupNames.removeAt(oldIndex);
        groupNames.insert(newIndex, movedGroup);

        _groupOrder = groupNames;
        _saveGroupOrder();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: _isSelectionMode
          ? Text('已选择 ${_selectedTasks.length} 项')
          : _isGroupSortMode
            ? const Text('拖拽排序分组')
            : const Text('任务管理'),
        leading: _isSelectionMode
          ? IconButton(
              icon: const Icon(Icons.close),
              onPressed: _toggleSelectionMode,
            )
          : _isGroupSortMode
            ? IconButton(
                icon: const Icon(Icons.close),
                onPressed: _toggleGroupSortMode,
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
          ] else if (_isGroupSortMode) ...[
            IconButton(
              icon: const Icon(Icons.check),
              onPressed: _toggleGroupSortMode,
              tooltip: '完成排序',
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
                const PopupMenuItem(
                  value: 'sort_groups',
                  child: ListTile(
                    leading: Icon(Icons.sort),
                    title: Text('排序分组'),
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ],
              onSelected: (value) {
                if (value == 'export') {
                  _exportTasks();
                } else if (value == 'import') {
                  _importTasks();
                } else if (value == 'sort_groups') {
                  _toggleGroupSortMode();
                }
              },
            ),
            IconButton(
              icon: const Icon(Icons.checklist),
              onPressed: _toggleSelectionMode,
              tooltip: '批量操作',
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
                prefixIcon: Icon(Icons.search, color: MiuixColors.onSecondaryContainer),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(MiuixSpacing.textFieldCornerRadius),
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
      return const MiuixLoadingState();
    }

    if (_error != null) {
      return MiuixErrorState(
        message: _error!,
        onRetry: _loadTasks,
      );
    }

    if (_tasks.isEmpty) {
      return MiuixEmptyState(
        icon: Icons.task_alt,
        title: '暂无任务',
        action: ElevatedButton.icon(
          onPressed: () => _showCreateTaskDialog(),
          icon: const Icon(Icons.add),
          label: const Text('创建任务'),
        ),
      );
    }

    final groupNames = _getSortedGroupNames();
    _ensureGroupCollapseState(groupNames);

    if (_isGroupSortMode) {
      return _buildGroupSortList(groupNames);
    }

    return _buildGroupedListView(groupNames);
  }

  Widget _buildGroupSortList(List<String> groupNames) {
    return ReorderableListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: groupNames.length,
      onReorder: _onGroupReorder,
      itemBuilder: (context, index) {
        final groupName = groupNames[index];
        final tasksInGroup = _getTasksInGroup(groupName);
        return Card(
          key: ValueKey(groupName),
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: const Icon(Icons.drag_handle),
            title: Text(
              groupName,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            subtitle: Text('${tasksInGroup.length} 个任务'),
          ),
        );
      },
    );
  }

  Widget _buildGroupedListView(List<String> groupNames) {
    return RefreshIndicator(
      onRefresh: _loadTasks,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: groupNames.fold<int>(0, (sum, name) {
          final isCollapsed = _groupCollapsed[name] ?? (name == _ungroupedLabel);
          return sum + 1 + (isCollapsed ? 0 : _getTasksInGroup(name).length);
        }),
        itemBuilder: (context, index) {
          int runningIndex = 0;
          for (final groupName in groupNames) {
            if (runningIndex == index) {
              return _GroupHeader(
                groupName: groupName,
                taskCount: _getTasksInGroup(groupName).length,
                isCollapsed: _groupCollapsed[groupName] ?? (groupName == _ungroupedLabel),
                onToggleCollapse: () {
                  setState(() {
                    _groupCollapsed[groupName] =
                        !(_groupCollapsed[groupName] ?? (groupName == _ungroupedLabel));
                  });
                },
                onRename: () => _showRenameGroupDialog(groupName),
                onDelete: () => _deleteGroup(groupName),
                onAddTask: () => _showCreateTaskInGroupDialog(groupName),
              );
            }
            runningIndex++;

            final isCollapsed = _groupCollapsed[groupName] ?? (groupName == _ungroupedLabel);
            if (!isCollapsed) {
              final tasksInGroup = _getTasksInGroup(groupName);
              final taskIndex = index - runningIndex;
              if (taskIndex < tasksInGroup.length) {
                final task = tasksInGroup[taskIndex];
                final isSelected = _selectedTasks.contains(task['id']);
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: _TaskCard(
                    task: task,
                    isSelectionMode: _isSelectionMode,
                    isSelected: isSelected,
                    onSelectionChanged: () => _toggleTaskSelection(task['id']),
                    onRun: () => _runTask(task['id']),
                    onStop: () => _stopTask(task['id']),
                    onEnable: () => _enableTask(task['id']),
                    onDisable: () => _disableTask(task['id']),
                    onDelete: () => _deleteTask(task['id']),
                    onEdit: () => _showEditTaskDialog(task),
                    onTap: () => _showTaskDetail(task),
                  ),
                );
              }
              runningIndex += tasksInGroup.length;
            }
          }
          return const SizedBox.shrink();
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

  void _showCreateTaskDialog({String? prefilledGroup}) {
    final nameController = TextEditingController();
    final commandController = TextEditingController();
    final cronController = TextEditingController();
    final timeoutController = TextEditingController(text: '0');
    final groupController = TextEditingController(text: prefilledGroup ?? '');
    String taskType = 'cron';

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
                const SizedBox(height: 16),
                TextField(
                  controller: groupController,
                  decoration: const InputDecoration(
                    labelText: '分组名称',
                    hintText: '留空则自动分组',
                    border: OutlineInputBorder(),
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
                if (nameController.text.isEmpty || commandController.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('请填写必填项'), backgroundColor: Colors.red),
                  );
                  return;
                }

                try {
                  final authService = context.read<AuthService>();
                  final body = <String, dynamic>{
                    'name': nameController.text,
                    'task_type': taskType,
                    'command': commandController.text,
                    'timeout': int.tryParse(timeoutController.text) ?? 0,
                    if (taskType == 'cron') 'cron_expression': cronController.text,
                    if (groupController.text.trim().isNotEmpty) 'group': groupController.text.trim(),
                  };
                  await authService.apiService.createTask(body);
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

  void _showEditTaskDialog(Map<String, dynamic> task) {
    final taskId = task['id'] ?? 0;
    final nameController = TextEditingController(text: task['name'] ?? '');
    final commandController = TextEditingController(text: task['command'] ?? '');
    final cronController = TextEditingController(text: task['cron_expression'] ?? '');
    final timeoutController = TextEditingController(text: '${task['timeout'] ?? 0}');
    final groupController = TextEditingController(text: task['group'] ?? '');
    final retryCountController = TextEditingController(text: '${task['retry_count'] ?? 0}');
    final retryDelayController = TextEditingController(text: '${task['retry_delay'] ?? 5}');
    final dependsOnController = TextEditingController(text: task['depends_on'] ?? '');
    final hookBeforeController = TextEditingController(text: task['hook_before'] ?? '');
    final hookAfterController = TextEditingController(text: task['hook_after'] ?? '');
    final concurrencyController = TextEditingController(text: '${task['task_concurrency'] ?? 1}');
    String taskType = task['task_type'] ?? 'cron';
    bool enableRetry = (task['retry_count'] ?? 0) > 0;

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
          title: const Text('编辑任务'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
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
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: timeoutController,
                  decoration: const InputDecoration(
                    labelText: '超时时间（秒）',
                    border: OutlineInputBorder(),
                    helperText: '0 表示不限制',
                  ),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: groupController,
                  decoration: const InputDecoration(
                    labelText: '分组（可选）',
                    border: OutlineInputBorder(),
                    helperText: '留空则自动分组',
                  ),
                ),
                const SizedBox(height: 24),
                const Text('重试设置', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                SwitchListTile(
                  title: const Text('启用重试'),
                  subtitle: const Text('任务失败时自动重试'),
                  value: enableRetry,
                  onChanged: (value) {
                    setDialogState(() => enableRetry = value);
                  },
                  contentPadding: EdgeInsets.zero,
                ),
                if (enableRetry) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: retryCountController,
                          decoration: const InputDecoration(
                            labelText: '重试次数',
                            border: OutlineInputBorder(),
                            helperText: '失败后重试次数',
                          ),
                          keyboardType: TextInputType.number,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: TextField(
                          controller: retryDelayController,
                          decoration: const InputDecoration(
                            labelText: '重试间隔（秒）',
                            border: OutlineInputBorder(),
                          ),
                          keyboardType: TextInputType.number,
                        ),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 24),
                const Text('并发控制', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                TextField(
                  controller: concurrencyController,
                  decoration: const InputDecoration(
                    labelText: '最大并发实例数',
                    border: OutlineInputBorder(),
                    helperText: '同一任务最多同时运行的实例数，1表示串行执行',
                  ),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 24),
                const Text('依赖与钩子', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                TextField(
                  controller: dependsOnController,
                  decoration: const InputDecoration(
                    labelText: '依赖任务ID（可选）',
                    border: OutlineInputBorder(),
                    helperText: '多个任务ID用逗号分隔，依赖任务完成后才执行',
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: hookBeforeController,
                  decoration: const InputDecoration(
                    labelText: '执行前钩子（可选）',
                    border: OutlineInputBorder(),
                    helperText: '任务执行前运行的命令',
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: hookAfterController,
                  decoration: const InputDecoration(
                    labelText: '执行后钩子（可选）',
                    border: OutlineInputBorder(),
                    helperText: '任务执行后运行的命令',
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
                if (nameController.text.isEmpty || commandController.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('请填写必填项'), backgroundColor: Colors.red),
                  );
                  return;
                }

                try {
                  final authService = context.read<AuthService>();
                  final body = <String, dynamic>{
                    'name': nameController.text,
                    'task_type': taskType,
                    'command': commandController.text,
                    'timeout': int.tryParse(timeoutController.text) ?? 0,
                    'task_concurrency': int.tryParse(concurrencyController.text) ?? 1,
                    if (taskType == 'cron') 'cron_expression': cronController.text,
                    if (groupController.text.trim().isNotEmpty) 'group': groupController.text.trim(),
                    'retry_count': enableRetry ? (int.tryParse(retryCountController.text) ?? 0) : 0,
                    'retry_delay': enableRetry ? (int.tryParse(retryDelayController.text) ?? 5) : 5,
                    if (dependsOnController.text.trim().isNotEmpty) 'depends_on': dependsOnController.text.trim(),
                    if (hookBeforeController.text.trim().isNotEmpty) 'hook_before': hookBeforeController.text.trim(),
                    if (hookAfterController.text.trim().isNotEmpty) 'hook_after': hookAfterController.text.trim(),
                  };
                  await authService.apiService.updateTask(taskId, body);
                  Navigator.pop(context);
                  _loadTasks();
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('任务已更新'), backgroundColor: Colors.green),
                    );
                  }
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('更新失败: $e'), backgroundColor: Colors.red),
                  );
                }
              },
              child: const Text('保存'),
            ),
          ],
        ),
      ),
    );
  }
}

class _GroupHeader extends StatelessWidget {
  final String groupName;
  final int taskCount;
  final bool isCollapsed;
  final VoidCallback onToggleCollapse;
  final VoidCallback onRename;
  final VoidCallback onDelete;
  final VoidCallback onAddTask;

  const _GroupHeader({
    required this.groupName,
    required this.taskCount,
    required this.isCollapsed,
    required this.onToggleCollapse,
    required this.onRename,
    required this.onDelete,
    required this.onAddTask,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onLongPress: () {
        final state = context.findAncestorStateOfType<_TasksScreenState>();
        state?._toggleGroupSortMode();
      },
      child: Padding(
        padding: const EdgeInsets.only(top: 8, bottom: 4),
        child: Row(
          children: [
            GestureDetector(
              onTap: onToggleCollapse,
              child: Icon(
                isCollapsed ? Icons.expand_more : Icons.expand_less,
                size: 22,
                color: isDark
                    ? MiuixColors.darkOnSurfaceVariantSummary
                    : MiuixColors.onSurfaceVariantSummary,
              ),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: GestureDetector(
                onTap: onToggleCollapse,
                child: Text(
                  groupName,
                  style: MiuixTextStyles.headline2.copyWith(
                    fontWeight: FontWeight.w600,
                    color: isDark ? MiuixColors.darkOnSurface : MiuixColors.onSurface,
                  ),
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: MiuixColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '$taskCount',
                style: TextStyle(
                  fontSize: 12,
                  color: MiuixColors.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            PopupMenuButton<String>(
              icon: Icon(
                Icons.more_vert,
                size: 20,
                color: isDark
                    ? MiuixColors.darkOnSurfaceVariantActions
                    : MiuixColors.onSurfaceVariantActions,
              ),
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'rename',
                  child: ListTile(
                    leading: Icon(Icons.edit),
                    title: Text('重命名分组'),
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
                const PopupMenuItem(
                  value: 'add_task',
                  child: ListTile(
                    leading: Icon(Icons.add),
                    title: Text('批量添加任务'),
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
                const PopupMenuItem(
                  value: 'delete',
                  child: ListTile(
                    leading: Icon(Icons.delete, color: Colors.red),
                    title: Text('删除分组', style: TextStyle(color: Colors.red)),
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ],
              onSelected: (value) {
                if (value == 'rename') {
                  onRename();
                } else if (value == 'delete') {
                  onDelete();
                } else if (value == 'add_task') {
                  onAddTask();
                }
              },
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
  final VoidCallback onEdit;

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
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final name = task['name'] ?? '未命名任务';
    final taskType = task['task_type'] ?? 'cron';
    final status = task['status'] ?? 0;
    final cronExpression = task['cron_expression'] ?? '';
    final command = task['command'] ?? '';
    final lastRunAt = task['last_run_at'] ?? '';
    final isPinned = task['is_pinned'] ?? false;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    Color statusColor;
    String statusText;
    final statusNum = status is int ? status.toDouble() : (status ?? 0.0);
    if (statusNum == 0) {
      statusColor = Colors.grey;
      statusText = '禁用';
    } else if (statusNum == 1) {
      statusColor = Colors.green;
      statusText = '启用';
    } else if (statusNum == 2) {
      statusColor = MiuixColors.primary;
      statusText = '运行中';
    } else if (statusNum > 0 && statusNum < 1) {
      statusColor = Colors.orange;
      statusText = '排队中';
    } else {
      statusColor = Colors.grey;
      statusText = '未知';
    }

    return MiuixCard(
      onTap: isSelectionMode ? onSelectionChanged : onTap,
      padding: const EdgeInsets.all(14),
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
                    color: isSelected ? MiuixColors.primary : MiuixColors.disabledOnSurface,
                    size: 22,
                  ),
                ),
              if (isPinned)
                Padding(
                  padding: const EdgeInsets.only(right: 4),
                  child: Icon(Icons.push_pin, size: 14, color: Colors.orange),
                ),
              Expanded(
                child: Text(
                  name,
                  style: MiuixTextStyles.headline2.copyWith(
                    fontWeight: FontWeight.w600,
                    color: isDark ? MiuixColors.darkOnSurface : MiuixColors.onSurface,
                  ),
                ),
              ),
              MiuixStatusBadge(text: statusText, color: statusColor),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(
                Icons.schedule,
                size: 14,
                color: isDark
                    ? MiuixColors.darkOnSurfaceVariantSummary
                    : MiuixColors.onSurfaceVariantSummary,
              ),
              const SizedBox(width: 4),
              Text(
                taskType == 'cron' ? cronExpression : '手动触发',
                style: MiuixTextStyles.footnote1.copyWith(
                  color: isDark
                      ? MiuixColors.darkOnSurfaceVariantSummary
                      : MiuixColors.onSurfaceVariantSummary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            command,
            style: MiuixTextStyles.footnote1.copyWith(
              color: isDark
                  ? MiuixColors.darkOnSurfaceVariantActions
                  : MiuixColors.onSurfaceVariantActions,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          if (lastRunAt.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              '上次运行: $lastRunAt',
              style: MiuixTextStyles.footnote2.copyWith(
                color: isDark
                    ? MiuixColors.darkOnSurfaceVariantActions
                    : MiuixColors.onSurfaceVariantActions,
              ),
            ),
          ],
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              if (statusNum != 2)
                _MiuixIconButton(
                  icon: Icons.play_arrow,
                  color: Colors.green,
                  onPressed: onRun,
                  tooltip: '运行',
                ),
              if (statusNum == 2)
                _MiuixIconButton(
                  icon: Icons.stop,
                  color: MiuixColors.error,
                  onPressed: onStop,
                  tooltip: '停止',
                ),
              if (statusNum == 0)
                _MiuixIconButton(
                  icon: Icons.check_circle,
                  color: MiuixColors.primary,
                  onPressed: onEnable,
                  tooltip: '启用',
                ),
              if (statusNum > 0)
                _MiuixIconButton(
                  icon: Icons.pause,
                  color: Colors.orange,
                  onPressed: onDisable,
                  tooltip: '禁用',
                ),
              _MiuixIconButton(
                icon: Icons.edit,
                color: MiuixColors.primary,
                onPressed: onEdit,
                tooltip: '编辑',
              ),
              _MiuixIconButton(
                icon: Icons.delete,
                color: MiuixColors.error,
                onPressed: onDelete,
                tooltip: '删除',
              ),
            ],
          ),
        ],
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
      final taskId = widget.task['id'];
      final status = widget.task['status'] ?? 0;
      final statusNum = status is int ? status.toDouble() : (status ?? 0.0);

      if (statusNum == 2) {
        try {
          final liveResult = await authService.apiService.getTaskLiveLogs(taskId);
          if (mounted) {
            final logs = liveResult['logs'];
            if (logs is List && logs.isNotEmpty) {
              final liveContent = logs.join('\n');
              setState(() {
                _taskLogs = [{
                  'id': -1,
                  'status': 2,
                  'content': liveContent,
                  'created_at': widget.task['last_run_at'] ?? '',
                }];
                _isLoadingLogs = false;
              });
              return;
            }
          }
        } catch (_) {}
      }

      final result = await authService.apiService.getLogs(taskId: taskId, pageSize: 20);
      if (mounted) {
        final logList = List<Map<String, dynamic>>.from(result['data'] ?? result['logs'] ?? []);

        for (int i = 0; i < logList.length && i < 10; i++) {
          final logId = logList[i]['id'];
          if (logId != null && (logList[i]['content'] == null || logList[i]['content'].toString().isEmpty)) {
            try {
              final detail = await authService.apiService.getLogById(logId);
              if (detail['data'] != null) {
                final detailData = detail['data'] as Map<String, dynamic>;
                logList[i]['content'] = detailData['content'] ?? logList[i]['content'];
                logList[i]['error'] = detailData['error'] ?? logList[i]['error'];
              }
            } catch (_) {}
          }
        }

        setState(() {
          _taskLogs = logList;
          _isLoadingLogs = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingLogs = false);
      }
    }
  }

  String _cleanLogContent(dynamic content) => MiuixLogUtils.cleanContent(content?.toString());

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
    final group = widget.task['group'] ?? '';

    Color statusColor;
    String statusText;
    final statusNum = status is int ? status.toDouble() : (status ?? 0.0);
    if (statusNum == 0) {
      statusColor = Colors.grey;
      statusText = '禁用';
    } else if (statusNum == 1) {
      statusColor = Colors.green;
      statusText = '启用';
    } else if (statusNum == 2) {
      statusColor = Colors.blue;
      statusText = '运行中';
    } else if (statusNum > 0 && statusNum < 1) {
      statusColor = Colors.orange;
      statusText = '排队中';
    } else {
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
          MiuixDetailRow(label: '任务类型', value: taskType == 'cron' ? '定时任务' : '手动任务'),
          MiuixDetailRow(label: '分组', value: group.isEmpty ? '自动分组' : group),
          MiuixDetailRow(label: 'Cron 表达式', value: cronExpression.isEmpty ? '无' : cronExpression),
          MiuixDetailRow(label: '执行命令', value: command),
          MiuixDetailRow(label: '超时时间', value: '${timeout}秒'),
          const Divider(height: 32),
          MiuixDetailRow(label: '创建时间', value: createdAt),
          MiuixDetailRow(label: '更新时间', value: updatedAt),
          MiuixDetailRow(label: '上次运行', value: lastRunAt.isEmpty ? '未运行' : lastRunAt),
          MiuixDetailRow(label: '下次运行', value: nextRunAt.isEmpty ? '无' : nextRunAt),
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
                      children: _taskLogs.expand((log) {
                        final logId = log['id'] ?? 0;
                        final isSelected = _selectedLog?['id'] == logId;
                        final items = <Widget>[_buildLogItem(log)];
                        if (isSelected) {
                          items.add(_buildLogDetail(log));
                        }
                        return items;
                      }).toList(),
                    ),
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
    final logStatus = status is int ? status.toDouble() : (status ?? 0.0);
    if (logStatus == 0) {
      statusColor = Colors.green;
      statusText = '成功';
      statusIcon = Icons.check_circle;
    } else if (logStatus == 1) {
      statusColor = Colors.red;
      statusText = '失败';
      statusIcon = Icons.error;
    } else if (logStatus == 2) {
      statusColor = Colors.orange;
      statusText = '运行中';
      statusIcon = Icons.hourglass_empty;
    } else {
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
          MiuixCodeBlock(
            content: _cleanLogContent(content).isEmpty ? '无日志内容' : _cleanLogContent(content),
            maxHeight: 300,
          ),
          if (error.isNotEmpty) ...[
            const SizedBox(height: 8),
            MiuixCodeBlock(
              content: _cleanLogContent(error),
              maxHeight: 150,
            ),
          ],
        ],
      ),
    );
  }
}

class _MiuixIconButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback? onPressed;
  final String? tooltip;

  const _MiuixIconButton({
    required this.icon,
    required this.color,
    this.onPressed,
    this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip ?? '',
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(6),
          child: Icon(icon, size: 20, color: color),
        ),
      ),
    );
  }
}
