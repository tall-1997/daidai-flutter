import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/api_service.dart';

class StatsScreen extends StatefulWidget {
  const StatsScreen({super.key});

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> {
  Map<String, dynamic>? _dashboard;
  Map<String, dynamic>? _systemStats;
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() { _isLoading = true; _error = null; });
    try {
      final api = context.read<ApiService>();
      final dashboard = await api.getDashboard();
      final systemInfo = await api.getSystemInfo();
      setState(() {
        _dashboard = dashboard['data'] ?? dashboard;
        _systemStats = systemInfo['data'] ?? systemInfo;
        _isLoading = false;
      });
    } catch (e) {
      setState(() { _error = '加载失败: $e'; _isLoading = false; });
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
    if (data == null) return const SizedBox.shrink();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('面板概览', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const Divider(),
            _buildStatRow('总任务数', data['task_count']?.toString() ?? '0'),
            _buildStatRow('启用任务', data['enabled_task_count']?.toString() ?? '0'),
            _buildStatRow('运行中任务', data['running_task_count']?.toString() ?? '0'),
            _buildStatRow('总日志数', data['log_count']?.toString() ?? '0'),
            _buildStatRow('环境变量数', data['env_count']?.toString() ?? '0'),
            _buildStatRow('脚本数', data['script_count']?.toString() ?? '0'),
          ],
        ),
      ),
    );
  }

  Widget _buildSystemSection() {
    final data = _systemStats;
    if (data == null) return const SizedBox.shrink();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('系统信息', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const Divider(),
            _buildStatRow('操作系统', data['os']?.toString() ?? '-'),
            _buildStatRow('架构', data['arch']?.toString() ?? '-'),
            _buildStatRow('Go版本', data['go_version']?.toString() ?? '-'),
            _buildStatRow('CPU核心数', data['num_cpu']?.toString() ?? '-'),
            _buildStatRow('面板版本', data['version']?.toString() ?? '-'),
            if (data['ip'] != null)
              _buildStatRow('IP地址', data['ip'].toString()),
          ],
        ),
      ),
    );
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
            _buildStatRow('成功次数', _dashboard?['success_count']?.toString() ?? '0'),
            _buildStatRow('失败次数', _dashboard?['fail_count']?.toString() ?? '0'),
            _buildStatRow('最后执行时间', _dashboard?['last_run_time']?.toString() ?? '-'),
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
          Text(value, style: const TextStyle(fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}
