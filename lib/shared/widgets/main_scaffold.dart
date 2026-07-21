import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';

import '../../core/theme/app_theme.dart';

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
      case 1:
        context.go('/tasks');
      case 2:
        context.go('/logs');
      case 3:
        context.go('/envs');
      case 4:
        context.go('/more');
    }
  }

  Widget _buildBottomBar(int idx) {
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

  @override
  Widget build(BuildContext context) {
    final idx = _currentIndex(context);

    return PopScope<void>(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) => _handleBackPress(didPop),
      child: GlassScaffold(
        body: Padding(
          padding: const EdgeInsets.only(bottom: 62),
          child: widget.child,
        ),
        bottomBar: _buildBottomBar(idx),
      ),
    );
  }
}