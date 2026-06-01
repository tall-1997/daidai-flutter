import 'package:json_annotation/json_annotation.dart';

part 'auth_models.g.dart';

@JsonSerializable()
class LoginRequest {
  final String username;
  final String password;
  @JsonKey(name: 'totp_code')
  final String? totpCode;

  LoginRequest({
    required this.username,
    required this.password,
    this.totpCode,
  });

  factory LoginRequest.fromJson(Map<String, dynamic> json) =>
      _$LoginRequestFromJson(json);

  Map<String, dynamic> toJson() => _$LoginRequestToJson(this);
}

@JsonSerializable()
class LoginResponse {
  final String? message;
  @JsonKey(name: 'access_token')
  final String? accessToken;
  @JsonKey(name: 'refresh_token')
  final String? refreshToken;
  final User? user;

  LoginResponse({
    this.message,
    this.accessToken,
    this.refreshToken,
    this.user,
  });

  factory LoginResponse.fromJson(Map<String, dynamic> json) =>
      _$LoginResponseFromJson(json);

  Map<String, dynamic> toJson() => _$LoginResponseToJson(this);
}

@JsonSerializable()
class RefreshTokenRequest {
  @JsonKey(name: 'refresh_token')
  final String refreshToken;

  RefreshTokenRequest({
    required this.refreshToken,
  });

  factory RefreshTokenRequest.fromJson(Map<String, dynamic> json) =>
      _$RefreshTokenRequestFromJson(json);

  Map<String, dynamic> toJson() => _$RefreshTokenRequestToJson(this);
}

@JsonSerializable()
class User {
  final int id;
  final String username;
  final String role;
  @JsonKey(name: 'avatar_url')
  final String? avatarUrl;

  User({
    required this.id,
    required this.username,
    required this.role,
    this.avatarUrl,
  });

  factory User.fromJson(Map<String, dynamic> json) => _$UserFromJson(json);

  Map<String, dynamic> toJson() => _$UserToJson(this);
}

@JsonSerializable()
class UserResponse {
  final User? user;

  UserResponse({this.user});

  factory UserResponse.fromJson(Map<String, dynamic> json) =>
      _$UserResponseFromJson(json);

  Map<String, dynamic> toJson() => _$UserResponseToJson(this);
}

@JsonSerializable()
class UserListResponse {
  final List<User>? data;
  final int total;

  UserListResponse({
    this.data,
    required this.total,
  });

  factory UserListResponse.fromJson(Map<String, dynamic> json) =>
      _$UserListResponseFromJson(json);

  Map<String, dynamic> toJson() => _$UserListResponseToJson(this);
}

@JsonSerializable()
class ChangePasswordRequest {
  @JsonKey(name: 'old_password')
  final String oldPassword;
  @JsonKey(name: 'new_password')
  final String newPassword;

  ChangePasswordRequest({
    required this.oldPassword,
    required this.newPassword,
  });

  factory ChangePasswordRequest.fromJson(Map<String, dynamic> json) =>
      _$ChangePasswordRequestFromJson(json);

  Map<String, dynamic> toJson() => _$ChangePasswordRequestToJson(this);
}

@JsonSerializable()
class ChangeUsernameRequest {
  final String username;
  final String password;

  ChangeUsernameRequest({
    required this.username,
    required this.password,
  });

  factory ChangeUsernameRequest.fromJson(Map<String, dynamic> json) =>
      _$ChangeUsernameRequestFromJson(json);

  Map<String, dynamic> toJson() => _$ChangeUsernameRequestToJson(this);
}

@JsonSerializable()
class CaptchaConfigResponse {
  final CaptchaConfig? data;

  CaptchaConfigResponse({this.data});

  factory CaptchaConfigResponse.fromJson(Map<String, dynamic> json) =>
      _$CaptchaConfigResponseFromJson(json);

  Map<String, dynamic> toJson() => _$CaptchaConfigResponseToJson(this);
}

@JsonSerializable()
class CaptchaConfig {
  final bool enabled;
  final String? type;

  CaptchaConfig({
    required this.enabled,
    this.type,
  });

  factory CaptchaConfig.fromJson(Map<String, dynamic> json) =>
      _$CaptchaConfigFromJson(json);

  Map<String, dynamic> toJson() => _$CaptchaConfigToJson(this);
}

@JsonSerializable()
class AvatarResponse {
  final String? message;
  @JsonKey(name: 'avatar_url')
  final String? avatarUrl;

  AvatarResponse({
    this.message,
    this.avatarUrl,
  });

  factory AvatarResponse.fromJson(Map<String, dynamic> json) =>
      _$AvatarResponseFromJson(json);

  Map<String, dynamic> toJson() => _$AvatarResponseToJson(this);
}

@JsonSerializable()
class CreateUserRequest {
  final String username;
  final String password;
  final String role;

  CreateUserRequest({
    required this.username,
    required this.password,
    this.role = 'viewer',
  });

  factory CreateUserRequest.fromJson(Map<String, dynamic> json) =>
      _$CreateUserRequestFromJson(json);

  Map<String, dynamic> toJson() => _$CreateUserRequestToJson(this);
}

@JsonSerializable()
class UpdateUserRequest {
  final String? username;
  final String? role;
  final bool? enabled;

  UpdateUserRequest({
    this.username,
    this.role,
    this.enabled,
  });

  factory UpdateUserRequest.fromJson(Map<String, dynamic> json) =>
      _$UpdateUserRequestFromJson(json);

  Map<String, dynamic> toJson() => _$UpdateUserRequestToJson(this);
}

@JsonSerializable()
class ResetPasswordRequest {
  final String password;

  ResetPasswordRequest({required this.password});

  factory ResetPasswordRequest.fromJson(Map<String, dynamic> json) =>
      _$ResetPasswordRequestFromJson(json);

  Map<String, dynamic> toJson() => _$ResetPasswordRequestToJson(this);
}
