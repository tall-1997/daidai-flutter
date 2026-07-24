import 'dart:async';

import 'package:flutter/services.dart';

import 'local_panel_host.dart';
import 'local_panel_models.dart';

class MethodChannelLocalPanelHost implements LocalPanelHost {
  static const _methodChannel = MethodChannel(
    'com.daidai.panel/local_host',
  );
  static const _eventChannel = EventChannel(
    'com.daidai.panel/local_host/events',
  );

  Stream<LocalPanelStatus>? _statusStream;

  @override
  Future<LocalPanelStatus> ensureStarted() => _invokeStatus('ensureStarted');

  @override
  Future<LocalPanelStatus> getStatus() => _invokeStatus('getStatus');

  @override
  Future<void> restart() => _methodChannel.invokeMethod<void>('restart');

  @override
  Future<void> stop() => _methodChannel.invokeMethod<void>('stop');

  @override
  Future<void> setPersistentSchedulingEnabled(bool enabled) {
    return _methodChannel.invokeMethod<void>(
      'setPersistentSchedulingEnabled',
      {'enabled': enabled},
    );
  }

  @override
  Stream<LocalPanelStatus> watchStatus() {
    return _statusStream ??= _eventChannel
        .receiveBroadcastStream()
        .where((event) => event is Map)
        .map(
          (event) => LocalPanelStatus.fromJson(
            Map<String, dynamic>.from(event as Map),
          ),
        )
        .asBroadcastStream();
  }

  Future<LocalPanelStatus> _invokeStatus(String method) async {
    final result = await _methodChannel.invokeMapMethod<String, dynamic>(method);
    return LocalPanelStatus.fromJson(result ?? const {});
  }
}
