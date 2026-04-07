import 'package:flutter/foundation.dart';
import '../config/api_config.dart';
import '../models/master_models.dart';
import '../models/template_info.dart';
import '../services/api_service.dart';

/// Service to fetch master/dropdown data from API
class MasterDataService {
  final ApiService _api;

  MasterDataService(this._api);

  /// Fetch departments list from API (names only)
  Future<List<String>> getDepartments() async {
    try {
      final data = await _api.getRawData(ApiConfig.departmentsEndpoint);
      if (data is List) {
        return data
            .map(
              (e) => e is String
                  ? e
                  : (e['name'] ?? e['departmentName'] ?? '$e').toString(),
            )
            .toList();
      }
    } catch (e) {
      debugPrint('[MasterData] getDepartments error: $e');
    }
    return [];
  }

  /// Fetch departments as {name: id} map
  Future<Map<String, int>> getDepartmentMap() async {
    try {
      final data = await _api.getRawData(ApiConfig.departmentsEndpoint);
      if (data is List) {
        final map = <String, int>{};
        for (final e in data) {
          if (e is Map) {
            final name = (e['name'] ?? e['departmentName'] ?? '').toString();
            final id = e['id'] is int
                ? e['id'] as int
                : int.tryParse('${e['id']}') ?? 0;
            if (name.isNotEmpty && id > 0) map[name] = id;
          }
        }
        return map;
      }
    } catch (e) {
      debugPrint('[MasterData] getDepartmentMap error: $e');
    }
    return {};
  }

  /// Fetch templates for a given department ID
  Future<List<TemplateInfo>> getTemplatesByDept(int deptId) async {
    try {
      final data = await _api.getRawData(
        '${ApiConfig.templatesEndpoint}?deptId=$deptId',
      );
      if (data is List) {
        return data
            .whereType<Map<String, dynamic>>()
            .map(TemplateInfo.fromJson)
            .toList();
      }
    } catch (e) {
      debugPrint('[MasterData] getTemplatesByDept error: $e');
    }
    return [];
  }

  /// Fetch source types from API
  Future<List<SourceTypeItem>> getSourceTypes() async {
    debugPrint('[MasterData] getSourceTypes called');
    try {
      final data = await _api.postRawData(ApiConfig.sourceTypeEndpoint);
      debugPrint('[MasterData] getSourceTypes raw response: $data');
      if (data is List) {
        return data
            .whereType<Map<String, dynamic>>()
            .map(SourceTypeItem.fromJson)
            .toList();
      }
    } catch (e, st) {
      debugPrint('[MasterData] getSourceTypes error: $e\n$st');
    }
    return [];
  }

  /// Fetch operations from API
  Future<List<OperationItem>> getOperations() async {
    debugPrint('[MasterData] getOperations called');
    try {
      final data = await _api.postRawData(ApiConfig.operationsEndpoint);
      debugPrint('[MasterData] getOperations raw response: $data');
      if (data is List) {
        return data
            .whereType<Map<String, dynamic>>()
            .map(OperationItem.fromJson)
            .toList();
      }
    } catch (e, st) {
      debugPrint('[MasterData] getOperations error: $e\n$st');
    }
    return [];
  }

  /// Fetch approval list from API
  Future<List<String>> getApprovalList() async {
    try {
      final data = await _api.getRawData(ApiConfig.approvalListEndpoint);
      if (data is List) {
        return data
            .map(
              (e) => e is String
                  ? e
                  : (e['name'] ?? e['approvalName'] ?? '$e').toString(),
            )
            .toList();
      }
    } catch (e) {
      debugPrint('[MasterData] getApprovalList error: $e');
    }
    return [];
  }
}
