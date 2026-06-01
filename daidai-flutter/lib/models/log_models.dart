import 'package:json_annotation/json_annotation.dart';

part 'log_models.g.dart';

@JsonSerializable()
class LogListResponse {
  final List<TaskLog>? data;
  final int total;
  final int page;
  @JsonKey(name: 'page_size')
  final int pageSize;

  LogListResponse({
    this.data,
    required this.total,
    required this.page,
    required this.pageSize,
  });

  factory LogListResponse.fromJson(Map<String, dynamic> json) =>
      _$LogListResponseFromJson(json);

  Map<String, dynamic> toJson() => _$LogListResponseToJson(this);
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
class LogDetailResponse {
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

  LogDetailResponse({
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

  factory LogDetailResponse.fromJson(Map<String, dynamic> json) =>
      _$LogDetailResponseFromJson(json);

  Map<String, dynamic> toJson() => _$LogDetailResponseToJson(this);
}

@JsonSerializable()
class BatchDeleteLogsRequest {
  final List<int> ids;

  BatchDeleteLogsRequest({required this.ids});

  factory BatchDeleteLogsRequest.fromJson(Map<String, dynamic> json) =>
      _$BatchDeleteLogsRequestFromJson(json);

  Map<String, dynamic> toJson() => _$BatchDeleteLogsRequestToJson(this);
}
