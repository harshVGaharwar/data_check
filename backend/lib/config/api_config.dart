/// Base URL for the external DataLake API.
/// Set this to the real URL before going live.
const String kBaseUrl = 'https://example.com';

/// Set to true to use local mock responses instead of hitting the external API.
const bool kDevMode = kBaseUrl == 'https://example.com';

/// External API endpoints (appended to [kBaseUrl])
class ExternalApi {
  static const String login = '/api/account/Login';
  static const String templateCreate = '/api/templateCreation';
  static const String departments = '/api/master/GetDepartments';
  static const String approvalList = '/api/template/GetApprovalList';
  static const String getTemplates = '/Template/GetTemplates';
  static const String getSourceType = '/api/template/GetSourceType';
  static const String getOperations = '/api/Template/GetOperations';
  static const String addTemplateConfig = '/api/Template/AddTemplateConfig';
  static const String addSourceMaster = '/api/templateAddSourceMasterList';
  static const String getSourceMasterList = '/api/template/GetSourceMasterList';
  static const String getSourceMasterListFilterwise = '/api/template/GetSourceMasterListFilterwise';
  static const String getManualTemplateDetails = '/api/template/GetManualTemplateDetails';
  static const String getSourceList = '/api/template/GetSourceList';
  static const String uploadManualData = '/api/template/UploadManualData';
  static const String getCheckerTayList = '/api/template/GetCheckerTayList';
  static const String uploadManualDataChecker = '/api/template/UploadManualDataChecker';
  static const String downloadFile = '/api/template/DownloadFile';
  static const String refreshToken = '/api/Account/refresh';
}
