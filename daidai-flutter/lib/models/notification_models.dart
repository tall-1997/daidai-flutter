import 'package:json_annotation/json_annotation.dart';

part 'notification_models.g.dart';

@JsonSerializable()
class NotificationListResponse {
  final List<Notification>? data;
  final int total;

  NotificationListResponse({
    this.data,
    required this.total,
  });

  factory NotificationListResponse.fromJson(Map<String, dynamic> json) =>
      _$NotificationListResponseFromJson(json);

  Map<String, dynamic> toJson() => _$NotificationListResponseToJson(this);
}

@JsonSerializable()
class AppNotification {
  final int id;
  final String name;
  final String type;
  final bool enabled;
  final Map<String, dynamic>? config;
  @JsonKey(name: 'created_at')
  final String createdAt;
  @JsonKey(name: 'updated_at')
  final String updatedAt;

  AppNotification({
    required this.id,
    required this.name,
    required this.type,
    required this.enabled,
    this.config,
    required this.createdAt,
    required this.updatedAt,
  });

  factory AppNotification.fromJson(Map<String, dynamic> json) =>
      _$AppNotificationFromJson(json);

  Map<String, dynamic> toJson() => _$AppNotificationToJson(this);
}

@JsonSerializable()
class NotificationResponse {
  final String? message;
  final AppNotification? data;

  NotificationResponse({
    this.message,
    this.data,
  });

  factory NotificationResponse.fromJson(Map<String, dynamic> json) =>
      _$NotificationResponseFromJson(json);

  Map<String, dynamic> toJson() => _$NotificationResponseToJson(this);
}

@JsonSerializable()
class CreateNotificationRequest {
  final String name;
  final String type;
  final Map<String, dynamic> config;

  CreateNotificationRequest({
    required this.name,
    required this.type,
    required this.config,
  });

  factory CreateNotificationRequest.fromJson(Map<String, dynamic> json) =>
      _$CreateNotificationRequestFromJson(json);

  Map<String, dynamic> toJson() => _$CreateNotificationRequestToJson(this);
}

@JsonSerializable()
class UpdateNotificationRequest {
  final String? name;
  final Map<String, dynamic>? config;

  UpdateNotificationRequest({
    this.name,
    this.config,
  });

  factory UpdateNotificationRequest.fromJson(Map<String, dynamic> json) =>
      _$UpdateNotificationRequestFromJson(json);

  Map<String, dynamic> toJson() => _$UpdateNotificationRequestToJson(this);
}

@JsonSerializable()
class NotificationTypesResponse {
  final List<NotificationType>? data;

  NotificationTypesResponse({this.data});

  factory NotificationTypesResponse.fromJson(Map<String, dynamic> json) =>
      _$NotificationTypesResponseFromJson(json);

  Map<String, dynamic> toJson() => _$NotificationTypesResponseToJson(this);
}

@JsonSerializable()
class NotificationType {
  final String type;
  final String name;

  NotificationType({
    required this.type,
    required this.name,
  });

  factory NotificationType.fromJson(Map<String, dynamic> json) =>
      _$NotificationTypeFromJson(json);

  Map<String, dynamic> toJson() => _$NotificationTypeToJson(this);
}

@JsonSerializable()
class SendNotificationRequest {
  @JsonKey(name: 'channel_id')
  final int? channelId;
  final String title;
  final String content;

  SendNotificationRequest({
    this.channelId,
    required this.title,
    required this.content,
  });

  factory SendNotificationRequest.fromJson(Map<String, dynamic> json) =>
      _$SendNotificationRequestFromJson(json);

  Map<String, dynamic> toJson() => _$SendNotificationRequestToJson(this);
}
