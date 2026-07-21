import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_provider.dart';
import 'features/app_lock/widgets/app_lock_gate.dart';

class DaidaiApp extends ConsumerWidget {
  const DaidaiApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    final styleSettings = ref.watch(appStyleProvider);

    return MaterialApp.router(
      title: '呆呆面板',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: styleSettings.themeMode,
      routerConfig: router,
      locale: const Locale('zh', 'CN'),
      builder: (context, child) {
        final wrapped = AppLockGate(
          child: child ?? const SizedBox.shrink(),
        );
        return GlassPage(
          edgeToEdge: true,
          statusBarStyle: GlassStatusBarStyle.auto,
          child: wrapped,
        );
      },
    );
  }
}