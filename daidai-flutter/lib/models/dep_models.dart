import 'package:json_annotation/json_annotation.dart';

part 'dep_models.g.dart';

@JsonSerializable()
class DependencyListResponse {
  final List<Dependency>? data;
  final int total;

  DependencyListResponse({
    this.data,
    required this.total,
  });

  factory DependencyListResponse.fromJson(Map<String, dynamic> json) =>
      _$DependencyListResponseFromJson(json);

  Map<String, dynamic> toJson() => _$DependencyListResponseToJson(this);
}

@JsonSerializable()
class Dependency {
  static const String typeNodejs = 'nodejs';
  static const String typePython = 'python';
  static const String typeLinux = 'linux';

  static const String statusQueued = 'queued';
  static const String statusInstalling = 'installing';
  static const String statusInstalled = 'installed';
  static const String statusFailed = 'failed';
  static const String statusRemoving = 'removing';
  static const String statusCancelled = 'cancelled';

  final int id;
  final String type;
  final String name;
  final String status;
  @JsonKey(name: 'created_at')
  final String createdAt;
  @JsonKey(name: 'updated_at')
  final String updatedAt;

  Dependency({
    required this.id,
    required this.type,
    required this.name,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Dependency.fromJson(Map<String, dynamic> json) =>
      _$DependencyFromJson(json);

  Map<String, dynamic> toJson() => _$DependencyToJson(this);

  String get statusText {
    switch (status) {
      case statusQueued:
        return '排队中';
      case statusInstalling:
        return '安装中';
      case statusInstalled:
        return '已安装';
      case statusFailed:
        return '安装失败';
      case statusRemoving:
        return '卸载中';
      case statusCancelled:
        return '已取消';
      default:
        return '未知';
    }
  }

  String get typeText {
    switch (type) {
      case typeNodejs:
        return 'Node.js';
      case typePython:
        return 'Python';
      case typeLinux:
        return 'Linux';
      default:
        return type;
    }
  }
}

@JsonSerializable()
class DependencyResponse {
  final String? message;
  final Dependency? data;

  DependencyResponse({
    this.message,
    this.data,
  });

  factory DependencyResponse.fromJson(Map<String, dynamic> json) =>
      _$DependencyResponseFromJson(json);

  Map<String, dynamic> toJson() => _$DependencyResponseToJson(this);
}

@JsonSerializable()
class CreateDepRequest {
  final String type;
  final List<String> names;

  CreateDepRequest({
    required this.type,
    required this.names,
  });

  factory CreateDepRequest.fromJson(Map<String, dynamic> json) =>
      _$CreateDepRequestFromJson(json);

  Map<String, dynamic> toJson() => _$CreateDepRequestToJson(this);
}

@JsonSerializable()
class InstallDepRequest {
  final String name;
  final String type;

  InstallDepRequest({
    required this.name,
    required this.type,
  });

  factory InstallDepRequest.fromJson(Map<String, dynamic> json) =>
      _$InstallDepRequestFromJson(json);

  Map<String, dynamic> toJson() => _$InstallDepRequestToJson(this);
}

@JsonSerializable()
class DepStatusResponse {
  final DepStatus? data;

  DepStatusResponse({this.data});

  factory DepStatusResponse.fromJson(Map<String, dynamic> json) =>
      _$DepStatusResponseFromJson(json);

  Map<String, dynamic> toJson() => _$DepStatusResponseToJson(this);
}

@JsonSerializable()
class DepStatus {
  final int id;
  final String status;
  final int? progress;
  final String? message;

  DepStatus({
    required this.id,
    required this.status,
    this.progress,
    this.message,
  });

  factory DepStatus.fromJson(Map<String, dynamic> json) =>
      _$DepStatusFromJson(json);

  Map<String, dynamic> toJson() => _$DepStatusToJson(this);
}

@JsonSerializable()
class BatchDepIdsRequest {
  final List<int> ids;

  BatchDepIdsRequest({required this.ids});

  factory BatchDepIdsRequest.fromJson(Map<String, dynamic> json) =>
      _$BatchDepIdsRequestFromJson(json);

  Map<String, dynamic> toJson() => _$BatchDepIdsRequestToJson(this);
}

@JsonSerializable()
class ExportDepsResponse {
  final String? data;

  ExportDepsResponse({this.data});

  factory ExportDepsResponse.fromJson(Map<String, dynamic> json) =>
      _$ExportDepsResponseFromJson(json);

  Map<String, dynamic> toJson() => _$ExportDepsResponseToJson(this);
}

@JsonSerializable()
class PipListResponse {
  final List<PipPackage>? data;

  PipListResponse({this.data});

  factory PipListResponse.fromJson(Map<String, dynamic> json) =>
      _$PipListResponseFromJson(json);

  Map<String, dynamic> toJson() => _$PipListResponseToJson(this);
}

@JsonSerializable()
class PipPackage {
  final String name;
  final String version;

  PipPackage({
    required this.name,
    required this.version,
  });

  factory PipPackage.fromJson(Map<String, dynamic> json) =>
      _$PipPackageFromJson(json);

  Map<String, dynamic> toJson() => _$PipPackageToJson(this);
}

@JsonSerializable()
class NpmListResponse {
  final List<NpmPackage>? data;

  NpmListResponse({this.data});

  factory NpmListResponse.fromJson(Map<String, dynamic> json) =>
      _$NpmListResponseFromJson(json);

  Map<String, dynamic> toJson() => _$NpmListResponseToJson(this);
}

@JsonSerializable()
class NpmPackage {
  final String name;
  final String version;

  NpmPackage({
    required this.name,
    required this.version,
  });

  factory NpmPackage.fromJson(Map<String, dynamic> json) =>
      _$NpmPackageFromJson(json);

  Map<String, dynamic> toJson() => _$NpmPackageToJson(this);
}

@JsonSerializable()
class DepMirrorsResponse {
  final DepMirrors? data;

  DepMirrorsResponse({this.data});

  factory DepMirrorsResponse.fromJson(Map<String, dynamic> json) =>
      _$DepMirrorsResponseFromJson(json);

  Map<String, dynamic> toJson() => _$DepMirrorsResponseToJson(this);
}

@JsonSerializable()
class DepMirrors {
  final String? npm;
  final String? pip;

  DepMirrors({
    this.npm,
    this.pip,
  });

  factory DepMirrors.fromJson(Map<String, dynamic> json) =>
      _$DepMirrorsFromJson(json);

  Map<String, dynamic> toJson() => _$DepMirrorsToJson(this);
}

@JsonSerializable()
class SetDepMirrorsRequest {
  final String? npm;
  final String? pip;

  SetDepMirrorsRequest({
    this.npm,
    this.pip,
  });

  factory SetDepMirrorsRequest.fromJson(Map<String, dynamic> json) =>
      _$SetDepMirrorsRequestFromJson(json);

  Map<String, dynamic> toJson() => _$SetDepMirrorsRequestToJson(this);
}
