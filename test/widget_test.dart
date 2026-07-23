import 'package:daidai_app/features/dashboard/providers/dashboard_provider.dart';
import 'package:daidai_app/core/services/android_update_manifest.dart';
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
}
