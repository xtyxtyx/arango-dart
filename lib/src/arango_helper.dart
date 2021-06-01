import 'dart:math';

String sanitizeUrl(String url) {
  final raw = RegExp(r'^(tcp|ssl|tls)((?::|\+).+)').firstMatch(url);
  if (raw != null) url = (raw[1] == 'tcp' ? 'http' : 'https') + raw[2]!;
  final unix = RegExp(r'^(?:(https?)\+)?unix:\/\/(\/.+)').firstMatch(url);
  if (unix != null) url = '${unix[1] ?? 'http'}://unix:${unix[2]}';
  return url;
}

final rand = Random();

Map<String, dynamic> asJson(dynamic data) {
  return Map<String, dynamic>.from(data);
}

List<dynamic> asJsonList(dynamic data) {
  return List<dynamic>.from(data);
}
