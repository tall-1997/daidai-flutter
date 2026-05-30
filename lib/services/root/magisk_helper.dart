import 'root_service.dart';

class MagiskModuleInfo {
  final String id;
  final String name;
  final String version;
  final int versionCode;
  final String author;
  final String description;

  MagiskModuleInfo({
    required this.id,
    required this.name,
    required this.version,
    required this.versionCode,
    required this.author,
    required this.description,
  });

  factory MagiskModuleInfo.fromMap(Map<String, dynamic> map) {
    return MagiskModuleInfo(
      id: map['id'] ?? 'unknown',
      name: map['name'] ?? 'unknown',
      version: map['version'] ?? 'unknown',
      versionCode: map['versionCode'] ?? 0,
      author: map['author'] ?? 'unknown',
      description: map['description'] ?? '',
    );
  }
}

class MagiskHelper {
  static const String _magiskModulesDir = '/data/adb/modules';
  static const String _magiskDataDir = '/data/adb';
  static const String _daidaiModuleDir = '$_magiskModulesDir/daidai-panel';
  static const String _daidaiDataDir = '/data/local/daidai';
  
  static Future<bool> isDaidaiModuleInstalled() async {
    if (!await RootService.isRooted()) return false;
    
    try {
      final result = await RootService.executeAsRoot(
        'test -d $_daidaiModuleDir && echo "exists"',
      );
      return result.contains('exists');
    } catch (e) {
      return false;
    }
  }
  
  static Future<MagiskModuleInfo?> getModuleInfo() async {
    if (!await RootService.isRooted()) return null;
    
    try {
      final content = await RootService.readFileAsRoot('$_daidaiModuleDir/module.prop');
      final props = <String, String>{};
      
      for (final line in content.split('\n')) {
        final parts = line.split('=');
        if (parts.length >= 2) {
          props[parts[0].trim()] = parts.sublist(1).join('=').trim();
        }
      }
      
      return MagiskModuleInfo(
        id: props['id'] ?? 'daidai-panel',
        name: props['name'] ?? '呆呆面板',
        version: props['version'] ?? 'unknown',
        versionCode: int.tryParse(props['versionCode'] ?? '0') ?? 0,
        author: props['author'] ?? 'unknown',
        description: props['description'] ?? '',
      );
    } catch (e) {
      return null;
    }
  }
  
  static String getDaidaiDataDir() => _daidaiDataDir;
  
  static String getPanelConfigPath() => '$_daidaiDataDir/app/Dumb-Panel/config.json';
  
  static String getPanelDbPath() => '$_daidaiDataDir/app/Dumb-Panel/database.db';
  
  static String getPanelLogsDir() => '$_daidaiDataDir/app/Dumb-Panel/logs';
  
  static String getPanelScriptsDir() => '$_daidaiDataDir/app/Dumb-Panel/scripts';
  
  static Future<String?> readPanelConfig() async {
    if (!await RootService.isRooted()) return null;
    
    try {
      return await RootService.readFileAsRoot(getPanelConfigPath());
    } catch (e) {
      return null;
    }
  }
  
  static Future<int> getPanelPort() async {
    if (!await RootService.isRooted()) return 5700;
    
    try {
      final content = await RootService.readFileAsRoot('/data/adb/daidai-panel/ports.conf');
      for (final line in content.split('\n')) {
        if (line.startsWith('PANEL_PORT=')) {
          return int.tryParse(line.split('=')[1].trim()) ?? 5700;
        }
      }
      return 5700;
    } catch (e) {
      return 5700;
    }
  }
  
  static Future<List<MagiskModuleInfo>> getInstalledModules() async {
    if (!await RootService.isRooted()) return [];
    
    try {
      final entries = await RootService.listDirectoryAsRoot(_magiskModulesDir);
      final modules = <MagiskModuleInfo>[];
      
      for (final entry in entries) {
        if (entry.startsWith('.') || entry.startsWith('total')) continue;
        
        final parts = entry.split(RegExp(r'\s+'));
        if (parts.length >= 9) {
          final moduleName = parts.last;
          
          try {
            final content = await RootService.readFileAsRoot(
              '$_magiskModulesDir/$moduleName/module.prop',
            );
            final props = <String, String>{};
            
            for (final line in content.split('\n')) {
              final p = line.split('=');
              if (p.length >= 2) {
                props[p[0].trim()] = p.sublist(1).join('=').trim();
              }
            }
            
            modules.add(MagiskModuleInfo(
              id: props['id'] ?? moduleName,
              name: props['name'] ?? moduleName,
              version: props['version'] ?? 'unknown',
              versionCode: int.tryParse(props['versionCode'] ?? '0') ?? 0,
              author: props['author'] ?? 'unknown',
              description: props['description'] ?? '',
            ));
          } catch (e) {
            // Skip modules that can't be read
          }
        }
      }
      
      return modules;
    } catch (e) {
      return [];
    }
  }
  
  static Future<Map<String, dynamic>> getSystemInfoViaRoot() async {
    if (!await RootService.isRooted()) return {};
    
    try {
      final results = await Future.wait([
        RootService.executeAsRoot('cat /proc/meminfo | head -3'),
        RootService.executeAsRoot('cat /proc/cpuinfo | grep "model name" | head -1'),
        RootService.executeAsRoot('df -h / | tail -1'),
        RootService.executeAsRoot('uptime'),
      ]);
      
      return {
        'memory': results[0],
        'cpu': results[1],
        'disk': results[2],
        'uptime': results[3],
        'source': 'root',
      };
    } catch (e) {
      return {};
    }
  }
  
  static Future<String> getPanelLogsViaRoot({int lines = 100}) async {
    if (!await RootService.isRooted()) return '';
    
    try {
      return await RootService.executeAsRoot(
        'tail -n $lines ${getPanelLogsDir()}/*.log 2>/dev/null || echo "No logs found"',
      );
    } catch (e) {
      return '';
    }
  }
}
