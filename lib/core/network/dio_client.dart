import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';
import 'app_user_agent.dart';

final _logger = Logger(printer: PrettyPrinter(methodCount: 0));

class DioClient {
  static DioClient? _instance;
  late final Dio dio;
  String _baseUrl = '';

  DioClient._() {
    dio = Dio(
      BaseOptions(
        validateStatus: (status) =>
            status != null && status >= 200 && status < 300,
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 30),
        sendTimeout: const Duration(seconds: 15),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          ...AppUserAgent.defaultHeaders,
        },
      ),
    );

    if (kDebugMode) {
      dio.interceptors.add(
        LogInterceptor(
          request: false,
          requestHeader: false,
          requestBody: false,
          responseHeader: false,
          responseBody: false,
          logPrint: (obj) => _logger.d(obj),
        ),
      );
    }
  }

  static DioClient get instance {
    _instance ??= DioClient._();
    return _instance!;
  }

  String get baseUrl => _baseUrl;

  void setBaseUrl(String url) {
    _baseUrl = url.endsWith('/') ? url.substring(0, url.length - 1) : url;
    dio.options.baseUrl = _baseUrl;
    dio.options.headers.addAll(AppUserAgent.defaultHeaders);
  }

  Dio get rawDio => Dio(
    BaseOptions(
      baseUrl: _baseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
      validateStatus: (status) =>
          status != null && status >= 200 && status < 300,
      headers: {'Accept': 'application/json', ...AppUserAgent.defaultHeaders},
    ),
  );
}
