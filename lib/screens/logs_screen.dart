import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../theme/miuix_theme.dart';
import '../widgets/miuix_widgets.dart';
import '../widgets/log_detail_sheet.dart';
import 'home_screen.dart';

class LogsScreen extends StatefulWidget {
  const LogsScreen({super.key});

  @override
  State<LogsScreen> createState() => _LogsScreenState();
}

class _LogsScreenState extends State<LogsScreen> with RefreshableScreen {
  List<Map<String, dynamic>> _logs = [];
  bool _isLoading = true;
  String? _error;
  int _currentPage = 1;
  int _totalLogs = 0;
  final int _pageSize = 50;
  String _filterStatus = 'all'; // all, success, failed, running
  bool _isSelectionMode = false;
  final Set<int> _selectedLogs = {};

  @override
  void initState() {
    super.initState();
    _loadLogs();
  }

  @override
  void refresh() {
    _loadLogs();
  }

  void _toggleSelectionMode() {
    setState(() {
      _isSelectionMode = !_isSelectionMode;
      if (!_isSelectionMode) {
        _selectedLogs.clear();
      }
    });
  }

  void _toggleLogSelection(int logId) {
    setState(() {
      if (_selectedLogs.contains(logId)) {
        _selectedLogs.remove(logId);
      } else {
        _selectedLogs.add(logId);
      }
    });
  }

  void _selectAllLogs() {
    setState(() {
      final filteredLogs = _getFilteredLogs();
      _selectedLogs.clear();
      for (var log in filteredLogs) {
        _selectedLogs.add(log['id']);
      }
    });
  }

  Future<void> _batchDeleteLogs() async {
    if (_selectedLogs.isEmpty) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('批量删除'),
        content: Text('确定要删除选中的 ${_selectedLogs.length} 条日志吗？'),
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

      for (var logId in _selectedLogs) {
        try {
          await authService.apiService.deleteLog(logId);
          successCount++;
        } catch (e) {
          // 继续删除其他日志
        }
      }

      setState(() {
        _isSelectionMode = false;
        _selectedLogs.clear();
      });

      _loadLogs();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('成功删除 $successCount 条日志'), backgroundColor: Colors.green),
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

  Future<void> _loadLogs({bool loadMore = false}) async {
    if (loadMore) {
      _currentPage++;
    } else {
      _currentPage = 1;
      setState(() {
        _isLoading = true;
        _error = null;
      });
    }

    try {
      final authService = context.read<AuthService>();
      // 将前端状态转换为后端状态参数
      String? statusParam;
      switch (_filterStatus) {
        case 'success':
          statusParam = '0';
          break;
        case 'failed':
          statusParam = '1';
          break;
        case 'running':
          statusParam = '2';
          break;
        default:
          statusParam = null; // 'all' 不传递状态参数
      }

      final result = await authService.apiService.getLogs(
        page: _currentPage,
        pageSize: _pageSize,
        status: statusParam,
      );

      if (result['data'] != null) {
        final newLogs = List<Map<String, dynamic>>.from(result['data'] ?? []);
        setState(() {
          if (loadMore) {
            _logs.addAll(newLogs);
          } else {
            _logs = newLogs;
          }
          _totalLogs = result['total'] ?? result['count'] ?? newLogs.length;
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = result['message'] ?? '获取日志失败';
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

  Future<void> _deleteLog(int id) async {
    try {
      final authService = context.read<AuthService>();
      await authService.apiService.deleteLog(id);
      _loadLogs();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('日志已删除')),
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

  Future<void> _clearOldLogs() async {
    final selectedDays = await showDialog<int>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('清理旧日志'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('选择要清理多少天前的日志：'),
            const SizedBox(height: 16),
            _buildDayOption(context, '1 天', 1),
            _buildDayOption(context, '3 天', 3),
            _buildDayOption(context, '7 天', 7),
            _buildDayOption(context, '30 天', 30),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
        ],
      ),
    );

    if (selectedDays == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认清理'),
        content: Text('确定要清理 $selectedDays 天前的日志吗？此操作不可撤销。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('清理'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final authService = context.read<AuthService>();
        await authService.apiService.clearLogsByDays(selectedDays);
        _loadLogs();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('已清理 $selectedDays 天前的日志'), backgroundColor: Colors.green),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('清理失败: $e'), backgroundColor: Colors.red),
          );
        }
      }
    }
  }

  Widget _buildDayOption(BuildContext context, String label, int days) {
    return ListTile(
      title: Text(label),
      trailing: const Icon(Icons.chevron_right),
      onTap: () => Navigator.pop(context, days),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
    );
  }

