import 'package:json_annotation/json_annotation.dart';

part 'task_models.g.dart';

@JsonSerializable()
class TaskListResponse {
  final List<Task>? data;
  final int total;
  final int page;
  @JsonKey(name: 'page_size')
  final int pageSize;

  TaskListResponse({
    this.data,
    required this.total,
    required this.page,
    required this.pageSize,
  });

  factory TaskListResponse.fromJson(Map<String, dynamic> json) =>
      _$TaskListResponseFromJson(json);

  Map<String, dynamic> toJson() => _$TaskListResponseToJson(this);
}

@JsonSerializable()
class Task {
  static const double statusDisabled = 0.0;
  static const double statusQueued = 0.5;
  static const double statusEnabled = 1.0;
  static const double statusRunning = 2.0;

  final int id;
  final String name;
  final String command;
  @JsonKey(name: 'cron_expression')
  final String? cronExpression;
  @JsonKey(name: 'cron_expressions')
  final List<String>? cronExpressions;
  @JsonKey(name: 'task_type')
  final String? taskType;
  final double status;
  @JsonKey(name: 'is_pinned')
  final bool isPinned;
  @JsonKey(name: 'last_run_at')
  final String? lastRunAt;
  @JsonKey(name: 'last_run_status')
  final int? lastRunStatus;
  @JsonKey(name: 'last_running_time')
  final String? lastRunningTime;
  @JsonKey(name: 'created_at')
  final String createdAt;
  @JsonKey(name: 'updated_at')
  final String updatedAt;
  @JsonKey(name: 'next_run_at')
  final String? nextRunAt;
  @JsonKey(name: 'log_path')
  final String? logPath;
  @JsonKey(name: 'allow_multiple_instances')
  final bool? allowMultipleInstances;
  @JsonKey(name: 'depends_on')
  final String? dependsOn;
  final List<String>? labels;
  @JsonKey(name: 'display_labels')
  final List<String>? displayLabels;
  @JsonKey(name: 'max_retries')
  final int? maxRetries;
  @JsonKey(name: 'notification_channel_id')
  final int? notificationChannelId;
  @JsonKey(name: 'notify_on_failure')
  final bool? notifyOnFailure;
  @JsonKey(name: 'notify_on_success')
  final bool? notifyOnSuccess;
  final int? pid;
  @JsonKey(name: 'random_delay_seconds')
  final int? randomDelaySeconds;
  @JsonKey(name: 'retry_interval')
  final int? retryInterval;
  @JsonKey(name: 'sort_order')
  final int? sortOrder;
  @JsonKey(name: 'stop_schedule')
  final String? stopSchedule;
  @JsonKey(name: 'task_after')
  final String? taskAfter;
  @JsonKey(name: 'task_before')
  final String? taskBefore;
  final int? timeout;

  Task({
    required this.id,
    required this.name,
    required this.command,
    this.cronExpression,
    this.cronExpressions,
    this.taskType,
    required this.status,
    required this.isPinned,
    this.lastRunAt,
    this.lastRunStatus,
    this.lastRunningTime,
    required this.createdAt,
    required this.updatedAt,
    this.nextRunAt,
    this.logPath,
    this.allowMultipleInstances,
    this.dependsOn,
    this.labels,
    this.displayLabels,
    this.maxRetries,
    this.notificationChannelId,
    this.notifyOnFailure,
    this.notifyOnSuccess,
    this.pid,
    this.randomDelaySeconds,
    this.retryInterval,
    this.sortOrder,
    this.stopSchedule,
    this.taskAfter,
    this.taskBefore,
    this.timeout,
  });

  factory Task.fromJson(Map<String, dynamic> json) => _$TaskFromJson(json);

  Map<String, dynamic> toJson() => _$TaskToJson(this);

  String get statusText {
    switch (status) {
      case statusDisabled:
        return '已禁用';
      case statusQueued:
        return '排队中';
      case statusEnabled:
        return '已启用';
      case statusRunning:
        return '运行中';
      default:
        return '未知';
    }
  }

  bool get isRunning => status == statusRunning;

  bool get isEnabled =>
      status == statusEnabled ||
      status == statusRunning ||
      status == statusQueued;

  String get schedule => cronExpression ?? '';
}

@JsonSerializable()
class TaskResponse {
  final String? message;
  final Task? data;

  TaskResponse({
    this.message,
    this.data,
  });

