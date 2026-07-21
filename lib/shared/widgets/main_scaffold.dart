import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';

import '../../core/theme/app_theme.dart';
import '../../core/theme/theme_provider.dart';

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
      settings: const LiquidGlassSettings(
        thickness: 36,
        blur: 12,
      ),
      quality: GlassQuality.premium,
      selectedIconColor: AppColors.primary,
      selectedLabelColor: AppColors.primary,
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
    final styleSettings = ref.watch(appStyleProvider);
    final bg = styleSettings.backgroundImagePath;
    final blur = styleSettings.blurIntensity;

    Widget backgroundWidget;
    if (bg != null) {
      final imageWidget = ClipRRect(
        borderRadius: BorderRadius.circular(blur > 0 ? blur * 2 : 0),
        child: Image.asset(
          bg,
          fit: BoxFit.cover,
          width: double.infinity,
          height: double.infinity,
          errorBuilder: (_, __, ___) => Container(
            color: Theme.of(context).scaffoldBackgroundColor,
          ),
        ),
      );
      if (blur > 0) {
        backgroundWidget = Stack(
          children: [
            imageWidget,
            BackdropFilter(
              filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
              child: Container(color: Colors.transparent),
            ),
          ],
        );
      } else {
        backgroundWidget = imageWidget;
      }
    } else {
      backgroundWidget =
          Container(color: Theme.of(context).scaffoldBackgroundColor);
    }

    return PopScope<void>(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) => _handleBackPress(didPop),
      child: GlassScaffold(
        background: backgroundWidget,
        statusBarStyle: GlassStatusBarStyle.auto,
        edgeToEdge: true,
        contentAwareBrightness: true,
        settings: const LiquidGlassSettings(
          thickness: 36,
          blur: 12,
          specularSharpness: GlassSpecularSharpness.medium,
        ),
        appBar: GlassAppBar(
          title: const Text('Daidai'),
          centerTitle: true,
        ),
        bottomBar: _buildBottomBar(idx),
        body: widget.child,
      ),
    );
  }
}