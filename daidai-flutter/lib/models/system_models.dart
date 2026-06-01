import 'package:json_annotation/json_annotation.dart';

part 'system_models.g.dart';

@JsonSerializable()
class SystemInfoResponse {
  final SystemInfo? data;

  SystemInfoResponse({this.data});

  factory SystemInfoResponse.fromJson(Map<String, dynamic> json) =>
      _$SystemInfoResponseFromJson(json);

  Map<String, dynamic> toJson() => _$SystemInfoResponseToJson(this);
}

@JsonSerializable()
class SystemInfo {
  final String? hostname;
  @JsonKey(name: 'machine_code')
  final String? machineCode;
  @JsonKey(name: 'cpu_usage')
  final double? cpuUsage;
  @JsonKey(name: 'memory_total')
  final int? memoryTotal;
  @JsonKey(name: 'memory_used')
  final int? memoryUsed;
  @JsonKey(name: 'memory_free')
  final int? memoryFree;
  @JsonKey(name: 'memory_usage')
  final double? memoryUsage;
  @JsonKey(name: 'disk_total')
  final int? diskTotal;
  @JsonKey(name: 'disk_used')
  final int? diskUsed;
  @JsonKey(name: 'disk_free')
  final int? diskFree;
  @JsonKey(name: 'disk_usage')
  final double? diskUsage;
  final String? uptime;
  final int? goroutines;
  @JsonKey(name: 'go_version')
  final String? goVersion;
  final String? os;
  final String? arch;
  @JsonKey(name: 'num_cpu')
  final int? numCpu;
  @JsonKey(name: 'data_dir')
  final String? dataDir;
  @JsonKey(name: 'net_rx_bytes')
  final int? netRxBytes;
  @JsonKey(name: 'net_tx_bytes')
  final int? netTxBytes;
  @JsonKey(name: 'net_rx_speed')
  final int? netRxSpeed;
  @JsonKey(name: 'net_tx_speed')
  final int? netTxSpeed;

  SystemInfo({
    this.hostname,
    this.machineCode,
    this.cpuUsage,
    this.memoryTotal,
    this.memoryUsed,
    this.memoryFree,
    this.memoryUsage,
    this.diskTotal,
    this.diskUsed,
    this.diskFree,
    this.diskUsage,
    this.uptime,
    this.goroutines,
    this.goVersion,
    this.os,
    this.arch,
    this.numCpu,
    this.dataDir,
    this.netRxBytes,
    this.netTxBytes,
    this.netRxSpeed,
    this.netTxSpeed,
  });

  factory SystemInfo.fromJson(Map<String, dynamic> json) =>
      _$SystemInfoFromJson(json);

  Map<String, dynamic> toJson() => _$SystemInfoToJson(this);
}

@JsonSerializable()
class HealthResponse {
  final HealthData? data;

  HealthResponse({this.data});

  factory HealthResponse.fromJson(Map<String, dynamic> json) =>
      _$HealthResponseFromJson(json);

  Map<String, dynamic> toJson() => _$HealthResponseToJson(this);
}

@JsonSerializable()
class HealthData {
  final String status;

  HealthData({required this.status});

  factory HealthData.fromJson(Map<String, dynamic> json) =>
      _$HealthDataFromJson(json);

  Map<String, dynamic> toJson() => _$HealthDataToJson(this);
}

@JsonSerializable()
class MachineCodeResponse {
  final MachineCodeData? data;

  MachineCodeResponse({this.data});

  factory MachineCodeResponse.fromJson(Map<String, dynamic> json) =>
      _$MachineCodeResponseFromJson(json);

  Map<String, dynamic> toJson() => _$MachineCodeResponseToJson(this);
}

@JsonSerializable()
class MachineCodeData {
  @JsonKey(name: 'machine_code')
  final String? machineCode;

  MachineCodeData({this.machineCode});

  factory MachineCodeData.fromJson(Map<String, dynamic> json) =>
      _$MachineCodeDataFromJson(json);

