class ReportItem {
  final String templateId;
  final String templateName;
  final String departmentName;
  final String filename;
  final String requestId;
  final String makerBy;
  final String makerDate;
  final String? status;

  const ReportItem({
    required this.templateId,
    required this.templateName,
    required this.departmentName,
    required this.filename,
    required this.requestId,
    required this.makerBy,
    required this.makerDate,
    this.status,
  });

  factory ReportItem.fromJson(Map<String, dynamic> json) {
    return ReportItem(
      templateId: json['template_id']?.toString() ?? '',
      templateName: json['templateName']?.toString() ?? '',
      // real API sends department name under 'department_id' key
      departmentName: json['departmentName']?.toString() ??
          json['department_id']?.toString() ??
          '',
      filename: json['filename']?.toString() ?? '',
      requestId: json['requestId']?.toString() ?? '',
      makerBy: json['makerBy']?.toString() ?? '',
      makerDate: json['makerDate']?.toString() ?? '',
      status: json['status']?.toString() ?? json['isApproved']?.toString(),
    );
  }
}
