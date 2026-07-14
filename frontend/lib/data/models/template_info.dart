import 'dart:convert';

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
  final String templateType;
  final int templateId;
  final String templateName;
  final String? department;
  final String frequency;
  final int normalVolume;
  final int peakVolume;
  final int sourceCount;
  final int numberOfOutputs;
  final int benefitType;
  final num benefitAmount;
  final String? benefitInTAT;
  final String? goLiveDate;
  final String? deactivateDate;
  final String? spocPerson;
  final String? spocManager;
  final String? unitHead;
  final int priority;

  final List<String> outputFormats;
  final List<DynamicTemplate> dynamicTemplates;

  final String? departmentName;
  final String? sourceListNames;
  final String? sourceList;

  /// Edit-mode canvas data (jsonData, jsonDataList, approvals, createdBy).
  /// Only populated when loaded via the edit-mode API endpoint (flag=4).
  final TemplateEditConfig? editConfig;

  TemplateInfo({
    required this.templateType,
    required this.templateId,
    required this.templateName,
    this.department,
    required this.frequency,
    required this.normalVolume,
    required this.peakVolume,
    required this.sourceCount,
    required this.numberOfOutputs,
    required this.benefitType,
    required this.benefitAmount,
    this.benefitInTAT,
    this.goLiveDate,
    this.deactivateDate,
    this.spocPerson,
    this.spocManager,
    this.unitHead,
    required this.priority,
    required this.outputFormats,
    required this.dynamicTemplates,
    this.departmentName,
    this.sourceListNames,
    this.sourceList,
    this.editConfig,
  });

  factory TemplateInfo.fromJson(Map<String, dynamic> json) {
    final templateArr = json['Template'] as List?;
    final tpl = (templateArr != null && templateArr.isNotEmpty)
        ? (templateArr[0] as Map<String, dynamic>? ?? {})
        : json;

    // Handle both PascalCase (old nested API) and camelCase (new flat API)
    final outputFormatsArr =
        (json['OutputFormats'] ?? json['outputFormats']) as List?;
    final parsedFormats =
        outputFormatsArr
            ?.map((e) {
              if (e is Map<String, dynamic>) return e;
              if (e is Map) return Map<String, dynamic>.from(e);
              return null;
            })
            .whereType<Map<String, dynamic>>()
            .map((f) => (f['FormatName'] ?? f['formatName'])?.toString() ?? '')
            .where((s) => s.isNotEmpty)
            .toList() ??
        [];

    final dynamicTemplateArr =
        (json['DynamicTemplate'] ?? json['dynamicTemplate']) as List?;
    final parsedDynamicTemplates =
        (dynamicTemplateArr ?? [])
            .map((e) {
              if (e is Map<String, dynamic>) return DynamicTemplate.fromJson(e);
              if (e is Map) {
                return DynamicTemplate.fromJson(Map<String, dynamic>.from(e));
              }
              return null;
            })
            .whereType<DynamicTemplate>()
            .toList();

    return TemplateInfo(
      templateType:
          tpl['TemplateType']?.toString() ??
          tpl['templateType']?.toString() ??
          '',
      templateId: _toInt(tpl['TemplateId'] ?? tpl['templateId']),
      templateName:
          tpl['TemplateName']?.toString() ??
          tpl['templateName']?.toString() ??
          '',
      department: (tpl['Department'] ?? tpl['department'])?.toString(),
      frequency:
          tpl['Frequency']?.toString() ?? tpl['frequency']?.toString() ?? '',
      normalVolume: _toInt(tpl['NormalVolume'] ?? tpl['normalVolume']),
      peakVolume: _toInt(tpl['PeakVolume'] ?? tpl['peakVolume']),
      sourceCount: _toInt(tpl['SourceCount'] ?? tpl['sourceCount']),
      numberOfOutputs: _toInt(tpl['NumberOfOutputs'] ?? tpl['numberOfOutputs']),
      benefitType: _toInt(tpl['BenefitType'] ?? tpl['benefitType']),
      benefitAmount: _toNum(tpl['BenefitAmount'] ?? tpl['benefitAmount']),
      benefitInTAT: (tpl['BenefitInTat'] ?? tpl['benefitInTAT'])?.toString(),
      goLiveDate: (tpl['GoLiveDate'] ?? tpl['goLiveDate'])?.toString(),
      deactivateDate:
          (tpl['DeactivateDate'] ?? tpl['deactivateDate'])?.toString(),
      spocPerson: (tpl['SpocPerson'] ?? tpl['spocPerson'])?.toString(),
      spocManager: (tpl['SpocManager'] ?? tpl['spocManager'])?.toString(),
      unitHead: (tpl['UnitHead'] ?? tpl['unitHead'])?.toString(),
      priority: _toInt(tpl['Priority'] ?? tpl['priority']),
      outputFormats: parsedFormats,
      dynamicTemplates: parsedDynamicTemplates,
      departmentName:
          (json['DepartmentName'] ?? json['departmentName'])?.toString(),
      sourceListNames:
          (json['SourceListNames'] ?? json['sourceListNames'])?.toString(),
      sourceList: (tpl['SourceList'] ?? tpl['sourceList'])?.toString(),
      editConfig: TemplateEditConfig.fromJson(json, tpl),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'templateType': templateType,
      'templateId': templateId,
      'templateName': templateName,
      'department': department,
      'frequency': frequency,
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
      'priority': priority,
      'departmentName': departmentName,
      'sourceListNames': sourceListNames,
      'sourceList': sourceList,
      'outputFormats': outputFormats,
      'dynamicTemplate': dynamicTemplates.map((e) => e.toJson()).toList(),
    };
  }

  static int _toInt(dynamic v) => v is int ? v : int.tryParse('$v') ?? 0;
  static num _toNum(dynamic v) => v is num ? v : num.tryParse('$v') ?? 0;
}

