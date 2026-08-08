import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/auth/auth_provider.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/storage/secure_storage.dart';
import '../../dashboard/providers/dashboard_provider.dart';

class AppBootPage extends ConsumerStatefulWidget {
  const AppBootPage({super.key});

  @override
  ConsumerState<AppBootPage> createState() => _AppBootPageState();
}

class _AppBootPageState extends ConsumerState<AppBootPage> {
  bool _jumping = false;
  String? _bootMessage;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _runBootFlow();
    });
  }

  Future<void> _runBootFlow() async {
    if (_jumping) {
      return;
    }

    _jumping = true;

    // 没有当前服务器时直接进入登录页，由用户配置面板地址。
    final serverUrl = await SecureStorage.getServerUrl();
    if (serverUrl == null || serverUrl.isEmpty) {
      _go('/login');
      return;
    }

    DioClient.instance.setBaseUrl(serverUrl);

    // 7 天可信会话内，直接进首页，不再重复请求登录接口。
    final authState = ref.read(authProvider);
    if (authState.status == AuthStatus.authenticated) {
      try {
        ref.invalidate(dashboardProvider);
      } catch (_) {}
      _go('/dashboard');
      return;
    }

    // 读取当前面板，决定是否允许静默自动登录。
    final currentPanel = await SecureStorage.getCurrentPanel();
    if (!mounted) return;
    if (currentPanel == null) {
      _go('/login');
      return;
    }

    try {
      if (!mounted) return;
      setState(() {
        _bootMessage = '正在检查面板状态...';
      });

      await ref.read(authProvider.notifier).checkInit();
      final latestAuthState = ref.read(authProvider);
      if (latestAuthState.needsInit) {
        _go('/login');
        return;
      }
    } catch (_) {
      // 初始化检测失败时不阻塞，交给登录页继续处理。
    }

    final canAutoLogin =
        currentPanel.rememberPassword &&
        currentPanel.autoLogin &&
        (currentPanel.username?.trim().isNotEmpty ?? false) &&
        (currentPanel.password?.isNotEmpty ?? false);

    if (!canAutoLogin) {
      _go('/login');
      return;
    }

    try {
      if (!mounted) return;
      setState(() {
        _bootMessage = '正在自动登录...';
      });

      final result = await ref
          .read(authProvider.notifier)
          .login(
            username: currentPanel.username!.trim(),
            password: currentPanel.password!,
          );

      if (!mounted) {
        return;
      }

      if (result['access_token'] == null ||
          result['access_token'].toString().isEmpty) {
        _go('/login?manual=1');
        return;
      }

      await SecureStorage.savePanel(
        currentPanel.copyWith(
          username: currentPanel.username!.trim(),
          password: currentPanel.password,
          rememberPassword: true,
          autoLogin: true,
        ),
      );
      if (!mounted) return;

      try {
        ref.invalidate(dashboardProvider);
        await ref.read(dashboardProvider.notifier).load();
      } catch (_) {}

      _go('/dashboard');
      return;
    } catch (_) {
      // 自动登录失败时回到手动登录，但保留记住密码，方便用户重新确认。
      _go('/login?manual=1');
      return;
    }
  }

  void _go(String location) {
    if (!mounted) {
      return;
    }
    context.go(location);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset('assets/icon.png', width: 72, height: 72),
              const SizedBox(height: 20),
              const SizedBox(
                width: 28,
                height: 28,
                child: CircularProgressIndicator(strokeWidth: 3),
              ),
              const SizedBox(height: 20),
              Text(
                _bootMessage ?? '正在启动呆呆面板...',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
