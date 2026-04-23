import 'dart:convert';
import '../config/api_config.dart';
import '../models/api_response.dart';
import 'api_service.dart';

class PipelineService {
  final ApiService _api;

  PipelineService(this._api);

  /// Submit join mapping configuration as multipart form-data.
  /// [payload] is the JSON config body.
  /// [fileEntries] is the list of files to send under the "Files" key.
  Future<ApiResponse<SubmitMappingResponse>> submitMapping(
    Map<String, dynamic> payload, {
    List<({String key, List<int> bytes, String filename})> fileEntries =
        const [],
  }) async {
    return _api.postMultipart(
      ApiConfig.pipelineSubmitMappingEndpoint,
      fields: {'TemplateConfig': jsonEncode(payload)},
      fileEntries: fileEntries,
      fromData: SubmitMappingResponse.fromJson,
    );
  }

 
}