/// Canvas configuration data from edit-mode API responses.
/// Kept separate from TemplateInfo to maintain a clean domain model.
class TemplateEditConfig {
  final Map<String, dynamic>? jsonData;
  final List<Map<String, dynamic>> jsonDataList;
  final String createdBy;
  final List<Map<String, dynamic>> approvals;

  const TemplateEditConfig({
    this.jsonData,
    this.jsonDataList = const [],
    this.createdBy = '',
    this.approvals = const [],
  });

  factory TemplateEditConfig.fromJson(
    Map<String, dynamic> json,
    Map<String, dynamic> tpl,
  ) {
    final approvalsArr = json['Approvals'] as List?;
    final parsedApprovals =
        approvalsArr?.whereType<Map<String, dynamic>>().toList() ?? [];

    Map<String, dynamic>? parsedJsonData;
    List<Map<String, dynamic>> parsedJsonDataList = [];
    final rawJsonData =
        json['jsonData'] ??
        json['JsonData'] ??
        tpl['jsonData'] ??
        tpl['JsonData'];
    if (rawJsonData is List && rawJsonData.isNotEmpty) {
      parsedJsonDataList =
          rawJsonData
              .map((e) {
                if (e is Map<String, dynamic>) return e;
                if (e is Map) return Map<String, dynamic>.from(e);
                return null;
              })
              .whereType<Map<String, dynamic>>()
              .toList();
      final first = rawJsonData.first;
      if (first is Map<String, dynamic>) {
        parsedJsonData = first;
      } else if (first is Map) {
        parsedJsonData = first.map((k, v) => MapEntry(k.toString(), v));
      }
    } else if (rawJsonData is Map<String, dynamic>) {
      parsedJsonData = rawJsonData;
      parsedJsonDataList = [rawJsonData];
    } else if (rawJsonData is Map) {
      parsedJsonData = rawJsonData.map((k, v) => MapEntry(k.toString(), v));
      parsedJsonDataList = [parsedJsonData];
    } else if (rawJsonData is String && rawJsonData.trim().isNotEmpty) {
      try {
        final decoded = jsonDecode(rawJsonData);
        if (decoded is Map<String, dynamic>) {
          parsedJsonData = decoded;
          parsedJsonDataList = [decoded];
        }
        if (decoded is Map) {
          parsedJsonData = decoded.map((k, v) => MapEntry(k.toString(), v));
          parsedJsonDataList = [parsedJsonData];
        }
      } catch (_) {}
    }

    return TemplateEditConfig(
      jsonData: parsedJsonData,
      jsonDataList: parsedJsonDataList,
      createdBy:
          json['CreatedBy']?.toString() ?? json['createdBy']?.toString() ?? '',
      approvals: parsedApprovals,
    );
  }
}

class DynamicTemplate {
  final int srno;
  final int id;
  final String sourceList;
  final String sourceCount;
  final String? sourceListName;
  final int templateId;
  final String sourceType;

  final List<SourceMasterInfo> sourceMasterList;

  DynamicTemplate({
    required this.srno,
    required this.id,
    required this.sourceList,
    required this.sourceCount,
    this.sourceListName,
    required this.templateId,
    required this.sourceType,
    required this.sourceMasterList,
  });

  factory DynamicTemplate.fromJson(Map<String, dynamic> json) {
    return DynamicTemplate(
      srno: json['srno'] ?? 0,
      id: json['id'] ?? 0,
      sourceList: json['sourceList']?.toString() ?? '',
      sourceCount: json['sourceCount']?.toString() ?? '0',
      sourceListName: json['sourceListName'],
      templateId: json['templateId'] ?? 0,
      sourceType: json['sourceType']?.toString() ?? '',
      sourceMasterList: (json['sourceMasterList'] as List<dynamic>? ?? [])
          .map((e) => SourceMasterInfo.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'srno': srno,
      'id': id,
      'sourceList': sourceList,
      'sourceCount': sourceCount,
      'sourceListName': sourceListName,
      'templateId': templateId,
      'sourceType': sourceType,
      'sourceMasterList': sourceMasterList.map((e) => e.toJson()).toList(),
    };
  }
}

class SourceMasterInfo {
  final int id;
  final String name;
  final String sourceType;
  final String? appName;
  final int itgrc;
  final String? dbVault;
  final String? createdBy;
  final String? createdOn;
  final String? svalues;
  final String? departmentId;
  final String? type;
  final int? templateId;
  final String? typeId;

  SourceMasterInfo({
    required this.id,
    required this.name,
    required this.sourceType,
    this.appName,
    required this.itgrc,
    this.dbVault,
    this.createdBy,
    this.createdOn,
    this.svalues,
    this.departmentId,
    this.type,
    this.templateId,
    this.typeId,
  });

  factory SourceMasterInfo.fromJson(Map<String, dynamic> json) {
    return SourceMasterInfo(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      sourceType: json['sourceType']?.toString() ?? '',
      appName: json['appName'],
      itgrc: json['itgrc'] ?? 0,
      dbVault: json['dbVault'],
      createdBy: json['createdBy'],
      createdOn: json['createdOn'],
      svalues: json['svalues'],
      departmentId: json['department_id']?.toString(),
      type: json['type']?.toString(),
      templateId: json['template_id'],
      typeId: json['typeId']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'sourceType': sourceType,
      'appName': appName,
      'itgrc': itgrc,
      'dbVault': dbVault,
      'createdBy': createdBy,
      'createdOn': createdOn,
      'svalues': svalues,
      'department_id': departmentId,
      'type': type,
      'template_id': templateId,
      'typeId': typeId,
    };
  }
}
