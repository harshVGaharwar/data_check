/// API Configuration
/// Change baseUrl to your actual backend server
class ApiConfig {
  static const String baseUrl = 'http://localhost:8080/api/v1';

  // Auth
  static const String loginEndpoint = '/auth/login';
  static const String logoutEndpoint = '/auth/logout';

  // Template Creation
  static const String templateCreateEndpoint = '/templates';
  static const String templateListEndpoint = '/templates';
  static const String templateDetailEndpoint = '/templates'; // + /{id}

  // Template Configuration (Pipeline)
  static const String pipelineSubmitMappingEndpoint =
      '/pipeline/submit-mapping';
  static const String pipelineSubmitFormatEndpoint = '/pipeline/submit-format';

  // Configuration Upload
  static const String configUploadEndpoint = '/config/upload';

  // Master Data
  static const String departmentsEndpoint = '/master/departments';
  static const String approvalListEndpoint = '/template/GetApprovalList';
  static const String templatesEndpoint = '/master/templates';
  static const String sourceTypeEndpoint = '/master/source-type';
  static const String operationsEndpoint = '/master/operations';

  // Source Configuration
  static const String saveSourceConfigEndpoint = '/pipeline/save-sources';
  static const String addSourceMasterEndpoint = '/templateAddSourceMasterList';
  static const String sourceMasterListEndpoint = '/template/GetSourceMasterList';
  static const String manualTemplatesEndpoint =
      '/template/GetManualTemplateDetails';
  static const String sourceListEndpoint = '/template/GetSourceList';
  static const String uploadManualDataEndpoint = '/template/UploadManualData';
  static const String checkerListEndpoint = '/template/GetCheckerTayList';
  static const String checkerApprovalEndpoint = '/template/UploadManualDataChecker';
  static const String downloadFileEndpoint = '/template/DownloadFile';

  // Timeouts
  static const Duration connectTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 30);

  // Headers
  static Map<String, String> headers(String? token) => {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
    if (token != null) 'Authorization': 'Bearer $token',
  };
}

// class ApiConfig {
//   static const String baseUrl =
//       'https://hbenetppuatdb01.hdfcbankuat.com/DataORCAPI/api/';

//   // Auth
//   static const String loginEndpoint = 'account/login';
//   static const String logoutEndpoint = 'auth/logout';



  // Source Configuration
  // static const String saveSourceConfigEndpoint = '/pipeline/save-sources';
  // static const String addSourceMasterEndpoint = '/templateAddSourceMasterList';
  // static const String sourceMasterListEndpoint = '/template/GetSourceMasterList';


//   // Template Creation
//   static const String templateCreateEndpoint = '/Template/AddTemplate';
//   static const String templateListEndpoint = '/templates';
//   static const String templateDetailEndpoint = '/templates'; // + /{id}

//   // Template Configuration (Pipeline)
//   static const String pipelineSubmitMappingEndpoint =
//       'Template/AddTemplateConfig';
//   static const String pipelineSubmitFormatEndpoint = '/pipeline/submit-format';

//   // Configuration Upload
//   static const String configUploadEndpoint = '/config/upload';

//   // Master Data
//   static const String departmentsEndpoint = 'Template/GetDepartment';
//   static const String approvalListEndpoint = 'master/approval-list';
//   static const String templatesEndpoint = 'Template/GetTemplates';
//   static const String sourceTypeEndpoint = 'Template/GetSourceType';
//   static const String operationsEndpoint = 'Template/GetOperations';



  // Configuration Upload
  //static const String configUploadEndpoint = '/config/upload';

// source Configuraiton 
//  static const String saveSourceConfigEndpoint = '/pipeline/save-sources';
//   static const String addSourceMasterEndpoint = '/templateAddSourceMasterList';
//   static const String sourceMasterListEndpoint = '/template/GetSourceMasterList';
//   static const String manualTemplatesEndpoint =
//       '/template/GetManualTemplateDetails';
//   static const String sourceListEndpoint = '/template/GetSourceList';
//   static const String uploadManualDataEndpoint = '/template/UploadManualData';
//   static const String checkerListEndpoint = '/template/GetCheckerTayList';
//   static const String checkerApprovalEndpoint = '/template/UploadManualDataChecker';
//   static const String downloadFileEndpoint = '/template/DownloadFile';

//   // Timeouts
//   static const Duration connectTimeout = Duration(seconds: 30);
//   static const Duration receiveTimeout = Duration(seconds: 30);

//   // Headers
//   static Map<String, String> headers(String? token) => {
//         'Content-Type': 'application/json',
//         'Accept': 'application/json',
//         if (token != null) 'Authorization': 'Bearer $token',
//       };
// }
