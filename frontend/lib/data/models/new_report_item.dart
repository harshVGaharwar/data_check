class NewReportItem {
  final String templateId;
  final String templateName;
  final String departmentName;
  final String filename;

  final String requestId;
  final String runId;

  final String makerBy;
  final String makerDate;

  final String checkerBy;
  final String checkerDate;

  final String createdOn;

  final String fromDate; // startdate
  final String toDate; // enddate

  final String? isFileReady;

  const NewReportItem({
    required this.templateId,
    required this.templateName,
    required this.departmentName,
    required this.filename,
    required this.requestId,
    required this.runId,
    required this.makerBy,
    required this.makerDate,
    required this.checkerBy,
    required this.checkerDate,
    required this.createdOn,
    required this.fromDate,
    required this.toDate,
    required this.isFileReady,
  });

  factory NewReportItem.fromJson(Map<String, dynamic> json) {
    return NewReportItem(
      templateId: json['template_id']?.toString() ?? '',
      templateName: json['templateName']?.toString() ?? '',
      departmentName: json['department_id']?.toString() ?? '',
      filename: json['filename']?.toString() ?? '',
      requestId: json['requestId']?.toString() ?? '',
      runId: json['runId']?.toString() ?? '',
      makerBy: json['makerBy']?.toString() ?? '',
      makerDate: json['makerDate']?.toString() ?? '',
      checkerBy: json['checkerBy']?.toString() ?? '',
      checkerDate: json['checkerDate']?.toString() ?? '',
      createdOn: json['createdOn']?.toString() ?? '',
      fromDate: json['startdate']?.toString() ?? '',
      toDate: json['enddate']?.toString() ?? '',
      isFileReady: json['isFileReady']?.toString(),
    );
  }
}