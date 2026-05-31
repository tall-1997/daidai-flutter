import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import 'tasks_screen.dart';
import 'envs_screen.dart';
import 'dependencies_screen.dart';
import 'scripts_screen.dart';
import 'logs_screen.dart';
import 'notifications_screen.dart';
import 'system_screen.dart';
import 'settings_screen.dart';
import 'quick_actions_screen.dart';
import 'stats_screen.dart';
import 'config_screen.dart';
import 'terminal_screen.dart';
import 'backup_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  bool _isSidebarExpanded = false;
  final GlobalKey<State<StatefulWidget>> _refreshableScreenKey = GlobalKey();

  final List<_NavigationItem> _navigationItems = [
    _NavigationItem(Icons.list_alt, '任务'),
    _NavigationItem(Icons.settings_ethernet, '环境变量'),
    _NavigationItem(Icons.extension, '依赖管理'),
    _NavigationItem(Icons.code, '脚本'),
    _NavigationItem(Icons.article, '日志'),
    _NavigationItem(Icons.notifications, '通知'),
    _NavigationItem(Icons.computer, '系统'),
    _NavigationItem(Icons.flash_on, '快捷操作'),
    _NavigationItem(Icons.bar_chart, '统计'),
    _NavigationItem(Icons.terminal, '终端'),
    _NavigationItem(Icons.backup, '备份'),
    _NavigationItem(Icons.settings, '配置'),
    _NavigationItem(Icons.tune, '设置'),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
      _isSidebarExpanded = false;
    });
  }

  void _refreshCurrentScreen() {
    final state = _refreshableScreenKey.currentState;
    if (state is RefreshableScreen) {
      (state as RefreshableScreen).refresh();
    }
  }

  @override
  Widget build(BuildContext context) {
    final authService = context.watch<AuthService>();

    return Scaffold(
      appBar: AppBar(
        title: Text(_navigationItems[_selectedIndex].title),
        leading: IconButton(
          icon: const Icon(Icons.menu),
          onPressed: () {
            setState(() {
              _isSidebarExpanded = !_isSidebarExpanded;
            });
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshCurrentScreen,
          ),
          PopupMenuButton(
            itemBuilder: (context) => [
              PopupMenuItem(
                child: ListTile(
                  leading: const Icon(Icons.person),
                  title: Text(authService.username ?? '用户'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              PopupMenuItem(
                value: 1,
                child: ListTile(
                  leading: const Icon(Icons.logout),
                  title: const Text('退出登录'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ],
            onSelected: (value) {
              if (value == 1) {
                authService.logout();
              }
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          // 主内容区域
          _getSelectedScreen(),
          // 侧边栏遮罩层
          if (_isSidebarExpanded)
            GestureDetector(
              onTap: () => setState(() => _isSidebarExpanded = false),
              child: Container(color: Colors.black38),
            ),
          // 侧边栏
          AnimatedPositioned(
            duration: const Duration(milliseconds: 200),
            left: _isSidebarExpanded ? 0 : -180,
            top: 0,
            bottom: 0,
            width: 180,
            child: Material(
              elevation: 8,
              child: Container(
                color: Theme.of(context).colorScheme.surface,
                child: Column(
                  children: [
                    // 用户信息
                    Container(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 16,
                            backgroundColor: Theme.of(context).colorScheme.primary,
                            child: Text(
                              (authService.username ?? 'U')[0].toUpperCase(),
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.onPrimary,
                                fontSize: 14,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              authService.username ?? '用户',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Divider(height: 1),
                    // 导航选项
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        itemCount: _navigationItems.length,
                        itemBuilder: (context, index) {
                          final item = _navigationItems[index];
                          final isSelected = _selectedIndex == index;

                          return InkWell(
                            onTap: () => _onItemTapped(index),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                              color: isSelected
                                  ? Theme.of(context).colorScheme.primaryContainer
                                  : null,
                              child: Row(
                                children: [
                                  Icon(
                                    item.icon,
                                    size: 20,
                                    color: isSelected
                                        ? Theme.of(context).colorScheme.primary
                                        : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      item.title,
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: isSelected
                                            ? Theme.of(context).colorScheme.primary
                                            : Theme.of(context).colorScheme.onSurface,
                                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _getSelectedScreen() {
    switch (_selectedIndex) {
      case 0:
        return TasksScreen(key: _refreshableScreenKey);
      case 1:
        return EnvsScreen(key: _refreshableScreenKey);
      case 2:
        return DependenciesScreen(key: _refreshableScreenKey);
      case 3:
        return ScriptsScreen(key: _refreshableScreenKey);
      case 4:
        return LogsScreen(key: _refreshableScreenKey);
      case 5:
        return NotificationsScreen(key: _refreshableScreenKey);
      case 6:
        return SystemScreen(key: _refreshableScreenKey);
      case 7:
        return QuickActionsScreen(key: _refreshableScreenKey);
      case 8:
        return StatsScreen(key: _refreshableScreenKey);
      case 9:
        return TerminalScreen(key: _refreshableScreenKey);
      case 10:
        return BackupScreen(key: _refreshableScreenKey);
      case 11:
        return ConfigScreen(key: _refreshableScreenKey);
      case 12:
        return SettingsScreen(key: _refreshableScreenKey);
      default:
        return TasksScreen(key: _refreshableScreenKey);
    }
  }
}

class _NavigationItem {
  final IconData icon;
  final String title;

  _NavigationItem(this.icon, this.title);
}

mixin RefreshableScreen<T extends StatefulWidget> on State<T> {
  void refresh();
}
