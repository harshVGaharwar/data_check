import 'dart:convert';
import '../config/api_config.dart';
import '../models/api_response.dart';
import '../models/template_request.dart';
import 'api_service.dart';

class TemplateService {
  final ApiService _api;

  TemplateService(this._api);

  /// Create new template with approval file uploads as multipart form-data.
  /// Response: {"status":"Success","reqID":"7"}
  Future<ApiResponse<CreateTemplateResponse>> createTemplate(
    TemplateRequest request, {
    Map<String, List<int>>? approvalFileBytes,
    Map<String, String>? approvalFileNames,
  }) async {
    // Build file entries: each approval file sent under key "Files"
    final fileEntries = <({String key, List<int> bytes, String filename})>[];
    if (approvalFileBytes != null) {
      for (final entry in approvalFileBytes.entries) {
        final filename = approvalFileNames?[entry.key] ?? entry.key;
        fileEntries.add((key: 'Files', bytes: entry.value, filename: filename));
      }
    }

    return _api.postMultipart(
      ApiConfig.templateCreateEndpoint,
      fields: {'Config': jsonEncode(request.toJson())},
      fileEntries: fileEntries,
      fromData: CreateTemplateResponse.fromJson,
    );
  }

  /// Get all templates
  Future<ApiResponse<List<TemplateListItem>>> getTemplates() async {
    final response = await _api.get(ApiConfig.templateListEndpoint);
    if (response.success) {
      // Parse list from response
      try {
        final list =
            (response.data as List?)
                ?.map((e) => TemplateListItem.fromJson(e))
                .toList() ??
            [];
        return ApiResponse(
          success: true,
          data: list,
          message: response.message,
        );
      } catch (_) {
        return ApiResponse(
          success: true,
          data: <TemplateListItem>[],
          message: response.message,
        );
      }
    }
    return ApiResponse.error(response.message, statusCode: response.statusCode);
  }

  /// Get template by ID
  Future<ApiResponse> getTemplateById(String id) async {
    return _api.get('${ApiConfig.templateDetailEndpoint}/$id');
  }
}
