import 'package:json_annotation/json_annotation.dart';

part 'env_models.g.dart';

@JsonSerializable()
class EnvListResponse {
  final List<Env>? data;
  final int total;
  final int page;
  @JsonKey(name: 'page_size')
  final int pageSize;

  EnvListResponse({
    this.data,
    required this.total,
    required this.page,
    required this.pageSize,
  });

  factory EnvListResponse.fromJson(Map<String, dynamic> json) =>
      _$EnvListResponseFromJson(json);

  Map<String, dynamic> toJson() => _$EnvListResponseToJson(this);
}

@JsonSerializable()
class Env {
  final int id;
  final String name;
  final String value;
  final String? remark;
  final String? remarks;
  @JsonKey(name: 'is_enabled')
  final bool isEnabled;
  final bool? enabled;
  final String? group;
  final List<String>? groups;
  final int? position;
  @JsonKey(name: 'sort_order')
  final int? sortOrder;
  @JsonKey(name: 'created_at')
  final String createdAt;
  @JsonKey(name: 'updated_at')
  final String updatedAt;

  Env({
    required this.id,
    required this.name,
    required this.value,
    this.remark,
    this.remarks,
    required this.isEnabled,
    this.enabled,
    this.group,
    this.groups,
    this.position,
    this.sortOrder,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Env.fromJson(Map<String, dynamic> json) => _$EnvFromJson(json);

  Map<String, dynamic> toJson() => _$EnvToJson(this);
}

@JsonSerializable()
class EnvResponse {
  final String? message;
  final Env? data;

  EnvResponse({
    this.message,
    this.data,
  });

  factory EnvResponse.fromJson(Map<String, dynamic> json) =>
      _$EnvResponseFromJson(json);

  Map<String, dynamic> toJson() => _$EnvResponseToJson(this);
}

@JsonSerializable()
class CreateEnvRequest {
  final String name;
  final String value;
  final String? remark;
  @JsonKey(name: 'is_enabled')
  final bool isEnabled;
  final bool? enabled;
  final String? group;

  CreateEnvRequest({
    required this.name,
    required this.value,
    this.remark,
    this.isEnabled = true,
    this.enabled,
    this.group,
  });

  factory CreateEnvRequest.fromJson(Map<String, dynamic> json) =>
      _$CreateEnvRequestFromJson(json);

  Map<String, dynamic> toJson() => _$CreateEnvRequestToJson(this);
}

@JsonSerializable()
class UpdateEnvRequest {
  final String? name;
  final String? value;
  final String? remark;
  final String? remarks;
  @JsonKey(name: 'is_enabled')
  final bool? isEnabled;
  final bool? enabled;
  final String? group;

  UpdateEnvRequest({
    this.name,
    this.value,
    this.remark,
    this.remarks,
    this.isEnabled,
    this.enabled,
    this.group,
  });

  factory UpdateEnvRequest.fromJson(Map<String, dynamic> json) =>
      _$UpdateEnvRequestFromJson(json);

  Map<String, dynamic> toJson() => _$UpdateEnvRequestToJson(this);
}

@JsonSerializable()
class BatchEnvIdsRequest {
  final List<int> ids;

  BatchEnvIdsRequest({required this.ids});

  factory BatchEnvIdsRequest.fromJson(Map<String, dynamic> json) =>
      _$BatchEnvIdsRequestFromJson(json);

  Map<String, dynamic> toJson() => _$BatchEnvIdsRequestToJson(this);
}

@JsonSerializable()
class BatchRenameEnvRequest {
  final List<int> ids;
  final String name;

  BatchRenameEnvRequest({
    required this.ids,
    required this.name,
  });

  factory BatchRenameEnvRequest.fromJson(Map<String, dynamic> json) =>
      _$BatchRenameEnvRequestFromJson(json);

  Map<String, dynamic> toJson() => _$BatchRenameEnvRequestToJson(this);
}

@JsonSerializable()
class BatchSetGroupRequest {
  final List<int> ids;
  final String group;

  BatchSetGroupRequest({
    required this.ids,
    required this.group,
  });

  factory BatchSetGroupRequest.fromJson(Map<String, dynamic> json) =>
      _$BatchSetGroupRequestFromJson(json);

  Map<String, dynamic> toJson() => _$BatchSetGroupRequestToJson(this);
}

@JsonSerializable()
class ExportEnvsResponse {
  final String? data;

  ExportEnvsResponse({this.data});

  factory ExportEnvsResponse.fromJson(Map<String, dynamic> json) =>
      _$ExportEnvsResponseFromJson(json);

  Map<String, dynamic> toJson() => _$ExportEnvsResponseToJson(this);
}

@JsonSerializable()
class SortEnvsRequest {
  final List<int> ids;

  SortEnvsRequest({required this.ids});

  factory SortEnvsRequest.fromJson(Map<String, dynamic> json) =>
      _$SortEnvsRequestFromJson(json);

  Map<String, dynamic> toJson() => _$SortEnvsRequestToJson(this);
}

@JsonSerializable()
class EnvGroupsResponse {
  final List<String>? data;

  EnvGroupsResponse({this.data});

  factory EnvGroupsResponse.fromJson(Map<String, dynamic> json) =>
      _$EnvGroupsResponseFromJson(json);

  Map<String, dynamic> toJson() => _$EnvGroupsResponseToJson(this);
}

@JsonSerializable()
class ImportEnvsRequest {
  final String data;

  ImportEnvsRequest({required this.data});

  factory ImportEnvsRequest.fromJson(Map<String, dynamic> json) =>
      _$ImportEnvsRequestFromJson(json);

  Map<String, dynamic> toJson() => _$ImportEnvsRequestToJson(this);
}
