import 'local_panel_models.dart';

abstract interface class LocalPanelHost {
  Future<LocalPanelStatus> ensureStarted();

  Future<LocalPanelStatus> getStatus();

  Future<void> restart();

  Future<void> stop();

  Future<void> setPersistentSchedulingEnabled(bool enabled);

  Stream<LocalPanelStatus> watchStatus();
}
