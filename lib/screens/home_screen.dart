import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../theme/miuix_theme.dart';
import 'tasks_screen.dart';
import 'envs_screen.dart';
import 'dependencies_screen.dart';
import 'scripts_screen.dart';
import 'logs_screen.dart';
import 'system_screen.dart';
import 'settings_screen.dart';
import 'config_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  bool _isSidebarExpanded = false;
  final GlobalKey<State<StatefulWidget>> _refreshableScreenKey = GlobalKey();
  String _panelVersion = '';

  final List<_NavigationItem> _navigationItems = [
    _NavigationItem(Icons.list_alt, '任务'),
    _NavigationItem(Icons.settings_ethernet, '环境变量'),
    _NavigationItem(Icons.extension, '依赖管理'),
    _NavigationItem(Icons.code, '脚本'),
    _NavigationItem(Icons.article, '日志'),
    _NavigationItem(Icons.computer, '系统'),
    _NavigationItem(Icons.settings, '配置'),
    _NavigationItem(Icons.tune, '设置'),
  ];

  @override
  void initState() {
    super.initState();
    _fetchPanelVersion();
  }

  Future<void> _fetchPanelVersion() async {
    try {
      final authService = context.read<AuthService>();
      final result = await authService.apiService.getSystemInfo();
      if (mounted && result['data'] != null) {
        final data = result['data'] as Map<String, dynamic>;
        final version = data['version'] ?? data['panel_version'] ?? '';
        if (version.isNotEmpty) {
          setState(() => _panelVersion = version);
        }
      }
    } catch (_) {
      // Fallback to default version
    }
  }

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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _navigationItems[_selectedIndex].title,
          style: MiuixTextStyles.title3.copyWith(
            fontWeight: FontWeight.w500,
            color: isDark ? MiuixColors.darkOnSurface : MiuixColors.onSurface,
          ),
        ),
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
            icon: const Icon(Icons.refresh),
            onPressed: _refreshCurrentScreen,
          ),
          PopupMenuButton(
            icon: Icon(
              Icons.more_vert,
              color: isDark ? MiuixColors.darkOnSurface : MiuixColors.onSurface,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(MiuixSpacing.cardCornerRadius),
            ),
            itemBuilder: (context) => <PopupMenuEntry<dynamic>>[
              PopupMenuItem(
                enabled: false,
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 14,
                      backgroundColor: MiuixColors.primary,
                      child: Text(
                        (authService.username ?? 'U')[0].toUpperCase(),
                        style: const TextStyle(color: Colors.white, fontSize: 12),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      authService.username ?? '用户',
                      style: MiuixTextStyles.body2.copyWith(fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
              const PopupMenuDivider(),
              PopupMenuItem(
                value: 1,
                child: Row(
                  children: [
                    Icon(Icons.logout, size: 20, color: MiuixColors.error),
                    const SizedBox(width: 8),
                    Text('退出登录', style: TextStyle(color: MiuixColors.error)),
                  ],
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
          _getSelectedScreen(),
          if (_isSidebarExpanded)
            GestureDetector(
              onTap: () => setState(() => _isSidebarExpanded = false),
              child: Container(color: MiuixColors.windowDimming),
            ),
          AnimatedPositioned(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOutCubic,
            left: _isSidebarExpanded ? 0 : -260,
            top: 0,
            bottom: 0,
            width: 260,
            child: Material(
              elevation: 0,
              child: Container(
                decoration: BoxDecoration(
                  color: isDark ? MiuixColors.darkSurfaceContainer : MiuixColors.surfaceContainer,
                  border: Border(
                    right: BorderSide(
                      color: isDark ? MiuixColors.darkDividerLine : MiuixColors.dividerLine,
                      width: 0.5,
                    ),
                  ),
                ),
                child: Column(
                  children: [
                    // User header
                    Container(
                      padding: const EdgeInsets.fromLTRB(16, 48, 16, 16),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 22,
                            backgroundColor: MiuixColors.primary,
                            child: Text(
                              (authService.username ?? 'U')[0].toUpperCase(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  authService.username ?? '用户',
                                  style: MiuixTextStyles.headline2.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '呆呆面板',
                                  style: MiuixTextStyles.footnote1.copyWith(
                                    color: isDark
                                        ? MiuixColors.darkOnSurfaceContainerVariant
                                        : MiuixColors.onSurfaceContainerVariant,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    Divider(
                      height: 1,
                      color: isDark ? MiuixColors.darkDividerLine : MiuixColors.dividerLine,
                    ),
                    // Navigation items
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        itemCount: _navigationItems.length,
                        itemBuilder: (context, index) {
                          final item = _navigationItems[index];
                          final isSelected = _selectedIndex == index;

                          return Padding(
                            padding: const EdgeInsets.only(bottom: 4),
                            child: Material(
                              color: isSelected
                                  ? (isDark
                                      ? MiuixColors.darkTertiaryContainer
                                      : MiuixColors.tertiaryContainer)
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(12),
                              child: InkWell(
                                onTap: () => _onItemTapped(index),
                                borderRadius: BorderRadius.circular(12),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                  child: Row(
                                    children: [
                                      Icon(
                                        item.icon,
                                        size: 22,
                                        color: isSelected
                                            ? (isDark
                                                ? MiuixColors.darkOnTertiaryContainer
                                                : MiuixColors.onTertiaryContainer)
                                            : (isDark
                                                ? MiuixColors.darkOnSurfaceVariantSummary
                                                : MiuixColors.onSurfaceVariantSummary),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Text(
                                          item.title,
                                          style: TextStyle(
                                            fontSize: 15,
                                            color: isSelected
                                                ? (isDark
                                                    ? MiuixColors.darkOnTertiaryContainer
                                                    : MiuixColors.onTertiaryContainer)
                                                : (isDark
                                                    ? MiuixColors.darkOnSurface
                                                    : MiuixColors.onSurface),
                                            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    // Version info
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(
                        _panelVersion.isNotEmpty ? _panelVersion :                         'v0.0.35',
                        style: MiuixTextStyles.footnote2.copyWith(
                          color: isDark
                              ? MiuixColors.darkOnSurfaceContainerVariant
                              : MiuixColors.onSurfaceContainerVariant,
                        ),
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
        return SystemScreen(key: _refreshableScreenKey);
      case 6:
        return ConfigScreen(key: _refreshableScreenKey);
      case 7:
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
