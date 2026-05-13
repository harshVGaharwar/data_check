import 'dart:convert';

class CheckerTrayItem {
  final String departmentName;
  final String makerBy;
  final String makerDate;

  // Source Configuration
  final int? sourceId;
  final String? sourceName;
  final String? sourceTypeName;
  final String? appName;
  final String? itgrc;
  final String? dbVault;

  // Template Creation / Template Configuration / Manual Upload
  final int? templateId;
  final String? templateName;
  final Map<String, dynamic>? jsonData;

  // Manual Upload
  final String? filename;
  final String? requestId;

  // Module tag (present in WithModule API responses)
  final String? module;

  const CheckerTrayItem({
    required this.departmentName,
    required this.makerBy,
    required this.makerDate,
    this.sourceId,
    this.sourceName,
    this.sourceTypeName,
    this.appName,
    this.itgrc,
    this.dbVault,
    this.templateId,
    this.templateName,
    this.jsonData,
    this.filename,
    this.requestId,
    this.module,
  });

  factory CheckerTrayItem.fromJson(Map<String, dynamic> json) {
    return CheckerTrayItem(
      departmentName: json['departmentName']?.toString() ?? '',
      makerBy: json['makerBy']?.toString() ?? '',
      makerDate: json['makerDate']?.toString() ?? '',
      sourceId: _parseInt(json['sourceID']),
      sourceName: json['sourceName']?.toString(),
      sourceTypeName: json['sourceTypeName']?.toString(),
      appName: json['appName']?.toString(),
      itgrc: json['itgrc']?.toString(),
      dbVault: json['dbVault']?.toString(),
      templateId: _parseInt(json['templateId'] ?? json['template_id']),
      templateName: json['templateName']?.toString(),
      jsonData: _parseJsonData(json['jsonData']),
      filename: json['filename']?.toString(),
      requestId: json['requestId']?.toString(),
      module: json['module']?.toString(),
    );
  }

  static int? _parseInt(dynamic v) {
    if (v == null) return null;
    if (v is int) return v;
    return int.tryParse(v.toString());
  }

  static Map<String, dynamic>? _parseJsonData(dynamic v) {
    if (v is Map<String, dynamic> && v.isNotEmpty) return v;
    if (v is Map && v.isNotEmpty) return v.map((k, e) => MapEntry(k.toString(), e));
    if (v is String && v.trim().isNotEmpty) {
      try {
        final decoded = jsonDecode(v);
        if (decoded is Map<String, dynamic>) return decoded;
        if (decoded is Map) return decoded.map((k, e) => MapEntry(k.toString(), e));
      } catch (_) {}
    }
    return null;
  }

  /// Converts back to a Map for pages that still accept Map<String, dynamic>.
  Map<String, dynamic> toMap() => {
    'departmentName': departmentName,
    'makerBy': makerBy,
    'makerDate': makerDate,
    if (sourceId != null) 'sourceID': sourceId,
    if (sourceName != null) ...{'sourceName': sourceName, 'Name': sourceName},
    if (sourceTypeName != null) 'sourceTypeName': sourceTypeName,
    if (appName != null) 'appName': appName,
    if (itgrc != null) 'itgrc': itgrc,
    if (dbVault != null) 'dbVault': dbVault,
    if (templateId != null) ...{'templateId': templateId, 'template_id': templateId},
    if (templateName != null) 'templateName': templateName,
    if (jsonData != null) 'jsonData': jsonData,
    if (filename != null) 'filename': filename,
    if (requestId != null) 'requestId': requestId,
    if (module != null) 'module': module,
  };
}
