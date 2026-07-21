import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';

import '../network/app_user_agent.dart';
import '../theme/app_theme.dart';

const _kGitHubRepo = 'tall-1997/daidai-flutter';
const _kGitHubDownloadHost = 'github.com';
const _kGitHubReleaseHost = 'objects.githubusercontent.com';
const _kGitHubAssetHost = 'githubusercontent.com';
const _kGitHubMirrorHost = 'gh.301.ee';
const _kGitHubMirrorPrefix = 'https://$_kGitHubMirrorHost/';

bool _isTrustedDownloadUrl(String rawUrl) {
  final uri = Uri.tryParse(rawUrl);
  if (uri == null || uri.scheme != 'https') {
    return false;
  }
  final host = uri.host.toLowerCase();
  return host == _kGitHubDownloadHost ||
      host == _kGitHubReleaseHost ||
      host == _kGitHubMirrorHost ||
      host.endsWith('.$_kGitHubAssetHost');
}

String _applyGitHubMirror(String url) {
  final uri = Uri.tryParse(url);
  if (uri == null) return url;
  final host = uri.host.toLowerCase();
  if (host == _kGitHubDownloadHost || host.endsWith('.$_kGitHubAssetHost')) {
    return '$_kGitHubMirrorPrefix$url';
  }
  return url;
}

class AppUpdateInfo {
  final String latestVersion;
  final String currentVersion;
  final String releaseNotes;
  final String downloadUrl;
  final String assetName;
  final bool hasUpdate;
  final DateTime? publishedAt;

  const AppUpdateInfo({
    required this.latestVersion,
    required this.currentVersion,
    required this.releaseNotes,
    required this.downloadUrl,
    required this.assetName,
    required this.hasUpdate,
    this.publishedAt,
  });
}

class AppUpdateService {
  AppUpdateService._();

  static final _dio = Dio(BaseOptions(
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 10),
    validateStatus: (status) => status != null && status < 400,
  ));

  static const _platform = MethodChannel('com.daidai.panel/app_install');

  /// Check GitHub Releases for new version.
  static Future<AppUpdateInfo?> checkUpdate() async {
    try {
      final resp = await _dio.get(
        'https://api.github.com/repos/$_kGitHubRepo/releases/latest',
        options: Options(headers: {'Accept': 'application/vnd.github.v3+json'}),
      );
      final data = resp.data;
      if (data is! Map<String, dynamic>) return null;

      final tagName = (data['tag_name'] as String?)?.replaceFirst('v', '') ?? '';
      final body = data['body']?.toString() ?? '';
      final assets = data['assets'];
      final publishedAtStr = data['published_at']?.toString();
      DateTime? publishedAt;
      if (publishedAtStr != null) {
        publishedAt = DateTime.tryParse(publishedAtStr);
        if (publishedAt != null) {
          publishedAt = publishedAt.toLocal();
        }
      }

      String apkUrl = '';
      String assetName = '';
      if (assets is List) {
        for (final asset in assets) {
          final name = asset['name']?.toString() ?? '';
          if (name.endsWith('.apk')) {
            final rawUrl = asset['browser_download_url']?.toString() ?? '';
            if (_isTrustedDownloadUrl(rawUrl)) {
              apkUrl = rawUrl;
              assetName = name;
              break;
            }
          }
        }
      }

      final currentVersion = AppUserAgent.versionLabel.split('+').first;
      final hasUpdate = tagName.isNotEmpty &&
          _isNewer(tagName, currentVersion, publishedAt: publishedAt);

      return AppUpdateInfo(
        latestVersion: tagName,
        currentVersion: currentVersion,
        releaseNotes: body,
        downloadUrl: apkUrl,
        assetName: assetName,
        hasUpdate: hasUpdate,
        publishedAt: publishedAt,
      );
    } catch (_) {
      return null;
    }
  }

  /// Compare semantic versions: returns true if remote > local.
  static bool _isNewer(String remote, String local,
      {DateTime? publishedAt}) {
    final rParts = remote.split('+');
    final lParts = local.split('+');
    final rVer = rParts[0].split('.').map((e) => int.tryParse(e) ?? 0).toList();
    final lVer = lParts[0].split('.').map((e) => int.tryParse(e) ?? 0).toList();
    while (rVer.length < 3) {
      rVer.add(0);
    }
    while (lVer.length < 3) {
      lVer.add(0);
    }
    for (int i = 0; i < 3; i++) {
      if (rVer[i] > lVer[i]) return true;
      if (rVer[i] < lVer[i]) return false;
    }
    final rBuild = rParts.length > 1 ? (int.tryParse(rParts[1]) ?? 0) : 0;
    final lBuild = lParts.length > 1 ? (int.tryParse(lParts[1]) ?? 0) : 0;
    if (rBuild > lBuild) return true;
    if (rBuild < lBuild) return false;
    if (publishedAt != null) {
      return publishedAt.isAfter(
        DateTime.now().subtract(const Duration(minutes: 30)),
      );
    }
    return false;
  }

  /// Download APK and install it.
  /// Uses GitHub mirror for acceleration and reuses existing downloads.
  static Future<void> downloadAndInstall(
    String url,
    String assetName,
    ValueChanged<double> onProgress,
    VoidCallback onDone,
    ValueChanged<String> onError,
  ) async {
    try {
      if (!_isTrustedDownloadUrl(url)) {
        throw const FormatException('更新地址不可信，已拒绝下载');
      }

      final dir = await getTemporaryDirectory();
      final safeName = assetName.trim().isEmpty
          ? 'daidai_update.apk'
          : assetName.replaceAll(RegExp(r'[^A-Za-z0-9._-]'), '_');
      final filePath = '${dir.path}/$safeName';

      final existingFile = File(filePath);
      bool needsDownload = true;

      if (await existingFile.exists()) {
        final existingSize = await existingFile.length();
        if (existingSize > 1024 * 1024) {
          needsDownload = false;
          onProgress(1.0);
        } else {
          await existingFile.delete();
        }
      }

      if (needsDownload) {
        final downloadUrl = _applyGitHubMirror(url);

        final response = await _dio.download(
          downloadUrl,
          filePath,
          onReceiveProgress: (received, total) {
            if (total > 0) {
              onProgress(received / total);
            }
          },
          options: Options(receiveTimeout: const Duration(minutes: 10)),
        );
        final finalHost = response.realUri.host.toLowerCase();
        if (!(_isTrustedDownloadUrl(response.realUri.toString()) ||
            finalHost == _kGitHubReleaseHost ||
            finalHost == _kGitHubMirrorHost ||
            finalHost.endsWith('.$_kGitHubAssetHost'))) {
          throw const FormatException('更新资源跳转到了不受信任的来源');
        }
      }

      onDone();

      if (Platform.isAndroid) {
        final originalHost = Uri.parse(url).host.toLowerCase();
        await _platform.invokeMethod('installApk', {
          'path': filePath,
          'sourceHost': originalHost,
        });
      }
    } catch (e) {
      onError(e.toString());
    }
  }

  /// Show update dialog.
  static Future<void> showUpdateDialog(
    BuildContext context,
    AppUpdateInfo info,
  ) async {
    if (!context.mounted) return;
    final isLight = Theme.of(context).brightness == Brightness.light;

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogCtx) => _UpdateDialog(
        info: info,
        isLight: isLight,
      ),
    );
  }
}

