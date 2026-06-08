import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import '../services/auth_service.dart';
import '../theme/miuix_theme.dart';
import '../widgets/miuix_widgets.dart';
import 'home_screen.dart';

class DependenciesScreen extends StatefulWidget {
  const DependenciesScreen({super.key});

  @override
  State<DependenciesScreen> createState() => _DependenciesScreenState();
}

class _DependenciesScreenState extends State<DependenciesScreen> with RefreshableScreen {
  List<Map<String, dynamic>> _dependencies = [];
  bool _isLoading = true;
  String? _error;
  String _filterType = 'all'; // all, nodejs, python, linux
  String _filterStatus = 'all'; // all, installed, installing, queued, failed
  String? _pythonVersion; // null, '3.10', '3.11', '3.12'
  Timer? _pollTimer;

  @override
  void initState() {
    super.initState();
    _loadDependencies();
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

  @override
  void refresh() {
    _loadDependencies();
  }

  Future<void> _loadDependencies() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final authService = context.read<AuthService>();
      
      if (_filterType == 'all') {
        // Fetch all types in parallel and merge
        final results = await Future.wait([
          authService.apiService.getDependencies(type: 'nodejs'),
          authService.apiService.getDependencies(type: 'python', pythonVersion: _pythonVersion),
          authService.apiService.getDependencies(type: 'linux'),
        ]);
        
        if (mounted) {
          List<dynamic> allDeps = [];
          for (final result in results) {
            if (result['data'] is List) {
              allDeps.addAll(result['data']);
            }
          }
          setState(() {
            _dependencies = List<Map<String, dynamic>>.from(allDeps);
            _isLoading = false;
          });
        }
      } else {
        final result = await authService.apiService.getDependencies(type: _filterType, pythonVersion: _pythonVersion);
        if (mounted) {
          List<dynamic> deps = [];
          if (result['data'] is List) {
            deps = result['data'];
          }
          setState(() {
            _dependencies = List<Map<String, dynamic>>.from(deps);
            _isLoading = false;
          });
        }
      }

      _startPollIfNeeded();
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = '获取依赖失败: $e';
          _isLoading = false;
        });
      }
    }
  }

  void _startPollIfNeeded() {
    final hasInProgress = _dependencies.any((d) {
      final s = d['status'] ?? '';
      return s == 'installing' || s == 'queued' || s == 'removing';
    });

    if (hasInProgress && _pollTimer == null) {
      _pollTimer = Timer.periodic(const Duration(seconds: 3), (_) {
        _loadDependencies();
      });
    } else if (!hasInProgress && _pollTimer != null) {
      _pollTimer?.cancel();
      _pollTimer = null;
    }
  }

  List<Map<String, dynamic>> _getFilteredDeps() {
    var filtered = _dependencies;
    if (_filterType != 'all') {
      filtered = filtered.where((dep) => dep['type'] == _filterType).toList();
    }
    if (_filterStatus != 'all') {
      filtered = filtered.where((dep) => dep['status'] == _filterStatus).toList();
    }
    return filtered;
  }

  // POST /deps {type, names}
  Future<void> _installDep(String type, List<String> names) async {
    try {
      final authService = context.read<AuthService>();
      await authService.apiService.installDependency(type, names);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('已提交 ${names.length} 个依赖安装'), backgroundColor: Colors.green),
        );
        _loadDependencies();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('安装失败: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  // DELETE /deps/:id
  Future<void> _uninstallDep(int id, String name) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认卸载'),
        content: Text('确定要卸载依赖 "$name" 吗？'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('取消')),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('卸载'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final authService = context.read<AuthService>();
        await authService.apiService.uninstallDependency(id);
        _loadDependencies();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('依赖已卸载'), backgroundColor: Colors.green),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('卸载失败: $e'), backgroundColor: Colors.red),
          );
        }
      }
    }
  }

  // PUT /deps/:id/reinstall
  Future<void> _reinstallDep(int id) async {
    try {
      final authService = context.read<AuthService>();
      await authService.apiService.reinstallDependency(id);
      _loadDependencies();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('重新安装中'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('重装失败: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  // PUT /deps/:id/cancel
  Future<void> _cancelDep(int id) async {
    try {
      final authService = context.read<AuthService>();
      await authService.apiService.cancelDepOperation(id);
      _loadDependencies();
    } catch (e) {
      // ignore
    }
  }

  // GET /deps/:id/status
  Future<void> _viewDepLog(int id, String name) async {
    try {
      final authService = context.read<AuthService>();
      final result = await authService.apiService.getDepStatus(id);
      if (mounted) {
        final data = result['data'] ?? {};
        final log = data['log'] ?? '';
        final status = data['status'] ?? '';
        _showLogDialog(name, log.toString(), status.toString());
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('获取日志失败: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _showLogDialog(String name, String log, String status) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Expanded(child: Text('$name 安装日志')),
            _buildStatusChip(status),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          height: 400,
          child: SingleChildScrollView(
            child: SelectableText(
              log.isEmpty ? '暂无日志' : log,
              style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('关闭')),
        ],
      ),
    );
  }

  Widget _buildStatusChip(String status) {
    Color color;
    String text;
    switch (status) {
      case 'installed':
        color = Colors.green;
        text = '已安装';
        break;
      case 'installing':
        color = Colors.orange;
        text = '安装中';
        break;
      case 'queued':
        color = Colors.blue;
        text = '排队中';
        break;
      case 'failed':
        color = Colors.red;
        text = '失败';
        break;
      case 'removing':
        color = Colors.orange;
        text = '卸载中';
        break;
      case 'cancelled':
        color = Colors.grey;
        text = '已取消';
        break;
      default:
        color = Colors.grey;
        text = status;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color),
      ),
      child: Text(text, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.bold)),
    );
  }

  void _showInstallDialog() {
    String selectedType = 'nodejs';
    final nameController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('安装依赖'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('依赖类型', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                SegmentedButton<String>(
                  segments: const [
                    ButtonSegment(value: 'nodejs', label: Text('Node.js')),
                    ButtonSegment(value: 'python', label: Text('Python')),
                    ButtonSegment(value: 'linux', label: Text('Linux')),
                  ],
                  selected: {selectedType},
                  onSelectionChanged: (values) {
                    setDialogState(() => selectedType = values.first);
                  },
                ),
                const SizedBox(height: 16),
                const Text('依赖名称', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    hintText: '例如: axios, requests, curl',
                    border: OutlineInputBorder(),
                    helperText: '多个依赖用逗号分隔',
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 16),
                _buildPresetChips(selectedType, nameController),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('取消')),
            FilledButton.icon(
              onPressed: () {
                if (nameController.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('请输入依赖名称'), backgroundColor: Colors.red),
                  );
                  return;
                }
                Navigator.pop(context);
                final names = nameController.text.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
                _installDep(selectedType, names);
              },
              icon: const Icon(Icons.download),
              label: const Text('安装'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPresetChips(String type, TextEditingController controller) {
    List<Map<String, String>> presets;
    switch (type) {
      case 'nodejs':
        presets = [
          {'label': 'axios', 'value': 'axios'},
          {'label': 'express', 'value': 'express'},
          {'label': 'lodash', 'value': 'lodash'},
          {'label': 'moment', 'value': 'moment'},
          {'label': 'typescript', 'value': 'typescript'},
          {'label': 'pm2', 'value': 'pm2'},
        ];
        break;
      case 'python':
        presets = [
          {'label': 'requests', 'value': 'requests'},
          {'label': 'flask', 'value': 'flask'},
          {'label': 'django', 'value': 'django'},
          {'label': 'numpy', 'value': 'numpy'},
          {'label': 'pandas', 'value': 'pandas'},
          {'label': 'pillow', 'value': 'pillow'},
        ];
        break;
      case 'linux':
        presets = [
          {'label': 'curl', 'value': 'curl'},
          {'label': 'wget', 'value': 'wget'},
          {'label': 'git', 'value': 'git'},
          {'label': 'vim', 'value': 'vim'},
          {'label': 'htop', 'value': 'htop'},
          {'label': 'unzip', 'value': 'unzip'},
        ];
        break;
      default:
        presets = [];
    }

    return Wrap(
      spacing: 8,
      runSpacing: 4,
      children: presets.map((preset) => ActionChip(
        label: Text(preset['label']!, style: const TextStyle(fontSize: 12)),
        onPressed: () {
          if (controller.text.isNotEmpty) {
            controller.text += ', ';
          }
          controller.text += preset['value']!;
        },
      )).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filteredDeps = _getFilteredDeps();

    return Scaffold(
      appBar: AppBar(
        title: const Text('依赖管理'),
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
                  _buildFilterChip('Node.js', 'nodejs'),
                  const SizedBox(width: 8),
                  _buildFilterChip('Python', 'python'),
                  const SizedBox(width: 8),
                  _buildFilterChip('Linux', 'linux'),
                ],
              ),
            ),
          ),
          // Status filter chips
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildStatusFilterChip('全部', 'all'),
                  const SizedBox(width: 8),
                  _buildStatusFilterChip('已安装', 'installed'),
                  const SizedBox(width: 8),
                  _buildStatusFilterChip('安装中', 'installing'),
                  const SizedBox(width: 8),
                  _buildStatusFilterChip('安装失败', 'failed'),
                  const SizedBox(width: 8),
                  _buildStatusFilterChip('排队中', 'queued'),
                ],
              ),
            ),
          ),
          // Python version filter
          if (_filterType == 'python' || _filterType == 'all')
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Row(
                children: [
                  Icon(Icons.code, size: 16, color: Colors.blue),
                  const SizedBox(width: 8),
                  Text('Python 版本:', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                  const SizedBox(width: 8),
                  _buildPythonVersionChip('全部', null),
                  const SizedBox(width: 6),
                  _buildPythonVersionChip('3.10', '3.10'),
                  const SizedBox(width: 6),
                  _buildPythonVersionChip('3.11', '3.11'),
                  const SizedBox(width: 6),
                  _buildPythonVersionChip('3.12', '3.12'),
                ],
              ),
            ),
          // Stats
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                _buildStatCard('Node.js', _dependencies.where((d) => d['type'] == 'nodejs').length, Colors.green),
                const SizedBox(width: 8),
                _buildStatCard('Python', _dependencies.where((d) => d['type'] == 'python').length, Colors.blue),
                const SizedBox(width: 8),
                _buildStatCard('Linux', _dependencies.where((d) => d['type'] == 'linux').length, Colors.orange),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Expanded(child: _buildBody(filteredDeps)),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showInstallDialog,
        child: const Icon(Icons.add, size: 24),
      ),
    );
  }

  Widget _buildFilterChip(String label, String value) {
    final isSelected = _filterType == value;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() => _filterType = value);
        _loadDependencies();
      },
    );
  }

  Widget _buildStatusFilterChip(String label, String value) {
    final isSelected = _filterStatus == value;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      selectedColor: MiuixColors.primary.withOpacity(0.2),
      checkmarkColor: MiuixColors.primary,
      labelStyle: TextStyle(
        color: isSelected
            ? MiuixColors.primary
            : (isDark ? MiuixColors.darkOnSurface : MiuixColors.onSurface),
        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
      ),
      side: isSelected
          ? BorderSide(color: MiuixColors.primary)
          : BorderSide(color: isDark ? MiuixColors.darkDividerLine : MiuixColors.dividerLine),
      onSelected: (selected) {
        setState(() => _filterStatus = value);
      },
    );
  }

  Widget _buildPythonVersionChip(String label, String? version) {
    final isSelected = _pythonVersion == version;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return FilterChip(
      label: Text(label, style: const TextStyle(fontSize: 12)),
      selected: isSelected,
      selectedColor: Colors.blue.withOpacity(0.2),
      checkmarkColor: Colors.blue,
      labelStyle: TextStyle(
        color: isSelected
            ? Colors.blue
            : (isDark ? MiuixColors.darkOnSurface : MiuixColors.onSurface),
        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
      ),
      side: isSelected
          ? BorderSide(color: Colors.blue)
          : BorderSide(color: isDark ? MiuixColors.darkDividerLine : MiuixColors.dividerLine),
      onSelected: (selected) {
        setState(() => _pythonVersion = version);
        _loadDependencies();
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
              Text('$count', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: color)),
              Text(label, style: TextStyle(color: color)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBody(List<Map<String, dynamic>> deps) {
    if (_isLoading) {
      return const MiuixLoadingState();
    }

    if (_error != null) {
      return MiuixErrorState(
        message: _error!,
        onRetry: _loadDependencies,
      );
    }

    if (deps.isEmpty) {
      return MiuixEmptyState(
        icon: Icons.extension_off,
        title: '暂无依赖',
        action: ElevatedButton.icon(
          onPressed: _showInstallDialog,
          icon: const Icon(Icons.add),
          label: const Text('安装依赖'),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadDependencies,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: deps.length,
        itemBuilder: (context, index) => _buildDepCard(deps[index]),
      ),
    );
  }

  Widget _buildDepCard(Map<String, dynamic> dep) {
    final id = dep['id'] ?? 0;
    final name = dep['name'] ?? '未知';
    final type = dep['type'] ?? 'unknown';
    final status = dep['status'] ?? 'unknown';
    final createdAt = dep['created_at'] ?? '';

    final isInProgress = status == 'installing' || status == 'queued' || status == 'removing';

    Color typeColor;
    String typeText;
    IconData typeIcon;
    switch (type) {
      case 'nodejs':
        typeColor = Colors.green;
        typeText = 'Node.js';
        typeIcon = Icons.javascript;
        break;
      case 'python':
        typeColor = Colors.blue;
        typeText = 'Python';
        typeIcon = Icons.code;
        break;
      case 'linux':
        typeColor = Colors.orange;
        typeText = 'Linux';
        typeIcon = Icons.terminal;
        break;
      default:
        typeColor = Colors.grey;
        typeText = type;
        typeIcon = Icons.extension;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(typeIcon, color: typeColor, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    name,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                  ),
                ),
                _buildStatusChip(status),
              ],
            ),
            const SizedBox(height: 4),
            Text('类型: $typeText', style: Theme.of(context).textTheme.bodySmall),
            if (createdAt.isNotEmpty)
              Text('创建: $createdAt', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey, fontSize: 11)),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                // View log
                OutlinedButton.icon(
                  onPressed: () => _viewDepLog(id, name),
                  icon: const Icon(Icons.article, size: 16),
                  label: const Text('日志'),
                ),
                const SizedBox(width: 8),
                if (isInProgress) ...[
                  // Cancel button
                  OutlinedButton.icon(
                    onPressed: () => _cancelDep(id),
                    icon: const Icon(Icons.stop, size: 16),
                    label: const Text('取消'),
                    style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
                  ),
                  const SizedBox(width: 8),
                  // Progress indicator
                  const SizedBox(
                    width: 20, height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ] else if (status == 'installed') ...[
                  OutlinedButton.icon(
                    onPressed: () => _reinstallDep(id),
                    icon: const Icon(Icons.refresh, size: 16),
                    label: const Text('重装'),
                  ),
                  const SizedBox(width: 8),
                  FilledButton.icon(
                    onPressed: () => _uninstallDep(id, name),
                    icon: const Icon(Icons.delete, size: 16),
                    label: const Text('卸载'),
                    style: FilledButton.styleFrom(backgroundColor: Colors.red),
                  ),
                ] else if (status == 'failed' || status == 'cancelled') ...[
                  FilledButton.icon(
                    onPressed: () => _reinstallDep(id),
                    icon: const Icon(Icons.refresh, size: 16),
                    label: const Text('重试'),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}
