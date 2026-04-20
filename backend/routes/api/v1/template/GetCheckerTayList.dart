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

  // Dev mode: return seeded mock data
  if (kDevMode) {
    if (templateId.isEmpty || departmentId.isEmpty) {
      return Response.json(body: <dynamic>[]);
    }
    final rid = requestId.isNotEmpty ? requestId : 'REQ_00010';
    final mockData = [
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
        'departmentName': 'CREDIT CARDS'
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
    return Response.json(body: mockData);
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
          Uri.parse('$kBaseUrl${ExternalApi.getCheckerTayList}'),
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