class _UpdateDialog extends StatefulWidget {
  final AppUpdateInfo info;
  final bool isLight;
  const _UpdateDialog({required this.info, required this.isLight});

  @override
  State<_UpdateDialog> createState() => _UpdateDialogState();
}

class _UpdateDialogState extends State<_UpdateDialog> {
  bool _downloading = false;
  double _progress = 0;
  String? _error;

  void _startDownload() {
    if (widget.info.downloadUrl.isEmpty) {
      setState(() => _error = '未找到 APK 下载链接');
      return;
    }
    setState(() {
      _downloading = true;
      _progress = 0;
      _error = null;
    });

    AppUpdateService.downloadAndInstall(
      widget.info.downloadUrl,
      widget.info.assetName,
      (p) {
        if (mounted) setState(() => _progress = p);
      },
      () {
        if (mounted) setState(() => _downloading = false);
      },
      (e) {
        if (mounted) {
          setState(() {
            _downloading = false;
            _error = '下载失败: $e';
          });
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isAndroid = !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

    return AlertDialog(
      title: const Text('发现新版本'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'v${widget.info.currentVersion}',
                style: TextStyle(
                  fontSize: 13,
                  color: widget.isLight
                      ? AppColors.slate500
                      : AppColors.slate400,
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 8),
                child: Icon(Icons.arrow_forward, size: 14),
              ),
              Text(
                'v${widget.info.latestVersion}',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
          if (widget.info.releaseNotes.isNotEmpty) ...[
            const SizedBox(height: 12),
            const Text(
              '更新内容',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 6),
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 200),
              child: SingleChildScrollView(
                child: Text(
                  widget.info.releaseNotes,
                  style: TextStyle(
                    fontSize: 12,
                    color: widget.isLight
                        ? AppColors.slate600
                        : AppColors.slate300,
                    height: 1.5,
                  ),
                ),
              ),
            ),
          ],
          if (_downloading) ...[
            const SizedBox(height: 16),
            LinearProgressIndicator(
              value: _progress,
              color: AppColors.primary,
              backgroundColor: widget.isLight
                  ? AppColors.slate200
                  : AppColors.slate800,
            ),
            const SizedBox(height: 6),
            Center(
              child: Text(
                '下载中 ${(_progress * 100).toStringAsFixed(0)}%',
                style: const TextStyle(fontSize: 12),
              ),
            ),
          ],
          if (_error != null) ...[
            const SizedBox(height: 12),
            Text(
              _error!,
              style: const TextStyle(fontSize: 12, color: AppColors.red500),
            ),
          ] else ...[
            const SizedBox(height: 12),
            Text(
              '更新包通过 GitHub 加速镜像下载，校验包名与签名后再安装。已下载的安装包会自动复用，无需重复下载。',
              style: TextStyle(
                fontSize: 12,
                color: widget.isLight
                    ? AppColors.slate600
                    : AppColors.slate300,
                height: 1.4,
              ),
            ),
          ],
        ],
      ),
      actions: _downloading
          ? null
          : [
              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 44,
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('稍后'),
                      ),
                    ),
                  ),
                  if (isAndroid && widget.info.downloadUrl.isNotEmpty) ...[
                    const SizedBox(width: 12),
                    Expanded(
                      child: SizedBox(
                        height: 44,
                        child: FilledButton(
                          onPressed: _startDownload,
                          child: const Text('立即更新'),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ],
    );
  }
}