  List<Map<String, dynamic>> _getFilteredLogs() {
    if (_filterStatus == 'all') return _logs;
    return _logs.where((log) {
      final status = log['status'] ?? 0;
      switch (_filterStatus) {
        case 'success': return status == 0;
        case 'failed': return status == 1;
        case 'running': return status == 2;
        default: return true;
      }
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final filteredLogs = _getFilteredLogs();

    return Scaffold(
      appBar: AppBar(
        title: _isSelectionMode
          ? Text('已选择 ${_selectedLogs.length} 项')
          : Text('日志管理 ($_totalLogs)'),
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
              onPressed: _selectAllLogs,
              tooltip: '全选',
            ),
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: _selectedLogs.isNotEmpty ? _batchDeleteLogs : null,
              tooltip: '批量删除',
            ),
          ] else ...[
            IconButton(
              icon: const Icon(Icons.cleaning_services),
              onPressed: _clearOldLogs,
              tooltip: '清理旧日志',
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
          // Filter chips
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildFilterChip('全部', 'all'),
                  const SizedBox(width: 8),
                  _buildFilterChip('成功', 'success'),
                  const SizedBox(width: 8),
                  _buildFilterChip('失败', 'failed'),
                  const SizedBox(width: 8),
                  _buildFilterChip('运行中', 'running'),
                ],
              ),
            ),
          ),
          // Stats
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                _buildStatCard('成功', _logs.where((l) => l['status'] == 0).length, Colors.green),
                const SizedBox(width: 8),
                _buildStatCard('失败', _logs.where((l) => l['status'] == 1).length, Colors.red),
                const SizedBox(width: 8),
                _buildStatCard('运行中', _logs.where((l) => l['status'] == 2).length, Colors.orange),
              ],
            ),
          ),
          const SizedBox(height: 8),
          // Log list
          Expanded(
            child: _buildBody(filteredLogs),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String value) {
    return FilterChip(
      label: Text(label),
      selected: _filterStatus == value,
      onSelected: (selected) {
        setState(() {
          _filterStatus = value;
        });
        _loadLogs(); // 切换状态时重新加载数据
      },
    );
  }

  Widget _buildStatCard(String label, int count, Color color) {
    return Expanded(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              Text(
                count.toString(),
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              Text(
                label,
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBody(List<Map<String, dynamic>> filteredLogs) {
    if (_isLoading && _logs.isEmpty) {
      return const MiuixLoadingState();
    }

    if (_error != null && _logs.isEmpty) {
      return MiuixErrorState(
        message: _error!,
        onRetry: () => _loadLogs(),
      );
    }

    if (filteredLogs.isEmpty) {
      return const MiuixEmptyState(
        icon: Icons.article,
        title: '暂无日志',
      );
    }

    return RefreshIndicator(
      onRefresh: () => _loadLogs(),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: filteredLogs.length + (filteredLogs.length < _totalLogs ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == filteredLogs.length) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: FilledButton(
                  onPressed: () => _loadLogs(loadMore: true),
                  child: const Text('加载更多'),
                ),
              ),
            );
          }

          final log = filteredLogs[index];
          final isSelected = _selectedLogs.contains(log['id']);

          return _LogCard(
            log: log,
            isSelectionMode: _isSelectionMode,
            isSelected: isSelected,
            onSelectionChanged: () => _toggleLogSelection(log['id']),
            onDelete: () => _deleteLog(log['id']),
            onTap: () => _isSelectionMode ? _toggleLogSelection(log['id']) : _showLogDetail(log),
            onLongPress: _toggleSelectionMode,
          );
        },
      ),
    );
  }

  void _showLogDetail(Map<String, dynamic> log) {
    showLogDetail(context, log);
  }
}

class _LogCard extends StatelessWidget {
  final Map<String, dynamic> log;
  final bool isSelectionMode;
  final bool isSelected;
  final VoidCallback? onSelectionChanged;
  final VoidCallback? onLongPress;
  final VoidCallback onDelete;
  final VoidCallback onTap;

  const _LogCard({
    required this.log,
    this.isSelectionMode = false,
    this.isSelected = false,
    this.onSelectionChanged,
    this.onLongPress,
    required this.onDelete,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final taskName = log['task_name'] ?? '未知任务';
    final content = log['content'] ?? '';
    final status = log['status'] ?? 0;
    final createdAt = log['created_at'] ?? '';
    final duration = log['duration'] ?? 0;

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

    final preview = content.split('\n').first;

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
      child: InkWell(
        onTap: onTap,
        onLongPress: !isSelectionMode ? onLongPress : null,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
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
                        size: 20,
                      ),
                    ),
                  Icon(statusIcon, color: statusColor, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      taskName,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: statusColor.withOpacity(0.3)),
                    ),
                    child: Text(
                      statusText,
                      style: TextStyle(
                        color: statusColor,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                preview,
                style: Theme.of(context).textTheme.bodySmall,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(
                    Icons.access_time,
                    size: 12,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    createdAt,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey,
                      fontSize: 11,
                    ),
                  ),
                  if (durationText.isNotEmpty) ...[
                    const SizedBox(width: 8),
                    Icon(
                      Icons.timer,
                      size: 12,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        durationText,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey,
                          fontSize: 11,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                  if (!isSelectionMode) ...[
                    const SizedBox(width: 4),
                    SizedBox(
                      width: 24,
                      height: 24,
                      child: InkWell(
                        onTap: onDelete,
                        borderRadius: BorderRadius.circular(12),
                        child: const Icon(Icons.delete, size: 16, color: Colors.red),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}