  factory TaskResponse.fromJson(Map<String, dynamic> json) =>
      _$TaskResponseFromJson(json);

  Map<String, dynamic> toJson() => _$TaskResponseToJson(this);
}

@JsonSerializable()
class CreateTaskRequest {
  final String name;
  final String command;
  @JsonKey(name: 'cron_expression')
  final String cronExpression;
  @JsonKey(name: 'task_type')
  final String taskType;

  CreateTaskRequest({
    required this.name,
    required this.command,
    required this.cronExpression,
    this.taskType = 'cron',
  });

  factory CreateTaskRequest.fromJson(Map<String, dynamic> json) =>
      _$CreateTaskRequestFromJson(json);

  Map<String, dynamic> toJson() => _$CreateTaskRequestToJson(this);
}

@JsonSerializable()
class UpdateTaskRequest {
  final String? name;
  final String? command;
  @JsonKey(name: 'cron_expression')
  final String? cronExpression;
  @JsonKey(name: 'is_enabled')
  final bool? isEnabled;
  @JsonKey(name: 'task_type')
  final String? taskType;
  final double? status;
  @JsonKey(name: 'is_pinned')
  final bool? isPinned;
  @JsonKey(name: 'allow_multiple_instances')
  final bool? allowMultipleInstances;
  @JsonKey(name: 'depends_on')
  final String? dependsOn;
  final List<String>? labels;
  @JsonKey(name: 'max_retries')
  final int? maxRetries;
  @JsonKey(name: 'notification_channel_id')
  final int? notificationChannelId;
  @JsonKey(name: 'notify_on_failure')
  final bool? notifyOnFailure;
  @JsonKey(name: 'notify_on_success')
  final bool? notifyOnSuccess;
  @JsonKey(name: 'random_delay_seconds')
  final int? randomDelaySeconds;
  @JsonKey(name: 'retry_interval')
  final int? retryInterval;
  @JsonKey(name: 'sort_order')
  final int? sortOrder;
  @JsonKey(name: 'stop_schedule')
  final String? stopSchedule;
  @JsonKey(name: 'task_after')
  final String? taskAfter;
  @JsonKey(name: 'task_before')
  final String? taskBefore;
  final int? timeout;

  UpdateTaskRequest({
    this.name,
    this.command,
    this.cronExpression,
    this.isEnabled,
    this.taskType,
    this.status,
    this.isPinned,
    this.allowMultipleInstances,
    this.dependsOn,
    this.labels,
    this.maxRetries,
    this.notificationChannelId,
    this.notifyOnFailure,
    this.notifyOnSuccess,
    this.randomDelaySeconds,
    this.retryInterval,
    this.sortOrder,
    this.stopSchedule,
    this.taskAfter,
    this.taskBefore,
    this.timeout,
  });

  factory UpdateTaskRequest.fromJson(Map<String, dynamic> json) =>
      _$UpdateTaskRequestFromJson(json);

  Map<String, dynamic> toJson() => _$UpdateTaskRequestToJson(this);
}

@JsonSerializable()
class BatchTaskRequest {
  final List<int> ids;
  final Map<String, dynamic> task;

  BatchTaskRequest({
    required this.ids,
    required this.task,
  });

  factory BatchTaskRequest.fromJson(Map<String, dynamic> json) =>
      _$BatchTaskRequestFromJson(json);

  Map<String, dynamic> toJson() => _$BatchTaskRequestToJson(this);
}

@JsonSerializable()
class BatchTaskIdsRequest {
  final List<int> ids;

  BatchTaskIdsRequest({required this.ids});

  factory BatchTaskIdsRequest.fromJson(Map<String, dynamic> json) =>
      _$BatchTaskIdsRequestFromJson(json);

  Map<String, dynamic> toJson() => _$BatchTaskIdsRequestToJson(this);
}

@JsonSerializable()
class ImportTasksRequest {
  final String data;

  ImportTasksRequest({required this.data});

  factory ImportTasksRequest.fromJson(Map<String, dynamic> json) =>
      _$ImportTasksRequestFromJson(json);

  Map<String, dynamic> toJson() => _$ImportTasksRequestToJson(this);
}

@JsonSerializable()
class ImportTasksResponse {
  final String? message;
  @JsonKey(name: 'imported_count')
  final int? importedCount;

  ImportTasksResponse({
    this.message,
    this.importedCount,
  });

