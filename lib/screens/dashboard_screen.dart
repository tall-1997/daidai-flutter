import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import '../services/auth_service.dart';
import '../theme/miuix_theme.dart';
import '../widgets/miuix_widgets.dart';
import 'home_screen.dart';

class DashboardScreen extends StatefulWidget {
  final Function(int)? onNavigate;

  const DashboardScreen({super.key, this.onNavigate});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> with RefreshableScreen {
  Map<String, dynamic>? _dashboardData;
  Map<String, dynamic>? _stats;
  bool _isLoading = true;
  String? _error;
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  @override
  void refresh() {
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final authService = context.read<AuthService>();
      final results = await Future.wait([
        authService.apiService.getDashboard(),
        authService.apiService.getStats(),
      ]);

      if (mounted) {
        setState(() {
          _dashboardData = results[0]['data'] ?? results[0];
          _stats = results[1]['data'] ?? results[1];
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = '加载失败: $e';
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('仪表盘'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
          ),
        ],
      ),
      body: _isLoading
          ? const MiuixLoadingState()
          : _error != null
              ? MiuixErrorState(message: _error!, onRetry: _loadData)
              : RefreshIndicator(
                  onRefresh: _loadData,
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      _buildStatsCards(isDark),
                      const SizedBox(height: 16),
                      _buildQuickActions(isDark),
                      const SizedBox(height: 16),
                      _buildRecentTasks(isDark),
                      const SizedBox(height: 16),
                      _buildSystemInfo(isDark),
                    ],
                  ),
                ),
    );
  }

  Widget _buildStatsCards(bool isDark) {
    final taskCount = _stats?['task_count'] ?? _dashboardData?['task_count'] ?? 0;
    final envCount = _stats?['env_count'] ?? _dashboardData?['env_count'] ?? 0;
    final todayRuns = _stats?['today_runs'] ?? _dashboardData?['today_runs'] ?? 0;
    final successRate = _stats?['success_rate'] ?? _dashboardData?['success_rate'] ?? 0.0;

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.5,
      children: [
        _buildStatCard(
          '任务总数',
          '$taskCount',
          Icons.task_alt,
          Colors.blue,
          isDark,
        ),
        _buildStatCard(
          '环境变量',
          '$envCount',
          Icons.key,
          Colors.green,
          isDark,
        ),
        _buildStatCard(
          '今日执行',
          '$todayRuns',
          Icons.play_circle,
          Colors.orange,
          isDark,
        ),
        _buildStatCard(
          '成功率',
          '${(successRate * 100).toStringAsFixed(1)}%',
          Icons.check_circle,
          successRate >= 0.9 ? Colors.green : Colors.red,
          isDark,
        ),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color, bool isDark) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(icon, size: 20, color: color),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 13,
                    color: isDark ? MiuixColors.darkOnSurfaceVariantSummary : MiuixColors.onSurfaceVariantSummary,
                  ),
                ),
              ],
            ),
            Text(
              value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActions(bool isDark) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '快捷操作',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: isDark ? MiuixColors.darkOnSurface : MiuixColors.onSurface,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildActionButton('任务', Icons.task_alt, Colors.blue, () {
                  widget.onNavigate?.call(1); // 任务在索引1
                }),
                _buildActionButton('脚本', Icons.code, Colors.green, () {
                  widget.onNavigate?.call(4); // 脚本在索引4
                }),
                _buildActionButton('日志', Icons.article, Colors.orange, () {
                  widget.onNavigate?.call(5); // 日志在索引5
                }),
                _buildActionButton('变量', Icons.key, Colors.purple, () {
                  widget.onNavigate?.call(2); // 环境变量在索引2
                }),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton(String label, IconData icon, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentTasks(bool isDark) {
    final recentTasks = _dashboardData?['recent_tasks'] ?? [];
    if (recentTasks.isEmpty) return const SizedBox.shrink();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '最近执行',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: isDark ? MiuixColors.darkOnSurface : MiuixColors.onSurface,
                  ),
                ),
                TextButton(
                  onPressed: () {
                    // Navigate to logs
                  },
                  child: const Text('查看全部'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ...recentTasks.take(5).map((task) => _buildRecentTaskItem(task, isDark)),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentTaskItem(Map<String, dynamic> task, bool isDark) {
    final name = task['task_name'] ?? task['name'] ?? '未知任务';
    final status = task['status'] ?? 0;
    final time = task['created_at'] ?? task['started_at'] ?? '';

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

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: statusColor,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: isDark ? MiuixColors.darkOnSurface : MiuixColors.onSurface,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (time.isNotEmpty)
                  Text(
                    time,
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? MiuixColors.darkOnSurfaceVariantSummary : MiuixColors.onSurfaceVariantSummary,
                    ),
                  ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              statusText,
              style: TextStyle(
                fontSize: 12,
                color: statusColor,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSystemInfo(bool isDark) {
    final systemInfo = _dashboardData?['system_info'] ?? _stats?['system_info'] ?? {};
    if (systemInfo.isEmpty) return const SizedBox.shrink();

    final cpuUsage = systemInfo['cpu_usage'] ?? 0.0;
    final memoryUsage = systemInfo['memory_usage'] ?? 0.0;
    final diskUsage = systemInfo['disk_usage'] ?? 0.0;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '系统资源',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: isDark ? MiuixColors.darkOnSurface : MiuixColors.onSurface,
              ),
            ),
            const SizedBox(height: 16),
            _buildResourceBar('CPU', cpuUsage, Colors.blue, isDark),
            const SizedBox(height: 12),
            _buildResourceBar('内存', memoryUsage, Colors.green, isDark),
            const SizedBox(height: 12),
            _buildResourceBar('磁盘', diskUsage, Colors.orange, isDark),
          ],
        ),
      ),
    );
  }

  Widget _buildResourceBar(String label, double value, Color color, bool isDark) {
    final percentage = (value * 100).toStringAsFixed(1);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                color: isDark ? MiuixColors.darkOnSurfaceVariantSummary : MiuixColors.onSurfaceVariantSummary,
              ),
            ),
            Text(
              '$percentage%',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        LinearProgressIndicator(
          value: value,
          backgroundColor: color.withOpacity(0.1),
          valueColor: AlwaysStoppedAnimation<Color>(color),
          minHeight: 6,
          borderRadius: BorderRadius.circular(3),
        ),
      ],
    );
  }
}
