import 'dart:convert';

Map<String, dynamic>? extractPayload(Map<String, dynamic> item) {
  final jsonData = item['jsonData'];
  if (jsonData is Map<String, dynamic> && jsonData.isNotEmpty) {
    return jsonData;
  }
  if (jsonData is Map && jsonData.isNotEmpty) {
    return jsonData.map((k, v) => MapEntry(k.toString(), v));
  }
  if (jsonData is String && jsonData.trim().isNotEmpty) {
    try {
      final decoded = jsonDecode(jsonData);
      if (decoded is Map<String, dynamic>) return decoded;
      if (decoded is Map) {
        return decoded.map((k, v) => MapEntry(k.toString(), v));
      }
    } catch (_) {}
  }

  final responseData = item['responseData'];
  if (responseData is Map<String, dynamic>) return responseData;
  if (responseData is Map) {
    return responseData.map((k, v) => MapEntry(k.toString(), v));
  }

  final payload = item['payload'];
  if (payload is Map<String, dynamic>) return payload;
  if (payload is Map) {
    return payload.map((k, v) => MapEntry(k.toString(), v));
  }

  final payloadJson = item['payloadJson']?.toString().trim() ?? '';
  if (payloadJson.isEmpty) return null;
  try {
    final decoded = jsonDecode(payloadJson);
    if (decoded is Map<String, dynamic>) return decoded;
    if (decoded is Map) {
      return decoded.map((k, v) => MapEntry(k.toString(), v));
    }
  } catch (_) {}
  return null;
}
