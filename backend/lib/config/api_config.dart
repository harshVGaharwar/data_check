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
  static const String approvalList = '/api/master/GetApprovalList';
}
