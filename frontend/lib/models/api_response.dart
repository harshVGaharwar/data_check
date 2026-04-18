/// Generic API response wrapper
class ApiResponse<T> {
  final bool success;
  final String message;
  final T? data;
  final int statusCode;

  ApiResponse({
    required this.success,
    this.message = '',
    this.data,
    this.statusCode = 200,
  });

  factory ApiResponse.fromJson(
    Map<String, dynamic> json, {
    T Function(Map<String, dynamic>)? fromData,
  }) {
    final bool success;
    if (json.containsKey('status')) {
      success = json['status']?.toString().toLowerCase() == 'success';
    } else if (json.containsKey('success')) {
      success = json['success'] == true;
    } else {
      // No explicit status field — HTTP layer already confirmed 2xx, treat as success
      success = true;
    }
    return ApiResponse(
      success: success,
      message: json['message'] ?? '',
      data: fromData != null
          ? fromData(
              json['data'] is Map<String, dynamic>
                  ? json['data'] as Map<String, dynamic>
                  : json,
            )
          : null,
      statusCode: json['statusCode'] ?? 200,
    );
  }

  factory ApiResponse.error(String message, {int statusCode = 500}) {
    return ApiResponse(
      success: false,
      message: message,
      statusCode: statusCode,
    );
  }
}

/// Response model for submit-mapping API
class SubmitMappingResponse {
  final int templateId;
  final int configId;

  SubmitMappingResponse({required this.templateId, required this.configId});

  factory SubmitMappingResponse.fromJson(Map<String, dynamic> json) {
    return SubmitMappingResponse(
      templateId: json['templateId'] ?? 0,
      configId: json['configId'] ?? 0,
    );
  }
}

/// Response model for create template API
/// {"status":"Success","reqID":"7"}
class CreateTemplateResponse {
  final String reqId;

  CreateTemplateResponse({required this.reqId});

  factory CreateTemplateResponse.fromJson(Map<String, dynamic> json) {
    return CreateTemplateResponse(
      reqId: json['reqID']?.toString() ?? '',
    );
  }
}

/// Response model for templateAddSourceMasterList API
/// {"status":"Success","reqID":17}
class AddSourceMasterResponse {
  final String status;
  final int reqId;

  AddSourceMasterResponse({required this.status, required this.reqId});

  bool get isSuccess => status.toLowerCase() == 'success';

  factory AddSourceMasterResponse.fromJson(Map<String, dynamic> json) {
    final rawReqId = json['reqID'] ?? json['reqId'] ?? json['ReqID'] ?? json['req_id'] ?? 0;
    return AddSourceMasterResponse(
      status: json['status']?.toString() ?? '',
      reqId: int.tryParse(rawReqId.toString()) ?? 0,
    );
  }
}

/// Template list item
class TemplateListItem {
  final String id;
  final String name;
  final String department;
  final String status;
  final String createdAt;

  TemplateListItem({
    required this.id,
    required this.name,
    required this.department,
    this.status = '',
    this.createdAt = '',
  });

  factory TemplateListItem.fromJson(Map<String, dynamic> json) {
    return TemplateListItem(
      id: json['id'] ?? json['templateId'] ?? '',
      name: json['templateName'] ?? json['name'] ?? '',
      department: json['department'] ?? '',
      status: json['status'] ?? '',
      createdAt: json['createdAt'] ?? '',
    );
  }
}
