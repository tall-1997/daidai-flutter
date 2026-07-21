import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/theme_provider.dart';
import 'app_background.dart';

class MainScaffold extends ConsumerStatefulWidget {
  final Widget child;

  const MainScaffold({super.key, required this.child});

  @override
  ConsumerState<MainScaffold> createState() => _MainScaffoldState();
}

class _MainScaffoldState extends ConsumerState<MainScaffold> {
  DateTime? _lastExitAttemptAt;

  int _currentIndex(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;
    if (location.startsWith('/dashboard')) return 0;
    if (location.startsWith('/tasks')) return 1;
    if (location.startsWith('/logs')) return 2;
    if (location.startsWith('/envs')) return 3;
    if (location.startsWith('/more')) return 4;
    return 0;
  }

  Future<void> _handleBackPress(bool didPop) async {
    if (didPop) return;
    final now = DateTime.now();
    if (_lastExitAttemptAt == null ||
        now.difference(_lastExitAttemptAt!) > const Duration(seconds: 5)) {
      _lastExitAttemptAt = now;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text('5秒内再按一次返回键退出应用'),
            duration: Duration(seconds: 5),
          ),
        );
      return;
    }
    await SystemNavigator.pop();
  }

  void _onTabSelected(int index) {
    switch (index) {
      case 0:
        context.go('/dashboard');
        break;
      case 1:
        context.go('/tasks');
        break;
      case 2:
        context.go('/logs');
        break;
      case 3:
        context.go('/envs');
        break;
      case 4:
        context.go('/more');
        break;
    }
  }

  Widget _buildGlassBottomBar(int idx) {
    return GlassTabBar.bottom(
      selectedIndex: idx,
      onTabSelected: _onTabSelected,
      iconSize: 22,
      labelFontSize: 10,
      barHeight: 58,
      horizontalPadding: 16,
      verticalPadding: 10,
      magnification: 1.05,
      tabs: const [
        GlassTab(
          icon: Icon(Icons.space_dashboard_outlined),
          activeIcon: Icon(Icons.space_dashboard),
          label: '主页',
        ),
        GlassTab(
          icon: Icon(Icons.schedule_outlined),
          activeIcon: Icon(Icons.schedule),
          label: '任务',
        ),
        GlassTab(
          icon: Icon(Icons.terminal_outlined),
          activeIcon: Icon(Icons.terminal),
          label: '日志',
        ),
        GlassTab(
          icon: Icon(Icons.key_outlined),
          activeIcon: Icon(Icons.key),
          label: '变量',
        ),
        GlassTab(
          icon: Icon(Icons.menu_outlined),
          activeIcon: Icon(Icons.menu),
          label: '更多',
        ),
      ],
    );
  }

  Widget _buildClassicBottomBar(int idx, bool isLight) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10, left: 12, right: 12),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 40, sigmaY: 40),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: isLight
                    ? [
                        Colors.white.withAlpha(180),
                        Colors.white.withAlpha(120),
                      ]
                    : [
                        AppColors.slate800.withAlpha(160),
                        AppColors.slate900.withAlpha(120),
                      ],
              ),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: isLight
                    ? Colors.white.withAlpha(200)
                    : Colors.white.withAlpha(20),
                width: 0.5,
              ),
            ),
            child: SafeArea(
              top: false,
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                child: Row(
                  children: _navItems(idx, isLight),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _navItems(int idx, bool isLight) {
    final items = [
      (Icons.space_dashboard_outlined, Icons.space_dashboard, '主页'),
      (Icons.schedule_outlined, Icons.schedule, '任务'),
      (Icons.terminal_outlined, Icons.terminal, '日志'),
      (Icons.key_outlined, Icons.key, '变量'),
      (Icons.menu_outlined, Icons.menu, '更多'),
    ];

    return List.generate(items.length, (i) {
      final (icon, activeIcon, label) = items[i];
      final isActive = i == idx;
      final color = isActive ? AppColors.primary : AppColors.slate400;

      return Expanded(
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => _onTabSelected(i),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOutCubic,
            padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 2),
            decoration: BoxDecoration(
              color: isActive
                  ? AppColors.primary.withAlpha(isLight ? 18 : 25)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  child: Icon(
                    isActive ? activeIcon : icon,
                    key: ValueKey('$i-$isActive'),
                    size: 21,
                    color: color,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 10,
                    color: color,
                    fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final idx = _currentIndex(context);
    final settings = ref.watch(appStyleProvider);
    final isLight = Theme.of(context).brightness == Brightness.light;
    final hasBg = settings.backgroundImagePath != null &&
        settings.backgroundImagePath!.isNotEmpty;

    return PopScope<void>(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) => _handleBackPress(didPop),
      child: settings.glassMode
          ? _buildGlassMode(idx, hasBg, settings)
          : _buildClassicMode(idx, isLight, hasBg, settings),
    );
  }

  /// 液态玻璃模式：GlassScaffold，背景图传入 background 参数
  Widget _buildGlassMode(int idx, bool hasBg, AppStyleSettings settings) {
    Widget? bgWidget;
    if (hasBg) {
      bgWidget = Image.file(
        File(settings.backgroundImagePath!),
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => const SizedBox.shrink(),
      );
    }

    return GlassScaffold(
      background: bgWidget,
      body: Padding(
        padding: const EdgeInsets.only(bottom: 62),
        child: widget.child,
      ),
      bottomBar: _buildGlassBottomBar(idx),
    );
  }

  /// 经典模式：AppBackground + Scaffold
  Widget _buildClassicMode(
      int idx, bool isLight, bool hasBg, AppStyleSettings settings) {
    return AppBackground(
      child: Scaffold(
        backgroundColor: hasBg ? Colors.transparent : null,
        body: widget.child,
        extendBody: true,
        bottomNavigationBar: _buildClassicBottomBar(idx, isLight),
      ),
    );
  }
}
