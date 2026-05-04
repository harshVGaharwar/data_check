import 'dart:convert';
import 'dart:io';
import 'package:dart_frog/dart_frog.dart';
import 'package:http/io_client.dart';
import '../../../../lib/config/api_config.dart';
import '../../../../lib/models/models.dart';

Future<Response> onRequest(RequestContext context) async {
  if (context.request.method != HttpMethod.post) {
    return Response.json(
      statusCode: HttpStatus.methodNotAllowed,
      body: ApiResponse.error(message: 'Only POST allowed').toJson(),
    );
  }

  Map<String, dynamic> body;
  try {
    final raw = await context.request.body();
    body = jsonDecode(raw) as Map<String, dynamic>;
  } catch (_) {
    return Response.json(
      statusCode: HttpStatus.badRequest,
      body: ApiResponse.error(message: 'Invalid JSON body').toJson(),
    );
  }

  final templateId = body['template_id']?.toString() ?? '';
  final departmentId = body['department_id']?.toString() ?? '';
  final requestId = body['Request_id']?.toString() ?? '';
  final module = body['module']?.toString() ?? '';
  final isSourceConfig = module == '2';

  // Dev mode: return seeded mock data
  if (kDevMode) {
    if (templateId.isEmpty || departmentId.isEmpty) {
      return Response.json(body: <dynamic>[]);
    }
    final rid = requestId.isNotEmpty ? requestId : 'REQ_00010';
    final mockData = [
      {
        'template_id': templateId,
        'templateName': 'Source Configuration Master',
        'department_id': departmentId,
        'filename': 'source_config_request.json',
        'makerBy': 'sc1001',
        'makerDate': '2026-04-18T08:45:00.00',
        'source_id': 101,
        'requestId': rid,
        'departmentName': 'RETAIL ASSETS'
      },
      {
        'template_id': templateId,
        'templateName': '2 manual 2 QRS',
        'department_id': departmentId,
        'filename': 'employee_master.csv',
        'makerBy': 'j3216',
        'makerDate': '2026-04-18T09:15:00.00',
        'source_id': null,
        'requestId': rid,
        'departmentName': 'RETAIL ASSETS'
      },
      {
        'template_id': templateId,
        'templateName': '2 manual 2 QRS',
        'department_id': departmentId,
        'filename': 'branch_data.xlsx',
        'makerBy': 'k4521',
        'makerDate': '2026-04-18T10:30:00.00',
        'source_id': null,
        'requestId': rid,
        'departmentName': 'HOME LOANS'
      },
      {
        'template_id': templateId,
        'templateName': 'Q1 Finance Report',
        'department_id': departmentId,
        'filename': 'Q1_2026_report.xlsx',
        'makerBy': 'm7890',
        'makerDate': '2026-04-18T11:00:00.00',
        'source_id': null,
        'requestId': rid,
        'departmentName': 'CORPORATE BANKING'
      },
      {
        'template_id': templateId,
        'templateName': '2 manual 2 QRS',
        'department_id': departmentId,
        'filename': 'salary_data.csv',
        'makerBy': 'j3216',
        'makerDate': '2026-04-18T11:45:00.00',
        'source_id': null,
        'requestId': rid,
        'departmentName': 'RETAIL ASSETS'
      },
      {
        'template_id': templateId,
        'templateName': 'Credit Card Template',
        'department_id': departmentId,
        'filename': 'card_transactions.csv',
        'makerBy': 'r2341',
        'makerDate': '2026-04-18T12:00:00.00',
        'source_id': null,
        'requestId': rid,
        'departmentName': 'CREDIT CARDS'
      },
      {
        'template_id': templateId,
        'templateName': 'Q1 Finance Report',
        'department_id': departmentId,
        'filename': 'audit_log.txt',
        'makerBy': 'k4521',
        'makerDate': '2026-04-18T12:30:00.00',
        'source_id': null,
        'requestId': rid,
        'departmentName': 'CORPORATE BANKING'
      },
      {
        'template_id': templateId,
        'templateName': '2 manual 2 QRS',
        'department_id': departmentId,
        'filename': 'customer_profiles.csv',
        'makerBy': 'm7890',
        'makerDate': '2026-04-19T09:00:00.00',
        'source_id': null,
        'requestId': rid,
        'departmentName': 'RETAIL ASSETS'
      },
      {
        'template_id': templateId,
        'templateName': 'Credit Card Template',
        'department_id': departmentId,
        'filename': 'billing_cycle.xlsx',
        'makerBy': 'j3216',
        'makerDate': '2026-04-19T09:30:00.00',
        'source_id': null,
        'requestId': rid,
        'departmentName': 'CREDIT CARDS'
      },
      {
        'template_id': templateId,
        'templateName': '2 manual 2 QRS',
        'department_id': departmentId,
        'filename': 'loan_disbursement.xlsx',
        'makerBy': 'r2341',
        'makerDate': '2026-04-19T10:00:00.00',
        'source_id': null,
        'requestId': rid,
        'departmentName': 'HOME LOANS'
      },
      {
        'template_id': templateId,
        'templateName': 'Asset Register',
        'department_id': departmentId,
        'filename': 'fixed_assets.csv',
        'makerBy': 'k4521',
        'makerDate': '2026-04-19T10:45:00.00',
        'source_id': null,
        'requestId': rid,
        'departmentName': 'CORPORATE BANKING'
      },
      {
        'template_id': templateId,
        'templateName': '2 manual 2 QRS',
        'department_id': departmentId,
        'filename': 'vendor_list.txt',
        'makerBy': 'j3216',
        'makerDate': '2026-04-19T11:15:00.00',
        'source_id': null,
        'requestId': rid,
        'departmentName': 'RETAIL ASSETS'
      },
      {
        'template_id': templateId,
        'templateName': 'Asset Register',
        'department_id': departmentId,
        'filename': 'it_inventory.xlsx',
        'makerBy': 'm7890',
        'makerDate': '2026-04-19T11:50:00.00',
        'source_id': null,
        'requestId': rid,
        'departmentName': 'CORPORATE BANKING'
      },
      {
        'template_id': templateId,
        'templateName': 'Credit Card Template',
        'department_id': departmentId,
        'filename': 'fraud_alerts.csv',
        'makerBy': 'r2341',
        'makerDate': '2026-04-19T13:00:00.00',
        'source_id': null,
        'requestId': rid,
        'departmentName': 'CREDIT CARDS'
      },
      {
        'template_id': templateId,
        'templateName': '2 manual 2 QRS',
        'department_id': departmentId,
        'filename': 'emi_schedule.csv',
        'makerBy': 'k4521',
        'makerDate': '2026-04-19T13:30:00.00',
        'source_id': null,
        'requestId': rid,
        'departmentName': 'HOME LOANS'
      },
      {
        'template_id': templateId,
        'templateName': 'Q1 Finance Report',
        'department_id': departmentId,
        'filename': 'pnl_statement.xlsx',
        'makerBy': 'j3216',
        'makerDate': '2026-04-19T14:00:00.00',
        'source_id': null,
        'requestId': rid,
        'departmentName': 'CORPORATE BANKING'
      },
      {
        'template_id': templateId,
        'templateName': 'Asset Register',
        'department_id': departmentId,
        'filename': 'branch_assets.csv',
        'makerBy': 'm7890',
        'makerDate': '2026-04-20T09:00:00.00',
        'source_id': null,
        'requestId': rid,
        'departmentName': 'RETAIL ASSETS'
      },
      {
        'template_id': templateId,
        'templateName': 'Credit Card Template',
        'department_id': departmentId,
        'filename': 'reward_points.txt',
        'makerBy': 'r2341',
        'makerDate': '2026-04-20T09:45:00.00',
        'source_id': null,
        'requestId': rid,
        'departmentName': 'CREDIT CARDS',
      },
      {
        'template_id': templateId,
        'templateName': '2 manual 2 QRS',
        'department_id': departmentId,
        'filename': 'repayment_data.csv',
        'makerBy': 'k4521',
        'makerDate': '2026-04-20T10:20:00.00',
        'source_id': null,
        'requestId': rid,
        'departmentName': 'HOME LOANS'
      },
    ];
    Map<String, dynamic> mockPayloadFor(int i, Map<String, dynamic> item) => {
          'sourceType': '${(i % 4) + 1}',
          'sourceTypeName': const ['Manual', 'QRS', 'FC', 'Laser'][i % 4],
          'AppName': 'APP_${i + 1}',
          'ITGRC': 1200 + i,
          'Name': 'SRC_${i + 1}',
          'DBVault': 'VAULT_${i + 1}',
          'Createdby': item['makerBy']?.toString() ?? 'unknown',
          'departmentName': item['departmentName']?.toString() ?? '',
          'department_id': item['department_id']?.toString() ?? '',
          'createdOn': item['makerDate']?.toString() ?? '',
        };

    Map<String, dynamic> mockResponseDataFor(
      int i,
      Map<String, dynamic> item,
      String moduleId,
    ) => {
          if (moduleId == '2') ...{
            // Same keys as Source Configuration submit API body
            'sourceType': '${(i % 4) + 1}',
            'sourceTypeId': '${(i % 4) + 1}',
            'sourceTypeName': const ['Manual', 'QRS', 'FC', 'Laser'][i % 4],
            'AppName': 'APP_${i + 1}',
            'ITGRC': 1200 + i,
            'Name': 'SRC_${i + 1}',
            'DBVault': 'VAULT_${i + 1}',
            'Createdby': item['makerBy']?.toString() ?? 'unknown',
            'department_id': item['department_id']?.toString() ?? '',
            'departmentId': item['department_id']?.toString() ?? '',
            'departmentName': item['departmentName']?.toString() ?? '',
          },
          if (moduleId == '1') ...{
            // Same shape as Template Creation submit body (TemplateRuequest)
            'templateId': item['template_id']?.toString() ?? '',
            'templateName': item['templateName']?.toString() ?? '',
            'departmentId': item['department_id']?.toString() ?? '',
            'departmentName': item['departmentName']?.toString() ?? '',
            'Template': [
              {
                'TemplateName': item['templateName']?.toString() ?? '',
                'Department': item['departmentName']?.toString() ?? '',
                'Frequency': 'Monthly',
                'NormalVolume': 100 + i,
                'PeakVolume': 150 + i,
                'SourceCount': 2,
                'NumberOfOutputs': 1,
                'BenefitType': 'Efficiency Improvement',
                'BenefitAmount': 25000,
                'BenefitInTat': '1 day',
                'GoLiveDate': '2026-05-01',
                'DeactivateDate': null,
                'SpocPerson': 'spoc_${i + 1}',
                'SpocManager': 'mgr_${i + 1}',
                'UnitHead': 'head_${i + 1}',
                'Priority': 'High',
                'SourceList': '1,2',
              },
            ],
            'OutputFormats': [
              {'TemplateTempId': null, 'FormatName': 'Unimailing'},
            ],
            'Approvals': [
              {
                'TemplateTempId': null,
                'Approval_Type': 'Unit Head',
                'ApprovalFile': 'approval_${i + 1}.pdf',
              },
            ],
          },
          if (moduleId == '3') ...{
            // Same shape as submit-mapping body (TemplateConfig)
            'TemplateId': int.tryParse('${item['template_id']}') ?? 0,
            'templateId': item['template_id']?.toString() ?? '',
            'templateName': item['templateName']?.toString() ?? '',
            'departmentId': item['department_id']?.toString() ?? '',
            'departmentName': item['departmentName']?.toString() ?? '',
            'Sources': [
              {
                'NodeId': 'SRC_${i + 1}',
                'Department': item['department_id']?.toString() ?? '',
                'SourceType': 'Manual',
                'SourceName': item['templateName']?.toString() ?? '',
              },
            ],
            'JoinMappings': [
              {
                'NodeId': 'JOIN_${i + 1}',
                'Operation': 'INNER',
                'LeftSource': 'SRC_${i + 1}',
                'RightSource': 'SRC_${i + 2}',
                'Conditions': [
                  {'left': 'customer_id', 'op': '=', 'right': 'customer_id'},
                ],
              },
            ],
            'Edges': [
              {'from': 'SRC_${i + 1}', 'to': 'JOIN_${i + 1}'},
            ],
          },
        };

    final dataWithModule = mockData.asMap().entries.map((entry) {
      final i = entry.key;
      final item = entry.value;
      final payload = isSourceConfig ? mockPayloadFor(i, item) : null;
      final responseData = mockResponseDataFor(i, item, module);
      return {
        ...item,
        'module': module,
        'payload': payload,
        'payloadJson': payload != null ? jsonEncode(payload) : null,
        'responseData': responseData,
      };
    }).toList(growable: false);
    return Response.json(body: dataWithModule);
  }

  // Production: forward to external API
  try {
    final httpClient = HttpClient()
      ..badCertificateCallback = (cert, host, port) => true;
    final client = IOClient(httpClient);

    final authHeader = context.request.headers['Authorization'] ??
        context.request.headers['authorization'] ??
        '';

    final externalResponse = await client
        .post(
          Uri.parse('$kBaseUrl${ExternalApi.getCheckerTayListWithModule}'),
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
            if (authHeader.isNotEmpty) 'Authorization': authHeader,
          },
          body: jsonEncode(body),
        )
        .timeout(const Duration(seconds: 30));

    print(
        '[GET CHECKER LIST] External API status: ${externalResponse.statusCode}');

    if (externalResponse.statusCode >= 200 &&
        externalResponse.statusCode < 300) {
      final decoded = jsonDecode(externalResponse.body);
      final data =
          (decoded is Map<String, dynamic> && decoded.containsKey('data'))
              ? decoded['data']
              : decoded;
      if (data is List) {
        final normalized = data.whereType<Map>().map((item) {
          final map = item.map((k, v) => MapEntry(k.toString(), v));
          final existingPayload = map['payload'];
          final existingPayloadJson = map['payloadJson'];
          final existingResponseData = map['responseData'];
          Map<String, dynamic>? payload;
          String? payloadJson;
          Map<String, dynamic>? responseData;

          if (existingPayload is Map<String, dynamic>) {
            payload = existingPayload;
            payloadJson = jsonEncode(existingPayload);
          } else if (existingPayload is Map) {
            payload = existingPayload.map((k, v) => MapEntry(k.toString(), v));
            payloadJson = jsonEncode(payload);
          } else if (existingPayloadJson is String &&
              existingPayloadJson.trim().isNotEmpty) {
            payloadJson = existingPayloadJson;
            try {
              final decoded = jsonDecode(existingPayloadJson);
              if (decoded is Map<String, dynamic>) payload = decoded;
              if (decoded is Map) {
                payload = decoded.map((k, v) => MapEntry(k.toString(), v));
              }
            } catch (_) {
              // Keep payloadJson as-is for client-side defensive parsing.
            }
          }

          if (existingResponseData is Map<String, dynamic>) {
            responseData = existingResponseData;
          } else if (existingResponseData is Map) {
            responseData = existingResponseData.map(
              (k, v) => MapEntry(k.toString(), v),
            );
          }

          return {
            ...map,
            'module': map['module']?.toString() ?? module,
            'payload': payload,
            'payloadJson': payloadJson,
            'responseData': responseData,
          };
        }).toList(growable: false);
        return Response.json(body: normalized);
      }
      return Response.json(body: data);
    }

    return Response.json(
      statusCode: externalResponse.statusCode,
      body: ApiResponse.error(message: 'Failed to fetch checker list').toJson(),
    );
  } catch (e) {
    return Response.json(
      statusCode: HttpStatus.internalServerError,
      body: ApiResponse.error(message: 'Checker list service unavailable: $e')
          .toJson(),
    );
  }
}