  Map<String, dynamic> toJson() => _$MachineCodeDataToJson(this);
}

@JsonSerializable()
class VersionResponse {
  final VersionData? data;

  VersionResponse({this.data});

  factory VersionResponse.fromJson(Map<String, dynamic> json) =>
      _$VersionResponseFromJson(json);

  Map<String, dynamic> toJson() => _$VersionResponseToJson(this);
}

@JsonSerializable()
class VersionData {
  final String? version;
  @JsonKey(name: 'api_version')
  final String? apiVersion;
  final String? framework;

  VersionData({
    this.version,
    this.apiVersion,
    this.framework,
  });

  factory VersionData.fromJson(Map<String, dynamic> json) =>
      _$VersionDataFromJson(json);

  Map<String, dynamic> toJson() => _$VersionDataToJson(this);
}

@JsonSerializable()
class CheckUpdateResponse {
  final CheckUpdateData? data;

  CheckUpdateResponse({this.data});

  factory CheckUpdateResponse.fromJson(Map<String, dynamic> json) =>
      _$CheckUpdateResponseFromJson(json);

  Map<String, dynamic> toJson() => _$CheckUpdateResponseToJson(this);
}

@JsonSerializable()
class CheckUpdateData {
  @JsonKey(name: 'has_update')
  final bool? hasUpdate;
  @JsonKey(name: 'latest_version')
  final String? latestVersion;
  @JsonKey(name: 'current_version')
  final String? currentVersion;
  final String? changelog;

  CheckUpdateData({
    this.hasUpdate,
    this.latestVersion,
    this.currentVersion,
    this.changelog,
  });

  factory CheckUpdateData.fromJson(Map<String, dynamic> json) =>
      _$CheckUpdateDataFromJson(json);

  Map<String, dynamic> toJson() => _$CheckUpdateDataToJson(this);
}

@JsonSerializable()
class HealthCheckResponse {
  final List<HealthCheckItem>? items;
  @JsonKey(name: 'last_checked_at')
  final String? lastCheckedAt;

  HealthCheckResponse({
    this.items,
    this.lastCheckedAt,
  });

  factory HealthCheckResponse.fromJson(Map<String, dynamic> json) =>
      _$HealthCheckResponseFromJson(json);

  Map<String, dynamic> toJson() => _$HealthCheckResponseToJson(this);
}

@JsonSerializable()
class HealthCheckItem {
  final String name;
  final String status;
  final String? message;

  HealthCheckItem({
    required this.name,
    required this.status,
    this.message,
  });

  factory HealthCheckItem.fromJson(Map<String, dynamic> json) =>
      _$HealthCheckItemFromJson(json);

  Map<String, dynamic> toJson() => _$HealthCheckItemToJson(this);
}

@JsonSerializable()
class DashboardResponse {
  final DashboardData? data;

  DashboardResponse({this.data});

  factory DashboardResponse.fromJson(Map<String, dynamic> json) =>
      _$DashboardResponseFromJson(json);

  Map<String, dynamic> toJson() => _$DashboardResponseToJson(this);
}

@JsonSerializable()
class DashboardData {
  @JsonKey(name: 'task_count')
  final int taskCount;
  @JsonKey(name: 'enabled_tasks')
  final int enabledTasks;
  @JsonKey(name: 'running_tasks')
  final int runningTasks;
  @JsonKey(name: 'today_logs')
  final int todayLogs;
  @JsonKey(name: 'success_logs')
  final int successLogs;
  @JsonKey(name: 'failed_logs')
  final int failedLogs;
  @JsonKey(name: 'env_count')
  final int envCount;
  @JsonKey(name: 'recent_logs')
  final List<TaskLog>? recentLogs;
  @JsonKey(name: 'daily_stats')
  final List<DailyStat>? dailyStats;
  @JsonKey(name: 'prev_task_count')
  final int? prevTaskCount;
  @JsonKey(name: 'range_days')
  final int? rangeDays;
  @JsonKey(name: 'sub_count')
  final int? subCount;
  @JsonKey(name: 'yesterday_logs')
  final int? yesterdayLogs;
  @JsonKey(name: 'yesterday_success')
  final int? yesterdaySuccess;

