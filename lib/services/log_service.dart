import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';

class LogService {
  static final LogService _instance = LogService._internal();
  factory LogService() => _instance;
  LogService._internal();

  final List<LogEntry> _logs = [];
  static const int _maxLogs = 1000;

  void log(String tag, String message, {LogLevel level = LogLevel.info}) {
    final entry = LogEntry(
      timestamp: DateTime.now(),
      tag: tag,
      message: message,
      level: level,
    );
    
    _logs.add(entry);
    
    if (_logs.length > _maxLogs) {
      _logs.removeAt(0);
    }
    
    if (kDebugMode) {
      print('[${level.name}] $tag: $message');
    }
  }

  void debug(String tag, String message) => log(tag, message, level: LogLevel.debug);
  void info(String tag, String message) => log(tag, message, level: LogLevel.info);
  void warning(String tag, String message) => log(tag, message, level: LogLevel.warning);
  void error(String tag, String message) => log(tag, message, level: LogLevel.error);

  List<LogEntry> get logs => List.unmodifiable(_logs);

  List<LogEntry> getLogsByTag(String tag) {
    return _logs.where((log) => log.tag == tag).toList();
  }

  List<LogEntry> getLogsByLevel(LogLevel level) {
    return _logs.where((log) => log.level == level).toList();
  }

  void clear() {
    _logs.clear();
  }

  String exportToJson() {
    final jsonList = _logs.map((log) => log.toJson()).toList();
    return const JsonEncoder.withIndent('  ').convert({
      'export_time': DateTime.now().toIso8601String(),
      'total_logs': _logs.length,
      'logs': jsonList,
    });
  }

  String exportToText() {
    final buffer = StringBuffer();
    buffer.writeln('=== 呆呆面板 App 日志导出 ===');
    buffer.writeln('导出时间: ${DateTime.now()}');
    buffer.writeln('日志总数: ${_logs.length}');
    buffer.writeln('==============================\n');

    for (final log in _logs) {
      buffer.writeln('${log.timestamp} [${log.level.name}] ${log.tag}');
      buffer.writeln('  ${log.message}');
      buffer.writeln();
    }

    return buffer.toString();
  }

  Future<String> exportToFile({bool json = true}) async {
    final directory = await getApplicationDocumentsDirectory();
    final timestamp = DateTime.now().toString().replaceAll(RegExp(r'[: ]'), '-').substring(0, 19);
    final extension = json ? 'json' : 'txt';
    final fileName = 'daidai-logs-$timestamp.$extension';
    final file = File('${directory.path}/$fileName');
    
    final content = json ? exportToJson() : exportToText();
    await file.writeAsString(content);
    return file.path;
  }

  Future<void> copyLogsToClipboard({bool json = true}) async {
    final content = json ? exportToJson() : exportToText();
    await Clipboard.setData(ClipboardData(text: content));
  }
}

class LogEntry {
  final DateTime timestamp;
  final String tag;
  final String message;
  final LogLevel level;

  LogEntry({
    required this.timestamp,
    required this.tag,
    required this.message,
    required this.level,
  });

  Map<String, dynamic> toJson() => {
    'timestamp': timestamp.toIso8601String(),
    'tag': tag,
    'message': message,
    'level': level.name,
  };

  @override
  String toString() {
    return '$timestamp [${level.name}] $tag: $message';
  }
}

enum LogLevel {
  debug,
  info,
  warning,
  error;

  String get name {
    switch (this) {
      case LogLevel.debug:
        return 'DEBUG';
      case LogLevel.info:
        return 'INFO';
      case LogLevel.warning:
        return 'WARN';
      case LogLevel.error:
        return 'ERROR';
    }
  }
}
