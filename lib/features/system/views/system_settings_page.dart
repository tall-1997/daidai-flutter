import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/network/api_endpoints.dart';
import '../../../core/network/panel_capability_registry.dart';
import '../../../core/auth/auth_session_epoch.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/models/python_runtime_info.dart';
import '../../../shared/utils/api_utils.dart';
import '../../../shared/widgets/app_card.dart';
import '../models/system_config_schema.dart';

class SystemSettingsPage extends ConsumerStatefulWidget {
  const SystemSettingsPage({super.key});

  @override
  ConsumerState<SystemSettingsPage> createState() => _SystemSettingsPageState();
}

class _SystemSettingsPageState extends ConsumerState<SystemSettingsPage> {
  Map<String, dynamic>? _versionInfo;
  Map<String, dynamic>? _panelSettings;
  Map<String, dynamic>? _updateInfo;
  Map<String, dynamic>? _updateStatus;
  List<PythonRuntimeInfo> _pythonRuntimes = const [];
  String _pythonDefaultVersion = '';
  bool _loading = true;
  bool _checking = false;
  bool _savingConfigs = false;
  bool _updatingPanel = false;
  String? _loadError;
  int _loadRequestId = 0;

  List<SystemConfigSchema> _configSchemas = const [];
  Map<String, String> _initialConfigValues = const {};
  final Map<String, String> _configValues = {};
  final Map<String, TextEditingController> _configControllers = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    for (final controller in _configControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _load() async {
    final requestId = ++_loadRequestId;
    final scope = AuthSessionEpoch.scoped(PanelCapabilityRegistry.currentScope);
    setState(() {
      _loading = true;
      _loadError = null;
    });
    try {
      final results = await Future.wait([
        DioClient.instance.dio.get(ApiEndpoints.systemVersion),
        DioClient.instance.dio.get(ApiEndpoints.configs),
      ]);
      final versionData = extractData(results[0].data);
      final configData = extractData(results[1].data);
      dynamic panelData;
      dynamic runtimeRaw;

      try {
        final panelResp = await DioClient.instance.dio.get(
          ApiEndpoints.panelSettings,
        );
        panelData = extractData(panelResp.data);
      } catch (_) {}

      try {
        final runtimeResp = await DioClient.instance.dio.get(
          ApiEndpoints.depsPythonRuntimes,
        );
        runtimeRaw = runtimeResp.data;
      } catch (_) {}

      final schemas = parseSystemConfigSchemas(configData);
      if (!mounted ||
          requestId != _loadRequestId ||
          scope != AuthSessionEpoch.scoped(PanelCapabilityRegistry.currentScope)) {
        return;
      }

      final values = {for (final schema in schemas) schema.key: schema.effectiveValue};
      for (final controller in _configControllers.values) {
        controller.dispose();
      }
      _configControllers
        ..clear()
        ..addEntries(schemas.where((schema) => !schema.isBool && !schema.isEnum).map(
          (schema) => MapEntry(schema.key, TextEditingController(text: values[schema.key])),
        ));
      _configValues
        ..clear()
        ..addAll(values);

      setState(() {
        _versionInfo = versionData is Map<String, dynamic> ? versionData : null;
        _panelSettings = panelData is Map<String, dynamic> ? panelData : null;
        _pythonRuntimes = _parsePythonRuntimes(runtimeRaw);
        _pythonDefaultVersion = _parsePythonDefaultVersion(runtimeRaw);
        _configSchemas = schemas;
        _initialConfigValues = Map.unmodifiable(values);
        _loading = false;
        _loadError = null;
      });
    } catch (error) {
      if (!mounted ||
          requestId != _loadRequestId ||
          scope != AuthSessionEpoch.scoped(PanelCapabilityRegistry.currentScope)) {
        return;
      }
      setState(() {
        _loading = false;
        _loadError = extractErrorMessage(error, '系统设置加载失败');
      });
    }
  }

  List<PythonRuntimeInfo> _parsePythonRuntimes(dynamic raw) {
    final map = raw is Map<String, dynamic>
        ? raw
        : raw is Map
        ? Map<String, dynamic>.from(raw)
        : <String, dynamic>{};
    final data = map['data'];
    if (data is! List) {
      return const [];
    }
    return data
        .whereType<Map>()
        .map((item) => PythonRuntimeInfo.fromJson(Map<String, dynamic>.from(item)))
        .where((item) => item.version.trim().isNotEmpty)
        .toList();
  }

  String _parsePythonDefaultVersion(dynamic raw) {
    if (raw is Map && raw['default_version'] != null) {
      return raw['default_version'].toString();
    }
    return '';
  }

  Future<void> _checkUpdate() async {
    setState(() => _checking = true);
    try {
      final resp = await DioClient.instance.dio.get(ApiEndpoints.checkUpdate);
      final data = extractData(resp.data);
      if (!mounted) return;
      setState(() {
        _updateInfo = data is Map<String, dynamic> ? data : null;
        _checking = false;
      });
      if (_updateInfo != null && _updateInfo!['has_update'] == true) {
        if (mounted) _showUpdateDialog();
      } else {
        if (mounted) {
          AppGlassNotice.show(
            context,
            '已是最新版本',
            type: AppGlassNoticeType.info,
          );
        }
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _checking = false);
      if (mounted) {
        String msg = '检查更新失败';
        if (e is DioException && e.response?.data is Map) {
          msg = (e.response!.data as Map)['error']?.toString() ?? msg;
        }
        AppGlassNotice.show(
          context,
          msg,
          type: AppGlassNoticeType.error,
        );
      }
    }
  }

  bool get _isWatchtowerManaged {
    final target = _updateInfo?['update_target'];
    if (target is! Map) {
      return false;
    }
    return target['update_manager']?.toString() == 'watchtower' ||
        target['watchtower_managed'] == true;
  }

  bool get _isBinaryUpdate {
    final target = _updateInfo?['update_target'];
    if (target is! Map) {
      return false;
    }
    return target['deployment_type']?.toString() == 'binary';
  }

  String _updateActionLabel() {
    if (_isWatchtowerManaged) {
      return '触发 Watchtower 检查';
    }
    return '立即更新';
  }

  String _updateSuccessHint() {
    if (_isWatchtowerManaged) {
      return '已触发 Watchtower 检查更新，请稍后查看 Watchtower 日志或等待容器重建结果';
    }
    if (_isBinaryUpdate) {
      return '后台更新任务已启动，面板完成替换后会自动重启';
    }
    return '更新任务已启动，面板将拉取镜像并重建容器';
  }

  String _buildUpdateSummary() {
    final target = _updateInfo?['update_target'];
    if (target is! Map) {
      return '';
    }
    final lines = <String>[];
    if (target['deployment_type']?.toString() == 'binary') {
      lines.add('更新方式：二进制后台更新');
    } else if (_isWatchtowerManaged) {
      lines.add('更新方式：Watchtower 托管更新');
    } else {
      lines.add('更新方式：Docker 镜像更新');
    }
    final assetName = target['asset_name']?.toString() ?? '';
    if (assetName.trim().isNotEmpty) {
      lines.add('更新包：$assetName');
    }
    final installDir = target['install_dir']?.toString() ?? '';
    if (installDir.trim().isNotEmpty) {
      lines.add('安装目录：$installDir');
    }
    final mirrorHost = target['mirror_host']?.toString() ?? '';
    if (mirrorHost.trim().isNotEmpty) {
      lines.add('镜像源：$mirrorHost');
    }
    final channel = target['channel']?.toString() ?? '';
    if (channel.trim().isNotEmpty) {
      lines.add('渠道：${channel == 'debian' ? 'Debian' : 'Latest (Alpine)'}');
    }
    final schedule = target['watchtower_schedule']?.toString() ?? '';
    if (schedule.trim().isNotEmpty) {
      lines.add('Watchtower 调度：$schedule');
    }
    final reason = _updateInfo?['update_disabled_reason']?.toString() ?? '';
    if (reason.trim().isNotEmpty) {
      lines.add(reason.trim());
    }
    return lines.join('\n');
  }

  Future<void> _loadUpdateStatus() async {
    try {
      final response = await DioClient.instance.dio.get(
        '${ApiEndpoints.baseApi}/system/update-status',
      );
      final data = extractData(response.data);
      if (!mounted) {
        return;
      }
      setState(() {
        _updateStatus = data is Map<String, dynamic>
            ? data
            : data is Map
            ? Map<String, dynamic>.from(data)
            : null;
      });
    } catch (_) {}
  }

  void _showUpdateDialog() {
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('发现新版本'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('当前: ${_updateInfo?['current'] ?? ''}'),
            Text('最新: ${_updateInfo?['latest'] ?? ''}'),
            if ((_updateInfo?['release_notes'] ?? '')
                .toString()
                .isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                _updateInfo!['release_notes'].toString(),
                style: const TextStyle(fontSize: 12),
              ),
            ],
          ],
        ),
        actions: [
          AppLiquidGlassDialogActions(
            actions: [
              AppGlassDialogAction(
                label: '稍后',
                onPressed: () => Navigator.pop(dialogCtx),
              ),
              if (_updateInfo?['auto_update_supported'] == true)
                AppGlassDialogAction(
                  label: _updateActionLabel(),
                  variant: AppLiquidGlassButtonVariant.warning,
                  onPressed: () {
                    Navigator.pop(dialogCtx);
                    _doUpdate();
                  },
                ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _doUpdate() async {
    setState(() => _updatingPanel = true);
    try {
      final response = await DioClient.instance.dio.post(
        '${ApiEndpoints.baseApi}/system/update',
      );
      final data = extractData(response.data);
      if (mounted) {
        setState(() {
          _updateStatus = data is Map<String, dynamic>
              ? data
              : data is Map
              ? Map<String, dynamic>.from(data)
              : _updateStatus;
        });
      }
      await _loadUpdateStatus();
      if (mounted) {
        AppGlassNotice.show(
          context,
          _updateSuccessHint(),
          type: AppGlassNoticeType.success,
        );
      }
    } catch (error) {
      if (mounted) {
        AppGlassNotice.show(
          context,
          extractErrorMessage(error, '更新失败'),
          type: AppGlassNoticeType.error,
        );
      }
    } finally {
      if (mounted) {
        setState(() => _updatingPanel = false);
      }
    }
  }

  Future<void> _restart() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('重启面板'),
        content: const Text('确定要重启面板吗？所有运行中的任务将被中断。'),
        actions: [
          AppLiquidGlassDialogActions(
            actions: [
              AppGlassDialogAction(
                label: '取消',
                onPressed: () => Navigator.pop(dialogCtx, false),
              ),
              AppGlassDialogAction(
                label: '重启',
                variant: AppLiquidGlassButtonVariant.danger,
                onPressed: () => Navigator.pop(dialogCtx, true),
              ),
            ],
          ),
        ],
      ),
    );
    if (confirm == true) {
      try {
        await DioClient.instance.dio.post(
          '${ApiEndpoints.baseApi}/system/restart',
        );
        if (mounted) {
          AppGlassNotice.show(
            context,
            '面板将在 2 秒后重启',
            type: AppGlassNoticeType.info,
          );
        }
      } catch (error) {
        if (mounted) {
          AppGlassNotice.show(
            context,
            extractErrorMessage(error, '面板重启失败'),
            type: AppGlassNoticeType.error,
          );
        }
      }
    }
  }

  Future<void> _saveTaskConfigs() async {
    setState(() => _savingConfigs = true);
    try {
      for (final entry in _configControllers.entries) {
        _configValues[entry.key] = entry.value.text.trim();
      }
      final changed = changedSystemConfigValues(
        _initialConfigValues,
        _configValues,
      );
      if (changed.isEmpty) {
        if (mounted) {
          AppGlassNotice.show(
            context,
            '配置没有变化',
            type: AppGlassNoticeType.info,
          );
        }
        return;
      }
      await DioClient.instance.dio.put(
        ApiEndpoints.configsBatch,
        data: {'configs': changed},
      );
      _initialConfigValues = Map.unmodifiable(_configValues);
      if (mounted) {
        AppGlassNotice.show(
          context,
          '配置已保存',
          type: AppGlassNoticeType.success,
        );
      }
    } catch (error) {
      if (mounted) {
        AppGlassNotice.show(
          context,
          extractErrorMessage(error, '保存失败'),
          type: AppGlassNoticeType.error,
        );
      }
      await _load();
    } finally {
      if (mounted) {
        setState(() => _savingConfigs = false);
      }
    }
  }

  List<Widget> _buildConfigSections(bool isLight) {
    final groups = <String, List<SystemConfigSchema>>{};
    for (final schema in _configSchemas) {
      groups.putIfAbsent(schema.group, () => []).add(schema);
    }
    return [
      for (final entry in groups.entries) ...[
        _SectionTitle(entry.key),
        const SizedBox(height: 8),
        _Card(
          isLight: isLight,
          child: Column(
            children: [
              for (var index = 0; index < entry.value.length; index++) ...[
                _buildConfigControl(entry.value[index], isLight),
                if (index < entry.value.length - 1) const Divider(height: 24),
              ],
            ],
          ),
        ),
        const SizedBox(height: 20),
      ],
    ];
  }

  Widget _buildConfigControl(SystemConfigSchema schema, bool isLight) {
    final details = <String>[
      if (schema.description.trim().isNotEmpty) schema.description.trim(),
      if (schema.defaultValue.isNotEmpty && !schema.isCredential)
        '默认值：${schema.defaultValue}',
      if (!schema.registered) '当前配置未注册',
      if (schema.readonly) '只读',
    ];
    Widget control;
    if (schema.isBool) {
      final enabled = _configValues[schema.key] == 'true' ||
          _configValues[schema.key] == '1';
      control = Row(
        children: [
          Expanded(child: _ConfigLabel(schema: schema, details: details)),
          AppLiquidGlassToggle(
            value: enabled,
            onChanged: schema.readonly
                ? null
                : (value) => setState(
                    () => _configValues[schema.key] = value ? 'true' : 'false',
                  ),
          ),
        ],
      );
    } else if (schema.isEnum) {
      final current = _configValues[schema.key] ?? '';
      final hasCurrent = schema.options.any((option) => option.value == current);
      control = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _ConfigLabel(schema: schema, details: details),
          const SizedBox(height: 6),
          DropdownButtonFormField<String>(
            initialValue: current.isEmpty ? null : current,
            hint: const Text('请选择'),
            items: [
              ...schema.options.map((option) => DropdownMenuItem(
                    value: option.value,
                    child: Text(option.label),
                  )),
              if (current.isNotEmpty && !hasCurrent)
                DropdownMenuItem(
                  value: current,
                  child: Text('$current（当前值）'),
                ),
            ],
            onChanged: schema.readonly
                ? null
                : (value) {
                    if (value != null) {
                      setState(() => _configValues[schema.key] = value);
                    }
                  },
          ),
        ],
      );
    } else {
      control = _ConfigField(
        label: schema.label,
        hint: details.join(' · '),
        controller: _configControllers[schema.key]!,
        isLight: isLight,
        enabled: !schema.readonly,
        keyboardType: schema.isInt ? TextInputType.number : TextInputType.text,
        obscureText: schema.isCredential,
      );
    }
    return control;
  }

  @override
  Widget build(BuildContext context) {
    final isLight = Theme.of(context).brightness == Brightness.light;
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Padding(
        padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top + 12),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => context.pop(),
                    child: const Icon(Icons.arrow_back_ios, size: 20),
                  ),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      '系统设置',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: _loading
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: AppColors.primary,
                      ),
                    )
                  : _loadError != null
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.cloud_off_outlined,
                              size: 44,
                              color: AppColors.red500,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              _loadError!,
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 16),
                            AppLiquidGlassButton(
                              label: '重试',
                              onPressed: _load,
                              performanceMode: true,
                            ),
                          ],
                        ),
                      ),
                    )
                  : RefreshIndicator(
                      color: AppColors.primary,
                      onRefresh: _load,
                      child: ListView(
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
                        children: [
                          // ── Version Info ──
                          if (_versionInfo != null) ...[
                            _SectionTitle('版本信息'),
                            _Card(
                              isLight: isLight,
                              child: Column(
                                children: [
                                  _KVRow(
                                    '版本',
                                    _versionInfo?['version']?.toString() ?? '',
                                    isLight,
                                  ),
                                  const Divider(height: 16),
                                  _KVRow(
                                    'API',
                                    _versionInfo?['api_version']?.toString() ??
                                        '',
                                    isLight,
                                  ),
                                  const Divider(height: 16),
                                  _KVRow(
                                    'Go',
                                    _versionInfo?['go_version']?.toString() ??
                                        '',
                                    isLight,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 12),
                            _SectionTitle('部署与运行时'),
                            _Card(
                              isLight: isLight,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _KVRow(
                                    '运行模式',
                                    _panelSettings?['panel_runtime_mode']
                                            ?.toString() ??
                                        '-',
                                    isLight,
                                  ),
                                  const Divider(height: 16),
                                  _KVRow(
                                    '服务管理',
                                    _panelSettings?['panel_service_manager']
                                            ?.toString() ??
                                        '-',
                                    isLight,
                                  ),
                                  const Divider(height: 16),
                                  _KVRow(
                                    '服务名称',
                                    _panelSettings?['panel_service_name']
                                            ?.toString() ??
                                        '-',
                                    isLight,
                                  ),
                                  if (_pythonRuntimes.isNotEmpty) ...[
                                    const Divider(height: 16),
                                    Text(
                                      'Python 运行时',
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: isLight
                                            ? AppColors.slate500
                                            : AppColors.slate400,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Wrap(
                                      spacing: 8,
                                      runSpacing: 8,
                                      children: _pythonRuntimes.map((runtime) {
                                        final isDefault = runtime.version ==
                                                _pythonDefaultVersion ||
                                            runtime.isDefault;
                                        return Chip(
                                          label: Text(
                                            '${runtime.label}${isDefault ? '（默认）' : ''}',
                                          ),
                                          avatar: Icon(
                                            runtime.available
                                                ? Icons.check_circle_outline
                                                : Icons.error_outline,
                                            size: 16,
                                            color: runtime.available
                                                ? AppColors.primary
                                                : AppColors.red500,
                                          ),
                                          visualDensity: VisualDensity.compact,
                                        );
                                      }).toList(),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            const SizedBox(height: 8),
                            SizedBox(
                              height: 40,
                              child: OutlinedButton.icon(
                                onPressed: _checking ? null : _checkUpdate,
                                icon: _checking
                                    ? const SizedBox(
                                        width: 14,
                                        height: 14,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                        ),
                                      )
                                    : const Icon(Icons.system_update, size: 16),
                                label: Text(
                                  _checking ? '检查中...' : '检查更新',
                                  style: const TextStyle(fontSize: 13),
                                ),
                              ),
                            ),
                            if (_updateInfo != null) ...[
                              const SizedBox(height: 10),
                              _Card(
                                isLight: isLight,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _updateInfo?['has_update'] == true
                                          ? '发现新版本：${_updateInfo?['latest'] ?? '-'}'
                                          : '当前已是最新版本',
                                      style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    if (_buildUpdateSummary().trim().isNotEmpty) ...[
                                      const SizedBox(height: 8),
                                      Text(
                                        _buildUpdateSummary(),
                                        style: TextStyle(
                                          fontSize: 12,
                                          height: 1.6,
                                          color: isLight
                                              ? AppColors.slate600
                                              : AppColors.slate300,
                                        ),
                                      ),
                                    ],
                                    if (_updateInfo?['has_update'] == true &&
                                        _updateInfo?['auto_update_supported'] ==
                                            true) ...[
                                      const SizedBox(height: 12),
                                      SizedBox(
                                        width: double.infinity,
                                        height: 42,
                                        child: FilledButton(
                                          onPressed: _updatingPanel
                                              ? null
                                              : _doUpdate,
                                          child: Text(
                                            _updatingPanel
                                                ? '处理中...'
                                                : _updateActionLabel(),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ],
                          ],

                          const SizedBox(height: 20),

                          if (_updateStatus != null &&
                              (_updateStatus?['status']?.toString().trim().isNotEmpty ??
                                  false) &&
                              _updateStatus?['status'] != 'idle') ...[
                            _SectionTitle('更新状态'),
                            const SizedBox(height: 8),
                            _Card(
                              isLight: isLight,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '状态：${_updateStatus?['status'] ?? '-'}',
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    _updateStatus?['message']?.toString() ?? '暂无状态说明',
                                    style: TextStyle(
                                      fontSize: 12,
                                      height: 1.6,
                                      color: isLight
                                          ? AppColors.slate600
                                          : AppColors.slate300,
                                    ),
                                  ),
                                  if ((_updateStatus?['phase']?.toString() ?? '')
                                      .trim()
                                      .isNotEmpty) ...[
                                    const SizedBox(height: 6),
                                    Text(
                                      '阶段：${_updateStatus?['phase']}',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: isLight
                                            ? AppColors.slate500
                                            : AppColors.slate400,
                                      ),
                                    ),
                                  ],
                                  const SizedBox(height: 12),
                                  SizedBox(
                                    width: double.infinity,
                                    height: 40,
                                    child: OutlinedButton.icon(
                                      onPressed: _loadUpdateStatus,
                                      icon: const Icon(
                                        Icons.refresh_rounded,
                                        size: 18,
                                      ),
                                      label: const Text('刷新更新状态'),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 20),
                          ],

                          ..._buildConfigSections(isLight),

                          const SizedBox(height: 16),
                          SizedBox(
                            width: double.infinity,
                            height: 44,
                            child: FilledButton(
                              onPressed: _savingConfigs
                                  ? null
                                  : _saveTaskConfigs,
                              child: Text(_savingConfigs ? '保存中...' : '保存配置'),
                            ),
                          ),

                          const SizedBox(height: 24),

                          // ── 系统操作 ──
                          _SectionTitle('系统操作'),
                          const SizedBox(height: 8),
                          _ActionBtn(
                            icon: Icons.backup,
                            title: '备份恢复',
                            subtitle: '创建备份、恢复、管理备份文件',
                            isLight: isLight,
                            onTap: () => context.push('/backup'),
                          ),
                          const SizedBox(height: 8),
                          _ActionBtn(
                            icon: Icons.article_outlined,
                            title: '面板日志',
                            subtitle: '查看面板运行日志，支持级别与关键字筛选',
                            isLight: isLight,
                            onTap: () => context.push('/panel-log'),
                          ),
                          const SizedBox(height: 8),
                          _ActionBtn(
                            icon: Icons.restart_alt,
                            title: '重启面板',
                            subtitle: '重启面板服务，运行中任务将中断',
                            isLight: isLight,
                            onTap: _restart,
                            danger: true,
                          ),
                        ],
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 2, bottom: 4),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

class _Card extends ConsumerWidget {
  final bool isLight;
  final Widget child;
  const _Card({required this.isLight, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AppCard(
      stableForScrolling: true,
      padding: const EdgeInsets.all(16),
      child: child,
    );
  }
}

class _KVRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isLight;
  const _KVRow(this.label, this.value, this.isLight);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            color: isLight ? AppColors.slate500 : AppColors.slate400,
          ),
        ),
        const Spacer(),
        Text(
          value,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
        ),
      ],
    );
  }
}

class _ConfigField extends StatelessWidget {
  final String label;
  final String hint;
  final TextEditingController controller;
  final bool isLight;
  final bool enabled;
  final TextInputType keyboardType;
  final bool obscureText;

  const _ConfigField({
    required this.label,
    required this.hint,
    required this.controller,
    required this.isLight,
    this.enabled = true,
    this.keyboardType = TextInputType.text,
    this.obscureText = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          enabled: enabled,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(
              fontSize: 11,
              color: isLight ? AppColors.slate400 : AppColors.slate500,
            ),
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 10,
            ),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          ),
          style: const TextStyle(fontSize: 13),
          keyboardType: keyboardType,
          obscureText: obscureText,
          enableSuggestions: !obscureText,
          autocorrect: !obscureText,
        ),
        const SizedBox(height: 2),
        Text(
          hint,
          style: TextStyle(
            fontSize: 10,
            color: isLight ? AppColors.slate400 : AppColors.slate500,
          ),
        ),
      ],
    );
  }
}

class _ConfigLabel extends StatelessWidget {
  final SystemConfigSchema schema;
  final List<String> details;

  const _ConfigLabel({required this.schema, required this.details});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          schema.label,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
        ),
        if (details.isNotEmpty) ...[
          const SizedBox(height: 3),
          Text(
            details.join(' · '),
            style: TextStyle(
              fontSize: 10,
              height: 1.4,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ],
    );
  }
}

class _ActionBtn extends ConsumerWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool isLight;
  final VoidCallback onTap;
  final bool danger;

  const _ActionBtn({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.isLight,
    required this.onTap,
    this.danger = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AppLiquidGlassSurface(
      onTap: onTap,
      borderRadius: 12,
      performanceMode: true,
      accentColor: danger ? AppColors.red500 : AppColors.primary,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          Icon(
            icon,
            size: 20,
            color: danger ? AppColors.red500 : AppColors.primary,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: danger ? AppColors.red500 : null,
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 11,
                    color: isLight ? AppColors.slate500 : AppColors.slate400,
                  ),
                ),
              ],
            ),
          ),
          Icon(
            Icons.chevron_right,
            size: 18,
            color: isLight ? AppColors.slate400 : AppColors.slate600,
          ),
        ],
      ),
    );
  }
}
