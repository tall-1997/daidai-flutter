import 'package:daidai_app/shared/models/raw_log_ticket.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('parses a direct raw log ticket response', () {
    final ticket = RawLogTicket.fromResponse({
      'url': '/api/logs/12/raw?ticket=test',
      'filename': 'task-12-raw.log',
      'size': 2048,
      'expires_at': '2026-08-08T12:00:00Z',
      'expires_in': 120,
    });
    expect(ticket.url, contains('/api/logs/12/raw'));
    expect(ticket.filename, 'task-12-raw.log');
    expect(ticket.size, 2048);
    expect(ticket.expiresIn, 120);
    expect(ticket.expiresAt, isNotNull);
  });

  test('parses a wrapped ticket and numeric strings', () {
    final ticket = RawLogTicket.fromResponse({
      'data': {
        'url': '/raw?ticket=test',
        'filename': 'raw.log',
        'size': '42',
        'expires_in': '60',
      },
    });
    expect(ticket.size, 42);
    expect(ticket.expiresIn, 60);
  });

  test('rejects an incomplete ticket', () {
    expect(
      () => RawLogTicket.fromResponse({'url': '/raw'}),
      throwsFormatException,
    );
  });
}
