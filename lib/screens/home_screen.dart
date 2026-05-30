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

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  bool _isSidebarExpanded = false;

  final List<_NavigationItem> _navigationItems = [
    _NavigationItem(Icons.list_alt, '任务'),
    _NavigationItem(Icons.settings_ethernet, '环境变量'),
    _NavigationItem(Icons.extension, '依赖管理'),
    _NavigationItem(Icons.code, '脚本'),
    _NavigationItem(Icons.article, '日志'),
    _NavigationItem(Icons.notifications, '通知'),
    _NavigationItem(Icons.computer, '系统'),
    _NavigationItem(Icons.tune, '设置'),
  ];

  @override
  Widget build(BuildContext context) {
    final authService = context.watch<AuthService>();
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('呆呆面板'),
        leading: IconButton(
          icon: Icon(_isSidebarExpanded ? Icons.menu_open : Icons.menu),
          onPressed: () {
            setState(() {
              _isSidebarExpanded = !_isSidebarExpanded;
            });
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              // TODO: Implement search
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              // TODO: Implement refresh
            },
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
              const PopupMenuItem(
                child: ListTile(
                  leading: const Icon(Icons.logout),
                  title: Text('退出登录'),
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
      body: Row(
        children: [
          // Sidebar
          if (_isSidebarExpanded)
            NavigationRail(
              selectedIndex: _selectedIndex,
              onDestinationSelected: (index) {
                setState(() {
                  _selectedIndex = index;
                });
              },
              labelType: NavigationRailLabelType.all,
              leading: IconButton(
                icon: const Icon(Icons.chevron_left),
                onPressed: () {
                  setState(() {
                    _isSidebarExpanded = false;
                  });
                },
              ),
              destinations: _navigationItems.map((item) {
                return NavigationRailDestination(
                  icon: Icon(item.icon),
                  label: Text(item.title),
                );
              }).toList(),
            ),
          // Main content
          Expanded(
            child: _getSelectedScreen(),
          ),
        ],
      ),
      bottomNavigationBar: _isSidebarExpanded
          ? null
          : NavigationBar(
              selectedIndex: _selectedIndex,
              onDestinationSelected: (index) {
                setState(() {
                  _selectedIndex = index;
                });
              },
              destinations: _navigationItems.map((item) {
                return NavigationDestination(
                  icon: Icon(item.icon),
                  label: item.title,
                );
              }).toList(),
            ),
    );
  }

  Widget _getSelectedScreen() {
    switch (_selectedIndex) {
      case 0:
        return const TasksScreen();
      case 1:
        return const EnvsScreen();
      case 2:
        return const DependenciesScreen();
      case 3:
        return const ScriptsScreen();
      case 4:
        return const LogsScreen();
      case 5:
        return const NotificationsScreen();
      case 6:
        return const SystemScreen();
      case 7:
        return const SettingsScreen();
      default:
        return const TasksScreen();
    }
  }
}

class _NavigationItem {
  final IconData icon;
  final String title;

  _NavigationItem(this.icon, this.title);
}
