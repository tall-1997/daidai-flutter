import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../auth/auth_provider.dart';
import '../../features/login/views/app_boot_page.dart';
import '../../features/login/views/login_page.dart';
import '../../features/server_config/views/server_config_page.dart';
import '../../features/dashboard/views/dashboard_page.dart';
import '../../features/tasks/views/task_list_page.dart';
import '../../features/tasks/views/task_form_page.dart';
import '../../features/logs/views/log_list_page.dart';
import '../../features/logs/views/log_stream_page.dart';
import '../../features/envs/views/env_list_page.dart';
import '../../features/settings/views/more_page.dart';
import '../../features/settings/views/sponsor_page.dart';
import '../../features/subscriptions/views/subscription_list_page.dart';
import '../../features/scripts/views/script_list_page.dart';
import '../../features/notifications/views/notification_list_page.dart';
import '../../features/notifications/views/local_notification_settings_page.dart';
import '../../features/deps/views/dep_list_page.dart';
import '../../features/users/views/user_list_page.dart';
import '../../features/security/views/security_page.dart';
import '../../features/security/views/ssh_keys_page.dart';
import '../../features/system/views/system_settings_page.dart';
import '../../features/system/views/panel_settings_page.dart';
import '../../features/system/views/panel_log_page.dart';
import '../../features/system/views/backup_page.dart';
import '../../features/openapi/views/open_api_page.dart';
import '../../features/app_lock/views/app_lock_settings_page.dart';
import '../../features/settings/views/theme_settings_page.dart';
import '../../shared/widgets/main_scaffold.dart';
import '../../shared/models/task.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();
final _shellNavigatorKey = GlobalKey<NavigatorState>();

/// 将 auth status 变化转为 Listenable，供 GoRouter.refreshListenable 使用
class _AuthNotifierBridge extends ChangeNotifier {
  _AuthNotifierBridge(Ref ref) {
    ref.listen<AuthStatus>(
      authProvider.select((s) => s.status),
      (previous, next) => notifyListeners(),
    );
  }
}

final _authNotifierProvider = Provider<_AuthNotifierBridge>((ref) {
  return _AuthNotifierBridge(ref);
});

