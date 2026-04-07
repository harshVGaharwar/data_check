import 'package:flutter/foundation.dart' show ChangeNotifier, debugPrint;
import '../models/master_models.dart';
import '../services/master_data_service.dart';

class PipelineMasterProvider extends ChangeNotifier {
  final MasterDataService _service;

  List<SourceTypeItem> sourceTypes = [];
  List<OperationItem> operations = [];
  bool loading = true;

  PipelineMasterProvider(this._service) {
    debugPrint('[PipelineMasterProvider] created, starting load...');
    _load();
  }

  Future<void> _load() async {
    try {
      debugPrint('[PipelineMasterProvider] calling getSourceTypes + getOperations');
      final results = await Future.wait([
        _service.getSourceTypes(),
        _service.getOperations(),
      ]);
      sourceTypes = results[0] as List<SourceTypeItem>;
      operations = results[1] as List<OperationItem>;
      debugPrint('[PipelineMasterProvider] loaded — sourceTypes: ${sourceTypes.length}, operations: ${operations.length}');
    } catch (e, st) {
      debugPrint('[PipelineMasterProvider] ERROR: $e\n$st');
    }
    loading = false;
    notifyListeners();
  }

  /// Operator values list for dropdowns (e.g. ['=', '!=', '>', ...])
  List<String> get operatorValues =>
      operations.map((o) => o.operationValue).toList();

  /// Display name for a given operator value
  String operatorLabel(String value) {
    final match = operations.where((o) => o.operationValue == value).toList();
    return match.isNotEmpty ? match.first.operationName : value;
  }
}
