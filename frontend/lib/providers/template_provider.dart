import 'dart:convert';
import 'package:flutter/material.dart';
import '../models/template_request.dart';
import '../services/template_service.dart';

class TemplateProvider extends ChangeNotifier {
  final TemplateService _service;

  TemplateProvider(this._service);

  bool _loading = false;
  String? _error;
  String? _successMessage;
  String? _reqId;

  bool get loading => _loading;
  String? get error => _error;
  String? get successMessage => _successMessage;
  String? get reqId => _reqId;

  void clearMessages() {
    _error = null;
    _successMessage = null;
    _reqId = null;
  }

  Future<bool> saveTemplate(TemplateRequest request, {Map<String, List<int>>? fileBytes, Map<String, String>? fileNames}) async {
    _loading = true;
    _error = null;
    _successMessage = null;
    _reqId = null;
    notifyListeners();

    debugPrint('[TEMPLATE SAVE] Payload:\n${const JsonEncoder.withIndent('  ').convert(request.toJson())}');
    if (fileNames != null) debugPrint('[TEMPLATE SAVE] Files: $fileNames');

    final response = await _service.createTemplate(request, approvalFileBytes: fileBytes, approvalFileNames: fileNames);

    _loading = false;

    if (response.success) {
      _reqId = response.data?.reqId;
      _successMessage = 'Template saved successfully';
      debugPrint('[TEMPLATE SAVE] reqID: $_reqId');
      notifyListeners();
      return true;
    } else {
      _error = response.message.isNotEmpty ? response.message : 'Failed to save template';
      notifyListeners();
      return false;
    }
  }
}
