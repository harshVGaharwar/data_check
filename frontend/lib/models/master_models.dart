/// Item returned by GetSourceList
class SourceListItem {
  final int id;
  final String name;

  const SourceListItem({required this.id, required this.name});

  factory SourceListItem.fromJson(Map<String, dynamic> json) {
    return SourceListItem(
      id: json['id'] as int? ?? int.tryParse('${json['id']}') ?? 0,
      name: (json['s_Name'] ?? '').toString(),
    );
  }
}

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

  static List<ApprovalItem> listFromJson(List<dynamic> json) => json
      .whereType<Map<String, dynamic>>()
      .map(ApprovalItem.fromJson)
      .toList();
}

class SourceTypeItem {
  final int id;
  final String sourceName;
  final String sourceValue;
  final int? sourceType;

  const SourceTypeItem({
    required this.id,
    required this.sourceName,
    required this.sourceValue,
    this.sourceType,
  });

  factory SourceTypeItem.fromJson(Map<String, dynamic> json) {
    return SourceTypeItem(
      id: json['id'] as int? ?? 0,
      sourceName: json['sourceName'] as String? ?? '',
      sourceValue: json['sourceValue'] as String? ?? '',
      sourceType: int.tryParse(json['sourceType']?.toString() ?? ''),
    );
  }
}

/// Item returned by template/GetSourceMasterListFilterwise
class SourceMasterFilterItem {
  final int id;
  final String name;
  final int? sourceType;
  final String? appName;
  final int itgrc;
  final String? dbVault;
  final String? createdBy;
  final String templateId;
  final String departmentId;

  const SourceMasterFilterItem({
    required this.id,
    required this.name,
    this.sourceType,
    this.appName,
    required this.itgrc,
    this.dbVault,
    this.createdBy,
    required this.templateId,
    required this.departmentId,
  });

  factory SourceMasterFilterItem.fromJson(Map<String, dynamic> json) {
    return SourceMasterFilterItem(
      id: json['id'] as int? ?? 0,
      name: (json['name'] ?? '').toString(),
      sourceType: int.tryParse(json['sourceType']?.toString() ?? ''),
      appName: json['appName'] as String?,
      itgrc: json['itgrc'] as int? ?? 0,
      dbVault: json['dbVault'] as String?,
      createdBy: json['createdBy'] as String?,
      templateId: (json['template_id'] ?? '').toString(),
      departmentId: (json['department_id'] ?? '').toString(),
    );
  }

  String get sourceTypeLabel {
    switch (sourceType) {
      case 1: return 'Manual';
      case 2: return 'QRS';
      case 3: return 'FC';
      default: return '';
    }
  }
}


class DashboardCount {
  final String count;
  final String label;
  final String lightColor;
  final String icon;
  final String darkColor;

  DashboardCount({
    required this.count,
    required this.label,
    required this.lightColor,
    required this.icon,
    required this.darkColor,
  });

  factory DashboardCount.fromJson(Map<String, dynamic> json) {
    return DashboardCount(
      count: json['count'] ?? '',
      label: json['label'] ?? '',
      lightColor: json['lightColor'] ?? '',
      icon: json['icon'] ?? '',
      darkColor: json['darkColor'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'count': count,
      'label': label,
      'lightColor': lightColor,
      'icon': icon,
      'darkColor': darkColor,
    };
  }
}

class DashboardDetails {
  final List<DashboardCount> dashboardCount;

  DashboardDetails({required this.dashboardCount});

  factory DashboardDetails.fromJson(Map<String, dynamic> json) {
    return DashboardDetails(
      dashboardCount: (json['dashboardCount'] as List<dynamic>)
          .map((item) => DashboardCount.fromJson(item))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'dashboardCount': dashboardCount.map((e) => e.toJson()).toList(),
    };
  }
}

class SourceMasterItem {
  final int id;
  final String name;
  final int? sourceType;
  final String appName;
  final int itgrc;
  final String dbVault;
  final String createdBy;
  final dynamic departmentId;

  const SourceMasterItem({
    required this.id,
    required this.name,
    this.sourceType,
    required this.appName,
    required this.itgrc,
    required this.dbVault,
    required this.createdBy,
    this.departmentId,
  });

  factory SourceMasterItem.fromJson(Map<String, dynamic> json) {
    return SourceMasterItem(
      id: json['id'] as int? ?? 0,
      name: (json['name'] as String? ?? '').trim(),
      sourceType: int.tryParse(json['sourceType']?.toString() ?? ''),
      appName: json['appName'] as String? ?? '',
      itgrc: json['itgrc'] as int? ?? 0,
      dbVault: json['dbVault'] as String? ?? '',
      createdBy: json['createdBy'] as String? ?? '',
      departmentId: json['department_id'],
    );
  }

  String get sourceTypeLabel {
    switch (sourceType) {
      case 1: return 'Manual';
      case 2: return 'QRS';
      case 3: return 'FC';
      default: return '';
    }
  }

  /// Label shown in the UI: "name (sourceTypeLabel)" or just "name"
  String get displayName =>
      name.isNotEmpty && sourceTypeLabel.isNotEmpty
          ? '$name ($sourceTypeLabel)'
          : name.isNotEmpty
          ? name
          : sourceTypeLabel;

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'sourceType': sourceType,
    'appName': appName,
    'itgrc': itgrc,
    'dbVault': dbVault,
    'createdBy': createdBy,
    'department_id': departmentId,
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
