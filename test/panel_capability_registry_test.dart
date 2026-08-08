import 'package:daidai_app/core/network/panel_capability_registry.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  setUp(PanelCapabilityRegistry.reset);

  test('normalizes equivalent panel URLs', () {
    expect(
      PanelCapabilityRegistry.normalizeServerUrl(
        'HTTPS://Panel.Example.com/root/',
      ),
      'https://panel.example.com/root',
    );
  });

  test('isolates capability entries by panel URL', () {
    PanelCapabilityRegistry.recordSupported(
      PanelCapability.taskViews,
      scope: 'https://one.example.com',
    );

    expect(
      PanelCapabilityRegistry.stateFor(
        PanelCapability.taskViews,
        scope: 'https://one.example.com',
      ),
      PanelCapabilityState.supported,
    );
    expect(
      PanelCapabilityRegistry.stateFor(
        PanelCapability.taskViews,
        scope: 'https://two.example.com',
      ),
      PanelCapabilityState.unknown,
    );
  });

  test('classifies missing endpoints as unsupported', () {
    for (final statusCode in [404, 405]) {
      final options = RequestOptions(path: '/api/tasks/views');
      final error = DioException.badResponse(
        statusCode: statusCode,
        requestOptions: options,
        response: Response(requestOptions: options, statusCode: statusCode),
      );

      expect(
        PanelCapabilityRegistry.classifyFailure(error),
        PanelCapabilityState.unsupported,
      );
    }
  });

  test('classifies server and transport errors as temporary failures', () {
    final options = RequestOptions(path: '/api/tasks/views');
    final serverError = DioException.badResponse(
      statusCode: 503,
      requestOptions: options,
      response: Response(requestOptions: options, statusCode: 503),
    );
    final timeout = DioException.connectionTimeout(
      timeout: const Duration(seconds: 1),
      requestOptions: options,
    );

    expect(
      PanelCapabilityRegistry.classifyFailure(serverError),
      PanelCapabilityState.temporaryFailure,
    );
    expect(
      PanelCapabilityRegistry.classifyFailure(timeout),
      PanelCapabilityState.temporaryFailure,
    );
  });
}
