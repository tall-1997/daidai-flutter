import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../services/root/magisk_helper.dart';

class SystemScreen extends StatefulWidget {
  const SystemScreen({super.key});

  @override
  State<SystemScreen> createState() => _SystemScreenState();
}

class _SystemScreenState extends State<SystemScreen> {
  bool _isLoading = true;
  bool _isRooted = false;
  Map<String, dynamic> _systemInfo = {};
  Map<String, dynamic> _dashboardData = {};
  String _error = '';

  @override
  void initState() {
    super.initState();
    _loadSystemInfo();
  }

  Future<void> _loadSystemInfo() async {
    setState(() {
      _isLoading = true;
      _error = '';
    });

    try {
      final authService = context.read<AuthService>();
      
      // Check root status
      _isRooted = await MagiskHelper.isDaidaiModuleInstalled();
      
      // Get system info from API
      try {
        final systemResult = await authService.apiService.getSystemInfo();
        if (systemResult['data'] != null) {
          _systemInfo = systemResult['data'];
        }
      } catch (e) {
        // API might not be available
      }
      
      // Get dashboard data
      try {
        final dashboardResult = await authService.apiService.getDashboard();
        if (dashboardResult['data'] != null) {
          _dashboardData = dashboardResult['data'];
        }
      } catch (e) {
        // API might not be available
      }
      
      // If rooted, get additional info via root
      if (_isRooted) {
        try {
          final rootInfo = await MagiskHelper.getSystemInfoViaRoot();
          if (rootInfo.isNotEmpty) {
            _systemInfo['root_info'] = rootInfo;
          }
        } catch (e) {
          // Root info not available
        }
      }
      
      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _error = '加载失败: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('系统信息'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadSystemInfo,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error.isNotEmpty
              ? Center(child: Text(_error))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildRootStatusCard(),
                      const SizedBox(height: 16),
                      _buildDashboardCard(),
                      const SizedBox(height: 16),
                      _buildSystemInfoCard(),
                      if (_systemInfo.containsKey('root_info')) ...[
                        const SizedBox(height: 16),
                        _buildRootSystemInfoCard(),
                      ],
                    ],
                  ),
                ),
    );
  }

  Widget _buildRootStatusCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(
              _isRooted ? Icons.check_circle : Icons.cancel,
              color: _isRooted ? Colors.green : Colors.orange,
              size: 32,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Root 权限',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  Text(
                    _isRooted ? '已获取 Root 权限' : '未获取 Root 权限',
                    style: TextStyle(
                      color: _isRooted ? Colors.green : Colors.orange,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDashboardCard() {
    final taskCount = _dashboardData['task_count'] ?? 0;
    final enabledTasks = _dashboardData['enabled_tasks'] ?? 0;
    final runningTasks = _dashboardData['running_tasks'] ?? 0;
    final todayLogs = _dashboardData['today_logs'] ?? 0;
    final successLogs = _dashboardData['success_logs'] ?? 0;
    final failedLogs = _dashboardData['failed_logs'] ?? 0;
    final envCount = _dashboardData['env_count'] ?? 0;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.dashboard, color: Colors.blue),
                const SizedBox(width: 8),
                Text(
                  '面板概览',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
            const Divider(),
            Row(
              children: [
                _buildStatItem('任务总数', '$taskCount', Colors.blue),
                _buildStatItem('已启用', '$enabledTasks', Colors.green),
                _buildStatItem('运行中', '$runningTasks', Colors.orange),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _buildStatItem('今日日志', '$todayLogs', Colors.purple),
                _buildStatItem('成功', '$successLogs', Colors.green),
                _buildStatItem('失败', '$failedLogs', Colors.red),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _buildStatItem('环境变量', '$envCount', Colors.teal),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        margin: const EdgeInsets.symmetric(horizontal: 4),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSystemInfoCard() {
    final hostname = _systemInfo['hostname'] ?? '';
    final cpuUsage = _systemInfo['cpu_usage'] ?? 0.0;
    final memoryTotal = _systemInfo['memory_total'] ?? 0;
    final memoryUsed = _systemInfo['memory_used'] ?? 0;
    final memoryUsage = _systemInfo['memory_usage'] ?? 0.0;
    final diskTotal = _systemInfo['disk_total'] ?? 0;
    final diskUsed = _systemInfo['disk_used'] ?? 0;
    final diskUsage = _systemInfo['disk_usage'] ?? 0.0;
    final uptime = _systemInfo['uptime'] ?? '';
    final goVersion = _systemInfo['go_version'] ?? '';
    final os = _systemInfo['os'] ?? '';
    final arch = _systemInfo['arch'] ?? '';
    final numCpu = _systemInfo['num_cpu'] ?? 0;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.computer, color: Colors.green),
                const SizedBox(width: 8),
                Text(
                  '系统信息',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
            const Divider(),
            if (hostname.isNotEmpty)
              _buildInfoRow('主机名', hostname),
            _buildInfoRow('操作系统', '$os $arch'),
            _buildInfoRow('CPU 核心', '$numCpu 核'),
            _buildInfoRow('CPU 使用率', '${cpuUsage.toStringAsFixed(1)}%'),
            const SizedBox(height: 8),
            _buildProgressBar('CPU', cpuUsage / 100, Colors.blue),
            const SizedBox(height: 12),
            _buildInfoRow('内存', '${_formatBytes(memoryUsed)} / ${_formatBytes(memoryTotal)}'),
            _buildInfoRow('内存使用率', '${memoryUsage.toStringAsFixed(1)}%'),
            const SizedBox(height: 8),
            _buildProgressBar('内存', memoryUsage / 100, Colors.green),
            const SizedBox(height: 12),
            _buildInfoRow('磁盘', '${_formatBytes(diskUsed)} / ${_formatBytes(diskTotal)}'),
            _buildInfoRow('磁盘使用率', '${diskUsage.toStringAsFixed(1)}%'),
            const SizedBox(height: 8),
            _buildProgressBar('磁盘', diskUsage / 100, Colors.orange),
            const SizedBox(height: 12),
            _buildInfoRow('运行时间', uptime),
            _buildInfoRow('Go 版本', goVersion),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressBar(String label, double progress, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        LinearProgressIndicator(
          value: progress,
          backgroundColor: color.withOpacity(0.2),
          valueColor: AlwaysStoppedAnimation<Color>(color),
          minHeight: 8,
          borderRadius: BorderRadius.circular(4),
        ),
      ],
    );
  }

  Widget _buildRootSystemInfoCard() {
    final rootInfo = _systemInfo['root_info'] as Map<String, dynamic>;
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.android, color: Colors.green),
                const SizedBox(width: 8),
                Text(
                  '系统信息 (Root)',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
            const Divider(),
            if (rootInfo.containsKey('memory'))
              _buildInfoRow('内存', rootInfo['memory']),
            if (rootInfo.containsKey('cpu'))
              _buildInfoRow('CPU', rootInfo['cpu']),
            if (rootInfo.containsKey('disk'))
              _buildInfoRow('磁盘', rootInfo['disk']),
            if (rootInfo.containsKey('uptime'))
              _buildInfoRow('运行时间', rootInfo['uptime']),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
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

  String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }
}
