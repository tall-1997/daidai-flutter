import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';

class DependenciesScreen extends StatefulWidget {
  const DependenciesScreen({super.key});

  @override
  State<DependenciesScreen> createState() => _DependenciesScreenState();
}

class _DependenciesScreenState extends State<DependenciesScreen> {
  List<Map<String, dynamic>> _dependencies = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadDependencies();
  }

  Future<void> _loadDependencies() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final authService = context.read<AuthService>();
      final result = await authService.apiService.getDependencies();

      if (result['data'] != null) {
        setState(() {
          _dependencies = List<Map<String, dynamic>>.from(result['data'] ?? []);
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = result['message'] ?? '获取依赖失败';
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

  Future<void> _deleteDep(int id) async {
    try {
      final authService = context.read<AuthService>();
      await authService.apiService.uninstallDependency(id);
      _loadDependencies();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('依赖已删除')),
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

  Future<void> _reinstallDep(int id) async {
    try {
      final authService = context.read<AuthService>();
      await authService.apiService.reinstallDependency(id);
      _loadDependencies();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('重新安装中')),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('依赖管理'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadDependencies,
          ),
        ],
      ),
      body: _buildBody(),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showInstallDialog(),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Theme.of(context).colorScheme.error),
            const SizedBox(height: 16),
            Text(_error!),
            const SizedBox(height: 16),
            FilledButton(onPressed: _loadDependencies, child: const Text('重试')),
          ],
        ),
      );
    }

    if (_dependencies.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.extension, size: 64, color: Theme.of(context).colorScheme.onSurfaceVariant),
            const SizedBox(height: 16),
            const Text('暂无依赖'),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: () => _showInstallDialog(),
              icon: const Icon(Icons.add),
              label: const Text('安装依赖'),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadDependencies,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _dependencies.length,
        itemBuilder: (context, index) {
          final dep = _dependencies[index];
          return _DependencyCard(
            dep: dep,
            onDelete: () => _deleteDep(dep['id']),
            onReinstall: () => _reinstallDep(dep['id']),
          );
        },
      ),
    );
  }

  void _showInstallDialog() {
    final nameController = TextEditingController();
    String depType = 'nodejs';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('安装依赖'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  value: depType,
                  decoration: const InputDecoration(
                    labelText: '依赖类型',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'nodejs', child: Text('Node.js')),
                    DropdownMenuItem(value: 'python', child: Text('Python')),
                    DropdownMenuItem(value: 'linux', child: Text('Linux')),
                  ],
                  onChanged: (value) {
                    setDialogState(() => depType = value!);
                  },
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: '依赖名称',
                    hintText: '例如: lodash, requests',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('取消'),
            ),
            FilledButton(
              onPressed: () async {
                if (nameController.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('请填写依赖名称'), backgroundColor: Colors.red),
                  );
                  return;
                }

                try {
                  final authService = context.read<AuthService>();
                  await authService.apiService.installDependency(
                    depType,
                    [nameController.text],
                  );
                  Navigator.pop(context);
                  _loadDependencies();
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('依赖安装请求已发送')),
                    );
                  }
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('安装失败: $e'), backgroundColor: Colors.red),
                  );
                }
              },
              child: const Text('安装'),
            ),
          ],
        ),
      ),
    );
  }
}

class _DependencyCard extends StatelessWidget {
  final Map<String, dynamic> dep;
  final VoidCallback onDelete;
  final VoidCallback onReinstall;

  const _DependencyCard({
    required this.dep,
    required this.onDelete,
    required this.onReinstall,
  });

  @override
  Widget build(BuildContext context) {
    final name = dep['name'] ?? '';
    final type = dep['type'] ?? '';
    final status = dep['status'] ?? '';

    IconData typeIcon;
    switch (type) {
      case 'nodejs':
        typeIcon = Icons.javascript;
        break;
      case 'python':
        typeIcon = Icons.code;
        break;
      case 'linux':
        typeIcon = Icons.terminal;
        break;
      default:
        typeIcon = Icons.extension;
    }

    Color statusColor;
    String statusText;
    switch (status) {
      case 'installed':
        statusColor = Colors.green;
        statusText = '已安装';
        break;
      case 'installing':
        statusColor = Colors.orange;
        statusText = '安装中';
        break;
      case 'failed':
        statusColor = Colors.red;
        statusText = '失败';
        break;
      default:
        statusColor = Colors.grey;
        statusText = status;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Icon(typeIcon, color: Theme.of(context).colorScheme.primary),
        title: Text(name),
        subtitle: Text(type),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: statusColor),
              ),
              child: Text(statusText, style: TextStyle(color: statusColor, fontSize: 12)),
            ),
            PopupMenuButton(
              itemBuilder: (context) => [
                const PopupMenuItem(value: 'reinstall', child: Text('重新安装')),
                const PopupMenuItem(value: 'delete', child: Text('删除', style: TextStyle(color: Colors.red))),
              ],
              onSelected: (value) {
                if (value == 'reinstall') onReinstall();
                if (value == 'delete') onDelete();
              },
            ),
          ],
        ),
      ),
    );
  }
}
