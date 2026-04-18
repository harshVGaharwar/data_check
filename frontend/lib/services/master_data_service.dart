import 'package:flutter/foundation.dart';
import '../config/api_config.dart';
import '../models/api_response.dart';
import '../models/master_models.dart';
import '../models/template_info.dart';
import '../services/api_service.dart';

/// Service to fetch master/dropdown data from API
class MasterDataService {
  final ApiService _api;

  MasterDataService(this._api);

  /// Fetch departments list from API
  Future<List<DepartmentItem>> getDepartments() async {
    try {
      final data = await _api.getRawData(ApiConfig.departmentsEndpoint);
      if (data is List) {
        return data
            .whereType<Map<String, dynamic>>()
            .map(DepartmentItem.fromJson)
            .toList();
      }
    } catch (e) {
      debugPrint('[MasterData] getDepartments error: $e');
    }
    return [];
  }

  /// Fetch departments as {name: id} map
  Future<Map<String, int>> getDepartmentMap() async {
    final departments = await getDepartments();
    return {
      for (final d in departments)
        if (d.name.isNotEmpty) d.name: d.id,
    };
  }

  /// Fetch source list for a given department + template.
  /// Uses GetSourceList?DeptId=<deptId>&TemplateId=<templateId>.
  /// Filters out the backend placeholder entry (id == 0).
  Future<List<SourceListItem>> getSourceList({
    required int deptId,
    required int templateId,
  }) async {
    try {
      final data = await _api.getRawData(
        '${ApiConfig.sourceListEndpoint}?DeptId=$deptId&TemplateId=$templateId',
      );
      if (data is List) {
        return data
            .whereType<Map<String, dynamic>>()
            .map(SourceListItem.fromJson)
            .where((s) => s.id != 0)
            .toList();
      }
    } catch (e) {
      debugPrint('[MasterData] getSourceList error: $e');
    }
    return [];
  }

  /// Fetch manual-upload templates for a given department ID.
  /// Uses GetManualTemplateDetails?DeptId=<id>.
  /// Filters out the backend placeholder entry (templateId == 0).
  Future<List<ManualTemplateInfo>> getManualTemplatesByDept(int deptId) async {
    try {
      final data = await _api.getRawData(
        '${ApiConfig.manualTemplatesEndpoint}?DeptId=$deptId',
      );
      if (data is List) {
        return data
            .whereType<Map<String, dynamic>>()
            .map(ManualTemplateInfo.fromJson)
            .where((t) => t.templateId != 0)
            .toList();
      }
    } catch (e) {
      debugPrint('[MasterData] getManualTemplatesByDept error: $e');
    }
    return [];
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
      final data = await _api.getRawData(ApiConfig.sourceTypeEndpoint);
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
      final data = await _api.getRawData(ApiConfig.operationsEndpoint);
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
  Future<List<ApprovalItem>> getApprovalList() async {
    try {
      final data = await _api.getRawData(ApiConfig.approvalListEndpoint);
      if (data is List) {
        return ApprovalItem.listFromJson(data);
      }
    } catch (e) {
      debugPrint('[MasterData] getApprovalList error: $e');
    }
    return [];
  }

  /// Fetch source master list from API (/template/GetSourceMasterList)
  Future<List<SourceMasterItem>> getSourceMasterList() async {
    try {
      final data = await _api.getRawData(ApiConfig.sourceMasterListEndpoint);
      if (data is List) {
        return data
            .whereType<Map<String, dynamic>>()
            .map(SourceMasterItem.fromJson)
            .toList();
      }
    } catch (e) {
      debugPrint('[MasterData] getSourceMasterList error: $e');
    }
    return [];
  }

  /// Upload manual data files
  Future<({bool success, String message, int reqId})> uploadManualData({
    required List<Map<String, String>> entries,
  }) async {
    try {
      final body = {'manualFileUploadslist': entries};
      final res = await _api.post<AddSourceMasterResponse>(
        ApiConfig.uploadManualDataEndpoint,
        body,
        fromData: AddSourceMasterResponse.fromJson,
      );
      final reqId = res.data?.reqId ?? 0;
      return (success: res.success, message: res.message, reqId: reqId);
    } catch (e) {
      debugPrint('[MasterData] uploadManualData error: $e');
      return (success: false, message: 'Network error. Please try again.', reqId: 0);
    }
  }

  /// Add a new source master record
  Future<({bool success, String message, int reqId})> addSourceMaster({
    required String sourceTypeId,
    required String appName,
    required int itgrc,
    required String name,
    required String dbVault,
    required String createdBy,
  }) async {
    try {
      final body = {
        'sourceType': sourceTypeId,
        'AppName': appName,
        'ITGRC': itgrc,
        'Name': name,
        'DBVault': dbVault,
        'Createdby': createdBy,
      };
      final res = await _api.post<AddSourceMasterResponse>(
        ApiConfig.addSourceMasterEndpoint,
        body,
        fromData: AddSourceMasterResponse.fromJson,
      );
      final reqId = res.data?.reqId ?? 0;
      return (success: res.success, message: res.message, reqId: reqId);
    } catch (e) {
      debugPrint('[MasterData] addSourceMaster error: $e');
      return (success: false, message: 'Network error. Please try again.', reqId: 0);
    }
  }
}
