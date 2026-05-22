class SourceConfigRequest {
  final String sourceTypeId;
  final String appName;
  final int itgrc;
  final String name;
  final String dbVault;
  final String createdBy;
  final String deptId;
  final String svalues;

  const SourceConfigRequest({
    required this.sourceTypeId,
    required this.appName,
    required this.itgrc,
    required this.name,
    required this.dbVault,
    required this.createdBy,
    required this.deptId,
    required this.svalues,
  });

  Map<String, dynamic> toJson() => {
    'sourceType': sourceTypeId,
    'AppName': appName,
    'ITGRC': itgrc,
    'Name': name,
    'DBVault': dbVault,
    'Createdby': createdBy,
    'department_id': deptId,
    'svalues': svalues,
  };
}