final routerProvider = Provider<GoRouter>((ref) {
  final refreshNotifier = ref.watch(_authNotifierProvider);

  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/boot',
    refreshListenable: refreshNotifier,
    redirect: (context, state) {
      // 每次 redirect 时实时读取最新状态（不用 watch）
      final authState = ref.read(authProvider);
      final isAuth = authState.status == AuthStatus.authenticated;
      final isUnknown = authState.status == AuthStatus.unknown;
      final isBootRoute = state.matchedLocation == '/boot';
      final isLoginRoute = state.matchedLocation == '/login';
      final isServerConfig = state.matchedLocation == '/server-config';
      final manualServerConfig = state.uri.queryParameters['manual'] == '1';
      final manageServerConfig = state.uri.queryParameters['manage'] == '1';

      if (isBootRoute) {
        return null;
      }
      if (isUnknown) {
        return '/boot';
      }
      if (isServerConfig) {
        if (isAuth && !manualServerConfig && !manageServerConfig) {
          return '/dashboard';
        }
        if (!isAuth &&
            !manualServerConfig &&
            !manageServerConfig &&
            authState.status == AuthStatus.unauthenticated) {
          return '/login';
        }
        return null;
      }
      if (!isAuth && !isLoginRoute) return '/login';
      if (isAuth && isLoginRoute) return '/dashboard';
      return null;
    },
    routes: [
      GoRoute(path: '/boot', builder: (_, state) => const AppBootPage()),
      GoRoute(
        path: '/server-config',
        builder: (_, state) => ServerConfigPage(
          manageMode: state.uri.queryParameters['manage'] == '1',
        ),
      ),
      GoRoute(path: '/login', builder: (_, state) => const LoginPage()),
      ShellRoute(
        navigatorKey: _shellNavigatorKey,
        builder: (_, state, child) => MainScaffold(child: child),
        routes: [
          GoRoute(
            path: '/dashboard',
            pageBuilder: (_, state) =>
                const NoTransitionPage(child: DashboardPage()),
          ),
          GoRoute(
            path: '/tasks',
            pageBuilder: (_, state) =>
                const NoTransitionPage(child: TaskListPage()),
          ),
          GoRoute(
            path: '/logs',
            pageBuilder: (_, state) =>
                const NoTransitionPage(child: LogListPage()),
          ),
          GoRoute(
            path: '/envs',
            pageBuilder: (_, state) =>
                const NoTransitionPage(child: EnvListPage()),
          ),
          GoRoute(
            path: '/more',
            pageBuilder: (_, state) =>
                const NoTransitionPage(child: MorePage()),
          ),
        ],
      ),
GoRoute(
        path: '/tasks/new',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (_, state) => TaskFormPage(
          prefill: state.extra is TaskFormPrefill
              ? state.extra as TaskFormPrefill
              : null,
        ),
      ),
      GoRoute(
        path: '/tasks/edit',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (_, state) {
          final task = state.extra as Task?;
          return TaskFormPage(task: task);
        },
      ),
      GoRoute(
        path: '/tasks/:id/live-logs',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (_, state) => TaskLiveLogPage(
          taskId: int.parse(state.pathParameters['id']!),
          taskName: state.extra as String?,
        ),
      ),
      GoRoute(
        path: '/logs/:id/stream',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (_, state) =>
            LogStreamPage(logId: int.parse(state.pathParameters['id']!)),
      ),
      // Phase 2 routes
      GoRoute(
        path: '/subscriptions',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (_, state) => const SubscriptionListPage(),
      ),
      GoRoute(
        path: '/subscriptions/:id/pull-stream',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (_, state) => SubscriptionPullStreamPage(
          subscriptionId: int.parse(state.pathParameters['id']!),
        ),
      ),
      GoRoute(
        path: '/subscriptions/:id/logs',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (_, state) => SubscriptionLogsPage(
          subscriptionId: int.parse(state.pathParameters['id']!),
          subscriptionName: state.extra as String?,
        ),
      ),
      GoRoute(
        path: '/scripts',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (_, state) => const ScriptListPage(),
      ),
      GoRoute(
        path: '/scripts/view',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (_, state) {
          final path = state.extra as String? ?? '';
          return ScriptViewPage(path: path);
        },
      ),
      GoRoute(
        path: '/notifications',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (_, state) => const NotificationListPage(),
      ),
      GoRoute(
        path: '/local-notifications',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (_, state) => const LocalNotificationSettingsPage(),
      ),
      GoRoute(
        path: '/deps',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (_, state) => const DepListPage(),
      ),
      GoRoute(
        path: '/deps/:id/log-stream',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (_, state) =>
            DepLogStreamPage(depId: int.parse(state.pathParameters['id']!)),
      ),
      // Phase 3 routes
      GoRoute(
        path: '/users',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (_, state) => const UserListPage(),
      ),
      GoRoute(
        path: '/security',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (_, state) => const SecurityPage(),
      ),
      GoRoute(
        path: '/app-lock',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (_, state) => const AppLockSettingsPage(),
      ),
      GoRoute(
        path: '/theme-settings',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (_, state) => const ThemeSettingsPage(),
      ),
      GoRoute(
        path: '/system-settings',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (_, state) => const SystemSettingsPage(),
      ),
      GoRoute(
        path: '/panel-settings',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (_, state) => const PanelSettingsPage(),
      ),
      GoRoute(
        path: '/panel-log',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (_, state) => const PanelLogPage(),
      ),
      GoRoute(
        path: '/backup',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (_, state) => const BackupPage(),
      ),
      GoRoute(
        path: '/open-api',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (_, state) => const OpenApiPage(),
      ),
      GoRoute(
        path: '/ssh-keys',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (_, state) => const SshKeysPage(),
      ),
      GoRoute(
        path: '/sponsor',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (_, state) => const SponsorPage(),
      ),
      GoRoute(
        path: '/open-api/:id/logs',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (_, state) => OpenApiLogsPage(
          appId: int.parse(state.pathParameters['id']!),
        ),
      ),
        ),
      ),
      GoRoute(
        path: '/tasks/edit',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (_, state) {
          final task = state.extra as Task?;
          return AppBackground(child: TaskFormPage(task: task));
        },
      ),
      GoRoute(
        path: '/tasks/:id/live-logs',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (_, state)
          child: TaskLiveLogPage(
            taskId: int.parse(state.pathParameters['id']!),
            taskName: state.extra as String?,
          ),
        ),
      ),
      GoRoute(
        path: '/logs/:id/stream',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (_, state)
          child: LogStreamPage(logId: int.parse(state.pathParameters['id']!)),
        ),
      ),
      // Phase 2 routes
      GoRoute(
        path: '/subscriptions',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (_, state)child: const SubscriptionListPage()),
      ),
      GoRoute(
        path: '/subscriptions/:id/pull-stream',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (_, state)
          child: SubscriptionPullStreamPage(
            subscriptionId: int.parse(state.pathParameters['id']!),
          ),
        ),
      ),
      GoRoute(
        path: '/subscriptions/:id/logs',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (_, state)
          child: SubscriptionLogsPage(
            subscriptionId: int.parse(state.pathParameters['id']!),
            subscriptionName: state.extra as String?,
          ),
        ),
      ),
      GoRoute(
        path: '/scripts',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (_, state)child: const ScriptListPage()),
      ),
      GoRoute(
        path: '/scripts/view',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (_, state) {
          final path = state.extra as String? ?? '';
          return AppBackground(child: ScriptViewPage(path: path));
        },
      ),
      GoRoute(
        path: '/notifications',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (_, state)child: const NotificationListPage()),
      ),
      GoRoute(
        path: '/local-notifications',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (_, state) =>
            AppBackground(child: const LocalNotificationSettingsPage()),
      ),
      GoRoute(
        path: '/deps',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (_, state)child: const DepListPage()),
      ),
      GoRoute(
        path: '/deps/:id/log-stream',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (_, state)
          child: DepLogStreamPage(depId: int.parse(state.pathParameters['id']!)),
        ),
      ),
      // Phase 3 routes
      GoRoute(
        path: '/users',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (_, state)child: const UserListPage()),
      ),
      GoRoute(
        path: '/security',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (_, state)child: const SecurityPage()),
      ),
      GoRoute(
        path: '/app-lock',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (_, state) =>
            AppBackground(child: const AppLockSettingsPage()),
      ),
      GoRoute(
        path: '/theme-settings',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (_, state) =>
            AppBackground(child: const ThemeSettingsPage()),
      ),
      GoRoute(
        path: '/system-settings',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (_, state) =>
            AppBackground(child: const SystemSettingsPage()),
      ),
      GoRoute(
        path: '/panel-settings',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (_, state) =>
            AppBackground(child: const PanelSettingsPage()),
      ),
      GoRoute(
        path: '/panel-log',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (_, state)child: const PanelLogPage()),
      ),
      GoRoute(
        path: '/backup',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (_, state)child: const BackupPage()),
      ),
      GoRoute(
        path: '/open-api',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (_, state)child: const OpenApiPage()),
      ),
      GoRoute(
        path: '/ssh-keys',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (_, state)child: const SshKeysPage()),
      ),
      GoRoute(
        path: '/sponsor',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (_, state)child: const SponsorPage()),
      ),
      GoRoute(
        path: '/open-api/:id/logs',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (_, state)
          child: OpenApiLogsPage(
            appId: int.parse(state.pathParameters['id']!),
          ),
        ),
      ),
    ],
  );
});