  DashboardData({
    required this.taskCount,
    required this.enabledTasks,
    required this.runningTasks,
    required this.todayLogs,
    required this.successLogs,
    required this.failedLogs,
    required this.envCount,
    this.recentLogs,
    this.dailyStats,
    this.prevTaskCount,
    this.rangeDays,
    this.subCount,
    this.yesterdayLogs,
    this.yesterdaySuccess,
  });

  factory DashboardData.fromJson(Map<String, dynamic> json) =>
      _$DashboardDataFromJson(json);

  Map<String, dynamic> toJson() => _$DashboardDataToJson(this);
}

@JsonSerializable()
class TaskLog {
  final int id;
  @JsonKey(name: 'task_id')
  final int taskId;
  @JsonKey(name: 'task_name')
  final String? taskName;
  @JsonKey(name: 'task_type')
  final String? taskType;
  final int? status;
  final String? content;
  final String? output;
  @JsonKey(name: 'started_at')
  final String startedAt;
  @JsonKey(name: 'ended_at')
  final String? endedAt;
  @JsonKey(name: 'finished_at')
  final String? finishedAt;
  final double? duration;
  @JsonKey(name: 'log_path')
  final String? logPath;
  final List<String>? labels;
  final LogTask? task;
  @JsonKey(name: 'created_at')
  final String? createdAt;
  @JsonKey(name: 'updated_at')
  final String? updatedAt;

  TaskLog({
    required this.id,
    required this.taskId,
    this.taskName,
    this.taskType,
    this.status,
    this.content,
    this.output,
    required this.startedAt,
    this.endedAt,
    this.finishedAt,
    this.duration,
    this.logPath,
    this.labels,
    this.task,
    this.createdAt,
    this.updatedAt,
  });

  factory TaskLog.fromJson(Map<String, dynamic> json) =>
      _$TaskLogFromJson(json);

  Map<String, dynamic> toJson() => _$TaskLogToJson(this);
}

@JsonSerializable()
class LogTask {
  final List<String>? labels;
  @JsonKey(name: 'task_type')
  final String? taskType;

  LogTask({
    this.labels,
    this.taskType,
  });

  factory LogTask.fromJson(Map<String, dynamic> json) =>
      _$LogTaskFromJson(json);

  Map<String, dynamic> toJson() => _$LogTaskToJson(this);
}

@JsonSerializable()
class DailyStat {
  final String date;
  final int success;
  final int failed;

  DailyStat({
    required this.date,
    required this.success,
    required this.failed,
  });

  factory DailyStat.fromJson(Map<String, dynamic> json) =>
      _$DailyStatFromJson(json);

  Map<String, dynamic> toJson() => _$DailyStatToJson(this);
}

@JsonSerializable()
class StatsResponse {
  final StatsData? data;

  StatsResponse({this.data});

  factory StatsResponse.fromJson(Map<String, dynamic> json) =>
      _$StatsResponseFromJson(json);

  Map<String, dynamic> toJson() => _$StatsResponseToJson(this);
}

@JsonSerializable()
class StatsData {
  final TaskStats tasks;
  final LogStats logs;
  final ScriptStats scripts;

  StatsData({
    required this.tasks,
    required this.logs,
    required this.scripts,
  });

  factory StatsData.fromJson(Map<String, dynamic> json) =>
      _$StatsDataFromJson(json);

  Map<String, dynamic> toJson() => _$StatsDataToJson(this);
}

@JsonSerializable()
class TaskStats {
  final int total;
  final int enabled;
  final int disabled;
  final int running;

  TaskStats({
    required this.total,
    required this.enabled,
    required this.disabled,
    required this.running,
  });

