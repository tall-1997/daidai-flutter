import 'dart:io';

import 'package:daidai_app/features/dashboard/providers/dashboard_provider.dart';
import 'package:daidai_app/core/services/android_update_manifest.dart';
import 'package:daidai_app/core/services/local_notification_service.dart';
import 'package:daidai_app/core/services/app_update_service.dart';
import 'package:daidai_app/features/deps/models/dependency_log_state.dart';
import 'package:daidai_app/features/system/models/system_config_schema.dart';
import 'package:daidai_app/shared/models/dependency.dart';
import 'package:daidai_app/shared/models/subscription.dart';
import 'package:daidai_app/shared/utils/api_utils.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('extractPaginated', () {
    test('extracts standard paginated responses', () {
      final result = extractPaginated({
        'data': [
          {'id': 1},
          {'id': 2},
        ],
        'total': '12',
      });

      expect(result.items, hasLength(2));
      expect(result.total, 12);
    });

    test('handles nested paginated responses', () {
      final result = extractPaginated({
        'data': {
          'data': [
            {'id': 1},
          ],
          'total': 3,
        },
      });

      expect(result.items.single['id'], 1);
      expect(result.total, 3);
    });
  });

  group('Subscription.fromJson', () {
    Subscription subscriptionWith(dynamic forceOverwrite) {
      return Subscription.fromJson({
        'id': 1,
        'name': 'test',
        'force_overwrite': forceOverwrite,
        'created_at': '2026-01-01T00:00:00Z',
        'updated_at': '2026-01-01T00:00:00Z',
      });
    }

    test('accepts numeric overwrite flags', () {
      expect(subscriptionWith(1).forceOverwrite, isTrue);
      expect(subscriptionWith(0).forceOverwrite, isFalse);
    });

    test('accepts string overwrite flags', () {
      expect(subscriptionWith('true').forceOverwrite, isTrue);
      expect(subscriptionWith('0').forceOverwrite, isFalse);
    });
  });

  test('DashboardData accepts numeric strings', () {
    const data = DashboardData(
      system: {
        'cpu_usage': '12.5',
        'memory_usage': '25',
        'memory_total': '2048',
      },
      dashboard: {
        'task_count': '8',
        'enabled_tasks': '5',
        'success_logs': '11',
      },
    );

    expect(data.cpuUsage, 12.5);
    expect(data.memoryUsage, 25);
    expect(data.memoryTotal, '2.0KB');
    expect(data.totalTasks, 8);
    expect(data.disabledTasks, 3);
    expect(data.todaySuccess, 11);
  });

  test('AndroidUpdateManifest parses full and patch assets', () {
    final manifest = AndroidUpdateManifest.fromJson({
      'schemaVersion': 1,
      'packageName': 'com.daidai.daidai_app',
      'version': '0.1.43',
      'versionCode': 43,
      'releaseNotes': 'Delta update',
      'full': {
        'url': 'https://github.com/example/app.apk',
        'name': 'app.apk',
        'size': 100,
        'md5': 'full-md5',
        'sha256': 'full-sha',
      },
      'patches': [
        {
          'fromVersion': '0.1.42',
          'fromVersionCode': 42,
          'oldApkMd5': 'old-md5',
          'oldApkSha256': 'old-sha',
          'url': 'https://github.com/example/update.patch',
          'name': 'update.patch',
          'size': 10,
          'md5': 'patch-md5',
          'sha256': 'patch-sha',
        },
      ],
    });

    expect(manifest.version, '0.1.43');
    expect(manifest.full.name, 'app.apk');
    expect(manifest.patches.single.fromVersionCode, 42);
    expect(manifest.patches.single.oldApkSha256, 'old-sha');
  });

  group('notification payload navigation', () {
    test('routes task and log payloads', () {
      expect(notificationPayloadRoute(taskNotificationPayload(12)), '/tasks/12/live-logs');
      expect(notificationPayloadRoute(logNotificationPayload(8)), '/logs/8/stream');
      expect(
        notificationPayloadRoute(updateNotificationPayload('1.2.0')),
        '/more',
      );
    });
    test('uses a stable version-specific update notification id', () {
      expect(updateNotificationId('1.2.0'), updateNotificationId('1.2.0'));
      expect(
        updateNotificationId('1.2.0'),
        isNot(updateNotificationId('1.2.1')),
      );
      expect(updateNotificationBody(''), '点击查看并更新应用');
      expect(updateNotificationBody(List.filled(121, 'a').join()).length, 120);
    });

    test('ignores malformed payloads', () {
      expect(notificationPayloadRoute('invalid'), isNull);
      expect(notificationPayloadRoute('{"type":"task","id":0}'), isNull);
    });
  });

  group('update availability', () {
    AppUpdateInfo info({required bool hasUpdate, String url = 'https://github.com/a.apk'}) => AppUpdateInfo(
      latestVersion: '1.1.0', currentVersion: '1.0.0', releaseNotes: '',
      downloadUrl: url, assetName: url.isEmpty ? '' : 'a.apk', assetSize: 1,
      assetDigest: '', hasUpdate: hasUpdate,
    );

    test('distinguishes current, available, and missing installer', () {
      expect(classifyAppUpdate(info(hasUpdate: false)), AppUpdateAvailability.upToDate);
      expect(classifyAppUpdate(info(hasUpdate: true)), AppUpdateAvailability.updateAvailable);
      expect(classifyAppUpdate(info(hasUpdate: true, url: '')), AppUpdateAvailability.installerMissing);
    });
  });

  group('automatic update policy', () {
    final now = DateTime.utc(2026, 7, 24, 12);

    test('checks at most once per 24 hours', () {
      expect(shouldRunAutomaticUpdateCheck(null, now), isTrue);
      expect(shouldRunAutomaticUpdateCheck(now.subtract(const Duration(hours: 23)), now), isFalse);
      expect(shouldRunAutomaticUpdateCheck(now.subtract(const Duration(hours: 24)), now), isTrue);
    });

    test('reminds for a new version or after 24 hours', () {
      expect(shouldShowAutomaticUpdateReminder(version: '2', lastVersion: '1', lastReminder: now, now: now), isTrue);
      expect(shouldShowAutomaticUpdateReminder(version: '2', lastVersion: '2', lastReminder: now.subtract(const Duration(hours: 12)), now: now), isFalse);
      expect(shouldShowAutomaticUpdateReminder(version: '2', lastVersion: '2', lastReminder: now.subtract(const Duration(hours: 24)), now: now), isTrue);
    });
  });

  test('update cache cleanup removes all artifacts and reports file bytes', () async {
    final root = await Directory.systemTemp.createTemp('daidai-update-test-');
    final nested = Directory('${root.path}/nested');
    await nested.create();
    await File('${root.path}/installer.apk').writeAsBytes(List.filled(8, 1));
    await File('${root.path}/installer.apk.download').writeAsBytes(List.filled(5, 2));
    await File('${nested.path}/delta.patch').writeAsBytes(List.filled(3, 3));

    final released = await clearUpdateArtifactDirectory(root);

    expect(released, 16);
    expect(await root.list().toList(), isEmpty);
    await root.delete();
  });

  group('dependency log state', () {
    test('connection errors remain distinct from successful completion', () {
      final state = const DependencyLogState().transition(
        DependencyLogPhase.connectionError,
        message: 'offline',
      );

      expect(state.phase, DependencyLogPhase.connectionError);
      expect(state.terminal, isTrue);
    });

    test('keeps only the most recent log entries', () {
      var state = const DependencyLogState();
      for (var index = 0; index < DependencyLogState.maxEntries + 5; index++) {
        state = state.add('$index');
      }

      expect(state.entries, hasLength(DependencyLogState.maxEntries));
      expect(state.entries.first, '5');
    });

    test('maps dependency terminal events', () {
      expect(dependencyLogDonePhase('failed'), DependencyLogPhase.failed);
      expect(dependencyLogDonePhase('cancelled'), DependencyLogPhase.cancelled);
      expect(dependencyLogDonePhase('installed'), DependencyLogPhase.succeeded);
    });
  });

  group('system config schema', () {
    test('parses metadata and applies the log size fallback', () {
      final schemas = parseSystemConfigSchemas({
        'max_log_content_size': {
          'value_type': 'int',
          'group': '日志',
          'description': '最大日志长度',
          'readonly': true,
          'registered': false,
        },
        'theme': {
          'value': 'dark',
          'value_type': 'enum',
          'options': ['light', {'value': 'dark', 'label': '深色'}],
        },
      });

      expect(schemas.first.effectiveValue, '102400000');
      expect(schemas.first.isInt, isTrue);
      expect(schemas.first.readonly, isTrue);
      expect(schemas.first.registered, isFalse);
      expect(schemas.last.options.last.label, '深色');
    });

    test('submits only changed values', () {
      expect(
        changedSystemConfigValues(
          {'unchanged': '1', 'changed': 'old'},
          {'unchanged': '1', 'changed': 'new'},
        ),
        {'changed': 'new'},
      );
    });

    test('preserves explicit empty values and defaults only missing values', () {
      final schemas = parseSystemConfigSchemas({
        'explicit_empty': {
          'value': '',
          'default_value': 'fallback',
        },
        'missing_value': {
          'default_value': 'fallback',
        },
      });

      expect(schemas.first.hasValue, isTrue);
      expect(schemas.first.effectiveValue, '');
      expect(schemas.last.hasValue, isFalse);
      expect(schemas.last.effectiveValue, 'fallback');
    });
  });

  test('Dependency exposes unknown status values', () {
    final dependency = Dependency.fromJson({
      'id': 1,
      'name': 'demo',
      'status': 'paused',
      'created_at': '2026-01-01T00:00:00Z',
      'updated_at': '2026-01-01T00:00:00Z',
    });

    expect(dependency.statusText, '未知状态(paused)');
  });

}
