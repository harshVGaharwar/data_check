class JobExecutionLog {
  final int id;
  final String jobName;
  final String runId;
  final int templateId;
  final String? requestId;
  final String? startTime;
  final String? endTime;
  final String? lastUpdated;
  final String status;
  final int totalSteps;
  final int? step;
  final String message;
  final String? createdAt;
  final String templateName;
  final String deptName;

  const JobExecutionLog({
    required this.id,
    required this.jobName,
    required this.runId,
    required this.templateId,
    this.requestId,
    this.startTime,
    this.endTime,
    this.lastUpdated,
    required this.status,
    required this.totalSteps,
    this.step,
    required this.message,
    this.createdAt,
    required this.templateName,
    required this.deptName,
  });

  factory JobExecutionLog.fromJson(Map<String, dynamic> json) =>
      JobExecutionLog(
        id: (json['id'] as num?)?.toInt() ?? 0,
        jobName: json['jobName']?.toString() ?? '',
        runId: json['runId']?.toString() ?? '',
        templateId: (json['templateId'] as num?)?.toInt() ?? 0,
        requestId: json['requestId']?.toString(),
        startTime: json['startTime']?.toString(),
        endTime: json['endTime']?.toString(),
        lastUpdated: json['last_updated']?.toString(),
        status: json['status']?.toString() ?? '',
        totalSteps: (json['total_steps'] as num?)?.toInt() ?? 0,
        step: (json['step'] as num?)?.toInt(),
        message: json['message']?.toString() ?? '',
        createdAt: json['createdAt']?.toString(),
        templateName: json['templateName']?.toString() ?? '',
        deptName: json['deptName']?.toString() ?? '',
      );
}
