import 'package:daidai_app/core/network/sse_protocol.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('parseSseField', () {
    test('parses fields with and without an optional space', () {
      expect(parseSseField('data:value')?.value, 'value');
      expect(parseSseField('data: value')?.value, 'value');
      expect(parseSseField('event:done\r')?.value, 'done');
    });

    test('ignores empty lines and comments', () {
      expect(parseSseField(''), isNull);
      expect(parseSseField(': keep-alive'), isNull);
    });

    test('preserves additional colons in values', () {
      final field = parseSseField('data: https://example.test:5700');
      expect(field?.name, 'data');
      expect(field?.value, 'https://example.test:5700');
    });
  });

  group('SSE completion decisions', () {
    test('recognizes reconnect events', () {
      expect(isReconnectSseEvent('done', 'reconnect'), isTrue);
      expect(isTerminalSseEvent('done', 'reconnect'), isFalse);
    });

    test('recognizes business terminal events', () {
      for (final value in [
        'finished',
        'installed',
        'failed',
        'not_running',
        'closed',
        'timeout',
      ]) {
        expect(isTerminalSseEvent('done', value), isTrue);
        expect(isReconnectSseEvent('done', value), isFalse);
      }
    });

    test('keeps ordinary events open', () {
      expect(isTerminalSseEvent('message', 'finished'), isFalse);
      expect(isReconnectSseEvent(null, 'reconnect'), isFalse);
    });
  });
}
