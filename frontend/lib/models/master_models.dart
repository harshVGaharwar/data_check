class DepartmentItem {
  final int id;
  final String name;

  const DepartmentItem({required this.id, required this.name});

  factory DepartmentItem.fromJson(Map<String, dynamic> json) {
    return DepartmentItem(
      id: json['dpt_Id'] as int? ?? int.tryParse('${json['dpt_Id']}') ?? 0,
      name: (json['dpt_Name'] ?? '').toString(),
    );
  }
}

class ApprovalItem {
  final int id;
  final String name;

  const ApprovalItem({this.id = 0, required this.name});

  factory ApprovalItem.fromJson(Map<String, dynamic> json) => ApprovalItem(
    id: json['id'] as int? ?? 0,
    name: (json['approvalName'] ?? '').toString(),
  );

  static List<ApprovalItem> listFromJson(List<dynamic> json) =>
      json
          .whereType<Map<String, dynamic>>()
          .map(ApprovalItem.fromJson)
          .toList();
}

class SourceTypeItem {
  final int id;
  final String sourceName;
  final String sourceValue;

  const SourceTypeItem({
    required this.id,
    required this.sourceName,
    required this.sourceValue,
  });

  factory SourceTypeItem.fromJson(Map<String, dynamic> json) {
    return SourceTypeItem(
      id: json['id'] as int? ?? 0,
      sourceName: json['sourceName'] as String? ?? '',
      sourceValue: json['sourceValue'] as String? ?? '',
    );
  }
}

class SourceMasterItem {
  final int id;
  final String name;
  final String sourceType;
  final String appName;
  final int itgrc;
  final String dbVault;
  final String createdBy;

  const SourceMasterItem({
    required this.id,
    required this.name,
    required this.sourceType,
    required this.appName,
    required this.itgrc,
    required this.dbVault,
    required this.createdBy,
  });

  factory SourceMasterItem.fromJson(Map<String, dynamic> json) {
    return SourceMasterItem(
      id: json['id'] as int? ?? 0,
      name: (json['name'] as String? ?? '').trim(),
      sourceType: json['sourceType'] as String? ?? '',
      appName: json['appName'] as String? ?? '',
      itgrc: json['itgrc'] as int? ?? 0,
      dbVault: json['dbVault'] as String? ?? '',
      createdBy: json['createdBy'] as String? ?? '',
    );
  }

  /// Label shown in the UI: "name (sourceType)" or just "sourceType"
  String get displayName =>
      name.isNotEmpty ? '$name ($sourceType)' : sourceType;

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'sourceType': sourceType,
    'appName': appName,
    'itgrc': itgrc,
    'dbVault': dbVault,
    'createdBy': createdBy,
  };
}

class OperationItem {
  final int id;
  final String operationName;
  final String operationValue;

  const OperationItem({
    required this.id,
    required this.operationName,
    required this.operationValue,
  });

  factory OperationItem.fromJson(Map<String, dynamic> json) {
    return OperationItem(
      id: json['id'] as int? ?? 0,
      operationName: json['operationName'] as String? ?? '',
      operationValue: json['operationValue'] as String? ?? '',
    );
  }
}
