import 'dart:convert';
import 'package:vizualizer/core/config/api_config.dart';
import 'package:vizualizer/data/models/api_response.dart';
import 'package:vizualizer/data/services/api_service.dart';
class PipelineService {
  final ApiService _api;

  PipelineService(this._api);

  /// Submit join mapping configuration as multipart form-data.
  /// [payload] is the JSON config body.
  /// [fileEntries] is the list of files to send under the "Files" key.
  Future<ApiResponse<SubmitMappingResponse>> submitMapping(
    dynamic payload, {
    List<({
String key, List<int> bytes, String filename})> fileEntries =
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
