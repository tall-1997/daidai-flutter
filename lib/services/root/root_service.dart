import 'package:flutter/services.dart';

class RootService {
  static const MethodChannel _channel = MethodChannel('com.daidai.app/root');
  
  static bool? _isRooted;
  
  static Future<bool> isRooted() async {
    if (_isRooted != null) return _isRooted!;
    
    try {
      final result = await _channel.invokeMethod<bool>('isRooted');
      _isRooted = result ?? false;
      return _isRooted!;
    } on PlatformException {
      _isRooted = false;
      return false;
    }
  }
  
  static Future<String> executeAsRoot(String command) async {
    try {
      final result = await _channel.invokeMethod<String>('executeAsRoot', {
        'command': command,
      });
      return result ?? '';
    } on PlatformException catch (e) {
      throw Exception('Root command failed: ${e.message}');
    }
  }
  
  static Future<String> readFileAsRoot(String path) async {
    try {
      final result = await _channel.invokeMethod<String>('readFileAsRoot', {
        'path': path,
      });
      return result ?? '';
    } on PlatformException catch (e) {
      throw Exception('Failed to read file: ${e.message}');
    }
  }
  
  static Future<List<String>> listDirectoryAsRoot(String path) async {
    try {
      final result = await _channel.invokeMethod<List>('listDirectoryAsRoot', {
        'path': path,
      });
      return result?.cast<String>() ?? [];
    } on PlatformException catch (e) {
      throw Exception('Failed to list directory: ${e.message}');
    }
  }
}