  factory ImportTasksResponse.fromJson(Map<String, dynamic> json) =>
      _$ImportTasksResponseFromJson(json);

  Map<String, dynamic> toJson() => _$ImportTasksResponseToJson(this);
}

@JsonSerializable()
class ExportTasksResponse {
  final String? data;

  ExportTasksResponse({this.data});

  factory ExportTasksResponse.fromJson(Map<String, dynamic> json) =>
      _$ExportTasksResponseFromJson(json);

  Map<String, dynamic> toJson() => _$ExportTasksResponseToJson(this);
}

@JsonSerializable()
class CronParseRequest {
  @JsonKey(name: 'cron_expression')
  final String cronExpression;

  CronParseRequest({required this.cronExpression});

  factory CronParseRequest.fromJson(Map<String, dynamic> json) =>
      _$CronParseRequestFromJson(json);

  Map<String, dynamic> toJson() => _$CronParseRequestToJson(this);
}

@JsonSerializable()
class CronParseResponse {
  final CronParseData? data;

  CronParseResponse({this.data});

  factory CronParseResponse.fromJson(Map<String, dynamic> json) =>
      _$CronParseResponseFromJson(json);

  Map<String, dynamic> toJson() => _$CronParseResponseToJson(this);
}

@JsonSerializable()
class CronParseData {
  @JsonKey(name: 'next_runs')
  final List<String>? nextRuns;
  final String? description;

  CronParseData({
    this.nextRuns,
    this.description,
  });

  factory CronParseData.fromJson(Map<String, dynamic> json) =>
      _$CronParseDataFromJson(json);

  Map<String, dynamic> toJson() => _$CronParseDataToJson(this);
}

@JsonSerializable()
class CronTemplatesResponse {
  final List<CronTemplate>? data;

  CronTemplatesResponse({this.data});

  factory CronTemplatesResponse.fromJson(Map<String, dynamic> json) =>
      _$CronTemplatesResponseFromJson(json);

  Map<String, dynamic> toJson() => _$CronTemplatesResponseToJson(this);
}

@JsonSerializable()
class CronTemplate {
  final String name;
  final String expression;
  final String? description;

  CronTemplate({
    required this.name,
    required this.expression,
    this.description,
  });

  factory CronTemplate.fromJson(Map<String, dynamic> json) =>
      _$CronTemplateFromJson(json);

  Map<String, dynamic> toJson() => _$CronTemplateToJson(this);
}

@JsonSerializable()
class NotificationChannelsResponse {
  final List<NotificationChannel>? data;

  NotificationChannelsResponse({this.data});

  factory NotificationChannelsResponse.fromJson(Map<String, dynamic> json) =>
      _$NotificationChannelsResponseFromJson(json);

  Map<String, dynamic> toJson() => _$NotificationChannelsResponseToJson(this);
}

@JsonSerializable()
class NotificationChannel {
  final int id;
  final String name;
  final String type;

  NotificationChannel({
    required this.id,
    required this.name,
    required this.type,
  });

  factory NotificationChannel.fromJson(Map<String, dynamic> json) =>
      _$NotificationChannelFromJson(json);

  Map<String, dynamic> toJson() => _$NotificationChannelToJson(this);
}

@JsonSerializable()
class TaskLatestLogResponse {
  final TaskLog? data;

  TaskLatestLogResponse({this.data});

  factory TaskLatestLogResponse.fromJson(Map<String, dynamic> json) =>
      _$TaskLatestLogResponseFromJson(json);

  Map<String, dynamic> toJson() => _$TaskLatestLogResponseToJson(this);
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
class TaskStatsResponse {
  final TaskStatsDetail? data;

  TaskStatsResponse({this.data});

  factory TaskStatsResponse.fromJson(Map<String, dynamic> json) =>
      _$TaskStatsResponseFromJson(json);

  Map<String, dynamic> toJson() => _$TaskStatsResponseToJson(this);
}

@JsonSerializable()
class TaskStatsDetail {
  @JsonKey(name: 'total_runs')
  final int? totalRuns;
  @JsonKey(name: 'success_runs')
  final int? successRuns;
  @JsonKey(name: 'failed_runs')
  final int? failedRuns;
  @JsonKey(name: 'avg_duration')
  final double? avgDuration;

  TaskStatsDetail({
    this.totalRuns,
    this.successRuns,
    this.failedRuns,
    this.avgDuration,
  });