  factory TaskStats.fromJson(Map<String, dynamic> json) =>
      _$TaskStatsFromJson(json);

  Map<String, dynamic> toJson() => _$TaskStatsToJson(this);
}

@JsonSerializable()
class LogStats {
  final int total;
  final int success;
  final int failed;
  @JsonKey(name: 'success_rate')
  final double successRate;

  LogStats({
    required this.total,
    required this.success,
    required this.failed,
    required this.successRate,
  });

  factory LogStats.fromJson(Map<String, dynamic> json) =>
      _$LogStatsFromJson(json);

  Map<String, dynamic> toJson() => _$LogStatsToJson(this);
}

@JsonSerializable()
class ScriptStats {
  final int total;

  ScriptStats({required this.total});

  factory ScriptStats.fromJson(Map<String, dynamic> json) =>
      _$ScriptStatsFromJson(json);

  Map<String, dynamic> toJson() => _$ScriptStatsToJson(this);
}

@JsonSerializable()
class PanelLogResponse {
  final PanelLogData? data;

  PanelLogResponse({this.data});

  factory PanelLogResponse.fromJson(Map<String, dynamic> json) =>
      _$PanelLogResponseFromJson(json);

  Map<String, dynamic> toJson() => _$PanelLogResponseToJson(this);
}

@JsonSerializable()
class PanelLogData {
  final List<String>? logs;
  final int total;
  final String? level;

  PanelLogData({
    this.logs,
    required this.total,
    this.level,
  });

  factory PanelLogData.fromJson(Map<String, dynamic> json) =>
      _$PanelLogDataFromJson(json);

  Map<String, dynamic> toJson() => _$PanelLogDataToJson(this);
}

@JsonSerializable()
class BackupResponse {
  final String? message;
  final BackupData? data;

  BackupResponse({
    this.message,
    this.data,
  });

  factory BackupResponse.fromJson(Map<String, dynamic> json) =>
      _$BackupResponseFromJson(json);

  Map<String, dynamic> toJson() => _$BackupResponseToJson(this);
}

@JsonSerializable()
class BackupData {
  final String? filename;

  BackupData({this.filename});

  factory BackupData.fromJson(Map<String, dynamic> json) =>
      _$BackupDataFromJson(json);

  Map<String, dynamic> toJson() => _$BackupDataToJson(this);
}

@JsonSerializable()
class BackupListResponse {
  final List<BackupFile>? data;

  BackupListResponse({this.data});

  factory BackupListResponse.fromJson(Map<String, dynamic> json) =>
      _$BackupListResponseFromJson(json);

  Map<String, dynamic> toJson() => _$BackupListResponseToJson(this);
}

@JsonSerializable()
class BackupFile {
  final String filename;
  final int size;
  @JsonKey(name: 'created_at')
  final String? createdAt;

  BackupFile({
    required this.filename,
    required this.size,
    this.createdAt,
  });

  factory BackupFile.fromJson(Map<String, dynamic> json) =>
      _$BackupFileFromJson(json);

  Map<String, dynamic> toJson() => _$BackupFileToJson(this);
}

@JsonSerializable()
class RestoreBackupRequest {
  final String filename;

  RestoreBackupRequest({required this.filename});

  factory RestoreBackupRequest.fromJson(Map<String, dynamic> json) =>
      _$RestoreBackupRequestFromJson(json);

  Map<String, dynamic> toJson() => _$RestoreBackupRequestToJson(this);
}

@JsonSerializable()
class RestoreProgressResponse {
  final RestoreProgress? data;

  RestoreProgressResponse({this.data});

  factory RestoreProgressResponse.fromJson(Map<String, dynamic> json) =>
      _$RestoreProgressResponseFromJson(json);

  Map<String, dynamic> toJson() => _$RestoreProgressResponseToJson(this);
}

@JsonSerializable()
class RestoreProgress {
  final String? status;
  final int? progress;
  final String? message;

