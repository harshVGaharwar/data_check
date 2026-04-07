class DepartmentItem {
  final int id;
  final String name;

  const DepartmentItem({required this.id, required this.name});

  factory DepartmentItem.fromJson(Map<String, dynamic> json) {
    return DepartmentItem(
      id: json['id'] as int? ?? int.tryParse('${json['id']}') ?? 0,
      name: (json['name'] ?? json['departmentName'] ?? '').toString(),
    );
  }
}

class ApprovalItem {
  final String name;

  const ApprovalItem({required this.name});

  factory ApprovalItem.fromJson(dynamic json) {
    if (json is String) return ApprovalItem(name: json);
    if (json is Map<String, dynamic>) {
      return ApprovalItem(
        name: (json['name'] ?? json['approvalName'] ?? '').toString(),
      );
    }
    return ApprovalItem(name: json.toString());
  }
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