  factory TaskStatsDetail.fromJson(Map<String, dynamic> json) =>
      _$TaskStatsDetailFromJson(json);

  Map<String, dynamic> toJson() => _$TaskStatsDetailToJson(this);
}

@JsonSerializable()
class TaskLogFilesResponse {
  final List<TaskLogFile>? data;

  TaskLogFilesResponse({this.data});

  factory TaskLogFilesResponse.fromJson(Map<String, dynamic> json) =>
      _$TaskLogFilesResponseFromJson(json);

  Map<String, dynamic> toJson() => _$TaskLogFilesResponseToJson(this);
}

@JsonSerializable()
class TaskLogFile {
  final String name;
  final int size;
  @JsonKey(name: 'created_at')
  final String? createdAt;

  TaskLogFile({
    required this.name,
    required this.size,
    this.createdAt,
  });

  factory TaskLogFile.fromJson(Map<String, dynamic> json) =>
      _$TaskLogFileFromJson(json);

  Map<String, dynamic> toJson() => _$TaskLogFileToJson(this);
}

@JsonSerializable()
class TaskLogFileContentResponse {
  final TaskLogFileContent? data;

  TaskLogFileContentResponse({this.data});

  factory TaskLogFileContentResponse.fromJson(Map<String, dynamic> json) =>
      _$TaskLogFileContentResponseFromJson(json);

  Map<String, dynamic> toJson() => _$TaskLogFileContentResponseToJson(this);
}

@JsonSerializable()
class TaskLogFileContent {
  final String content;
  final String? name;

  TaskLogFileContent({
    required this.content,
    this.name,
  });

  factory TaskLogFileContent.fromJson(Map<String, dynamic> json) =>
      _$TaskLogFileContentFromJson(json);

  Map<String, dynamic> toJson() => _$TaskLogFileContentToJson(this);
}

@JsonSerializable()
class TaskViewsResponse {
  final List<TaskView>? data;

  TaskViewsResponse({this.data});

  factory TaskViewsResponse.fromJson(Map<String, dynamic> json) =>
      _$TaskViewsResponseFromJson(json);

  Map<String, dynamic> toJson() => _$TaskViewsResponseToJson(this);
}

@JsonSerializable()
class TaskView {
  final String id;
  final String name;
  final Map<String, dynamic>? filter;
  @JsonKey(name: 'sort_order')
  final int? sortOrder;

  TaskView({
    required this.id,
    required this.name,
    this.filter,
    this.sortOrder,
  });

  factory TaskView.fromJson(Map<String, dynamic> json) =>
      _$TaskViewFromJson(json);

  Map<String, dynamic> toJson() => _$TaskViewToJson(this);
}

@JsonSerializable()
class TaskViewResponse {
  final String? message;
  final TaskView? data;

  TaskViewResponse({
    this.message,
    this.data,
  });

  factory TaskViewResponse.fromJson(Map<String, dynamic> json) =>
      _$TaskViewResponseFromJson(json);

  Map<String, dynamic> toJson() => _$TaskViewResponseToJson(this);
}

@JsonSerializable()
class CreateTaskViewRequest {
  final String name;
  final Map<String, dynamic>? filter;

  CreateTaskViewRequest({
    required this.name,
    this.filter,
  });

  factory CreateTaskViewRequest.fromJson(Map<String, dynamic> json) =>
      _$CreateTaskViewRequestFromJson(json);

  Map<String, dynamic> toJson() => _$CreateTaskViewRequestToJson(this);
}

@JsonSerializable()
class UpdateTaskViewRequest {
  final String? name;
  final Map<String, dynamic>? filter;

  UpdateTaskViewRequest({
    this.name,
    this.filter,
  });

  factory UpdateTaskViewRequest.fromJson(Map<String, dynamic> json) =>
      _$UpdateTaskViewRequestFromJson(json);

  Map<String, dynamic> toJson() => _$UpdateTaskViewRequestToJson(this);
}

@JsonSerializable()
class ReorderTaskViewsRequest {
  final List<String> ids;

  ReorderTaskViewsRequest({required this.ids});

  factory ReorderTaskViewsRequest.fromJson(Map<String, dynamic> json) =>
      _$ReorderTaskViewsRequestFromJson(json);

  Map<String, dynamic> toJson() => _$ReorderTaskViewsRequestToJson(this);
}
