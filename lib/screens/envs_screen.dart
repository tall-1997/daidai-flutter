import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'dart:convert';
import '../services/auth_service.dart';
import '../theme/miuix_theme.dart';
import '../widgets/miuix_widgets.dart';
import 'home_screen.dart';

class EnvsScreen extends StatefulWidget {
  const EnvsScreen({super.key});

  @override
  State<EnvsScreen> createState() => _EnvsScreenState();
}

class _EnvsScreenState extends State<EnvsScreen> with RefreshableScreen {
  List<Map<String, dynamic>> _envs = [];
  bool _isLoading = true;
  String? _error;
  bool _isSelectionMode = false;
  final Set<int> _selectedEnvs = {};
  bool _isSortMode = false;
  bool _isSavingSort = false;

  @override
  void initState() {
    super.initState();
    _loadEnvs();
  }

  @override
  void refresh() {
    _loadEnvs();
  }

  void _toggleSelectionMode() {
    setState(() {
      _isSelectionMode = !_isSelectionMode;
      if (!_isSelectionMode) {
        _selectedEnvs.clear();
      }
    });
  }

  void _toggleEnvSelection(int envId) {
    setState(() {
      if (_selectedEnvs.contains(envId)) {
        _selectedEnvs.remove(envId);
      } else {
        _selectedEnvs.add(envId);
      }
    });
  }

  void _selectAllEnvs() {
    setState(() {
      _selectedEnvs.clear();
      for (var env in _envs) {
        _selectedEnvs.add(env['id']);
      }
    });
  }

  void _enterSortMode() {
    setState(() {
      _isSortMode = true;
    });
  }

  void _exitSortMode() {
    setState(() {
      _isSortMode = false;
    });
  }

  Future<void> _saveSortOrder() async {
    setState(() {
      _isSavingSort = true;
    });

    try {
      final authService = context.read<AuthService>();
      final ids = _envs.map((e) => e['id'] as int).toList();
      await authService.apiService.sortEnvs(ids);

      setState(() {
        _isSortMode = false;
        _isSavingSort = false;
      });

      _loadEnvs();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('排序已保存'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      setState(() {
        _isSavingSort = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('保存排序失败: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _batchDeleteEnvs() async {
    if (_selectedEnvs.isEmpty) return;
    
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('批量删除'),
        content: Text('确定要删除选中的 ${_selectedEnvs.length} 个环境变量吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('删除'),
          ),
        ],
      ),
    );
    
    if (confirmed != true) return;
    
    try {
      final authService = context.read<AuthService>();
      int successCount = 0;
      
      for (var envId in _selectedEnvs) {
        try {
          await authService.apiService.deleteEnv(envId);
          successCount++;
        } catch (e) {
          // 继续删除其他环境变量
        }
      }
      
      setState(() {
        _isSelectionMode = false;
        _selectedEnvs.clear();
      });
      
      _loadEnvs();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('成功删除 $successCount 个环境变量'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('批量删除失败: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _batchToggleEnvs(bool enabled) async {
    if (_selectedEnvs.isEmpty) return;
    
    try {
      final authService = context.read<AuthService>();
      int successCount = 0;
      
      for (var envId in _selectedEnvs) {
        try {
          if (enabled) {
            await authService.apiService.enableEnv(envId);
          } else {
            await authService.apiService.disableEnv(envId);
          }
          successCount++;
        } catch (e) {
          // 继续切换其他环境变量
        }
      }
      
      setState(() {
        _isSelectionMode = false;
        _selectedEnvs.clear();
      });
      
      _loadEnvs();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('成功${enabled ? "启用" : "禁用"} $successCount 个环境变量'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('批量操作失败: $e'), backgroundColor: Colors.red),
        );
      }
    }
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

  Future<void> _exportEnvs() async {
    try {
      final authService = context.read<AuthService>();
      final result = await authService.apiService.exportEnvs();
      
      if (result['code'] == 0 || result['code'] == 200 || result['success'] == true) {
        final data = result['data'] ?? result['envs'] ?? [];
        final jsonStr = const JsonEncoder.withIndent('  ').convert(data);
        
        if (mounted) {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('导出环境变量'),
              content: SingleChildScrollView(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: SelectableText(
                    jsonStr,
                    style: MiuixTextStyles.monospace,
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('关闭'),
                ),
                FilledButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    _copyToClipboard(jsonStr);
                  },
                  icon: const Icon(Icons.copy),
                  label: const Text('复制'),
                ),
              ],
            ),
          );
        }
      } else {
        throw Exception(result['message'] ?? '导出失败');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('导出失败: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _copyToClipboard(String content) {
    Clipboard.setData(ClipboardData(text: content));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('已复制到剪贴板'), backgroundColor: Colors.green),
    );
  }

  Future<void> _importEnvs() async {
    final controller = TextEditingController();
    
    final jsonStr = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('导入环境变量'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('请粘贴环境变量 JSON 数据:'),
              const SizedBox(height: 16),
              TextField(
                controller: controller,
                decoration: const InputDecoration(
                  hintText: '[{"name": "VAR_NAME", "value": "var_value", "remarks": "备注"}]',
                  border: OutlineInputBorder(),
                ),
                maxLines: 10,
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
            onPressed: () => Navigator.pop(context, controller.text),
            child: const Text('导入'),
          ),
        ],
      ),
    );
    
