import 'package:json_annotation/json_annotation.dart';

part 'script_models.g.dart';

@JsonSerializable()
class ScriptListResponse {
  final List<Script>? data;
  final int total;

  ScriptListResponse({
    this.data,
    required this.total,
  });

  factory ScriptListResponse.fromJson(Map<String, dynamic> json) =>
      _$ScriptListResponseFromJson(json);

  Map<String, dynamic> toJson() => _$ScriptListResponseToJson(this);
}

@JsonSerializable()
class Script {
  final String name;
  final String path;
  final int size;
  @JsonKey(name: 'is_dir')
  final bool isDir;
  @JsonKey(name: 'modified_at')
  final String? modifiedAt;
  final int? mtime;

  Script({
    required this.name,
    required this.path,
    required this.size,
    this.isDir = false,
    this.modifiedAt,
    this.mtime,
  });

  factory Script.fromJson(Map<String, dynamic> json) =>
      _$ScriptFromJson(json);

  Map<String, dynamic> toJson() => _$ScriptToJson(this);
}

@JsonSerializable()
class ScriptTreeResponse {
  final List<ScriptTreeNode>? data;

  ScriptTreeResponse({this.data});

  factory ScriptTreeResponse.fromJson(Map<String, dynamic> json) =>
      _$ScriptTreeResponseFromJson(json);

  Map<String, dynamic> toJson() => _$ScriptTreeResponseToJson(this);
}

@JsonSerializable()
class ScriptTreeNode {
  final String name;
  final String path;
  @JsonKey(name: 'is_dir')
  final bool isDir;
  final List<ScriptTreeNode>? children;

  ScriptTreeNode({
    required this.name,
    required this.path,
    required this.isDir,
    this.children,
  });

  factory ScriptTreeNode.fromJson(Map<String, dynamic> json) =>
      _$ScriptTreeNodeFromJson(json);

  Map<String, dynamic> toJson() => _$ScriptTreeNodeToJson(this);
}

@JsonSerializable()
class ScriptContentResponse {
  final ScriptContent? data;

  ScriptContentResponse({this.data});

  factory ScriptContentResponse.fromJson(Map<String, dynamic> json) =>
      _$ScriptContentResponseFromJson(json);

  Map<String, dynamic> toJson() => _$ScriptContentResponseToJson(this);
}

@JsonSerializable()
class ScriptContent {
  final String content;
  final String? path;
  final bool? binary;
  @JsonKey(name: 'is_binary')
  final bool? isBinary;

  ScriptContent({
    required this.content,
    this.path,
    this.binary,
    this.isBinary,
  });

  factory ScriptContent.fromJson(Map<String, dynamic> json) =>
      _$ScriptContentFromJson(json);

  Map<String, dynamic> toJson() => _$ScriptContentToJson(this);
}

@JsonSerializable()
class SaveScriptRequest {
  final String path;
  final String content;

  SaveScriptRequest({
    required this.path,
    required this.content,
  });

  factory SaveScriptRequest.fromJson(Map<String, dynamic> json) =>
      _$SaveScriptRequestFromJson(json);

  Map<String, dynamic> toJson() => _$SaveScriptRequestToJson(this);
}

@JsonSerializable()
class CreateScriptRequest {
  final String name;
  final String content;
  final String? description;

  CreateScriptRequest({
    required this.name,
    required this.content,
    this.description,
  });

  factory CreateScriptRequest.fromJson(Map<String, dynamic> json) =>
      _$CreateScriptRequestFromJson(json);

  Map<String, dynamic> toJson() => _$CreateScriptRequestToJson(this);
}

@JsonSerializable()
class UpdateScriptRequest {
  final String name;
  final String content;
  final String? description;

  UpdateScriptRequest({
    required this.name,
    required this.content,
    this.description,
  });

  factory UpdateScriptRequest.fromJson(Map<String, dynamic> json) =>
      _$UpdateScriptRequestFromJson(json);

  Map<String, dynamic> toJson() => _$UpdateScriptRequestToJson(this);
}

@JsonSerializable()
class CreateDirectoryRequest {
  final String path;

  CreateDirectoryRequest({required this.path});

  factory CreateDirectoryRequest.fromJson(Map<String, dynamic> json) =>
      _$CreateDirectoryRequestFromJson(json);

  Map<String, dynamic> toJson() => _$CreateDirectoryRequestToJson(this);
}

@JsonSerializable()
class RenameScriptRequest {
  @JsonKey(name: 'old_path')
  final String oldPath;
  @JsonKey(name: 'new_path')
  final String newPath;

  RenameScriptRequest({
    required this.oldPath,
    required this.newPath,
  });

  factory RenameScriptRequest.fromJson(Map<String, dynamic> json) =>
      _$RenameScriptRequestFromJson(json);

  Map<String, dynamic> toJson() => _$RenameScriptRequestToJson(this);
}

@JsonSerializable()
class MoveScriptRequest {
  final String source;
  final String destination;

  MoveScriptRequest({
    required this.source,
    required this.destination,
  });

  factory MoveScriptRequest.fromJson(Map<String, dynamic> json) =>
      _$MoveScriptRequestFromJson(json);

  Map<String, dynamic> toJson() => _$MoveScriptRequestToJson(this);
}

@JsonSerializable()
class CopyScriptRequest {
  final String source;
  final String destination;

  CopyScriptRequest({
    required this.source,
    required this.destination,
  });

