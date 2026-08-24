import 'package:vizualizer/data/models/login_response.dart';

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
        'SourceListNames': sourceList.map((m) => m['name']).join(','),
        'SourceType': "3",
      };
}

class TemplateRequest {
  String templateName;
  String department;
  String frequency;
  String frequencyName;
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
  String templateTypeName;
  String createdBy;
  List<String> outputFormats;
  List<String> approvals;
  String departmentName;
  String sourceListName;

  Map<String, String> approvalFiles;
  List<Map<String, dynamic>> sourceList;

  List<DynamicOutputModel> dynamicOutputs;

  TemplateRequest({
    this.templateName = '',
    this.department = '',
    this.frequency = '',
    this.frequencyName = '',
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
    this.templateTypeName = '',
    this.createdBy = '',
    this.sourceListName = '',
    this.departmentName = '',
    List<String>? outputFormats,
    List<String>? approvals,
    Map<String, String>? approvalFiles,
    List<Map<String, dynamic>>? sourceList,
    List<DynamicOutputModel>? dynamicOutputs,
  })  : outputFormats = outputFormats ?? [],
        approvals = approvals ?? [],
        approvalFiles = approvalFiles ?? {},
        sourceList = sourceList ?? [],
        dynamicOutputs = dynamicOutputs ?? [];

  // ---------------------------------------------------------------------------
  // ✅ NEW RULE SUPPORT
  // ---------------------------------------------------------------------------

  /// ✅ True if Frequency ID == 3
  bool get frequencyIs3 => frequency == '3';

  /// ✅ True if ANY static or dynamic sourceList contains ID = 1
  bool get hasMandatorySourceId1 {
    // Check Static list
    final hasInStatic = sourceList.any((m) => m['id'] == 1);

    // Check Dynamic list
    final hasInDynamic = dynamicOutputs.any(
      (d) => d.sourceList.any((m) => m['id'] == 1),
    );

    return hasInStatic || hasInDynamic;
  }

  // ---------------------------------------------------------------------------
  // Standard properties
  // ---------------------------------------------------------------------------

  bool get isDynamic => selectedTemplateType?.id == 3;

  Map<String, dynamic> toJson() => {
        'TemplateType': selectedTemplateType?.id.toString(),
        'TemplateTypeName': selectedTemplateType?.name,
        'Template': [
          {
            'TemplateName': templateName,
            'Department': department,
            'Frequency': frequency,
            'FrequencyName': frequencyName,
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
        // Both Static and Dynamic can be Unimailing or User Defined; the
        // combination is what AddTemplateConfig later turns into a 1/2/3/4
        // TemplateType (see PipelineController.configTemplateType).
        'OutputFormats': outputFormats
            .toSet()
            .map((f) => {'TemplateTempId': null, 'FormatName': f})
            .toList(),
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
                  'SourceListNames': sourceList.map((m) => m['name']).join(','),
                  'SourceType': "1",
                },
                ...dynamicOutputs.asMap().entries.map(
                      (e) => {
                        'SourceList':
                            e.value.sourceList.map((m) => m['id']).join(','),
                        'SourceListNames':
                            e.value.sourceList.map((m) => m['name']).join(','),
                        'SourceCount': e.value.sourceCount.toString(),
                        'SourceType': "3",
                      },
                    ),
              ]
            : [],
      };

  // ---------------------------------------------------------------------------
  // Validation
  // ---------------------------------------------------------------------------

  bool get isGeneralInfoValid =>
      templateName.isNotEmpty &&
      department.isNotEmpty &&
      frequency.isNotEmpty &&
      benefitType.isNotEmpty &&
      spocPerson.isNotEmpty;

  // bool get isOutputFormatValid =>
  //     templateType.isNotEmpty &&
  //     (templateType == '1 - Static' || numberOfOutputs > 0) &&
  //     outputFormats.isNotEmpty &&
  //     (isDynamic || (sourceCount > 0 && sourceList.isNotEmpty));
  TemplateType? selectedTemplateType;

  bool get isOutputFormatValid =>
      (selectedTemplateType?.id == 2 || numberOfOutputs > 0) &&
      outputFormats.isNotEmpty &&
      (!isDynamic || (sourceCount > 0 && sourceList.isNotEmpty));

  bool get isDynamicOutputsValid =>
      !isDynamic ||
      (sourceCount > 0 &&
          sourceList.isNotEmpty &&
          dynamicOutputs.every((d) => d.isValid));

  bool get isApprovalValid => approvals.isNotEmpty;

  bool get isFileUploaded => approvalFiles.isNotEmpty;

  bool get isComplete =>
      isGeneralInfoValid &&
      isOutputFormatValid &&
      isDynamicOutputsValid &&
      isApprovalValid &&
      isFileUploaded;

  void reset() {
    templateName = '';
    department = '';
    frequency = '';
    frequencyName = '';
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
    templateTypeName = '';
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