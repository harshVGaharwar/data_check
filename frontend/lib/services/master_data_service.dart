import 'package:flutter/foundation.dart';
import '../config/api_config.dart';
import '../services/api_service.dart';

/// Service to fetch master/dropdown data from API
class MasterDataService {
  final ApiService _api;

  MasterDataService(this._api);

  /// Fetch departments list from API
  Future<List<String>> getDepartments() async {
    try {
      final data = await _api.getRawData(ApiConfig.departmentsEndpoint);
      if (data is List) {
        return data
            .map((e) => e is String
                ? e
                : (e['name'] ?? e['departmentName'] ?? '$e').toString())
            .toList();
      }
    } catch (e) {
      debugPrint('[MasterData] getDepartments error: $e');
    }
    return [];
  }

  /// Fetch approval list from API
  Future<List<String>> getApprovalList() async {
    try {
      final data = await _api.getRawData(ApiConfig.approvalListEndpoint);
      if (data is List) {
        return data
            .map((e) => e is String
                ? e
                : (e['name'] ?? e['approvalName'] ?? '$e').toString())
            .toList();
      }
    } catch (e) {
      debugPrint('[MasterData] getApprovalList error: $e');
    }
    return [];
  }
}
