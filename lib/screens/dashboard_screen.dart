import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import '../services/auth_service.dart';
import '../services/log_service.dart';
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

    final logService = context.read<LogService>();
    logService.info('Dashboard', '开始加载仪表盘数据');

    try {
      final authService = context.read<AuthService>();
      
      // 分别加载数据，一个失败不影响另一个
      Map<String, dynamic> dashboard = {};
      Map<String, dynamic> system = {};
      
      try {
        logService.debug('Dashboard', '调用 getDashboard API');
        final dashboardResult = await authService.apiService.getDashboard();
        logService.info('Dashboard', 'Dashboard API 返回: $dashboardResult');
        
        if (dashboardResult is Map && dashboardResult.containsKey('data')) {
          dashboard = Map<String, dynamic>.from(dashboardResult['data'] ?? {});
        } else if (dashboardResult is Map) {
          dashboard = Map<String, dynamic>.from(dashboardResult);
        }
        logService.info('Dashboard', '处理后的 Dashboard 数据: $dashboard');
      } catch (e) {
        logService.error('Dashboard', 'Dashboard API 错误: $e');
      }
      
      try {
        logService.debug('Dashboard', '调用 getSystemInfo API');
        final systemResult = await authService.apiService.getSystemInfo();
        logService.info('Dashboard', 'SystemInfo API 返回: $systemResult');
        
        if (systemResult is Map && systemResult.containsKey('data')) {
          system = Map<String, dynamic>.from(systemResult['data'] ?? {});
        } else if (systemResult is Map) {
          system = Map<String, dynamic>.from(systemResult);
        }
        logService.info('Dashboard', '处理后的 System 数据: $system');
      } catch (e) {
        logService.error('Dashboard', 'SystemInfo API 错误: $e');
      }

      if (mounted) {
        setState(() {
          _dashboardData = dashboard;
          _systemInfo = system;
          _isLoading = false;
        });
        logService.info('Dashboard', '仪表盘数据加载完成');
      }
    } catch (e) {
      logService.error('Dashboard', '加载数据异常: $e');
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
    // Dashboard API 返回的字段
    final taskCount = _dashboardData['task_count'] ?? _dashboardData['enabled_tasks'] ?? 0;
    final envCount = _dashboardData['env_count'] ?? 0;
    final todayLogs = _dashboardData['today_logs'] ?? 0;
    final successLogs = _dashboardData['success_logs'] ?? 0;
    final failedLogs = _dashboardData['failed_logs'] ?? 0;
    
    // 计算成功率
    double successRate = 0.0;
    if (todayLogs > 0) {
      successRate = successLogs / todayLogs;
    }

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.5,
      children: [
        _buildStatCard(
          '启用任务',
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
          '$todayLogs',
          Icons.play_circle,
          Colors.orange,
          isDark,
        ),
        _buildStatCard(
          '失败任务',
          '$failedLogs',
          Icons.error_outline,
          failedLogs > 0 ? Colors.red : Colors.green,
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
    // SystemInfo API 返回的字段（注意：返回的是百分比值，如 30.36 表示 30.36%）
    final cpuUsage = (_systemInfo['cpu_usage'] ?? 0).toDouble() / 100;
    final memoryUsage = (_systemInfo['memory_usage'] ?? 0).toDouble() / 100;
    final diskUsage = (_systemInfo['disk_usage'] ?? 0).toDouble() / 100;
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
              subtitle: '${(_systemInfo['cpu_usage'] ?? 0).toStringAsFixed(1)}%',
            ),
            const SizedBox(height: 12),
            _buildResourceBar(
              '内存',
              memoryUsage,
              Colors.green,
              isDark,
              subtitle: '${_formatBytes(memoryUsed)} / ${_formatBytes(memoryTotal)}',
            ),
            const SizedBox(height: 12),
            _buildResourceBar(
              '磁盘',
              diskUsage,
              Colors.orange,
              isDark,
              subtitle: '${_formatBytes(diskUsed)} / ${_formatBytes(diskTotal)}',
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
    final recentLogs = _dashboardData['recent_logs'];
    if (recentLogs == null || recentLogs is! List || recentLogs.isEmpty) {
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
            ...recentLogs.take(5).map((log) => _buildRecentLogItem(log, isDark)),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentLogItem(Map<String, dynamic> log, bool isDark) {
    final taskName = log['task_name'] ?? log['task']?['name'] ?? '未知任务';
    final status = log['status'] ?? 0;
    final createdAt = log['created_at'] ?? '';
    final logId = log['id'];

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

    return InkWell(
      onTap: () {
        // 跳转到日志页面（索引5）
        widget.onNavigate?.call(5);
      },
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
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
                    taskName,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: isDark ? MiuixColors.darkOnSurface : MiuixColors.onSurface,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (createdAt.isNotEmpty)
                    Text(
                      createdAt,
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
            const SizedBox(width: 4),
            Icon(
              Icons.chevron_right,
              size: 16,
              color: isDark ? MiuixColors.darkOnSurfaceVariantSummary : MiuixColors.onSurfaceVariantSummary,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSystemInfoCard(bool isDark) {
    final hostname = _systemInfo['hostname'] ?? '';
    final goVersion = _systemInfo['go_version'] ?? '';
    final os = _systemInfo['os'] ?? '';
    final arch = _systemInfo['arch'] ?? '';
    final uptime = _systemInfo['uptime'] ?? '';
    final numCpu = _systemInfo['num_cpu'] ?? 0;
    final goroutines = _systemInfo['goroutines'] ?? 0;

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
            if (hostname.toString().isNotEmpty) _buildInfoRow('主机名', hostname.toString(), isDark),
            if (goVersion.toString().isNotEmpty) _buildInfoRow('Go 版本', goVersion.toString(), isDark),
            if (os.toString().isNotEmpty) _buildInfoRow('操作系统', '$os ($arch)', isDark),
            if (numCpu > 0) _buildInfoRow('CPU 核心', '$numCpu 核', isDark),
            if (uptime.toString().isNotEmpty) _buildInfoRow('运行时间', uptime.toString(), isDark),
            if (goroutines > 0) _buildInfoRow('协程数', '$goroutines', isDark),
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
