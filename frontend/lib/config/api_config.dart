const String kAppName = 'DATA FUSION';

/// API Configuration
/// Change baseUrl to your actual backend server
class ApiConfig {
  //   static const String baseUrl =
  //       'https://hbenetppuatdb01.hdfcbankuat.com/DataORCAPI/api/';
  static const String baseUrl = 'http://localhost:8080/api/v1/';

  // Auth
  static const String loginEndpoint = 'account/login';
  static const String logoutEndpoint = 'auth/logout';
  static const String refreshEndpoint = 'account/refresh';

  // Master Data
  static const String departmentsEndpoint = 'template/GetDepartment';
  static const String approvalListEndpoint = 'template/GetApprovalList';
  static const String templatesEndpoint = 'template/GetTemplates';
  static const String sourceTypeEndpoint = 'template/GetSourceType';
  static const String operationsEndpoint = 'template/GetOperations';

  // Template Creation
  static const String templateCreateEndpoint = 'template/AddTemplate';

  // Template Configuration (Pipeline)
  static const String pipelineSubmitMappingEndpoint =
      '/template/AddTemplateConfig';

  // Source Configuration
  static const String addSourceMasterEndpoint = 'template/AddSourceMasterList';
  static const String sourceMasterListEndpoint = 'template/GetSourceMasterList';
  static const String sourceMasterListFilterwiseEndpoint =
      'template/GetSourceMasterListFilterwise';
  static const String manualTemplatesEndpoint =
      'template/GetManualTemplateDetails';
  static const String sourceListEndpoint = 'template/GetSourceList';

  // manual data upload
  static const String uploadManualDataEndpoint = 'template/UploadManualData';

  // checker page
  static const String checkerListEndpoint = 'template/GetCheckerTayList';
  static const String checkerApprovalEndpoint =
      'template/UploadManualDataChecker';
  static const String downloadFileEndpoint = 'template/DownloadFile';

  // report page
  static const String reportListEndpoint = 'template/GetReportList';

  // // Timeouts
  // static const Duration connectTimeout = Duration(seconds: 30);
  // static const Duration receiveTimeout = Duration(seconds: 30);

  // // Headers
  // static Map<String, String> headers(String? token) => {
  //   'Content-Type': 'application/json',
  //   'Accept': 'application/json',
  //   if (token != null) 'Authorization': 'Bearer $token',
  // };
}
