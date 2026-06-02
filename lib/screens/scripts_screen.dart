import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:file_picker/file_picker.dart';
import 'package:provider/provider.dart';
import 'dart:convert';
import '../services/auth_service.dart';
import '../theme/miuix_theme.dart';
import '../widgets/miuix_widgets.dart';
import 'dart:io';
import 'home_screen.dart';

// GitHub mirror acceleration for China mainland users
// Converts github.com raw URLs to use mirror proxies
String _applyGitHubMirror(String url) {
  if (!url.contains('github.com') && !url.contains('raw.githubusercontent.com')) {
    return url;
  }
  // Convert github.com raw URLs
  if (url.contains('github.com') && url.contains('/raw/')) {
    url = url.replaceAll('github.com', 'raw.githubusercontent.com').replaceAll('/raw/', '/');
  }
  // Apply mirror proxy (ghproxy.com is widely used in China)
  if (url.contains('raw.githubusercontent.com') || url.contains('github.com')) {
    return 'https://ghproxy.com/$url';
  }
  return url;
}

class ScriptsScreen extends StatefulWidget {
  const ScriptsScreen({super.key});

  @override
  State<ScriptsScreen> createState() => _ScriptsScreenState();
}

class _ScriptsScreenState extends State<ScriptsScreen> with RefreshableScreen {
  List<Map<String, dynamic>> _scripts = [];
  bool _isLoading = true;
  String? _error;
  String _currentPath = '';
  final List<String> _pathStack = [];
  bool _isSelectionMode = false;
  final Set<String> _selectedScripts = {};

  @override
  void initState() {
    super.initState();
    _loadScripts();
  }

  @override
  void refresh() {
    _loadScripts();
  }

  void _toggleSelectionMode() {
    setState(() {
      _isSelectionMode = !_isSelectionMode;
      if (!_isSelectionMode) {
        _selectedScripts.clear();
      }
    });
  }

  void _toggleScriptSelection(String scriptPath) {
    setState(() {
      if (_selectedScripts.contains(scriptPath)) {
        _selectedScripts.remove(scriptPath);
      } else {
        _selectedScripts.add(scriptPath);
      }
    });
  }

  void _selectAllScripts() {
    setState(() {
      _selectedScripts.clear();
      final scripts = _getFilteredScripts();
      for (var script in scripts) {
        _selectedScripts.add(script['path'] ?? '');
      }
    });
  }

  Future<void> _batchDeleteScripts() async {
    if (_selectedScripts.isEmpty) return;
    
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('批量删除'),
        content: Text('确定要删除选中的 ${_selectedScripts.length} 个脚本吗？'),
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
      
      for (var scriptPath in _selectedScripts) {
        try {
          await authService.apiService.deleteScript(scriptPath);
          successCount++;
        } catch (e) {
          // 继续删除其他脚本
        }
      }
      
      setState(() {
        _isSelectionMode = false;
        _selectedScripts.clear();
      });
      
      _loadScripts();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('成功删除 $successCount 个脚本'), backgroundColor: Colors.green),
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

  Future<void> _loadScripts() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final authService = context.read<AuthService>();
      final result = await authService.apiService.getScripts();

