// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'auth_models.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

LoginRequest _$LoginRequestFromJson(Map<String, dynamic> json) =>
    LoginRequest(
      username: json['username'] as String,
      password: json['password'] as String,
      totpCode: json['totp_code'] as String?,
    );

Map<String, dynamic> _$LoginRequestToJson(LoginRequest instance) =>
    <String, dynamic>{
      'username': instance.username,
      'password': instance.password,
      'totp_code': instance.totpCode,
    };

LoginResponse _$LoginResponseFromJson(Map<String, dynamic> json) =>
    LoginResponse(
      message: json['message'] as String?,
      accessToken: json['access_token'] as String?,
      refreshToken: json['refresh_token'] as String?,
      user: json['user'] == null
          ? null
          : User.fromJson(json['user'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$LoginResponseToJson(LoginResponse instance) =>
    <String, dynamic>{
      'message': instance.message,
      'access_token': instance.accessToken,
      'refresh_token': instance.refreshToken,
      'user': instance.user,
    };

RefreshTokenRequest _$RefreshTokenRequestFromJson(Map<String, dynamic> json) =>
    RefreshTokenRequest(
      refreshToken: json['refresh_token'] as String,
    );

Map<String, dynamic> _$RefreshTokenRequestToJson(
        RefreshTokenRequest instance) =>
    <String, dynamic>{
      'refresh_token': instance.refreshToken,
    };

User _$UserFromJson(Map<String, dynamic> json) => User(
      id: json['id'] as int,
      username: json['username'] as String,
      role: json['role'] as String,
      avatarUrl: json['avatar_url'] as String?,
    );

Map<String, dynamic> _$UserToJson(User instance) => <String, dynamic>{
      'id': instance.id,
      'username': instance.username,
      'role': instance.role,
      'avatar_url': instance.avatarUrl,
    };

UserResponse _$UserResponseFromJson(Map<String, dynamic> json) =>
    UserResponse(
      user: json['user'] == null
          ? null
          : User.fromJson(json['user'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$UserResponseToJson(UserResponse instance) =>
    <String, dynamic>{
      'user': instance.user,
    };

UserListResponse _$UserListResponseFromJson(Map<String, dynamic> json) =>
    UserListResponse(
      data: (json['data'] as List<dynamic>?)
          ?.map((e) => User.fromJson(e as Map<String, dynamic>))
          .toList(),
      total: json['total'] as int,
    );

Map<String, dynamic> _$UserListResponseToJson(UserListResponse instance) =>
    <String, dynamic>{
      'data': instance.data,
      'total': instance.total,
    };

ChangePasswordRequest _$ChangePasswordRequestFromJson(
        Map<String, dynamic> json) =>
    ChangePasswordRequest(
      oldPassword: json['old_password'] as String,
      newPassword: json['new_password'] as String,
    );

Map<String, dynamic> _$ChangePasswordRequestToJson(
        ChangePasswordRequest instance) =>
    <String, dynamic>{
      'old_password': instance.oldPassword,
      'new_password': instance.newPassword,
    };

ChangeUsernameRequest _$ChangeUsernameRequestFromJson(
        Map<String, dynamic> json) =>
    ChangeUsernameRequest(
      username: json['username'] as String,
      password: json['password'] as String,
    );

Map<String, dynamic> _$ChangeUsernameRequestToJson(
        ChangeUsernameRequest instance) =>
    <String, dynamic>{
      'username': instance.username,
      'password': instance.password,
    };

CaptchaConfigResponse _$CaptchaConfigResponseFromJson(
        Map<String, dynamic> json) =>
    CaptchaConfigResponse(
      data: json['data'] == null
          ? null
          : CaptchaConfig.fromJson(json['data'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$CaptchaConfigResponseToJson(
        CaptchaConfigResponse instance) =>
    <String, dynamic>{
      'data': instance.data,
    };

CaptchaConfig _$CaptchaConfigFromJson(Map<String, dynamic> json) =>
    CaptchaConfig(
      enabled: json['enabled'] as bool,
      type: json['type'] as String?,
    );

Map<String, dynamic> _$CaptchaConfigToJson(CaptchaConfig instance) =>
    <String, dynamic>{
      'enabled': instance.enabled,
      'type': instance.type,
    };

AvatarResponse _$AvatarResponseFromJson(Map<String, dynamic> json) =>
    AvatarResponse(
      message: json['message'] as String?,
      avatarUrl: json['avatar_url'] as String?,
    );

Map<String, dynamic> _$AvatarResponseToJson(AvatarResponse instance) =>
    <String, dynamic>{
      'message': instance.message,
      'avatar_url': instance.avatarUrl,
    };

CreateUserRequest _$CreateUserRequestFromJson(Map<String, dynamic> json) =>
    CreateUserRequest(
      username: json['username'] as String,
      password: json['password'] as String,
      role: json['role'] as String? ?? 'viewer',
    );

Map<String, dynamic> _$CreateUserRequestToJson(CreateUserRequest instance) =>
    <String, dynamic>{
      'username': instance.username,
      'password': instance.password,
      'role': instance.role,
    };

UpdateUserRequest _$UpdateUserRequestFromJson(Map<String, dynamic> json) =>
    UpdateUserRequest(
      username: json['username'] as String?,
      role: json['role'] as String?,
      enabled: json['enabled'] as bool?,
    );

Map<String, dynamic> _$UpdateUserRequestToJson(UpdateUserRequest instance) =>
    <String, dynamic>{
      'username': instance.username,
      'role': instance.role,
      'enabled': instance.enabled,
    };

ResetPasswordRequest _$ResetPasswordRequestFromJson(
        Map<String, dynamic> json) =>
    ResetPasswordRequest(
      password: json['password'] as String,
    );

Map<String, dynamic> _$ResetPasswordRequestToJson(
        ResetPasswordRequest instance) =>
    <String, dynamic>{
      'password': instance.password,
    };
