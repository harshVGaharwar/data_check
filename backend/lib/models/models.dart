import 'dart:convert';

// ═══════════════════════════════════════════════════
// API Response wrapper
// ═══════════════════════════════════════════════════
class ApiResponse {
  final String status;
  final String message;
  final dynamic data;

  ApiResponse({required this.status, this.message = '', this.data});

  Map<String, dynamic> toJson() => {
    'status': status,
    'message': message,
    if (data != null) 'data': data,
  };

  factory ApiResponse.success({String message = 'Success', dynamic data}) =>
      ApiResponse(status: 'success', message: message, data: data);

  factory ApiResponse.error({String message = 'Error'}) =>
      ApiResponse(status: 'error', message: message);
}

// ═══════════════════════════════════════════════════
// User / Auth
// ═══════════════════════════════════════════════════
class User {
  final String id;
  final String username;
  final String password;
  final String role;
  final DateTime createdAt;

  User({
    required this.id,
    required this.username,
    required this.password,
    this.role = 'user',
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toPublicJson() => {
    'userId': id,
    'username': username,
    'role': role,
  };
}

// ═══════════════════════════════════════════════════
// Department
// ═══════════════════════════════════════════════════
class Department {
  final int id;
  final String name;

  Department({required this.id, required this.name});

  Map<String, dynamic> toJson() => {'dpt_Id': id, 'dpt_Name': name};
}

// ═══════════════════════════════════════════════════
// Template
// ═══════════════════════════════════════════════════
class Template {
  final String id;
  String templateName;
  String department;
  String frequency;
  String priority;
  int normalVolume;
  int peakVolume;
  int sourceCount;
  int numberOfOutputs;
  String benefitType;
  double benefitAmount;
  String benefitInTAT;
  String goLiveDate;
  String deactivateDate;
  String spocPerson;
  String spocManager;
  String unitHead;
  List<String> outputFormats;
  List<String> approvals;
  Map<String, String> approvalFiles;
  String status;
  DateTime createdAt;

  Template({
    required this.id,
    required this.templateName,
    this.department = '',
    this.frequency = '',
    this.priority = 'Medium',
    this.normalVolume = 0,
    this.peakVolume = 0,
    this.sourceCount = 0,
    this.numberOfOutputs = 0,
    this.benefitType = '',
    this.benefitAmount = 0,
    this.benefitInTAT = '',
    this.goLiveDate = '',
    this.deactivateDate = '',
    this.spocPerson = '',
    this.spocManager = '',
    this.unitHead = '',
    List<String>? outputFormats,
    List<String>? approvals,
    Map<String, String>? approvalFiles,
    this.status = 'draft',
    DateTime? createdAt,
  })  : outputFormats = outputFormats ?? [],
        approvals = approvals ?? [],
        approvalFiles = approvalFiles ?? {},
        createdAt = createdAt ?? DateTime.now();

  factory Template.fromJson(String id, Map<String, dynamic> json) {
    return Template(
      id: id,
      templateName: json['templateName'] ?? '',
      department: json['department'] ?? '',
      frequency: json['frequency'] ?? '',
      priority: json['priority'] ?? 'Medium',
      normalVolume: _toInt(json['normalVolume']),
      peakVolume: _toInt(json['peakVolume']),
      sourceCount: _toInt(json['sourceCount']),
      numberOfOutputs: _toInt(json['numberOfOutputs']),
      benefitType: json['benefitType'] ?? '',
      benefitAmount: _toDouble(json['benefitAmount']),
      benefitInTAT: json['benefitInTAT'] ?? '',
      goLiveDate: json['goLiveDate'] ?? '',
      deactivateDate: json['deactivateDate'] ?? '',
      spocPerson: json['spocPerson'] ?? '',
      spocManager: json['spocManager'] ?? '',
      unitHead: json['unitHead'] ?? '',
      outputFormats: _toStringList(json['outputFormats']),
      approvals: _toStringList(json['approvals']),
      approvalFiles: _toStringMap(json['approvalFiles']),
    );
  }

  Map<String, dynamic> toJson() => {
    'templateId': id,
    'templateName': templateName,
    'department': department,
    'frequency': frequency,
    'priority': priority,
    'normalVolume': normalVolume,
    'peakVolume': peakVolume,
    'sourceCount': sourceCount,
    'numberOfOutputs': numberOfOutputs,
    'benefitType': benefitType,
    'benefitAmount': benefitAmount,
    'benefitInTAT': benefitInTAT,
    'goLiveDate': goLiveDate,
    'deactivateDate': deactivateDate,
    'spocPerson': spocPerson,
    'spocManager': spocManager,
    'unitHead': unitHead,
    'outputFormats': outputFormats,
    'approvals': approvals,
    'approvalFiles': approvalFiles,
    'status': status,
    'createdAt': createdAt.toIso8601String(),
  };

  static int _toInt(dynamic v) => v is int ? v : int.tryParse('$v') ?? 0;
  static double _toDouble(dynamic v) => v is double ? v : double.tryParse('$v') ?? 0;
  static List<String> _toStringList(dynamic v) {
    if (v is List) return v.map((e) => '$e').toList();
    if (v is String) {
      try { return (jsonDecode(v) as List).map((e) => '$e').toList(); } catch (_) {}
    }
    return [];
  }
  static Map<String, String> _toStringMap(dynamic v) {
    if (v is Map) return v.map((k, val) => MapEntry('$k', '$val'));
    if (v is String) {
      try { return (jsonDecode(v) as Map).map((k, val) => MapEntry('$k', '$val')); } catch (_) {}
    }
    return {};
  }
}

// ═══════════════════════════════════════════════════
// Template Checker Tray Item
// ═══════════════════════════════════════════════════

/// Represents one row returned by the GetTemplateCheckerTray API.
/// TemplateType inside jsonData drives the UI:
///   "1" → Static + User Defined
///   "2" → Static + Unimailing
///   "3" → Dynamic + Unimailing  (DynamicTemplate list populated)
///
/// [jsonData] is typed as [dynamic] so it survives the production path:
///   - If the real API sends a valid JSON string  → decoded to Map
///   - If the real API sends malformed JSON string → raw string kept as-is
///     (the frontend's _parseJsonData handles both Map and String)
class TemplateCheckerTrayItem {
  final String templateId;
  final String departmentId;
  final String templateName;
  final String departmentName;
  final String makerBy;
  final String makerDate;

  /// Decoded Map<String,dynamic> in dev/happy-path.
  /// Raw JSON string when the real API returns malformed JSON (type 3 edge case).
  final dynamic jsonData;

  const TemplateCheckerTrayItem({
    required this.templateId,
    required this.departmentId,
    required this.templateName,
    required this.departmentName,
    required this.makerBy,
    required this.makerDate,
    required this.jsonData,
  });

  /// Build from a raw API map where [jsonData] may be a JSON string or Map.
  /// Handles the known real-API malformation for TemplateType "3" where an
  /// extra `}]` appears before "Approvals" and an extra `}` before
  /// "DynamicTemplate", causing standard jsonDecode to fail.
  factory TemplateCheckerTrayItem.fromMap(Map<String, dynamic> map) {
    final raw = map['jsonData'];
    dynamic jsonData;

    if (raw is Map<String, dynamic>) {
      jsonData = raw;
    } else if (raw is Map) {
      jsonData = raw.map((k, v) => MapEntry(k.toString(), v));
    } else if (raw is List) {
      jsonData = raw;
    } else if (raw is String && raw.trim().isNotEmpty) {
      // First attempt: direct decode (valid JSON — may be Map or List)
      try {
        jsonData = _decodeJsonValue(raw);
      } catch (_) {
        // Second attempt: repair known Map malformations then decode
        try {
          jsonData = _decodeJsonValue(_repairJsonData(raw));
        } catch (_) {
          jsonData = raw; // last resort — pass raw string to frontend
        }
      }
    } else {
      jsonData = raw ?? '';
    }

    return TemplateCheckerTrayItem(
      templateId: map['templateId']?.toString() ?? '',
      departmentId: map['departmentId']?.toString() ?? '',
      templateName: map['templateName']?.toString() ?? '',
      departmentName: map['departmentName']?.toString() ?? '',
      makerBy: map['makerBy']?.toString() ?? '',
      makerDate: map['makerDate']?.toString() ?? '',
      jsonData: jsonData,
    );
  }

  /// Decode a JSON string into Map<String,dynamic> or List — whatever the JSON contains.
  static dynamic _decodeJsonValue(String s) {
    final decoded = jsonDecode(s);
    if (decoded is Map<String, dynamic>) return decoded;
    if (decoded is Map) return decoded.map((k, v) => MapEntry(k.toString(), v));
    if (decoded is List) return decoded;
    throw const FormatException('Unexpected JSON shape');
  }

  /// Repair the two known malformations in the real API's TemplateType-3 response:
  ///   1. Spurious `}]` injected before "Approvals" key.
  ///   2. Spurious `}` injected before "DynamicTemplate" key.
  static String _repairJsonData(String s) {
    // Remove extra `}]` before "Approvals":
    var r = s.replaceFirst(RegExp(r'\}\]\s*,\s*"Approvals"'), ',"Approvals"');
    // Remove extra `}` before "DynamicTemplate":
    r = r.replaceFirst(RegExp(r'\}\s*,\s*"DynamicTemplate"'), ',"DynamicTemplate"');
    return r;
  }

  Map<String, dynamic> toJson() => {
    'templateId': templateId,
    'departmentId': departmentId,
    'templateName': templateName,
    'departmentName': departmentName,
    'makerBy': makerBy,
    'makerDate': makerDate,
    'jsonData': jsonData, // Map or raw String — frontend handles both
  };
}

// ═══════════════════════════════════════════════════
// Pipeline Source Config
// ═══════════════════════════════════════════════════
class PipelineConfig {
  final String id;
  final List<Map<String, dynamic>> sources;
  final List<Map<String, dynamic>> joinMappings;
  final List<Map<String, dynamic>> edges;
  final DateTime createdAt;

  PipelineConfig({
    required this.id,
    required this.sources,
    required this.joinMappings,
    required this.edges,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toJson() => {
    'configurationId': id,
    'sources': sources,
    'joinMappings': joinMappings,
    'edges': edges,
    'createdAt': createdAt.toIso8601String(),
  };
}
