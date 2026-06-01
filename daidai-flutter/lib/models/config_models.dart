import 'package:json_annotation/json_annotation.dart';

part 'config_models.g.dart';

@JsonSerializable()
class ConfigListResponse {
  final List<Config>? data;
  final int total;

  ConfigListResponse({
    this.data,
    required this.total,
  });

  factory ConfigListResponse.fromJson(Map<String, dynamic> json) =>
      _$ConfigListResponseFromJson(json);

  Map<String, dynamic> toJson() => _$ConfigListResponseToJson(this);
}

@JsonSerializable()
class Config {
  final String key;
  final String? value;
  final String? description;

  Config({
    required this.key,
    this.value,
    this.description,
  });

  factory Config.fromJson(Map<String, dynamic> json) =>
      _$ConfigFromJson(json);

  Map<String, dynamic> toJson() => _$ConfigToJson(this);
}

@JsonSerializable()
class ConfigResponse {
  final Config? data;

  ConfigResponse({this.data});

  factory ConfigResponse.fromJson(Map<String, dynamic> json) =>
      _$ConfigResponseFromJson(json);

  Map<String, dynamic> toJson() => _$ConfigResponseToJson(this);
}

@JsonSerializable()
class SetConfigRequest {
  final String key;
  final String value;

  SetConfigRequest({
    required this.key,
    required this.value,
  });

  factory SetConfigRequest.fromJson(Map<String, dynamic> json) =>
      _$SetConfigRequestFromJson(json);

  Map<String, dynamic> toJson() => _$SetConfigRequestToJson(this);
}

@JsonSerializable()
class BatchSetConfigsRequest {
  final List<Config> configs;

  BatchSetConfigsRequest({required this.configs});

  factory BatchSetConfigsRequest.fromJson(Map<String, dynamic> json) =>
      _$BatchSetConfigsRequestFromJson(json);

  Map<String, dynamic> toJson() => _$BatchSetConfigsRequestToJson(this);
}