  factory CopyScriptRequest.fromJson(Map<String, dynamic> json) =>
      _$CopyScriptRequestFromJson(json);

  Map<String, dynamic> toJson() => _$CopyScriptRequestToJson(this);
}

@JsonSerializable()
class BatchDeleteScriptsRequest {
  final List<String> paths;

  BatchDeleteScriptsRequest({required this.paths});

  factory BatchDeleteScriptsRequest.fromJson(Map<String, dynamic> json) =>
      _$BatchDeleteScriptsRequestFromJson(json);

  Map<String, dynamic> toJson() => _$BatchDeleteScriptsRequestToJson(this);
}

@JsonSerializable()
class ScriptVersionsResponse {
  final List<ScriptVersion>? data;

  ScriptVersionsResponse({this.data});

  factory ScriptVersionsResponse.fromJson(Map<String, dynamic> json) =>
      _$ScriptVersionsResponseFromJson(json);

  Map<String, dynamic> toJson() => _$ScriptVersionsResponseToJson(this);
}

@JsonSerializable()
class ScriptVersion {
  final String id;
  final String path;
  final String? content;
  @JsonKey(name: 'created_at')
  final String? createdAt;

  ScriptVersion({
    required this.id,
    required this.path,
    this.content,
    this.createdAt,
  });

  factory ScriptVersion.fromJson(Map<String, dynamic> json) =>
      _$ScriptVersionFromJson(json);

  Map<String, dynamic> toJson() => _$ScriptVersionToJson(this);
}

@JsonSerializable()
class ScriptVersionResponse {
  final ScriptVersion? data;

  ScriptVersionResponse({this.data});

  factory ScriptVersionResponse.fromJson(Map<String, dynamic> json) =>
      _$ScriptVersionResponseFromJson(json);

  Map<String, dynamic> toJson() => _$ScriptVersionResponseToJson(this);
}

@JsonSerializable()
class RunScriptRequest {
  final String path;
  final List<String>? args;
  final Map<String, String>? env;

  RunScriptRequest({
    required this.path,
    this.args,
    this.env,
  });

  factory RunScriptRequest.fromJson(Map<String, dynamic> json) =>
      _$RunScriptRequestFromJson(json);

  Map<String, dynamic> toJson() => _$RunScriptRequestToJson(this);
}

@JsonSerializable()
class RunCodeRequest {
  final String code;
  final String language;

  RunCodeRequest({
    required this.code,
    this.language = 'javascript',
  });

  factory RunCodeRequest.fromJson(Map<String, dynamic> json) =>
      _$RunCodeRequestFromJson(json);

  Map<String, dynamic> toJson() => _$RunCodeRequestToJson(this);
}

@JsonSerializable()
class RunScriptResponse {
  final RunScriptData? data;

  RunScriptResponse({this.data});

  factory RunScriptResponse.fromJson(Map<String, dynamic> json) =>
      _$RunScriptResponseFromJson(json);

  Map<String, dynamic> toJson() => _$RunScriptResponseToJson(this);
}

@JsonSerializable()
class RunScriptData {
  @JsonKey(name: 'run_id')
  final String? runId;
  final String? message;

  RunScriptData({
    this.runId,
    this.message,
  });

  factory RunScriptData.fromJson(Map<String, dynamic> json) =>
      _$RunScriptDataFromJson(json);

  Map<String, dynamic> toJson() => _$RunScriptDataToJson(this);
}

@JsonSerializable()
class ScriptRunLogsResponse {
  final ScriptRunLogs? data;

  ScriptRunLogsResponse({this.data});

  factory ScriptRunLogsResponse.fromJson(Map<String, dynamic> json) =>
      _$ScriptRunLogsResponseFromJson(json);

  Map<String, dynamic> toJson() => _$ScriptRunLogsResponseToJson(this);
}

@JsonSerializable()
class ScriptRunLogs {
  final String? logs;
  final String? status;
  @JsonKey(name: 'exit_code')
  final int? exitCode;

  ScriptRunLogs({
    this.logs,
    this.status,
    this.exitCode,
  });

  factory ScriptRunLogs.fromJson(Map<String, dynamic> json) =>
      _$ScriptRunLogsFromJson(json);

  Map<String, dynamic> toJson() => _$ScriptRunLogsToJson(this);
}

@JsonSerializable()
class FormatScriptRequest {
  final String content;
  final String language;

  FormatScriptRequest({
    required this.content,
    this.language = 'javascript',
  });

  factory FormatScriptRequest.fromJson(Map<String, dynamic> json) =>
      _$FormatScriptRequestFromJson(json);

  Map<String, dynamic> toJson() => _$FormatScriptRequestToJson(this);
}

@JsonSerializable()
class FormatScriptResponse {
  final FormatScriptData? data;

  FormatScriptResponse({this.data});

  factory FormatScriptResponse.fromJson(Map<String, dynamic> json) =>
      _$FormatScriptResponseFromJson(json);

  Map<String, dynamic> toJson() => _$FormatScriptResponseToJson(this);
}

@JsonSerializable()
class FormatScriptData {
  final String? content;

  FormatScriptData({this.content});

  factory FormatScriptData.fromJson(Map<String, dynamic> json) =>
      _$FormatScriptDataFromJson(json);

  Map<String, dynamic> toJson() => _$FormatScriptDataToJson(this);
}