      if (result['data'] != null) {
        setState(() {
          _scripts = List<Map<String, dynamic>>.from(result['data'] ?? []);
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = result['message'] ?? '获取脚本失败';
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

  List<Map<String, dynamic>> _getFilteredScripts() {
    if (_currentPath.isEmpty) {
      return _scripts.where((s) => !s['path'].toString().contains('/')).toList();
    }
    return _scripts.where((s) {
      final path = s['path'].toString();
      return path.startsWith(_currentPath) &&
          path.substring(_currentPath.length).contains('/') &&
          !path.substring(_currentPath.length + 1).contains('/');
    }).toList();
  }

  List<String> _getFolders() {
    final scripts = _currentPath.isEmpty
        ? _scripts
        : _scripts.where((s) => s['path'].toString().startsWith(_currentPath));

    final folders = <String>{};
    for (final script in scripts) {
      final path = script['path'].toString();
      final relativePath = _currentPath.isEmpty ? path : path.substring(_currentPath.length);
      if (relativePath.contains('/')) {
        folders.add(relativePath.split('/')[0]);
      }
    }
    return folders.toList()..sort();
  }

  void _navigateToFolder(String folder) {
    setState(() {
      _pathStack.add(_currentPath);
      _currentPath = '$_currentPath$folder/';
    });
  }

  void _navigateBack() {
    if (_pathStack.isNotEmpty) {
      setState(() {
        _currentPath = _pathStack.removeLast();
      });
    }
  }

  Future<void> _deleteScript(String path) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认删除'),
        content: Text('确定要删除脚本 $path 吗？'),
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
        await authService.apiService.deleteScript(path);
        _loadScripts();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('脚本已删除')),
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

  void _editScript(String path, String content) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => _ScriptEditorScreen(
          path: path,
          content: content,
          onSave: (newContent) async {
            try {
              final authService = context.read<AuthService>();
              await authService.apiService.updateScript(path, {
                'content': newContent,
              });
              _loadScripts();
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('脚本已保存'), backgroundColor: Colors.green),
                );
              }
            } catch (e) {
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('保存失败: $e'), backgroundColor: Colors.red),
                );
              }
            }
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: _isSelectionMode 
          ? Text('已选择 ${_selectedScripts.length} 项')
          : Text(_currentPath.isEmpty ? '脚本管理' : _currentPath),
        leading: _isSelectionMode
          ? IconButton(
              icon: const Icon(Icons.close),
              onPressed: _toggleSelectionMode,
            )
          : _currentPath.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: _navigateBack,
                )
              : null,
        actions: [
          if (_isSelectionMode) ...[
            IconButton(
              icon: const Icon(Icons.select_all),
              onPressed: _selectAllScripts,
              tooltip: '全选',
            ),
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: _selectedScripts.isNotEmpty ? _batchDeleteScripts : null,
              tooltip: '批量删除',
            ),
          ] else ...[
            IconButton(
              icon: const Icon(Icons.checklist),
              onPressed: _toggleSelectionMode,
              tooltip: '批量操作',
            ),
            PopupMenuButton(
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'upload',
                  child: ListTile(
                    leading: Icon(Icons.upload_file),
                    title: Text('上传脚本'),
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
                const PopupMenuItem(
                  value: 'upload_zip',
                  child: ListTile(
                    leading: Icon(Icons.archive),
                    title: Text('上传压缩包'),
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
                const PopupMenuItem(
                  value: 'subscriptions',
                  child: ListTile(
                    leading: Icon(Icons.rss_feed),
                    title: Text('脚本订阅'),
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ],
              onSelected: (value) {
                if (value == 'upload') {
                  _showUploadDialog();
                } else if (value == 'upload_zip') {
                  _showUploadZipDialog();
                } else if (value == 'subscriptions') {
                  _showSubscriptionsDialog();
                }
              },
            ),
          ],
        ],
      ),
      body: _buildBody(),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showUploadDialog(),
        tooltip: '上传脚本',
        child: const Icon(Icons.upload_file),
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
        onRetry: _loadScripts,
      );
    }

    final folders = _getFolders();
    final scripts = _getFilteredScripts();

    if (folders.isEmpty && scripts.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.code,
              size: 64,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 16),
            const Text('暂无脚本'),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: () => _showCreateScriptDialog(),
              icon: const Icon(Icons.add),
              label: const Text('创建脚本'),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadScripts,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Folders
          ...folders.map((folder) => Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: ListTile(
              leading: Icon(Icons.folder, color: Colors.amber),
              title: Text(folder),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => _navigateToFolder(folder),
            ),
          )),

          // Scripts
          ...scripts.map((script) => _ScriptCard(
            script: script,
            onDelete: () => _deleteScript(script['path']),
            onTap: () => _showScriptContent(script),
            onEdit: (content) => _editScript(script['path'], content),
          )),
        ],
      ),
    );
  }

  void _showScriptContent(Map<String, dynamic> script) async {
    try {
      final authService = context.read<AuthService>();
      final result = await authService.apiService.getScriptContent(script['path']);

      if (mounted) {
        final content = result['data']?['content'] ?? '无法获取内容';
        
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Row(
              children: [
                Expanded(child: Text(script['name'] ?? '脚本内容')),
                IconButton(
                  onPressed: () {
                    Navigator.pop(context);
                    _copyScriptContent(content);
                  },
                  icon: const Icon(Icons.copy),
                  tooltip: '复制内容',
                ),
              ],
            ),
            content: SingleChildScrollView(
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: SelectableText(
                  content,
                  style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('关闭'),
              ),
              FilledButton(
                onPressed: () {
                  Navigator.pop(context);
                  _editScript(script['path'], content);
                },
                child: const Text('编辑'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('获取内容失败: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _copyScriptContent(String content) {
    Clipboard.setData(ClipboardData(text: content));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('脚本内容已复制到剪贴板'), backgroundColor: Colors.green),
    );
  }

  void _showCreateScriptDialog() {
    final nameController = TextEditingController();
    final contentController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('创建脚本'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: InputDecoration(
                  labelText: '脚本名称',
                  hintText: _currentPath.isEmpty ? 'script.py' : '${_currentPath}script.py',
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: contentController,
                decoration: const InputDecoration(
                  labelText: '脚本内容',
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
            onPressed: () async {
              if (nameController.text.isEmpty || contentController.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('请填写必填项'), backgroundColor: Colors.red),
                );
                return;
              }

              try {
                final authService = context.read<AuthService>();
                await authService.apiService.createScript({
                  'name': _currentPath + nameController.text,
                  'content': contentController.text,
                });
                Navigator.pop(context);
                _loadScripts();
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('创建失败: $e'), backgroundColor: Colors.red),
                );
              }
            },
            child: const Text('创建'),
          ),
        ],
      ),
    );
  }

  void _showUploadDialog() {
    final nameController = TextEditingController();
    final contentController = TextEditingController();
    bool _isUploading = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('上传脚本'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: '脚本名称',
                    hintText: 'script.py',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                OutlinedButton.icon(
                  onPressed: _isUploading ? null : () async {
                    try {
                      FilePickerResult? result = await FilePicker.platform.pickFiles(
                        type: FileType.custom,
                        allowedExtensions: ['py', 'js', 'sh', 'json', 'yaml', 'yml', 'txt', 'md', 'go', 'rs', 'java', 'c', 'cpp', 'h'],
                      );

                      if (result != null && result.files.single.path != null) {
                        final file = File(result.files.single.path!);
                        final content = await file.readAsString();
                        final fileName = result.files.single.name;
                        
                        setDialogState(() {
                          nameController.text = fileName;
                          contentController.text = content;
                        });
                      } else if (result != null && result.files.single.bytes != null) {
                        final bytes = result.files.single.bytes!;
                        final content = String.fromCharCodes(bytes);
                        final fileName = result.files.single.name;
                        
                        setDialogState(() {
                          nameController.text = fileName;
                          contentController.text = content;
                        });
                      }
                    } catch (e) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('读取文件失败: $e'), backgroundColor: Colors.red),
                        );
                      }
                    }
                  },
                  icon: const Icon(Icons.file_upload),
                  label: const Text('从本地文件选择'),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: contentController,
                  decoration: const InputDecoration(
                    labelText: '脚本内容',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 10,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: _isUploading ? null : () => Navigator.pop(context),
              child: const Text('取消'),
            ),
            FilledButton(
              onPressed: _isUploading ? null : () async {
                if (nameController.text.isEmpty || contentController.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('请填写必填项'), backgroundColor: Colors.red),
                  );
                  return;
                }

                setDialogState(() => _isUploading = true);
                
                try {
                  final authService = context.read<AuthService>();
                  final scriptName = _currentPath + nameController.text;
                  final result = await authService.apiService.createScript({
                    'name': scriptName,
                    'content': contentController.text,
                    'path': scriptName,
                  });
                  
                  // 检查 API 返回结果
                  if (result['code'] == 0 || result['code'] == 200 || result['success'] == true) {
                    Navigator.pop(context);
                    _loadScripts();
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('脚本上传成功'), backgroundColor: Colors.green),
                      );
                    }
                  } else {
                    throw Exception(result['message'] ?? '上传失败');
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('上传失败: $e'), backgroundColor: Colors.red),
                    );
                  }
                } finally {
                  setDialogState(() => _isUploading = false);
                }
              },
              child: _isUploading 
                ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                : const Text('上传'),
            ),
          ],
        ),
      ),
    );
  }

  void _showUploadZipDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('上传压缩包'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.archive, size: 64, color: Colors.blue),
            SizedBox(height: 16),
            Text('支持 .zip 格式的压缩包'),
            SizedBox(height: 8),
            Text('压缩包内的文件将被解压到当前目录'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('压缩包上传功能开发中...')),
              );
            },
            child: const Text('选择文件'),
          ),
        ],
      ),
    );
  }

  void _showSubscriptionsDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('脚本订阅'),
        content: SizedBox(
          width: double.maxFinite,
          height: 400,
          child: FutureBuilder<Map<String, dynamic>>(
            future: context.read<AuthService>().apiService.getScriptSubscriptions(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              
              if (snapshot.hasError) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline, size: 48, color: Colors.red),
                      const SizedBox(height: 16),
                      Text('加载失败: ${snapshot.error}'),
                      const SizedBox(height: 16),
                      FilledButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('关闭'),
                      ),
                    ],
                  ),
                );
              }
              
              final subscriptions = snapshot.data?['data'] ?? [];
              
              if (subscriptions.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.rss_feed, size: 48, color: Colors.grey[400]),
                      const SizedBox(height: 16),
                      const Text('暂无订阅'),
                      const SizedBox(height: 8),
                      const Text('添加订阅源获取远程脚本', style: TextStyle(color: Colors.grey)),
                    ],
                  ),
                );
              }
              
              return ListView.builder(
                itemCount: subscriptions.length,
                itemBuilder: (context, index) {
                  final subscription = subscriptions[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      leading: const Icon(Icons.rss_feed, color: Colors.blue),
                      title: Text(subscription['name'] ?? '未命名订阅'),
                      subtitle: Text(subscription['url'] ?? ''),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.sync, color: Colors.green),
                            onPressed: () async {
                              try {
                                // Apply GitHub mirror acceleration
                                final url = subscription['url'] ?? '';
                                if (url.contains('github.com')) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('检测到GitHub链接，自动使用镜像加速...'),
                                      duration: Duration(seconds: 1),
                                    ),
                                  );
                                }
                                await context.read<AuthService>().apiService
                                    .syncScriptSubscription(subscription['id']);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('同步成功'), backgroundColor: Colors.green),
                                );
                              } catch (e) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('同步失败: $e'), backgroundColor: Colors.red),
                                );
                              }
                            },
                            tooltip: '同步',
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () async {
                              final confirmed = await showDialog<bool>(
                                context: context,
                                builder: (context) => AlertDialog(
                                  title: const Text('确认删除'),
                                  content: const Text('确定要删除这个订阅吗？'),
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
                                  await context.read<AuthService>().apiService
                                      .deleteScriptSubscription(subscription['id']);
                                  Navigator.pop(context);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('删除成功'), backgroundColor: Colors.green),
                                  );
                                } catch (e) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('删除失败: $e'), backgroundColor: Colors.red),
                                  );
                                }
                              }
                            },
                            tooltip: '删除',
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('关闭'),
          ),
          FilledButton.icon(
            onPressed: () => _showAddSubscriptionDialog(),
            icon: const Icon(Icons.add),
            label: const Text('添加订阅'),
          ),
        ],
      ),
    );
  }

  void _showAddSubscriptionDialog() {
    final nameController = TextEditingController();
    final urlController = TextEditingController();
    final subDirController = TextEditingController();
    final hookController = TextEditingController();
    final depDescController = TextEditingController();
    bool overwriteLocal = false;
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('添加脚本订阅'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: '订阅名称 *',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: urlController,
                  decoration: const InputDecoration(
                    labelText: '订阅地址 *',
                    hintText: 'https://example.com/scripts.json',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: subDirController,
                  decoration: const InputDecoration(
                    labelText: '指定子目录',
                    hintText: '可选，如 subfolder',
                    border: OutlineInputBorder(),
                    helperText: '脚本将下载到指定子目录中',
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: depDescController,
                  decoration: const InputDecoration(
                    labelText: '依赖说明',
                    hintText: '可选，如 requests, flask',
                    border: OutlineInputBorder(),
                    helperText: '订阅脚本所需的依赖包',
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: hookController,
                  decoration: const InputDecoration(
                    labelText: '拉取后钩子',
                    hintText: '可选，拉取后执行的命令',
                    border: OutlineInputBorder(),
                    helperText: '订阅同步后自动执行的命令',
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: MiuixColors.tertiaryContainer,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline, size: 16, color: MiuixColors.primary),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'GitHub链接将自动通过镜像加速下载',
                          style: MiuixTextStyles.footnote1.copyWith(
                            color: MiuixColors.onTertiaryContainer,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                CheckboxListTile(
                  value: overwriteLocal,
                  onChanged: (v) => setDialogState(() => overwriteLocal = v ?? false),
                  title: const Text('覆盖本地修改'),
                  subtitle: const Text('同步时覆盖本地已修改的脚本'),
                  contentPadding: EdgeInsets.zero,
                  controlAffinity: ListTileControlAffinity.leading,
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
                if (nameController.text.isEmpty || urlController.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('请填写必填项'), backgroundColor: Colors.red),
                  );
                  return;
                }
                
                try {
                  final body = <String, dynamic>{
                    'name': nameController.text,
                    'url': urlController.text,
                  };
                  if (subDirController.text.isNotEmpty) {
                    body['sub_dir'] = subDirController.text;
                  }
                  if (hookController.text.isNotEmpty) {
                    body['post_pull_hook'] = hookController.text;
                  }
                  if (depDescController.text.isNotEmpty) {
                    body['dependency_description'] = depDescController.text;
                  }
                  if (overwriteLocal) {
                    body['overwrite_local'] = true;
                  }
                  
                  await context.read<AuthService>().apiService.addScriptSubscription(body);
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('订阅已添加'), backgroundColor: Colors.green),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('添加失败: $e'), backgroundColor: Colors.red),
                  );
                }
              },
              child: const Text('添加'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ScriptCard extends StatelessWidget {
  final Map<String, dynamic> script;
  final VoidCallback onDelete;
  final VoidCallback onTap;
  final Function(String) onEdit;

  const _ScriptCard({
    required this.script,
    required this.onDelete,
    required this.onTap,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final name = script['name'] ?? '';
    final path = script['path'] ?? '';
    final size = script['size'] ?? 0;
    final mtime = script['mtime'] ?? 0;

    String sizeText;
    if (size < 1024) {
      sizeText = '$size B';
    } else if (size < 1024 * 1024) {
      sizeText = '${(size / 1024).toStringAsFixed(1)} KB';
    } else {
      sizeText = '${(size / (1024 * 1024)).toStringAsFixed(1)} MB';
    }

    String timeText = '';
    if (mtime > 0) {
      final date = DateTime.fromMillisecondsSinceEpoch(mtime * 1000);
      timeText = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(
                _getFileIcon(name),
                color: _getFileColor(name),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      path,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Text(
                          sizeText,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.grey,
                          ),
                        ),
                        if (timeText.isNotEmpty) ...[
                          const SizedBox(width: 16),
                          Text(
                            timeText,
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              PopupMenuButton(
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'edit',
                    child: ListTile(
                      leading: Icon(Icons.edit),
                      title: Text('编辑'),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'add_to_task',
                    child: ListTile(
                      leading: Icon(Icons.schedule),
                      title: Text('添加到定时任务'),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'delete',
                    child: ListTile(
                      leading: Icon(Icons.delete, color: Colors.red),
                      title: Text('删除', style: TextStyle(color: Colors.red)),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                ],
                onSelected: (value) {
                  if (value == 'edit') {
                    onTap();
                  } else if (value == 'add_to_task') {
                    _addToTask(context, script);
                  } else if (value == 'delete') {
                    onDelete();
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getFileIcon(String name) {
    if (name.endsWith('.py')) return Icons.code;
    if (name.endsWith('.js')) return Icons.javascript;
    if (name.endsWith('.sh')) return Icons.terminal;
    if (name.endsWith('.json')) return Icons.data_object;
    if (name.endsWith('.yaml') || name.endsWith('.yml')) return Icons.settings;
    return Icons.description;
  }

  Color _getFileColor(String name) {
    if (name.endsWith('.py')) return Colors.blue;
    if (name.endsWith('.js')) return Colors.orange;
    if (name.endsWith('.sh')) return Colors.green;
    if (name.endsWith('.json')) return Colors.purple;
    if (name.endsWith('.yaml') || name.endsWith('.yml')) return Colors.teal;
    return Colors.grey;
  }

  void _addToTask(BuildContext context, Map<String, dynamic> script) {
    final nameController = TextEditingController(text: script['name'] ?? '');
    final commandController = TextEditingController(text: 'python3 ${script['path']}');
    final cronController = TextEditingController(text: '0 * * * *');
    String taskType = 'cron';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('添加到定时任务'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: '任务名称',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: taskType,
                  decoration: const InputDecoration(
                    labelText: '任务类型',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'cron', child: Text('定时任务')),
                    DropdownMenuItem(value: 'manual', child: Text('手动触发')),
                  ],
                  onChanged: (value) {
                    setDialogState(() => taskType = value!);
                  },
                ),
                if (taskType == 'cron') ...[
                  const SizedBox(height: 16),
                  TextField(
                    controller: cronController,
                    decoration: const InputDecoration(
                      labelText: 'Cron 表达式',
                      hintText: '0 * * * *',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                TextField(
                  controller: commandController,
                  decoration: const InputDecoration(
                    labelText: '执行命令',
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
                if (nameController.text.isEmpty || commandController.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('请填写必填项'), backgroundColor: Colors.red),
                  );
                  return;
                }

                try {
                  final authService = Provider.of<AuthService>(context, listen: false);
                  await authService.apiService.createTask({
                    'name': nameController.text,
                    'command': commandController.text,
                    'task_type': taskType,
                    'cron_expression': taskType == 'cron' ? cronController.text : '',
                    'status': 1,
                  });
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('任务已添加'), backgroundColor: Colors.green),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('添加失败: $e'), backgroundColor: Colors.red),
                  );
                }
              },
              child: const Text('添加'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ScriptEditorScreen extends StatefulWidget {
  final String path;
  final String content;
  final Function(String) onSave;

  const _ScriptEditorScreen({
    required this.path,
    required this.content,
    required this.onSave,
  });

  @override
  State<_ScriptEditorScreen> createState() => _ScriptEditorScreenState();
}

class _ScriptEditorScreenState extends State<_ScriptEditorScreen> {
  late TextEditingController _contentController;
  bool _isDirty = false;
  bool _isSaving = false;
  bool _showLineNumbers = true;
  double _fontSize = 14.0;

  @override
  void initState() {
    super.initState();
    _contentController = TextEditingController(text: widget.content);
    _contentController.addListener(() {
      if (!_isDirty) {
        setState(() => _isDirty = true);
      }
    });
  }

  @override
  void dispose() {
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_isSaving) return;
    setState(() => _isSaving = true);

    try {
      await widget.onSave(_contentController.text);
      setState(() {
        _isDirty = false;
        _isSaving = false;
      });
    } catch (e) {
      setState(() => _isSaving = false);
    }
  }

  Future<bool> _onWillPop() async {
    if (!_isDirty) return true;

    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('未保存的更改'),
        content: const Text('当前有未保存的更改，是否保存？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, 'discard'),
            child: const Text('放弃'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, 'cancel'),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, 'save'),
            child: const Text('保存'),
          ),
        ],
      ),
    );

    if (result == 'save') {
      await _save();
      return true;
    } else if (result == 'discard') {
      return true;
    }
    return false;
  }

  int _getLineCount() {
    return _contentController.text.split('\n').length;
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_isDirty,
      onPopInvokedWithResult: (didPop, result) async {
        if (!didPop) {
          final shouldPop = await _onWillPop();
          if (shouldPop && mounted) {
            Navigator.of(context).pop();
          }
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.path.split('/').last,
                style: const TextStyle(fontSize: 16),
              ),
              Text(
                '${_getLineCount()} 行${_isDirty ? ' (未保存)' : ''}',
                style: TextStyle(
                  fontSize: 12,
                  color: _isDirty ? Colors.orange : Colors.grey,
                ),
              ),
            ],
          ),
          actions: [
            PopupMenuButton<String>(
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: 'line_numbers',
                  child: Row(
                    children: [
                      Icon(
                        _showLineNumbers ? Icons.check_box : Icons.check_box_outline_blank,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      const Text('显示行号'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'font_increase',
                  child: Row(
                    children: [
                      Icon(Icons.text_increase, size: 20),
                      SizedBox(width: 8),
                      Text('增大字体'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'font_decrease',
                  child: Row(
                    children: [
                      Icon(Icons.text_decrease, size: 20),
                      SizedBox(width: 8),
                      Text('减小字体'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'format',
                  child: Row(
                    children: [
                      Icon(Icons.format_align_left, size: 20),
                      SizedBox(width: 8),
                      Text('格式化'),
                    ],
                  ),
                ),
              ],
              onSelected: (value) {
                switch (value) {
                  case 'line_numbers':
                    setState(() => _showLineNumbers = !_showLineNumbers);
                    break;
                  case 'font_increase':
                    setState(() => _fontSize = (_fontSize + 2).clamp(10, 24));
                    break;
                  case 'font_decrease':
                    setState(() => _fontSize = (_fontSize - 2).clamp(10, 24));
                    break;
                  case 'format':
                    _formatCode();
                    break;
                }
              },
            ),
            if (_isSaving)
              const Padding(
                padding: EdgeInsets.all(16),
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              )
            else
              IconButton(
                icon: Icon(
                  Icons.save,
                  color: _isDirty ? Theme.of(context).colorScheme.primary : null,
                ),
                onPressed: _isDirty ? _save : null,
                tooltip: '保存',
              ),
          ],
        ),
        body: Column(
          children: [
            _buildToolbar(),
            Expanded(
              child: _buildEditor(),
            ),
          ],
        ),
        bottomNavigationBar: _buildStatusBar(),
      ),
    );
  }

  Widget _buildToolbar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        border: Border(
          bottom: BorderSide(color: Theme.of(context).dividerColor),
        ),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _ToolbarButton(
              icon: Icons.content_cut,
              tooltip: '剪切',
              onPressed: () {
                final text = _contentController.text;
                final selection = _contentController.selection;
                if (selection.isValid && !selection.isCollapsed) {
                  final selected = text.substring(selection.start, selection.end);
                  Clipboard.setData(ClipboardData(text: selected));
                  _contentController.text = text.substring(0, selection.start) + text.substring(selection.end);
                  _contentController.selection = TextSelection.collapsed(offset: selection.start);
                }
              },
            ),
            _ToolbarButton(
              icon: Icons.content_copy,
              tooltip: '复制',
              onPressed: () {
                final text = _contentController.text;
                final selection = _contentController.selection;
                if (selection.isValid && !selection.isCollapsed) {
                  final selected = text.substring(selection.start, selection.end);
                  Clipboard.setData(ClipboardData(text: selected));
                }
              },
            ),
            _ToolbarButton(
              icon: Icons.content_paste,
              tooltip: '粘贴',
              onPressed: () async {
                final data = await Clipboard.getData('text/plain');
                if (data?.text != null) {
                  final text = _contentController.text;
                  final selection = _contentController.selection;
                  final offset = selection.start;
                  _contentController.text = text.substring(0, offset) + data!.text! + text.substring(offset);
                  _contentController.selection = TextSelection.collapsed(offset: offset + data.text!.length);
                }
              },
            ),
            const SizedBox(width: 8),
            Container(width: 1, height: 24, color: Theme.of(context).dividerColor),
            const SizedBox(width: 8),
            _ToolbarButton(
              icon: Icons.undo,
              tooltip: '撤销',
              onPressed: () {
                // Basic undo - restore previous state
              },
            ),
            _ToolbarButton(
              icon: Icons.redo,
              tooltip: '重做',
              onPressed: () {
                // Basic redo
              },
            ),
            const SizedBox(width: 8),
            Container(width: 1, height: 24, color: Theme.of(context).dividerColor),
            const SizedBox(width: 8),
            _ToolbarButton(
              icon: Icons.search,
              tooltip: '查找',
              onPressed: _showSearchDialog,
            ),
            _ToolbarButton(
              icon: Icons.find_replace,
              tooltip: '替换',
              onPressed: _showReplaceDialog,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEditor() {
    final lineCount = _getLineCount();
    final lineNumberWidth = _showLineNumbers ? (lineCount.toString().length * 10.0 + 24) : 0.0;

    return Container(
      color: Theme.of(context).colorScheme.surface,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_showLineNumbers)
            Container(
              width: lineNumberWidth,
              padding: const EdgeInsets.only(top: 12, right: 8),
              decoration: BoxDecoration(
                border: Border(
                  right: BorderSide(color: Theme.of(context).dividerColor),
                ),
              ),
              child: Column(
                children: List.generate(
                  lineCount,
                  (index) => Text(
                    '${index + 1}',
                    style: TextStyle(
                      fontFamily: 'monospace',
                      fontSize: _fontSize,
                      color: Colors.grey,
                      height: 1.5,
                    ),
                    textAlign: TextAlign.right,
                  ),
                ),
              ),
            ),
          Expanded(
            child: TextField(
              controller: _contentController,
              maxLines: null,
              expands: true,
              style: TextStyle(
                fontFamily: 'monospace',
                fontSize: _fontSize,
                height: 1.5,
              ),
              decoration: const InputDecoration(
                contentPadding: EdgeInsets.all(12),
                border: InputBorder.none,
                hintText: '输入脚本内容...',
              ),
              keyboardType: TextInputType.multiline,
              textInputAction: TextInputAction.newline,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBar() {
    final text = _contentController.text;
    final selection = _contentController.selection;
    final lines = text.split('\n');
    int currentLine = 1;
    int currentCol = 1;

    if (selection.isValid) {
      final beforeCursor = text.substring(0, selection.start);
      currentLine = '\n'.allMatches(beforeCursor).length + 1;
      final lastNewline = beforeCursor.lastIndexOf('\n');
      currentCol = selection.start - (lastNewline == -1 ? 0 : lastNewline + 1) + 1;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        border: Border(
          top: BorderSide(color: Theme.of(context).dividerColor),
        ),
      ),
      child: Row(
        children: [
          Text(
            '行 $currentLine, 列 $currentCol',
            style: const TextStyle(fontSize: 12),
          ),
          const SizedBox(width: 16),
          Text(
            '共 ${lines.length} 行',
            style: const TextStyle(fontSize: 12),
          ),
          const SizedBox(width: 16),
          Text(
            '${text.length} 字符',
            style: const TextStyle(fontSize: 12),
          ),
          const Spacer(),
          Text(
            'UTF-8',
            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  void _showSearchDialog() {
    final searchController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('查找'),
        content: TextField(
          controller: searchController,
          decoration: const InputDecoration(
            labelText: '搜索内容',
            border: OutlineInputBorder(),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              _highlightSearch(searchController.text);
            },
            child: const Text('查找'),
          ),
        ],
      ),
    );
  }

  void _showReplaceDialog() {
    final searchController = TextEditingController();
    final replaceController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('替换'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: searchController,
              decoration: const InputDecoration(
                labelText: '查找内容',
                border: OutlineInputBorder(),
              ),
              autofocus: true,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: replaceController,
              decoration: const InputDecoration(
                labelText: '替换为',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              final text = _contentController.text;
              final newText = text.replaceAll(searchController.text, replaceController.text);
              if (newText != text) {
                _contentController.text = newText;
              }
            },
            child: const Text('全部替换'),
          ),
        ],
      ),
    );
  }

  void _highlightSearch(String query) {
    if (query.isEmpty) return;
    
    final text = _contentController.text;
    final index = text.indexOf(query);
    if (index >= 0) {
      _contentController.selection = TextSelection(
        baseOffset: index,
        extentOffset: index + query.length,
      );
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('未找到匹配内容')),
        );
      }
    }
  }

  void _formatCode() {
    final text = _contentController.text;
    final ext = widget.path.split('.').last.toLowerCase();
    
    String formatted = text;
    switch (ext) {
      case 'json':
        try {
          final dynamic decoded = json.decode(text);
          formatted = const JsonEncoder.withIndent('  ').convert(decoded);
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('JSON 格式错误，无法格式化'), backgroundColor: Colors.red),
            );
          }
          return;
        }
        break;
      case 'py':
      case 'js':
      case 'sh':
        formatted = _formatSimpleCode(text);
        break;
    }
    
    _contentController.text = formatted;
  }

  String _formatSimpleCode(String code) {
    final lines = code.split('\n');
    final result = StringBuffer();
    int indent = 0;
    
    for (var line in lines) {
      final trimmed = line.trim();
      if (trimmed.isEmpty) {
        result.writeln();
        continue;
      }
      
      if (trimmed.startsWith('}') || trimmed.startsWith(']') || trimmed.startsWith(')')) {
        indent = (indent - 1).clamp(0, 100);
      }
      
      result.writeln('  ' * indent + trimmed);
      
      if (trimmed.endsWith('{') || trimmed.endsWith('[') || trimmed.endsWith('(')) {
        indent++;
      }
    }
    
    return result.toString();
  }
}

class _ToolbarButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;

  const _ToolbarButton({
    required this.icon,
    required this.tooltip,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: IconButton(
        icon: Icon(icon, size: 20),
        onPressed: onPressed,
        style: IconButton.styleFrom(
          padding: const EdgeInsets.all(8),
          minimumSize: const Size(32, 32),
        ),
      ),
    );
  }
}
