import 'dart:io';

import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';

import '../../shared/models/raw_log_ticket.dart';
import '../network/dio_client.dart';

class RawLogDownloadService {
  static final Set<String> _reservedPaths = <String>{};

  static Future<String> download({
    required String ticketPath,
    Map<String, dynamic>? queryParameters,
  }) async {
    final response = await DioClient.instance.dio.get(
      ticketPath,
      queryParameters: queryParameters,
    );
    final ticket = RawLogTicket.fromResponse(response.data);
    final documentsDirectory = await getApplicationDocumentsDirectory();
    final downloadDirectory = Directory(
      '${documentsDirectory.path}${Platform.pathSeparator}downloads',
    );
    await downloadDirectory.create(recursive: true);
    final targetPath = await _availablePath(
      downloadDirectory.path,
      _safeFilename(ticket.filename),
    );

    Dio? downloadDio;
    try {
      final ticketUri = Uri.parse(ticket.url);
      final resolvedUrl = ticketUri.hasScheme
          ? ticketUri.toString()
          : Uri.parse('${DioClient.instance.baseUrl}/')
              .resolveUri(ticketUri)
              .toString();
      downloadDio = DioClient.instance.rawDio;
      await downloadDio.download(
        resolvedUrl,
        targetPath,
        options: Options(receiveTimeout: const Duration(minutes: 10)),
        deleteOnError: true,
      );
      return targetPath;
    } finally {
      _reservedPaths.remove(targetPath);
      downloadDio?.close(force: true);
    }
  }

  static Future<String> _availablePath(String directory, String filename) async {
    final separator = Platform.pathSeparator;
    final dot = filename.lastIndexOf('.');
    final basename = dot > 0 ? filename.substring(0, dot) : filename;
    final extension = dot > 0 ? filename.substring(dot) : '';
    var suffix = 1;
    var candidate = '$directory$separator$filename';
    while (true) {
      if (_reservedPaths.contains(candidate) || await File(candidate).exists()) {
        candidate = '$directory$separator$basename-$suffix$extension';
        suffix++;
        continue;
      }
      // Another download can reserve the same path while File.exists awaits.
      if (_reservedPaths.contains(candidate)) continue;
      _reservedPaths.add(candidate);
      return candidate;
    }
  }

  static String _safeFilename(String filename) {
    final sanitized = filename
        .replaceAll(RegExp(r'[\\/:*?"<>|\x00-\x1F]'), '_')
        .trim();
    if (sanitized.isEmpty || sanitized == '.' || sanitized == '..') {
      return 'raw.log';
    }
    return sanitized.length > 180 ? sanitized.substring(0, 180) : sanitized;
  }
}
