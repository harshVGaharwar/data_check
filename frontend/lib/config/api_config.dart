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
  static const String approvalListEndpoint = '/master/approval-list';
  static const String templatesEndpoint = '/master/templates';
  static const String sourceTypeEndpoint = '/master/source-type';
  static const String operationsEndpoint = '/master/operations';

  // Source Configuration
  static const String saveSourceConfigEndpoint = '/pipeline/save-sources';

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