    if (jsonStr == null || jsonStr.isEmpty) return;
    
    try {
      final List<dynamic> data = jsonDecode(jsonStr);
      final envs = List<Map<String, dynamic>>.from(data);
      
      final authService = context.read<AuthService>();
      final result = await authService.apiService.importEnvs(envs);
      
      if (result['code'] == 0 || result['code'] == 200 || result['success'] == true) {
        _loadEnvs();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('成功导入 ${envs.length} 个环境变量'), backgroundColor: Colors.green),
          );
        }
      } else {
        throw Exception(result['message'] ?? '导入失败');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('导入失败: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _onReorder(int oldIndex, int newIndex) {
    setState(() {
      if (newIndex > oldIndex) {
        newIndex -= 1;
      }
      final item = _envs.removeAt(oldIndex);
      _envs.insert(newIndex, item);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: _isSelectionMode
          ? Text('已选择 ${_selectedEnvs.length} 项')
          : _isSortMode
            ? const Text('拖拽排序')
            : const Text('环境变量'),
        leading: _isSelectionMode || _isSortMode
          ? IconButton(
              icon: const Icon(Icons.close),
              onPressed: _isSelectionMode ? _toggleSelectionMode : _exitSortMode,
            )
          : null,
        actions: [
          if (_isSortMode) ...[
            TextButton.icon(
              onPressed: _isSavingSort ? null : _saveSortOrder,
              icon: _isSavingSort
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.save),
              label: const Text('保存排序'),
            ),
          ] else if (_isSelectionMode) ...[
            IconButton(
              icon: const Icon(Icons.select_all),
              onPressed: _selectAllEnvs,
              tooltip: '全选',
            ),
            IconButton(
              icon: const Icon(Icons.toggle_on),
              onPressed: _selectedEnvs.isNotEmpty ? () => _batchToggleEnvs(true) : null,
              tooltip: '批量启用',
            ),
            IconButton(
              icon: const Icon(Icons.toggle_off),
              onPressed: _selectedEnvs.isNotEmpty ? () => _batchToggleEnvs(false) : null,
              tooltip: '批量禁用',
            ),
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: _selectedEnvs.isNotEmpty ? _batchDeleteEnvs : null,
              tooltip: '批量删除',
            ),
          ] else ...[
            PopupMenuButton(
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'export',
                  child: ListTile(
                    leading: Icon(Icons.upload),
                    title: Text('导出备份'),
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
                const PopupMenuItem(
                  value: 'import',
                  child: ListTile(
                    leading: Icon(Icons.download),
                    title: Text('导入备份'),
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
                const PopupMenuItem(
                  value: 'sort',
                  child: ListTile(
                    leading: Icon(Icons.sort),
                    title: Text('拖拽排序'),
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ],
              onSelected: (value) {
                if (value == 'export') {
                  _exportEnvs();
                } else if (value == 'import') {
                  _importEnvs();
                } else if (value == 'sort') {
                  _enterSortMode();
                }
              },
            ),
            IconButton(
              icon: const Icon(Icons.checklist),
              onPressed: _toggleSelectionMode,
              tooltip: '批量操作',
            ),
          ],
        ],
      ),
      body: _buildBody(),
      floatingActionButton: _isSelectionMode || _isSortMode
        ? null
        : FloatingActionButton(
            onPressed: () => _showCreateEnvDialog(),
            child: const Icon(Icons.add),
          ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const MiuixLoadingState();
    }

    if (_error != null) {
      return MiuixErrorState(
        message: _error!,
        onRetry: _loadEnvs,
      );
    }

    if (_envs.isEmpty) {
      return MiuixEmptyState(
        icon: Icons.settings_ethernet,
        title: '暂无环境变量',
        action: ElevatedButton.icon(
          onPressed: () => _showCreateEnvDialog(),
          icon: const Icon(Icons.add),
          label: const Text('添加环境变量'),
        ),
      );
    }

    if (_isSortMode) {
      return ReorderableListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _envs.length,
        onReorder: _onReorder,
        itemBuilder: (context, index) {
          final env = _envs[index];
          return _EnvCard(
            key: ValueKey(env['id']),
            env: env,
            isSortMode: true,
            isSelectionMode: false,
            isSelected: false,
            onSelectionChanged: null,
            onToggle: (enabled) => _toggleEnv(env['id'], enabled),
            onDelete: () => _deleteEnv(env['id']),
            onEdit: () => _showEditEnvDialog(env),
          );
        },
      );
    }

    return RefreshIndicator(
      onRefresh: _loadEnvs,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _envs.length,
        itemBuilder: (context, index) {
          final env = _envs[index];
          final isSelected = _selectedEnvs.contains(env['id']);
          
          return _EnvCard(
            env: env,
            isSelectionMode: _isSelectionMode,
            isSelected: isSelected,
            onSelectionChanged: () => _toggleEnvSelection(env['id']),
            onToggle: (enabled) => _toggleEnv(env['id'], enabled),
            onDelete: () => _deleteEnv(env['id']),
            onEdit: () => _showEditEnvDialog(env),
            onLongPress: _enterSortMode,
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
    final nameController = TextEditingController(text: env['name'] ?? '');
    final valueController = TextEditingController(text: env['value'] ?? '');
    final remarksController = TextEditingController(text: env['remarks'] ?? '');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('编辑环境变量'),
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
              try {
                final authService = context.read<AuthService>();
                await authService.apiService.updateEnv(env['id'], {
                  'name': nameController.text,
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
  final bool isSelectionMode;
  final bool isSortMode;
  final bool isSelected;
  final VoidCallback? onSelectionChanged;
  final VoidCallback? onLongPress;
  final Function(bool) onToggle;
  final VoidCallback onDelete;
  final VoidCallback onEdit;

  const _EnvCard({
    super.key,
    required this.env,
    this.isSelectionMode = false,
    this.isSortMode = false,
    this.isSelected = false,
    this.onSelectionChanged,
    this.onLongPress,
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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: isSelectionMode ? onSelectionChanged : null,
        onLongPress: (!isSelectionMode && !isSortMode) ? onLongPress : null,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  if (isSortMode)
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: Icon(
                        Icons.drag_handle,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  if (isSelectionMode)
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: Icon(
                        isSelected ? Icons.check_circle : Icons.circle_outlined,
                        color: isSelected ? Theme.of(context).colorScheme.primary : Colors.grey,
                      ),
                    ),
                  Expanded(
                    child: Text(
                      name,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  if (!isSelectionMode && !isSortMode)
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
                  color: isDark ? MiuixColors.darkSurfaceContainerHighest : Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  value,
                  style: MiuixTextStyles.monospace.copyWith(
                    color: isDark ? MiuixColors.darkOnSurface : MiuixColors.onSurface,
                  ),
                ),
              ),
              if (remarks.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  remarks,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: isDark ? MiuixColors.darkOnSurfaceVariantSummary : Colors.grey,
                  ),
                ),
              ],
              if (!isSelectionMode && !isSortMode) ...[
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
            ],
          ),
        ),
      ),
    );
  }
}
