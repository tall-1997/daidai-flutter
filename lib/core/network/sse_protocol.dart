class SseField {
  final String name;
  final String value;

  const SseField(this.name, this.value);
}

SseField? parseSseField(String rawLine) {
  final line = rawLine.endsWith('\r')
      ? rawLine.substring(0, rawLine.length - 1)
      : rawLine;
  if (line.isEmpty || line.startsWith(':')) return null;

  final separator = line.indexOf(':');
  if (separator < 0) return SseField(line, '');

  var value = line.substring(separator + 1);
  if (value.startsWith(' ')) value = value.substring(1);
  return SseField(line.substring(0, separator), value);
}

bool isTerminalSseEvent(String? event, String data) {
  return event == 'done' && data.trim() != 'reconnect';
}

bool isReconnectSseEvent(String? event, String data) {
  return event == 'done' && data.trim() == 'reconnect';
}
