import '../utils/api_utils.dart';

class RawLogTicket {
  final String url;
  final String filename;
  final int size;
  final DateTime? expiresAt;
  final int expiresIn;

  const RawLogTicket({
    required this.url,
    required this.filename,
    this.size = 0,
    this.expiresAt,
    this.expiresIn = 0,
  });

  factory RawLogTicket.fromResponse(dynamic response) {
    final data = extractData(response);
    if (data is! Map) throw const FormatException('下载票据格式错误');
    final map = Map<String, dynamic>.from(data);
    final url = map['url']?.toString().trim() ?? '';
    final filename = map['filename']?.toString().trim() ?? '';
    if (url.isEmpty || filename.isEmpty) {
      throw const FormatException('下载票据缺少 URL 或文件名');
    }
    return RawLogTicket(
      url: url,
      filename: filename,
      size: _toInt(map['size']),
      expiresAt: DateTime.tryParse(map['expires_at']?.toString() ?? ''),
      expiresIn: _toInt(map['expires_in']),
    );
  }
}

int _toInt(dynamic value) {
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '') ?? 0;
}
