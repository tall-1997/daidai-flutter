import 'dart:async';

import 'package:dio/dio.dart';

import '../network/api_endpoints.dart';
import '../network/dio_client.dart';
import '../storage/secure_storage.dart';

class TokenRefreshCoordinator {
  TokenRefreshCoordinator._();

  static Future<String>? _inFlight;

  static Future<String> refresh() {
    return _inFlight ??= _refreshOnce().whenComplete(() => _inFlight = null);
  }

  static Future<String> _refreshOnce() async {
    final refreshToken = await SecureStorage.getRefreshToken();
    if (refreshToken == null || refreshToken.isEmpty) {
      throw StateError('Missing refresh token');
    }

    final response = await DioClient.instance.rawDio.post(
      ApiEndpoints.refresh,
      options: Options(headers: {'Authorization': 'Bearer $refreshToken'}),
    );
    final accessToken = _readToken(response.data, 'access_token');
    final rotatedRefreshToken = _readOptionalToken(
      response.data,
      'refresh_token',
    );
    await SecureStorage.saveAccessToken(accessToken);
    if (rotatedRefreshToken != null) {
      await SecureStorage.saveRefreshToken(rotatedRefreshToken);
    }
    return accessToken;
  }

  static String _readToken(dynamic data, String key) {
    final token = _readOptionalToken(data, key);
    if (token == null) throw StateError('Missing $key in refresh response');
    return token;
  }

  static String? _readOptionalToken(dynamic data, String key) {
    if (data is! Map) return null;
    final direct = data[key]?.toString();
    if (direct != null && direct.isNotEmpty) return direct;
    final nested = data['data'];
    if (nested is Map) {
      final value = nested[key]?.toString();
      if (value != null && value.isNotEmpty) return value;
    }
    return null;
  }
}
