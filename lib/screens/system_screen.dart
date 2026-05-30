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
  bool _isDaidaiModuleInstalled = false;
  MagiskModuleInfo? _moduleInfo;
  Map<String, dynamic> _systemInfo = {};
  Map<String, dynamic>? _rootSystemInfo;
  String _panelLogs = '';
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
      
      // Get Magisk module info if rooted
      if (_isRooted) {
        _isDaidaiModuleInstalled = true;
        _moduleInfo = await MagiskHelper.getModuleInfo();
        _rootSystemInfo = await MagiskHelper.getSystemInfoViaRoot();
        _panelLogs = await MagiskHelper.getPanelLogsViaRoot(lines: 50);
      }
      
      // Get API system info
      try {
        final dashboard = await authService.apiService.getDashboard();
        if (dashboard['data'] != null) {
          _systemInfo = dashboard['data'];
        }
      } catch (e) {
        // API might not be available
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
                      if (_isDaidaiModuleInstalled) ...[
                        _buildMagiskModuleCard(),
                        const SizedBox(height: 16),
                      ],
                      _buildSystemInfoCard(),
                      const SizedBox(height: 16),
                      if (_rootSystemInfo != null) ...[
                        _buildRootSystemInfoCard(),
                        const SizedBox(height: 16),
                      ],
                      if (_panelLogs.isNotEmpty) ...[
                        _buildPanelLogsCard(),
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

  Widget _buildMagiskModuleCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.extension, color: Colors.purple),
                const SizedBox(width: 8),
                Text(
                  'Magisk 模块',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
            const Divider(),
            if (_moduleInfo != null) ...[
              _buildInfoRow('模块名称', _moduleInfo!.name),
              _buildInfoRow('版本', _moduleInfo!.version),
              _buildInfoRow('作者', _moduleInfo!.author),
              _buildInfoRow('描述', _moduleInfo!.description),
            ] else
              const Text('无法读取模块信息'),
          ],
        ),
      ),
    );
  }

  Widget _buildSystemInfoCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.info, color: Colors.blue),
                const SizedBox(width: 8),
                Text(
                  '面板信息',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
            const Divider(),
            if (_systemInfo.isNotEmpty) ...[
              _buildInfoRow('运行任务', '${_systemInfo['runningTasks'] ?? 0}'),
              _buildInfoRow('今日日志', '${_systemInfo['todayLogs'] ?? 0}'),
            ] else
              const Text('无法获取面板信息'),
          ],
        ),
      ),
    );
  }

  Widget _buildRootSystemInfoCard() {
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
            if (_rootSystemInfo!.containsKey('memory'))
              _buildInfoRow('内存', _rootSystemInfo!['memory']),
            if (_rootSystemInfo!.containsKey('cpu'))
              _buildInfoRow('CPU', _rootSystemInfo!['cpu']),
            if (_rootSystemInfo!.containsKey('disk'))
              _buildInfoRow('磁盘', _rootSystemInfo!['disk']),
            if (_rootSystemInfo!.containsKey('uptime'))
              _buildInfoRow('运行时间', _rootSystemInfo!['uptime']),
          ],
        ),
      ),
    );
  }

  Widget _buildPanelLogsCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.article, color: Colors.orange),
                const SizedBox(width: 8),
                Text(
                  '面板日志 (Root)',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
            const Divider(),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.black87,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                _panelLogs,
                style: const TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 12,
                  color: Colors.green,
                ),
                maxLines: 20,
                overflow: TextOverflow.ellipsis,
              ),
            ),
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
}
