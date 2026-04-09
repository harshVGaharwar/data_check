/// Template Creation Request Model
/// Share this with backend team for API structure
///
/// POST /api/v1/templates
/// Content-Type: multipart/form-data (due to file upload)
///
/// Example JSON (form fields):
// {
//   "template": {
//     "templateName": "Sample Template",
//     "department": "Finance",
//     "frequency": "Monthly",
//     "normalVolume": 100,
//     "peakVolume": 200,
//     "sourceCount": 2,
//     "numberOfOutputs": 3,
//     "benefitType": "CostSaving",
//     "benefitAmount": 5000,
//     "benefitInTat": "2 days",
//     "goLiveDate": "2025-01-01",
//     "deactivateDate": null,
//     "spocPerson": "John",
//     "spocManager": "Manager A",
//     "unitHead": "Head A",
//     "priority": "High"
//   },
//   "outputFormats": [
//     { "formatName": "CSV" },
//     { "formatName": "Excel" }
//   ],
//   "approvals": [
//     {
//       "approval_Type": "Manager",
//       "approvalFile": "file1.pdf"
//     }
//   ]
// }
class TemplateRequest {
  String templateName;
  String department;
  String frequency;
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
  List<String> outputFormats;
  List<String> approvals;

  /// Per-approval file uploads: {"Unit Head": "approval_uh.pdf", "UAT Sign Off": "uat.pdf"}
  Map<String, String> approvalFiles;
  // Actual file bytes handled separately in multipart upload

  TemplateRequest({
    this.templateName = '',
    this.department = '',
    this.frequency = '',
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
    List<String>? outputFormats,
    List<String>? approvals,
    Map<String, String>? approvalFiles,
  }) : outputFormats = outputFormats ?? [],
       approvals = approvals ?? [],
       approvalFiles = approvalFiles ?? {};

  Map<String, dynamic> toJson() => {
    'Template': [
      {
        'TemplateName': templateName,
        'Department': department,
        'Frequency': frequency,
        'NormalVolume': normalVolume,
        'PeakVolume': peakVolume,
        'SourceCount': sourceCount,
        'NumberOfOutputs': numberOfOutputs,
        'BenefitType': benefitType,
        'BenefitAmount': benefitAmount,
        'BenefitInTat': benefitInTAT,
        'GoLiveDate': goLiveDate.isEmpty ? null : goLiveDate,
        'DeactivateDate': deactivateDate.isEmpty ? null : deactivateDate,
        'SpocPerson': spocPerson,
        'SpocManager': spocManager,
        'UnitHead': unitHead,
        'Priority': priority,
      }
    ],
    'OutputFormats': outputFormats
        .map((f) => {'TemplateTempId': null, 'FormatName': f})
        .toList(),
    'Approvals': approvals
        .map((a) => {
              'TemplateTempId': null,
              'Approval_Type': a,
              'ApprovalFile': approvalFiles[a] ?? '',
            })
        .toList(),
  };

  bool get isGeneralInfoValid =>
      templateName.isNotEmpty &&
      department.isNotEmpty &&
      frequency.isNotEmpty &&
      spocPerson.isNotEmpty &&
      sourceCount > 0 &&
      numberOfOutputs > 0;

  bool get isOutputFormatValid => outputFormats.isNotEmpty;

  bool get isApprovalValid => approvals.isNotEmpty;

  bool get isFileUploaded => approvalFiles.isNotEmpty;

  bool get isComplete =>
      isGeneralInfoValid &&
      isOutputFormatValid &&
      isApprovalValid &&
      isFileUploaded;

  void reset() {
    templateName = '';
    department = '';
    frequency = '';
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
    outputFormats = [];
    approvals = [];
    approvalFiles = {};
  }
}
