import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../theme/miuix_theme.dart';
import '../widgets/miuix_widgets.dart';
import 'home_screen.dart';

class OpenApiScreen extends StatefulWidget {
  const OpenApiScreen({super.key});

  @override
  State<OpenApiScreen> createState() => _OpenApiScreenState();
}

class _OpenApiScreenState extends State<OpenApiScreen> with RefreshableScreen {
  List<Map<String, dynamic>> _apiKeys = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadApiKeys();
  }

  @override
  void refresh() {
    _loadApiKeys();
  }

  Future<void> _loadApiKeys() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final authService = context.read<AuthService>();
      final response = await authService.apiService.get('/api-keys');
      final result = Map<String, dynamic>.from(
        response is Map ? response : {'data': []},
      );

      if (mounted) {
        setState(() {
          _apiKeys = List<Map<String, dynamic>>.from(result['data'] ?? []);
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = '加载失败: $e';
          _isLoading = false;
        });
      }
    }
  }

  void _showCreateDialog() {
    final nameController = TextEditingController();
    final descriptionController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('创建 API Key'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: '名称',
                  border: OutlineInputBorder(),
                  hintText: '例如: 我的应用',
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: descriptionController,
                decoration: const InputDecoration(
                  labelText: '描述（可选）',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
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
                  const SnackBar(content: Text('请输入名称'), backgroundColor: Colors.red),
                );
                return;
              }

              try {
                final authService = context.read<AuthService>();
                await authService.apiService.post('/api-keys', body: {
                  'name': nameController.text,
                  if (descriptionController.text.isNotEmpty) 'description': descriptionController.text,
                });
                Navigator.pop(context);
                _loadApiKeys();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('API Key 已创建'), backgroundColor: Colors.green),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('创建失败: $e'), backgroundColor: Colors.red),
                  );
                }
              }
            },
            child: const Text('创建'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteApiKey(int id, String name) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认删除'),
        content: Text('确定要删除 API Key "$name" 吗？'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('取消')),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('删除'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final authService = context.read<AuthService>();
        await authService.apiService.delete('/api-keys/$id');
        _loadApiKeys();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('API Key 已删除'), backgroundColor: Colors.green),
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

  void _showApiKeyDetail(Map<String, dynamic> apiKey) {
    final appKey = apiKey['app_key'] ?? '';
    final appSecret = apiKey['app_secret'] ?? '';
    bool showSecret = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(apiKey['name'] ?? 'API Key'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (apiKey['description'] != null && apiKey['description'].toString().isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Text(apiKey['description']),
                  ),
                const Text('App Key:', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          appKey,
                          style: const TextStyle(fontFamily: 'monospace'),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.copy, size: 18),
                        onPressed: () {
                          // Copy to clipboard
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('已复制'), backgroundColor: Colors.green),
                          );
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                const Text('App Secret:', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          showSecret ? appSecret : '••••••••••••••••',
                          style: const TextStyle(fontFamily: 'monospace'),
                        ),
                      ),
                      IconButton(
                        icon: Icon(showSecret ? Icons.visibility_off : Icons.visibility, size: 18),
                        onPressed: () {
                          setDialogState(() => showSecret = !showSecret);
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.copy, size: 18),
                        onPressed: () {
                          // Copy to clipboard
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('已复制'), backgroundColor: Colors.green),
                          );
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                const Text('使用说明:', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                const Text(
                  '1. 在请求头中添加 X-App-Key 和 X-App-Secret\n'
                  '2. 或使用 Basic 认证: base64(app_key:app_secret)',
                  style: TextStyle(fontSize: 12),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('关闭'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('开放 API'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadApiKeys,
          ),
        ],
      ),
      body: _isLoading
          ? const MiuixLoadingState()
          : _error != null
              ? MiuixErrorState(message: _error!, onRetry: _loadApiKeys)
              : Column(
                  children: [
                    _buildApiDocCard(isDark),
                    Expanded(
                      child: _apiKeys.isEmpty
                          ? MiuixEmptyState(
                              icon: Icons.vpn_key,
                              title: '暂无 API Key',
                              action: ElevatedButton.icon(
                                onPressed: _showCreateDialog,
                                icon: const Icon(Icons.add),
                                label: const Text('创建 API Key'),
                              ),
                            )
                          : RefreshIndicator(
                              onRefresh: _loadApiKeys,
                              child: ListView.builder(
                                padding: const EdgeInsets.all(16),
                                itemCount: _apiKeys.length,
                                itemBuilder: (context, index) => _buildApiKeyCard(_apiKeys[index], isDark),
                              ),
                            ),
                    ),
                  ],
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showCreateDialog,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildApiDocCard(bool isDark) {
    return Card(
      margin: const EdgeInsets.all(16),
      color: Colors.blue.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.info_outline, color: Colors.blue.shade700),
                const SizedBox(width: 8),
                Text(
                  'API 文档',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.blue.shade700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              '使用 API Key 可以通过 HTTP 请求访问面板功能。\n'
              '支持的操作：任务管理、环境变量管理、脚本管理等。',
              style: TextStyle(color: Colors.blue.shade700),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () {
                // Open API docs
              },
              child: const Text('查看完整文档'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildApiKeyCard(Map<String, dynamic> apiKey, bool isDark) {
    final id = apiKey['id'] ?? 0;
    final name = apiKey['name'] ?? '未命名';
    final appKey = apiKey['app_key'] ?? '';
    final createdAt = apiKey['created_at'] ?? '';
    final lastUsedAt = apiKey['last_used_at'] ?? '';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => _showApiKeyDetail(apiKey),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.vpn_key, color: Colors.orange),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: isDark ? MiuixColors.darkOnSurface : MiuixColors.onSurface,
                          ),
                        ),
                        Text(
                          'Key: ${appKey.substring(0, 8)}...',
                          style: TextStyle(
                            fontSize: 12,
                            fontFamily: 'monospace',
                            color: isDark ? MiuixColors.darkOnSurfaceVariantSummary : MiuixColors.onSurfaceVariantSummary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () => _deleteApiKey(id, name),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  _buildInfoChip(Icons.access_time, '创建: $createdAt', isDark),
                  const SizedBox(width: 8),
                  if (lastUsedAt.isNotEmpty)
                    _buildInfoChip(Icons.login, '使用: $lastUsedAt', isDark),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String text, bool isDark) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: isDark ? MiuixColors.darkSurfaceContainerHighest : Colors.grey[100],
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(icon, size: 14, color: isDark ? MiuixColors.darkOnSurfaceVariantSummary : MiuixColors.onSurfaceVariantSummary),
            const SizedBox(width: 4),
            Expanded(
              child: Text(
                text,
                style: TextStyle(
                  fontSize: 11,
                  color: isDark ? MiuixColors.darkOnSurfaceVariantSummary : MiuixColors.onSurfaceVariantSummary,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
