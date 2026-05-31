import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import 'home_screen.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> with RefreshableScreen {
  List<Map<String, dynamic>> _notifications = [];
  bool _isLoading = true;
  String? _error;
  bool _hasNotificationPermission = false;

  @override
  void initState() {
    super.initState();
    _loadNotifications();
    _checkNotificationPermission();
  }

  @override
  void refresh() {
    _loadNotifications();
  }

  Future<void> _checkNotificationPermission() async {
    final status = await Permission.notification.status;
    if (mounted) {
      setState(() {
        _hasNotificationPermission = status.isGranted;
      });
    }
  }

  Future<void> _requestNotificationPermission() async {
    final status = await Permission.notification.request();
    if (mounted) {
      setState(() {
        _hasNotificationPermission = status.isGranted;
      });
      
      if (!status.isGranted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('通知权限'),
            content: const Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('通知权限被拒绝，无法接收任务执行通知。'),
                SizedBox(height: 16),
                Text('请在系统设置中手动开启：'),
                Text('1. 打开系统设置'),
                Text('2. 找到呆呆面板App'),
                Text('3. 开启通知权限'),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('知道了'),
              ),
              FilledButton(
                onPressed: () {
                  Navigator.pop(context);
                  openAppSettings();
                },
                child: const Text('打开设置'),
              ),
            ],
          ),
        );
      }
    }
  }

  Future<void> _loadNotifications() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final authService = context.read<AuthService>();
      final result = await authService.apiService.getNotifications();
      
      if (result['data'] != null) {
        setState(() {
          _notifications = List<Map<String, dynamic>>.from(result['data'] ?? []);
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = result['message'] ?? '获取通知失败';
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

  Future<void> _deleteNotification(int id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认删除'),
        content: const Text('确定要删除这个通知渠道吗？'),
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
        await authService.apiService.deleteNotification(id);
        _loadNotifications();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('通知渠道已删除')),
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

  Future<void> _testNotification(int id) async {
    try {
      final authService = context.read<AuthService>();
      await authService.apiService.testNotification(id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('测试通知已发送')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('测试失败: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('通知管理'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadNotifications,
          ),
        ],
      ),
      body: Column(
        children: [
          Card(
            margin: const EdgeInsets.all(16),
            color: _hasNotificationPermission ? Colors.green.shade50 : Colors.orange.shade50,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(
                    _hasNotificationPermission ? Icons.notifications_active : Icons.notifications_off,
                    color: _hasNotificationPermission ? Colors.green : Colors.orange,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _hasNotificationPermission ? '通知权限已开启' : '通知权限未开启',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: _hasNotificationPermission ? Colors.green.shade700 : Colors.orange.shade700,
                          ),
                        ),
                        Text(
                          _hasNotificationPermission ? '可以接收任务执行通知' : '开启后可接收任务执行通知',
                          style: TextStyle(
                            fontSize: 12,
                            color: _hasNotificationPermission ? Colors.green.shade600 : Colors.orange.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (!_hasNotificationPermission)
                    FilledButton(
                      onPressed: _requestNotificationPermission,
                      child: const Text('开启'),
                    ),
                ],
              ),
            ),
          ),
          Expanded(
            child: _buildBody(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showCreateNotificationDialog(),
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
              onPressed: _loadNotifications,
              child: const Text('重试'),
            ),
          ],
        ),
      );
    }

    if (_notifications.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.notifications,
              size: 64,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 16),
            const Text('暂无通知渠道'),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: () => _showCreateNotificationDialog(),
              icon: const Icon(Icons.add),
              label: const Text('添加通知渠道'),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadNotifications,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _notifications.length,
        itemBuilder: (context, index) {
          final notification = _notifications[index];
          return _NotificationCard(
            notification: notification,
            onDelete: () => _deleteNotification(notification['id']),
            onTest: () => _testNotification(notification['id']),
            onEdit: () => _showEditNotificationDialog(notification),
          );
        },
      ),
    );
  }

  void _showCreateNotificationDialog() {
    final nameController = TextEditingController();
    String notificationType = 'webhook';
    final webhookUrlController = TextEditingController();
    final emailController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('添加通知渠道'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: '渠道名称',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: notificationType,
                  decoration: const InputDecoration(
                    labelText: '通知类型',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'webhook', child: Text('Webhook')),
                    DropdownMenuItem(value: 'email', child: Text('邮件')),
                    DropdownMenuItem(value: 'telegram', child: Text('Telegram')),
                    DropdownMenuItem(value: 'bark', child: Text('Bark')),
                  ],
                  onChanged: (value) {
                    setDialogState(() => notificationType = value!);
                  },
                ),
                const SizedBox(height: 16),
                if (notificationType == 'webhook')
                  TextField(
                    controller: webhookUrlController,
                    decoration: const InputDecoration(
                      labelText: 'Webhook URL',
                      border: OutlineInputBorder(),
                    ),
                  ),
                if (notificationType == 'email')
                  TextField(
                    controller: emailController,
                    decoration: const InputDecoration(
                      labelText: '邮箱地址',
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
                    const SnackBar(content: Text('请填写名称'), backgroundColor: Colors.red),
                  );
                  return;
                }

                try {
                  final authService = context.read<AuthService>();
                  final config = <String, dynamic>{};
                  
                  if (notificationType == 'webhook') {
                    config['webhook_url'] = webhookUrlController.text;
                  } else if (notificationType == 'email') {
                    config['email'] = emailController.text;
                  }

                  await authService.apiService.createNotification({
                    'name': nameController.text,
                    'type': notificationType,
                    'config': config,
                  });
                  Navigator.pop(context);
                  _loadNotifications();
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
      ),
    );
  }

  void _showEditNotificationDialog(Map<String, dynamic> notification) {
    final nameController = TextEditingController(text: notification['name'] ?? '');
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('编辑通知渠道'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: '渠道名称',
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
                await authService.apiService.updateNotification(
                  notification['id'],
                  {'name': nameController.text},
                );
                Navigator.pop(context);
                _loadNotifications();
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

class _NotificationCard extends StatelessWidget {
  final Map<String, dynamic> notification;
  final VoidCallback onDelete;
  final VoidCallback onTest;
  final VoidCallback onEdit;

  const _NotificationCard({
    required this.notification,
    required this.onDelete,
    required this.onTest,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final name = notification['name'] ?? '';
    final type = notification['type'] ?? 'webhook';
    final enabled = notification['enabled'] ?? true;

    IconData typeIcon;
    String typeText;
    switch (type) {
      case 'webhook':
        typeIcon = Icons.link;
        typeText = 'Webhook';
        break;
      case 'email':
        typeIcon = Icons.email;
        typeText = '邮件';
        break;
      case 'telegram':
        typeIcon = Icons.telegram;
        typeText = 'Telegram';
        break;
      case 'bark':
        typeIcon = Icons.notifications;
        typeText = 'Bark';
        break;
      default:
        typeIcon = Icons.notifications;
        typeText = type;
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
                Icon(typeIcon, color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    name,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: enabled ? Colors.green.withOpacity(0.1) : Colors.grey.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: enabled ? Colors.green : Colors.grey),
                  ),
                  child: Text(
                    enabled ? '启用' : '禁用',
                    style: TextStyle(
                      color: enabled ? Colors.green : Colors.grey,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              '类型: $typeText',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  onPressed: onTest,
                  icon: const Icon(Icons.send, size: 18),
                  label: const Text('测试'),
                ),
                TextButton.icon(
                  onPressed: onEdit,
                  icon: const Icon(Icons.edit, size: 18),
                  label: const Text('编辑'),
                ),
                TextButton.icon(
                  onPressed: onDelete,
                  icon: const Icon(Icons.delete, size: 18, color: Colors.red),
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
