class DynamicOutputModel {
  int sourceCount;
  List<Map<String, dynamic>> sourceList;

  DynamicOutputModel({
    this.sourceCount = 0,
    List<Map<String, dynamic>>? sourceList,
  }) : sourceList = sourceList ?? [];

  bool get isValid => sourceCount > 0 && sourceList.isNotEmpty;

  Map<String, dynamic> toJson() => {
    'SourceList': sourceList.map((m) => m['id']).join(','),
    'SourceCount': sourceCount.toString(),
    'SourceType': "3",
  };
}

class TemplateRequest {
  String templateName;
  String department;
  String frequency;
  int frequencyId;
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
  String priority;
  String templateType;
  String createdBy;
  List<String> outputFormats;
  List<String> approvals;
  String departmentName;
  String sourceListName;

  /// Per-approval file uploads: {"Unit Head": "approval_uh.pdf", ...}
  Map<String, String> approvalFiles;

  /// Selected source master items (static case)
  List<Map<String, dynamic>> sourceList;

  /// Per-output source config (dynamic case)
  List<DynamicOutputModel> dynamicOutputs;

  TemplateRequest({
    this.templateName = '',
    this.department = '',
    this.frequency = '',
    this.frequencyId = 0,
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
    this.priority = 'Medium',
    this.templateType = '',
    this.createdBy = '',
    this.sourceListName = '',
    this.departmentName = '',
    List<String>? outputFormats,
    List<String>? approvals,
    Map<String, String>? approvalFiles,
    List<Map<String, dynamic>>? sourceList,
    List<DynamicOutputModel>? dynamicOutputs,
  }) : outputFormats = outputFormats ?? [],
       approvals = approvals ?? [],
       approvalFiles = approvalFiles ?? {},
       sourceList = sourceList ?? [],
       dynamicOutputs = dynamicOutputs ?? [];

  bool get isDynamic => templateType == '2 - Dynamic';

  /// "1" = Static + User Defined
  /// "2" = Static + UniMailing
  /// "3" = Dynamic + UniMailing
  ///       1.1-->static
  ///       1.2-->dynamic
  ///       1.n--->dynmic n
  ///
  ///
  String get templateTypeCode {
    if (isDynamic) return '3';
    if (outputFormats.any((f) => f.toLowerCase().contains('unimailing'))) {
      return '2';
    }
    return '1';
  }

  Map<String, dynamic> toJson() => {
    'TemplateType': templateTypeCode,
    'Template': [
      {
        'TemplateName': templateName,
        'Department': department,
        'Frequency': frequencyId.toString(),
        'FrequencyName': frequency,
        'NormalVolume': normalVolume,
        'PeakVolume': peakVolume,
        'SourceCount': sourceCount,
        'BenefitType': benefitType,
        'BenefitAmount': benefitAmount,
        'BenefitInTat': benefitInTAT,
        'GoLiveDate': goLiveDate.isEmpty ? null : goLiveDate,
        'DeactivateDate': deactivateDate.isEmpty ? null : deactivateDate,
        'SpocPerson': spocPerson,
        'SpocManager': spocManager,
        'UnitHead': unitHead,
        'Priority': priority,
        'NumberOfOutputs': isDynamic ? numberOfOutputs : null,
        'SourceList': sourceList.map((m) => m['id']).join(','),
      },
    ],
    'OutputFormats': (() {
      // Dynamic → always Unimailing; Static → deduplicate, keep one
      final formats = isDynamic
          ? ['Unimailing']
          : outputFormats.toSet().toList();
      return formats
          .map((f) => {'TemplateTempId': null, 'FormatName': f})
          .toList();
    })(),
    'Approvals': approvals
        .map(
          (a) => {
            'TemplateTempId': null,
            'Approval_Type': a,
            'ApprovalFile': approvalFiles[a] ?? '',
          },
        )
        .toList(),
    'CreatedBy': createdBy,
    'jsonData': '',
    'DepartmentName': departmentName,
    'SourceListNames': sourceListName,
    'DynamicTemplate': isDynamic
        ? [
            {
              'SourceList': sourceList.map((m) => m['id']).join(','),
              'SourceCount': sourceCount.toString(),
              'SourceType': "1",
            },
            ...dynamicOutputs.asMap().entries.map(
              (e) => {
                'SourceList': e.value.sourceList.map((m) => m['id']).join(','),
                'SourceCount': e.value.sourceCount.toString(),
                'SourceType': "3",
              },
            ),
          ]
        : [],
  };

  // ── Validation ──────────────────────────────────────────────────────────────

  bool get isGeneralInfoValid =>
      templateName.isNotEmpty &&
      department.isNotEmpty &&
      frequency.isNotEmpty &&
      spocPerson.isNotEmpty;

  bool get isOutputFormatValid =>
      templateType.isNotEmpty &&
      (templateType == '1 - Static' || numberOfOutputs > 0) &&
      outputFormats.isNotEmpty &&
      (isDynamic || (sourceCount > 0 && sourceList.isNotEmpty));

  bool get isDynamicOutputsValid =>
      !isDynamic ||
      (sourceCount > 0 &&
          sourceList.isNotEmpty &&
          dynamicOutputs.every((d) => d.isValid));

  bool get isOnDemandSourceValid {
    if (frequency.toLowerCase() != 'on-demand') return true;
    if (isDynamic) {
      return sourceList.any((s) => s['sourceType'] == 1) ||
          dynamicOutputs.any(
            (d) => d.sourceList.any((s) => s['sourceType'] == 1),
          );
    }
    return sourceList.any((s) => s['sourceType'] == 1);
  }

  bool get isApprovalValid => approvals.isNotEmpty;

  bool get isFileUploaded => approvalFiles.isNotEmpty;

  bool get isComplete =>
      isGeneralInfoValid &&
      isOutputFormatValid &&
      isDynamicOutputsValid &&
      isOnDemandSourceValid &&
      isApprovalValid &&
      isFileUploaded;

  void reset() {
    templateName = '';
    department = '';
    frequency = '';
    frequencyId = 0;
    normalVolume = 0;
    peakVolume = 0;
    sourceCount = 0;
    numberOfOutputs = 0;
    benefitType = '';
    benefitAmount = 0;
    benefitInTAT = '';
    goLiveDate = '';
    deactivateDate = '';
    spocPerson = '';
    spocManager = '';
    unitHead = '';
    priority = 'Medium';
    templateType = '';
    createdBy = '';
    outputFormats = [];
    approvals = [];
    approvalFiles = {};
    sourceList = [];
    sourceListName = '';
    departmentName = '';
    dynamicOutputs = [];
  }
}
