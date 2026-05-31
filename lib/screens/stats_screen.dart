import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import 'home_screen.dart';

class StatsScreen extends StatefulWidget {
  const StatsScreen({super.key});

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> with RefreshableScreen {
  Map<String, dynamic>? _dashboard;
  Map<String, dynamic>? _systemStats;
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void refresh() {
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() { _isLoading = true; _error = null; });
    try {
      final authService = context.read<AuthService>();
      final api = authService.apiService;
      
      // Fetch dashboard and system info in parallel
      final results = await Future.wait([
        api.getDashboard().catchError((e) => {'error': e.toString()}),
        api.getSystemInfo().catchError((e) => {'error': e.toString()}),
      ]);
      
      final dashboard = results[0];
      final systemInfo = results[1];
      
      if (mounted) {
        setState(() {
          _dashboard = dashboard['data'] ?? dashboard;
          _systemStats = systemInfo['data'] ?? systemInfo;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() { _error = '加载失败: $e'; _isLoading = false; });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('数据统计'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(_error!, style: const TextStyle(color: Colors.red)),
                      const SizedBox(height: 16),
                      ElevatedButton(onPressed: _loadData, child: const Text('重试')),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadData,
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      _buildDashboardSection(),
                      const SizedBox(height: 16),
                      _buildSystemSection(),
                      const SizedBox(height: 16),
                      _buildTaskStatsSection(),
                    ],
                  ),
                ),
    );
  }

  Widget _buildDashboardSection() {
    final data = _dashboard;
    if (data == null || data.containsKey('error')) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('面板概览', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const Divider(),
              Text('加载失败: ${data?['error'] ?? '未知错误'}', 
                style: const TextStyle(color: Colors.red)),
            ],
          ),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('面板概览', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const Divider(),
            _buildStatRow('总任务数', data['task_count']?.toString() ?? 
              data['total_tasks']?.toString() ?? '0'),
            _buildStatRow('启用任务', data['enabled_task_count']?.toString() ?? 
              data['enabled_tasks']?.toString() ?? '0'),
            _buildStatRow('运行中任务', data['running_task_count']?.toString() ?? 
              data['running_tasks']?.toString() ?? '0'),
            _buildStatRow('总日志数', data['log_count']?.toString() ?? 
              data['total_logs']?.toString() ?? '0'),
            _buildStatRow('环境变量数', data['env_count']?.toString() ?? 
              data['total_envs']?.toString() ?? '0'),
            _buildStatRow('脚本数', data['script_count']?.toString() ?? 
              data['total_scripts']?.toString() ?? '0'),
          ],
        ),
      ),
    );
  }

  Widget _buildSystemSection() {
    final data = _systemStats;
    if (data == null || data.containsKey('error')) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('系统信息', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const Divider(),
              Text('加载失败: ${data?['error'] ?? '未知错误'}', 
                style: const TextStyle(color: Colors.red)),
            ],
          ),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('系统信息', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const Divider(),
            _buildStatRow('操作系统', data['os']?.toString() ?? 
              data['platform']?.toString() ?? '-'),
            _buildStatRow('架构', data['arch']?.toString() ?? 
              data['architecture']?.toString() ?? '-'),
            _buildStatRow('Go版本', data['go_version']?.toString() ?? '-'),
            _buildStatRow('CPU核心数', data['num_cpu']?.toString() ?? 
              data['cpu_count']?.toString() ?? '-'),
            _buildStatRow('面板版本', data['version']?.toString() ?? '-'),
            if (data['ip'] != null)
              _buildStatRow('IP地址', data['ip'].toString()),
            if (data['hostname'] != null)
              _buildStatRow('主机名', data['hostname'].toString()),
            if (data['uptime'] != null)
              _buildStatRow('运行时间', _formatUptime(data['uptime'])),
          ],
        ),
      ),
    );
  }

  String _formatUptime(dynamic uptime) {
    if (uptime is int) {
      final days = uptime ~/ 86400;
      final hours = (uptime % 86400) ~/ 3600;
      final minutes = (uptime % 3600) ~/ 60;
      if (days > 0) return '$days天${hours}小时${minutes}分钟';
      if (hours > 0) return '$hours小时${minutes}分钟';
      return '$minutes分钟';
    }
    return uptime.toString();
  }

  Widget _buildTaskStatsSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('任务统计', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const Divider(),
            _buildStatRow('成功次数', _dashboard?['success_count']?.toString() ?? 
              _dashboard?['success_runs']?.toString() ?? '0'),
            _buildStatRow('失败次数', _dashboard?['fail_count']?.toString() ?? 
              _dashboard?['failed_runs']?.toString() ?? '0'),
            _buildStatRow('最后执行时间', _dashboard?['last_run_time']?.toString() ?? 
              _dashboard?['last_execution']?.toString() ?? '-'),
          ],
        ),
      ),
    );
  }

  Widget _buildStatRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey)),
          Flexible(
            child: Text(
              value, 
              style: const TextStyle(fontWeight: FontWeight.w500),
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }
}
