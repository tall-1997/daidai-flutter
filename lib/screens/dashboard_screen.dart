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
  Map<String, dynamic> _dashboardData = {};
  Map<String, dynamic> _systemInfo = {};
  bool _isLoading = true;
  Timer? _refreshTimer;

  // Trend data
  final List<double> _cpuHistory = [];
  final List<double> _memoryHistory = [];
  Timer? _trendTimer;
  static const int _maxHistoryLength = 30;

  @override
  void initState() {
    super.initState();
    _loadData();
    _startTrendMonitoring();
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _trendTimer?.cancel();
    super.dispose();
  }

  @override
  void refresh() {
    _loadData();
  }

  void _startTrendMonitoring() {
    _trendTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (mounted) {
        setState(() {
          final cpuUsage = (_systemInfo['cpu_usage'] ?? 0).toDouble();
          final memoryUsage = (_systemInfo['memory_usage'] ?? 0).toDouble();
          _cpuHistory.add(cpuUsage);
          _memoryHistory.add(memoryUsage);
          
          if (_cpuHistory.length > _maxHistoryLength) {
            _cpuHistory.removeAt(0);
          }
          if (_memoryHistory.length > _maxHistoryLength) {
            _memoryHistory.removeAt(0);
          }
        });
      }
    });
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final authService = context.read<AuthService>();
      
      // 分别加载数据，避免一个失败导致全部失败
      Map<String, dynamic> dashboard = {};
      Map<String, dynamic> system = {};
      
      try {
        final dashboardResult = await authService.apiService.getDashboard();
        if (dashboardResult is Map) {
          dashboard = Map<String, dynamic>.from(dashboardResult['data'] ?? dashboardResult);
        }
      } catch (e) {
        debugPrint('Dashboard API error: $e');
      }
      
      try {
        final systemResult = await authService.apiService.getSystemInfo();
        if (systemResult is Map) {
          system = Map<String, dynamic>.from(systemResult['data'] ?? systemResult);
        }
      } catch (e) {
        debugPrint('System API error: $e');
      }

      if (mounted) {
        setState(() {
          _dashboardData = dashboard;
          _systemInfo = system;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _dashboardData = {};
          _systemInfo = {};
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
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadData,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _buildStatsCards(isDark),
                  const SizedBox(height: 16),
                  _buildQuickActions(isDark),
                  const SizedBox(height: 16),
                  _buildSystemResourceCard(isDark),
                  if (_cpuHistory.length >= 3) ...[
                    const SizedBox(height: 16),
                    _buildTrendChartCard(isDark),
                  ],
                  const SizedBox(height: 16),
                  _buildRecentTasks(isDark),
                  const SizedBox(height: 16),
                  _buildSystemInfoCard(isDark),
                ],
              ),
            ),
    );
  }

  Widget _buildStatsCards(bool isDark) {
    final taskCount = _dashboardData['task_count'] ?? _systemInfo['task_count'] ?? 0;
    final envCount = _dashboardData['env_count'] ?? _systemInfo['env_count'] ?? 0;
    final todayRuns = _dashboardData['today_runs'] ?? _systemInfo['today_runs'] ?? 0;
    final successRate = _dashboardData['success_rate'] ?? _systemInfo['success_rate'] ?? 0.0;

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
          '${(successRate is num ? successRate * 100 : 0).toStringAsFixed(1)}%',
          Icons.check_circle,
          (successRate is num && successRate >= 0.9) ? Colors.green : Colors.red,
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
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 13,
                      color: isDark ? MiuixColors.darkOnSurfaceVariantSummary : MiuixColors.onSurfaceVariantSummary,
                    ),
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
                  widget.onNavigate?.call(1);
                }),
                _buildActionButton('脚本', Icons.code, Colors.green, () {
                  widget.onNavigate?.call(4);
                }),
                _buildActionButton('日志', Icons.article, Colors.orange, () {
                  widget.onNavigate?.call(5);
                }),
                _buildActionButton('变量', Icons.key, Colors.purple, () {
                  widget.onNavigate?.call(2);
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
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSystemResourceCard(bool isDark) {
    final cpuUsage = (_systemInfo['cpu_usage'] ?? 0).toDouble();
    final memoryUsage = (_systemInfo['memory_usage'] ?? 0).toDouble();
    final diskUsage = (_systemInfo['disk_usage'] ?? 0).toDouble();
    final memoryTotal = _systemInfo['memory_total'] ?? 0;
    final memoryUsed = _systemInfo['memory_used'] ?? 0;
    final diskTotal = _systemInfo['disk_total'] ?? 0;
    final diskUsed = _systemInfo['disk_used'] ?? 0;

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
            _buildResourceBar(
              'CPU',
              cpuUsage,
              Colors.blue,
              isDark,
              subtitle: '${(cpuUsage * 100).toStringAsFixed(1)}%',
            ),
            const SizedBox(height: 12),
            _buildResourceBar(
              '内存',
              memoryUsage,
              Colors.green,
              isDark,
              subtitle: memoryTotal > 0 ? '${_formatBytes(memoryUsed)} / ${_formatBytes(memoryTotal)}' : '${(memoryUsage * 100).toStringAsFixed(1)}%',
            ),
            const SizedBox(height: 12),
            _buildResourceBar(
              '磁盘',
              diskUsage,
              Colors.orange,
              isDark,
              subtitle: diskTotal > 0 ? '${_formatBytes(diskUsed)} / ${_formatBytes(diskTotal)}' : '${(diskUsage * 100).toStringAsFixed(1)}%',
            ),
          ],
        ),
      ),
    );
  }

  String _formatBytes(dynamic bytes) {
    if (bytes == null || bytes == 0) return '0 B';
    final b = bytes is int ? bytes : int.tryParse(bytes.toString()) ?? 0;
    if (b < 1024) return '$b B';
    if (b < 1024 * 1024) return '${(b / 1024).toStringAsFixed(1)} KB';
    if (b < 1024 * 1024 * 1024) return '${(b / (1024 * 1024)).toStringAsFixed(1)} MB';
    return '${(b / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }

  Widget _buildResourceBar(String label, double value, Color color, bool isDark, {String? subtitle}) {
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
              subtitle ?? '$percentage%',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: value.clamp(0.0, 1.0),
            backgroundColor: color.withOpacity(0.1),
            valueColor: AlwaysStoppedAnimation<Color>(color),
            minHeight: 8,
          ),
        ),
      ],
    );
  }

  Widget _buildTrendChartCard(bool isDark) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '资源趋势',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: isDark ? MiuixColors.darkOnSurface : MiuixColors.onSurface,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 150,
              child: CustomPaint(
                size: Size.infinite,
                painter: _TrendChartPainter(
                  cpuData: _cpuHistory,
                  memoryData: _memoryHistory,
                  isDark: isDark,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildLegendItem('CPU', Colors.blue),
                const SizedBox(width: 24),
                _buildLegendItem('内存', Colors.green),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }

  Widget _buildRecentTasks(bool isDark) {
    final recentTasks = _dashboardData['recent_tasks'];
    if (recentTasks == null || recentTasks is! List || recentTasks.isEmpty) {
      return const SizedBox.shrink();
    }

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
                  onPressed: () => widget.onNavigate?.call(5),
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

  Widget _buildSystemInfoCard(bool isDark) {
    final panelVersion = _systemInfo['panel_version'] ?? _systemInfo['version'] ?? '未知';
    final goVersion = _systemInfo['go_version'] ?? '';
    final os = _systemInfo['os'] ?? '';
    final arch = _systemInfo['arch'] ?? '';
    final uptime = _systemInfo['uptime'] ?? 0;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '系统信息',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: isDark ? MiuixColors.darkOnSurface : MiuixColors.onSurface,
              ),
            ),
            const SizedBox(height: 12),
            _buildInfoRow('面板版本', panelVersion.toString(), isDark),
            if (goVersion.toString().isNotEmpty) _buildInfoRow('Go 版本', goVersion.toString(), isDark),
            if (os.toString().isNotEmpty) _buildInfoRow('操作系统', '$os ($arch)', isDark),
            if (uptime > 0) _buildInfoRow('运行时间', _formatUptime(uptime), isDark),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: isDark ? MiuixColors.darkOnSurfaceVariantSummary : MiuixColors.onSurfaceVariantSummary,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: isDark ? MiuixColors.darkOnSurface : MiuixColors.onSurface,
            ),
          ),
        ],
      ),
    );
  }

  String _formatUptime(dynamic uptime) {
    final seconds = uptime is int ? uptime : int.tryParse(uptime.toString()) ?? 0;
    if (seconds < 60) return '$seconds 秒';
    if (seconds < 3600) return '${(seconds / 60).floor()} 分钟';
    if (seconds < 86400) return '${(seconds / 3600).floor()} 小时';
    return '${(seconds / 86400).floor()} 天';
  }
}

class _TrendChartPainter extends CustomPainter {
  final List<double> cpuData;
  final List<double> memoryData;
  final bool isDark;

  _TrendChartPainter({
    required this.cpuData,
    required this.memoryData,
    required this.isDark,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (cpuData.isEmpty || memoryData.isEmpty) return;

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;

    final path = Path();
    final width = size.width;
    final height = size.height;
    final stepX = cpuData.length > 1 ? width / (cpuData.length - 1) : width;

    // Draw CPU line
    paint.color = Colors.blue;
    path.reset();
    for (int i = 0; i < cpuData.length; i++) {
      final x = i * stepX;
      final y = height - (cpuData[i].clamp(0.0, 1.0) * height);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    canvas.drawPath(path, paint);

    // Draw Memory line
    paint.color = Colors.green;
    path.reset();
    for (int i = 0; i < memoryData.length; i++) {
      final x = i * stepX;
      final y = height - (memoryData[i].clamp(0.0, 1.0) * height);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
