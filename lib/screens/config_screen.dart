import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/api_service.dart';

class ConfigScreen extends StatefulWidget {
  const ConfigScreen({super.key});

  @override
  State<ConfigScreen> createState() => _ConfigScreenState();
}

class _ConfigScreenState extends State<ConfigScreen> {
  List<dynamic> _configs = [];
  List<dynamic> _platforms = [];
  List<dynamic> _platformTokens = [];
  bool _isLoading = false;
  String? _message;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() { _isLoading = true; _message = null; });
    try {
      final api = context.read<ApiService>();
      final config = await api.getConfig();
      setState(() {
        _configs = config['data'] ?? [];
        _isLoading = false;
      });
    } catch (e) {
      setState(() { _message = '加载失败: $e'; _isLoading = false; });
    }
  }

  Future<void> _updateConfig(String key, String value) async {
    try {
      final api = context.read<ApiService>();
      await api.updateConfig({key: value});
      setState(() { _message = '配置已更新'; });
      _loadData();
    } catch (e) {
      setState(() { _message = '更新失败: $e'; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('配置管理'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadData,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  if (_message != null)
                    Card(
                      color: _message!.contains('失败') ? Colors.red.shade50 : Colors.green.shade50,
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          children: [
                            Icon(
                              _message!.contains('失败') ? Icons.error_outline : Icons.check_circle_outline,
                              color: _message!.contains('失败') ? Colors.red : Colors.green,
                            ),
                            const SizedBox(width: 8),
                            Expanded(child: Text(_message!)),
                            IconButton(
                              icon: const Icon(Icons.close, size: 16),
                              onPressed: () => setState(() { _message = null; }),
                            ),
                          ],
                        ),
                      ),
                    ),
                  const SizedBox(height: 16),
                  
                  // System config section
                  _buildSectionTitle('系统配置'),
                  if (_configs.isEmpty)
                    const Card(
                      child: Padding(
                        padding: EdgeInsets.all(16),
                        child: Text('暂无配置项', style: TextStyle(color: Colors.grey)),
                      ),
                    )
                  else
                    ..._configs.map((config) => _buildConfigItem(config)),
                  
                  const SizedBox(height: 24),
                  
                  // Platform management
                  _buildSectionTitle('平台管理'),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('平台列表', style: TextStyle(fontWeight: FontWeight.w500)),
                          const SizedBox(height: 8),
                          if (_platforms.isEmpty)
                            const Text('暂无平台', style: TextStyle(color: Colors.grey))
                          else
                            ..._platforms.map((p) => ListTile(
                              title: Text(p['name'] ?? ''),
                              subtitle: Text(p['type'] ?? ''),
                              trailing: IconButton(
                                icon: const Icon(Icons.delete, color: Colors.red),
                                onPressed: () => _deletePlatform(p['id']),
                              ),
                            )),
                          const Divider(),
                          ElevatedButton.icon(
                            onPressed: _showAddPlatformDialog,
                            icon: const Icon(Icons.add),
                            label: const Text('添加平台'),
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Platform tokens
                  _buildSectionTitle('平台Token'),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Token列表', style: TextStyle(fontWeight: FontWeight.w500)),
                          const SizedBox(height: 8),
                          if (_platformTokens.isEmpty)
                            const Text('暂无Token', style: TextStyle(color: Colors.grey))
                          else
                            ..._platformTokens.map((t) => ListTile(
                              title: Text(t['name'] ?? ''),
                              subtitle: Text(t['token'] ?? ''),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Switch(
                                    value: t['enabled'] ?? true,
                                    onChanged: (v) => _toggleToken(t['id'], v),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete, color: Colors.red),
                                    onPressed: () => _deleteToken(t['id']),
                                  ),
                                ],
                              ),
                            )),
                          const Divider(),
                          ElevatedButton.icon(
                            onPressed: _showAddTokenDialog,
                            icon: const Icon(Icons.add),
                            label: const Text('添加Token'),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildConfigItem(dynamic config) {
    final key = config['key']?.toString() ?? '';
    final value = config['value']?.toString() ?? '';
    
    return Card(
      child: ListTile(
        title: Text(key),
        subtitle: Text(value, maxLines: 1, overflow: TextOverflow.ellipsis),
        trailing: IconButton(
          icon: const Icon(Icons.edit),
          onPressed: () => _showEditConfigDialog(key, value),
        ),
      ),
    );
  }

  void _showEditConfigDialog(String key, String currentValue) {
    final controller = TextEditingController(text: currentValue);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('编辑配置: $key'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: '配置值',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              _updateConfig(key, controller.text);
            },
            child: const Text('保存'),
          ),
        ],
      ),
    );
  }

  void _showAddPlatformDialog() {
    final nameController = TextEditingController();
    final typeController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('添加平台'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: '平台名称', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: typeController,
              decoration: const InputDecoration(labelText: '平台类型', border: OutlineInputBorder()),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              // TODO: Implement add platform
            },
            child: const Text('添加'),
          ),
        ],
      ),
    );
  }

  void _showAddTokenDialog() {
    final nameController = TextEditingController();
    final tokenController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('添加Token'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: 'Token名称', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: tokenController,
              decoration: const InputDecoration(labelText: 'Token值', border: OutlineInputBorder()),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              // TODO: Implement add token
            },
            child: const Text('添加'),
          ),
        ],
      ),
    );
  }

  Future<void> _deletePlatform(int id) async {
    // TODO: Implement delete platform
  }

  Future<void> _toggleToken(int id, bool enabled) async {
    // TODO: Implement toggle token
  }

  Future<void> _deleteToken(int id) async {
    // TODO: Implement delete token
  }
}