  RestoreProgress({
    this.status,
    this.progress,
    this.message,
  });

  factory RestoreProgress.fromJson(Map<String, dynamic> json) =>
      _$RestoreProgressFromJson(json);

  Map<String, dynamic> toJson() => _$RestoreProgressToJson(this);
}

@JsonSerializable()
class DeleteBackupRequest {
  final String filename;

  DeleteBackupRequest({required this.filename});

  factory DeleteBackupRequest.fromJson(Map<String, dynamic> json) =>
      _$DeleteBackupRequestFromJson(json);

  Map<String, dynamic> toJson() => _$DeleteBackupRequestToJson(this);
}

@JsonSerializable()
class ConfigScriptResponse {
  final ConfigScriptData? data;

  ConfigScriptResponse({this.data});

  factory ConfigScriptResponse.fromJson(Map<String, dynamic> json) =>
      _$ConfigScriptResponseFromJson(json);

  Map<String, dynamic> toJson() => _$ConfigScriptResponseToJson(this);
}

@JsonSerializable()
class ConfigScriptData {
  final String? content;

  ConfigScriptData({this.content});

  factory ConfigScriptData.fromJson(Map<String, dynamic> json) =>
      _$ConfigScriptDataFromJson(json);

  Map<String, dynamic> toJson() => _$ConfigScriptDataToJson(this);
}

@JsonSerializable()
class SaveConfigScriptRequest {
  final String content;

  SaveConfigScriptRequest({required this.content});

  factory SaveConfigScriptRequest.fromJson(Map<String, dynamic> json) =>
      _$SaveConfigScriptRequestFromJson(json);

  Map<String, dynamic> toJson() => _$SaveConfigScriptRequestToJson(this);
}

@JsonSerializable()
class ApiVersionResponse {
  final String? version;
  @JsonKey(name: 'api_version')
  final String? apiVersion;
  final String? framework;

  ApiVersionResponse({
    this.version,
    this.apiVersion,
    this.framework,
  });

  factory ApiVersionResponse.fromJson(Map<String, dynamic> json) =>
      _$ApiVersionResponseFromJson(json);

  Map<String, dynamic> toJson() => _$ApiVersionResponseToJson(this);
}

@JsonSerializable()
class ApiHealthResponse {
  final String? status;

  ApiHealthResponse({this.status});

  factory ApiHealthResponse.fromJson(Map<String, dynamic> json) =>
      _$ApiHealthResponseFromJson(json);

  Map<String, dynamic> toJson() => _$ApiHealthResponseToJson(this);
}

@JsonSerializable()
class PanelSettingsResponse {
  final PanelSettings? data;

  PanelSettingsResponse({this.data});

  factory PanelSettingsResponse.fromJson(Map<String, dynamic> json) =>
      _$PanelSettingsResponseFromJson(json);

  Map<String, dynamic> toJson() => _$PanelSettingsResponseToJson(this);
}

@JsonSerializable()
class PanelSettings {
  final String? title;
  final String? logo;
  final String? theme;

  PanelSettings({
    this.title,
    this.logo,
    this.theme,
  });

  factory PanelSettings.fromJson(Map<String, dynamic> json) =>
      _$PanelSettingsFromJson(json);

  Map<String, dynamic> toJson() => _$PanelSettingsToJson(this);
}

@JsonSerializable()
class PublicVersionResponse {
  final PublicVersionData? data;

  PublicVersionResponse({this.data});

  factory PublicVersionResponse.fromJson(Map<String, dynamic> json) =>
      _$PublicVersionResponseFromJson(json);

  Map<String, dynamic> toJson() => _$PublicVersionResponseToJson(this);
}

@JsonSerializable()
class PublicVersionData {
  final String? version;

  PublicVersionData({this.version});

  factory PublicVersionData.fromJson(Map<String, dynamic> json) =>
      _$PublicVersionDataFromJson(json);

  Map<String, dynamic> toJson() => _$PublicVersionDataToJson(this);
}
