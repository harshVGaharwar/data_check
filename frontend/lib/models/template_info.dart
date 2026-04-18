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
  });

  factory TemplateInfo.fromJson(Map<String, dynamic> json) {
    return TemplateInfo(
      templateId: _toInt(json['templateId']),
      templateName: json['templateName']?.toString() ?? '',
      department: json['department']?.toString() ?? '',
      frequency: json['frequency']?.toString() ?? '',
      sourceCount: _toInt(json['sourceCount']),
      numberOfOutputs: _toInt(json['numberOfOutputs']),
      normalVolume: _toInt(json['normalVolume']),
      peakVolume: _toInt(json['peakVolume']),
      priority: json['priority']?.toString() ?? '',
      benefitType: json['benefitType']?.toString() ?? '',
      benefitAmount: _toDouble(json['benefitAmount']),
      outputFormats: (json['outputFormats'] as List?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
    );
  }

  static int _toInt(dynamic v) =>
      v is int ? v : int.tryParse('$v') ?? 0;
  static double _toDouble(dynamic v) =>
      v is double ? v : double.tryParse('$v') ?? 0;
}
