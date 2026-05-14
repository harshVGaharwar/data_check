/// Lightweight template model returned by GetManualTemplateDetails.
/// Response shape: { templateId, templateName, department, sourceCount, manualCount }
class ManualTemplateInfo {
  final int templateId;
  final String templateName;
  final String? department;
  final int sourceCount;
  final int manualCount;

  ManualTemplateInfo({
    required this.templateId,
    required this.templateName,
    this.department,
    required this.sourceCount,
    required this.manualCount,
  });

  factory ManualTemplateInfo.fromJson(Map<String, dynamic> json) {
    return ManualTemplateInfo(
      templateId: _toInt(json['templateId']),
      templateName: json['templateName']?.toString() ?? '',
      department: json['department']?.toString(),
      sourceCount: _toInt(json['sourceCount']),
      manualCount: _toInt(json['manualCount']),
    );
  }

  static int _toInt(dynamic v) => v is int ? v : int.tryParse('$v') ?? 0;
}

class TemplateInfo {
  final int templateId;
  final String templateName;
  final String department;
  final String frequency;
  final int sourceCount;
  final int numberOfOutputs;
  final int normalVolume;
  final int peakVolume;
  final String priority;
  final String benefitType;
  final double benefitAmount;
  final List<String> outputFormats;
  final String templateType;
  final String benefitInTAT;
  final String goLiveDate;
  final String deactivateDate;
  final String spocPerson;
  final String spocManager;
  final String unitHead;
  final String sourceList;
  final String createdBy;
  final String departmentName;
  final String sourceListNames;
  final List<Map<String, dynamic>> approvals;

  TemplateInfo({
    required this.templateId,
    required this.templateName,
    required this.department,
    required this.frequency,
    required this.sourceCount,
    required this.numberOfOutputs,
    required this.normalVolume,
    required this.peakVolume,
    required this.priority,
    required this.benefitType,
    required this.benefitAmount,
    required this.outputFormats,
    this.templateType = '',
    this.benefitInTAT = '',
    this.goLiveDate = '',
    this.deactivateDate = '',
    this.spocPerson = '',
    this.spocManager = '',
    this.unitHead = '',
    this.sourceList = '',
    this.createdBy = '',
    this.departmentName = '',
    this.sourceListNames = '',
    this.approvals = const [],
  });

  /// Parses the nested response shape returned by GetTemplates?deptId=&flag=:
  /// { Template:[{...}], OutputFormats:[{FormatName}], Approvals:[{...}], CreatedBy, DepartmentName, SourceListNames }
  /// Falls back to a flat camelCase shape for backwards-compatible endpoints.
  factory TemplateInfo.fromJson(Map<String, dynamic> json) {
    final templateArr = json['Template'] as List?;
    final tpl = (templateArr != null && templateArr.isNotEmpty)
        ? (templateArr[0] as Map<String, dynamic>? ?? {})
        : json;

    final outputFormatsArr = json['OutputFormats'] as List?;
    final parsedFormats = outputFormatsArr
            ?.whereType<Map<String, dynamic>>()
            .map((f) => f['FormatName']?.toString() ?? '')
            .where((s) => s.isNotEmpty)
            .toList() ??
        (json['outputFormats'] as List?)?.map((e) => e.toString()).toList() ??
        [];

    final approvalsArr = json['Approvals'] as List?;
    final parsedApprovals = approvalsArr
            ?.whereType<Map<String, dynamic>>()
            .toList() ??
        [];

    return TemplateInfo(
      templateId: _toInt(tpl['TemplateId'] ?? tpl['templateId']),
      templateName: tpl['TemplateName']?.toString() ?? tpl['templateName']?.toString() ?? '',
      department: tpl['Department']?.toString() ?? tpl['department']?.toString() ?? '',
      frequency: tpl['Frequency']?.toString() ?? tpl['frequency']?.toString() ?? '',
      sourceCount: _toInt(tpl['SourceCount'] ?? tpl['sourceCount']),
      numberOfOutputs: _toInt(tpl['NumberOfOutputs'] ?? tpl['numberOfOutputs']),
      normalVolume: _toInt(tpl['NormalVolume'] ?? tpl['normalVolume']),
      peakVolume: _toInt(tpl['PeakVolume'] ?? tpl['peakVolume']),
      priority: tpl['Priority']?.toString() ?? tpl['priority']?.toString() ?? '',
      benefitType: tpl['BenefitType']?.toString() ?? tpl['benefitType']?.toString() ?? '',
      benefitAmount: _toDouble(tpl['BenefitAmount'] ?? tpl['benefitAmount']),
      outputFormats: parsedFormats,
      templateType: tpl['TemplateType']?.toString() ?? tpl['templateType']?.toString() ?? '',
      benefitInTAT: tpl['BenefitInTat']?.toString() ?? tpl['benefitInTAT']?.toString() ?? '',
      goLiveDate: tpl['GoLiveDate']?.toString() ?? tpl['goLiveDate']?.toString() ?? '',
      deactivateDate: tpl['DeactivateDate']?.toString() ?? tpl['deactivateDate']?.toString() ?? '',
      spocPerson: tpl['SpocPerson']?.toString() ?? tpl['spocPerson']?.toString() ?? '',
      spocManager: tpl['SpocManager']?.toString() ?? tpl['spocManager']?.toString() ?? '',
      unitHead: tpl['UnitHead']?.toString() ?? tpl['unitHead']?.toString() ?? '',
      sourceList: tpl['SourceList']?.toString() ?? tpl['sourceList']?.toString() ?? '',
      createdBy: json['CreatedBy']?.toString() ?? json['createdBy']?.toString() ?? '',
      departmentName: json['DepartmentName']?.toString() ?? json['departmentName']?.toString() ?? '',
      sourceListNames: json['SourceListNames']?.toString() ?? json['sourceListNames']?.toString() ?? '',
      approvals: parsedApprovals,
    );
  }

  static int _toInt(dynamic v) =>
      v is int ? v : int.tryParse('$v') ?? 0;
  static double _toDouble(dynamic v) =>
      v is double ? v : double.tryParse('$v') ?? 0;
}
