import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:convert';
import 'dart:io';
import '../services/auth_service.dart';
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

  @override
  void initState() {
    super.initState();
    _loadLogs();
  }

  @override
  void refresh() {
    _loadLogs();
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
      final result = await authService.apiService.getLogs(
        page: _currentPage,
        pageSize: _pageSize,
      );

      if (result['data'] != null) {
        final newLogs = List<Map<String, dynamic>>.from(result['data'] ?? []);
        // 确保日志包含所有状态（成功、失败、运行中）
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
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('清理旧日志'),
        content: const Text('确定要清理7天前的日志吗？此操作不可撤销。'),
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
        // Call API to clear old logs
        await authService.apiService.post('/logs/clear', body: {'days': 7});
        _loadLogs();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('旧日志已清理')),
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
        title: Text('日志管理 ($_totalLogs)'),
        actions: [
          IconButton(
            icon: const Icon(Icons.cleaning_services),
            onPressed: _clearOldLogs,
            tooltip: '清理旧日志',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => _loadLogs(),
          ),
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
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null && _logs.isEmpty) {
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
              onPressed: () => _loadLogs(),
              child: const Text('重试'),
            ),
          ],
        ),
      );
    }

    if (filteredLogs.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.article,
              size: 64,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 16),
            const Text('暂无日志'),
          ],
        ),
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
          return _LogCard(
            log: log,
            onDelete: () => _deleteLog(log['id']),
            onTap: () => _showLogDetail(log),
          );
        },
      ),
    );
  }

  void _showLogDetail(Map<String, dynamic> log) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) => _LogDetailSheet(
          log: log,
          scrollController: scrollController,
        ),
      ),
    );
  }
}

class _LogCard extends StatelessWidget {
  final Map<String, dynamic> log;
  final VoidCallback onDelete;
  final VoidCallback onTap;

  const _LogCard({
    required this.log,
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
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
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
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LogDetailSheet extends StatelessWidget {
  final Map<String, dynamic> log;
  final ScrollController scrollController;

  const _LogDetailSheet({
    required this.log,
    required this.scrollController,
  });

  // Clean content: remove ANSI escape sequences and control characters
  String _cleanContent(dynamic rawContent) {
    if (rawContent == null) return '';
    
    String content = rawContent.toString();
    
    // Try to decode base64 + gzip (eJ prefix = gzip compressed base64)
    if (content.length > 8 && RegExp(r'^[A-Za-z0-9+/]*={0,2}$').hasMatch(content.trim())) {
      try {
        final bytes = base64Decode(content.trim());
        // Check gzip magic number (1f 8b)
        if (bytes.length > 2 && bytes[0] == 0x1f && bytes[1] == 0x8b) {
          content = utf8.decode(gzip.decode(bytes), allowMalformed: true);
        } else {
          content = utf8.decode(bytes, allowMalformed: true);
        }
      } catch (e) {
        // Try without gzip
        try {
          final bytes = base64Decode(content.trim());
          content = utf8.decode(bytes, allowMalformed: true);
        } catch (e2) {
          // Use original content
        }
      }
    }
    
    // Remove ANSI escape sequences
    content = _stripAnsi(content);
    
    return content.trim();
  }

  // Comprehensive ANSI escape sequence removal
  String _stripAnsi(String str) {
    // ESC sequences with ESC prefix
    str = str.replaceAll(RegExp(r'\x1B(?:[@-Z\\-_]|\[[0-?]*[ -/]*[@-~])'), '');
    // OSC sequences
    str = str.replaceAll(RegExp(r'\x1B\][^\x07\x1B]*(?:\x07|\x1B\\)'), '');
    // CSI sequences without ESC prefix (stored logs may have lost ESC byte)
    str = str.replaceAll(RegExp(r'\[(?:\d+;)*\d+[A-Za-z]'), '');
    // Remove bare [32m, [0m etc
    str = str.replaceAll(RegExp(r'\[\d+m'), '');
    // Remove control characters except newline and tab
    str = str.replaceAll(RegExp(r'[\x00-\x08\x0B\x0C\x0E-\x1F\x7F]'), '');
    return str;
  }

  @override
  Widget build(BuildContext context) {
    final taskName = log['task_name'] ?? log['taskName'] ?? '未知任务';
    final content = log['content'] ?? log['output'] ?? log['message'] ?? '';
    final status = log['status'] ?? 0;
    final createdAt = log['created_at'] ?? log['createdAt'] ?? '';
    final startedAt = log['started_at'] ?? log['startedAt'] ?? '';
    final endedAt = log['ended_at'] ?? log['endedAt'] ?? '';
    final duration = log['duration'] ?? log['execution_time'] ?? 0;
    final taskType = log['task_type'] ?? log['taskType'] ?? '';
    final taskId = log['task_id'] ?? log['taskId'] ?? '';
    final logId = log['id'] ?? '';
    final errorMsg = log['error'] ?? log['error_message'] ?? '';

    Color statusColor;
    String statusText;
    switch (status) {
      case 0:
        statusColor = Colors.green;
        statusText = '成功';
        break;
      case 1:
        statusColor = Colors.red;
        statusText = '失败';
        break;
      case 2:
        statusColor = Colors.orange;
        statusText = '运行中';
        break;
      default:
        statusColor = Colors.grey;
        statusText = '未知';
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
                  taskName,
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
          _buildDetailRow('日志ID', logId.toString()),
          _buildDetailRow('任务ID', taskId.toString()),
          _buildDetailRow('任务类型', taskType),
          _buildDetailRow('创建时间', createdAt),
          _buildDetailRow('开始时间', startedAt.isEmpty ? '无' : startedAt),
          _buildDetailRow('结束时间', endedAt.isEmpty ? '无' : endedAt),
          _buildDetailRow('执行耗时', durationText.isEmpty ? '无' : durationText),
          if (errorMsg.isNotEmpty) _buildDetailRow('错误信息', _cleanContent(errorMsg)),
          const Divider(height: 32),
          Text(
            '执行日志',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(8),
            ),
            child: SelectableText(
              _cleanContent(content).isEmpty ? '无日志内容' : _cleanContent(content),
              style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
            ),
          ),
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
            width: 80,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(child: Text(value.isEmpty ? '无' : value)),
        ],
      ),
    );
  }
}
