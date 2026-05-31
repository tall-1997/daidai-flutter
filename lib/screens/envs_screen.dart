import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';

class EnvsScreen extends StatefulWidget {
  const EnvsScreen({super.key});

  @override
  State<EnvsScreen> createState() => _EnvsScreenState();
}

class _EnvsScreenState extends State<EnvsScreen> {
  List<Map<String, dynamic>> _envs = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadEnvs();
  }

  Future<void> _loadEnvs() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final authService = context.read<AuthService>();
      final result = await authService.apiService.getEnvs();
      
      // API returns {data: [...], page: 1, page_size: 20, total: 1}
      if (result['data'] != null) {
        setState(() {
          _envs = List<Map<String, dynamic>>.from(result['data'] ?? []);
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = result['message'] ?? '获取环境变量失败';
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

  Future<void> _deleteEnv(int id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认删除'),
        content: const Text('确定要删除这个环境变量吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('删除'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final authService = context.read<AuthService>();
        await authService.apiService.deleteEnv(id);
        _loadEnvs();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('环境变量已删除')),
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
  }

  Future<void> _toggleEnv(int id, bool enabled) async {
    try {
      final authService = context.read<AuthService>();
      if (enabled) {
        await authService.apiService.enableEnv(id);
      } else {
        await authService.apiService.disableEnv(id);
      }
      _loadEnvs();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('操作失败: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('环境变量'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadEnvs,
          ),
        ],
      ),
      body: _buildBody(),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showCreateEnvDialog(),
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
            Icon(
              Icons.error_outline,
              size: 64,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(_error!),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: _loadEnvs,
              child: const Text('重试'),
            ),
          ],
        ),
      );
    }

    if (_envs.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.settings_ethernet,
              size: 64,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 16),
            const Text('暂无环境变量'),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: () => _showCreateEnvDialog(),
              icon: const Icon(Icons.add),
              label: const Text('添加环境变量'),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadEnvs,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _envs.length,
        itemBuilder: (context, index) {
          final env = _envs[index];
          return _EnvCard(
            env: env,
            onToggle: (enabled) => _toggleEnv(env['id'], enabled),
            onDelete: () => _deleteEnv(env['id']),
            onEdit: () => _showEditEnvDialog(env),
          );
        },
      ),
    );
  }

  void _showCreateEnvDialog() {
    final nameController = TextEditingController();
    final valueController = TextEditingController();
    final remarksController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('添加环境变量'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: '变量名',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: valueController,
                decoration: const InputDecoration(
                  labelText: '变量值',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: remarksController,
                decoration: const InputDecoration(
                  labelText: '备注',
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
              if (nameController.text.isEmpty || valueController.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('请填写必填项'), backgroundColor: Colors.red),
                );
                return;
              }

              try {
                final authService = context.read<AuthService>();
                await authService.apiService.createEnv({
                  'name': nameController.text,
                  'value': valueController.text,
                  'remarks': remarksController.text,
                });
                Navigator.pop(context);
                _loadEnvs();
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('创建失败: $e'), backgroundColor: Colors.red),
                );
              }
            },
            child: const Text('添加'),
          ),
        ],
      ),
    );
  }

  void _showEditEnvDialog(Map<String, dynamic> env) {
    final valueController = TextEditingController(text: env['value'] ?? '');
    final remarksController = TextEditingController(text: env['remarks'] ?? '');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('编辑环境变量: ${env['name']}'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: valueController,
                decoration: const InputDecoration(
                  labelText: '变量值',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: remarksController,
                decoration: const InputDecoration(
                  labelText: '备注',
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
              try {
                final authService = context.read<AuthService>();
                await authService.apiService.updateEnv(env['id'], {
                  'value': valueController.text,
                  'remarks': remarksController.text,
                });
                Navigator.pop(context);
                _loadEnvs();
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('更新失败: $e'), backgroundColor: Colors.red),
                );
              }
            },
            child: const Text('保存'),
          ),
        ],
      ),
    );
  }
}

class _EnvCard extends StatelessWidget {
  final Map<String, dynamic> env;
  final Function(bool) onToggle;
  final VoidCallback onDelete;
  final VoidCallback onEdit;

  const _EnvCard({
    required this.env,
    required this.onToggle,
    required this.onDelete,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final name = env['name'] ?? '';
    final value = env['value'] ?? '';
    final enabled = env['enabled'] ?? true;
    final remarks = env['remarks'] ?? '';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    name,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Switch(
                  value: enabled,
                  onChanged: onToggle,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                value,
                style: const TextStyle(fontFamily: 'monospace'),
              ),
            ),
            if (remarks.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                remarks,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.grey,
                ),
              ),
            ],
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  onPressed: onEdit,
                  icon: const Icon(Icons.edit),
                  label: const Text('编辑'),
                ),
                TextButton.icon(
                  onPressed: onDelete,
                  icon: const Icon(Icons.delete, color: Colors.red),
                  label: const Text('删除', style: TextStyle(color: Colors.red)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
