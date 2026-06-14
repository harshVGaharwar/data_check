import 'dart:convert';
import 'dart:io';
import 'package:dart_frog/dart_frog.dart';
import 'package:http/io_client.dart';
import '../../../../lib/config/api_config.dart';
import '../../../../lib/models/models.dart';

Future<Response> onRequest(RequestContext context) async {
  if (context.request.method != HttpMethod.get) {
    return Response.json(
      statusCode: HttpStatus.methodNotAllowed,
      body: ApiResponse.error(message: 'Only GET allowed').toJson(),
    );
  }

  final params = context.request.uri.queryParameters;
  final deptId = params['DeptId'] ?? '';
  final flag = int.tryParse(params['flag'] ?? '') ?? 0;

  if (deptId.isEmpty || (flag != 4 && flag != 5)) {
    return Response.json(
      statusCode: HttpStatus.badRequest,
      body: ApiResponse.error(
        message: 'DeptId and flag (4 or 5) are required',
      ).toJson(),
    );
  }

  if (kDevMode) {
    // jsonData is sent as a JSON-encoded string, matching real API format.
    // TemplateCheckerTrayItem.fromMap decodes it — same path as production.
    final rawRows = [
      {
        'templateId': '108',
        'departmentId': '7',
        'templateName': 'test static',
        'departmentName': 'RETAIL ASSETS',
        'makerBy': 'J3216',
        'makerDate': '27/05/2026 2:40:39 PM',
        'jsonData': jsonEncode({
          'TemplateType': '1',
          'Template': [
            {
              'TemplateName': 'test static',
              'Department': '7',
              'Frequency': 'Daily',
              'NormalVolume': 100000,
              'PeakVolume': 100000000,
              'SourceCount': 2,
              'BenefitType': 'Cost Saving',
              'BenefitAmount': 1000000,
              'BenefitInTat': '1000000000',
              'GoLiveDate': '2026-05-27',
              'DeactivateDate': '2026-05-31',
              'SpocPerson': 'test',
              'SpocManager': 'test',
              'UnitHead': 'test',
              'Priority': 'Low',
              'NumberOfOutputs': null,
              'SourceList': '1',
            },
          ],
          'OutputFormats': [
            {'TemplateTempId': null, 'FormatName': 'User Defined'},
          ],
          'Approvals': [
            {
              'TemplateTempId': null,
              'Approval_Type': 'UAT test',
              'ApprovalFile': 'uatApproval.pdf',
            },
          ],
          'CreatedBy': 'J3216',
          'jsonData': '',
          'DepartmentName': 'RETAIL ASSETS',
          'SourceListNames': 'Manual',
          'DynamicTemplate': [],
        }),
      },
      {
        'templateId': '21',
        'departmentId': '1',
        'templateName': 'asd',
        'departmentName': 'Finance',
        'makerBy': 'J3216',
        'makerDate': '11/05/2026 3:21:50 PM',
        'jsonData': jsonEncode({
          'TemplateType': '1',
          'Template': [
            {
              'TemplateName': 'asd',
              'Department': '1',
              'Frequency': 'Daily',
              'NormalVolume': 5000,
              'PeakVolume': 50000,
              'SourceCount': 1,
              'BenefitType': 'Cost Saving',
              'BenefitAmount': 200000,
              'BenefitInTat': '500000',
              'GoLiveDate': '2026-05-11',
              'DeactivateDate': '2026-12-31',
              'SpocPerson': 'John',
              'SpocManager': 'Jane',
              'UnitHead': 'Jack',
              'Priority': 'High',
              'NumberOfOutputs': null,
              'SourceList': '1',
            },
          ],
          'OutputFormats': [
            {'TemplateTempId': null, 'FormatName': 'User Defined'},
          ],
          'Approvals': [
            {
              'TemplateTempId': null,
              'Approval_Type': 'UAT test',
              'ApprovalFile': 'finance_approval.pdf',
            },
          ],
          'CreatedBy': 'J3216',
          'jsonData': '',
          'DepartmentName': 'Finance',
          'SourceListNames': 'Manual',
          'DynamicTemplate': [],
        }),
      },
      {
        'templateId': '22',
        'departmentId': '1',
        'templateName': 'Finance Dynamic Report',
        'departmentName': 'Finance',
        'makerBy': 'J3216',
        'makerDate': '12/05/2026 10:15:00 AM',
        'jsonData': jsonEncode({
          'TemplateType': '3',
          'TemplateTypeName': '2-Dynamic',
          'Template': [
            {
              'TemplateName': 'Finance Dynamic Report',
              'Department': '1',
              'Frequency': 'Monthly',
              'NormalVolume': 10000,
              'PeakVolume': 100000,
              'SourceCount': 3,
              'BenefitType': 'Revenue Generation',
              'BenefitAmount': 500000,
              'BenefitInTat': '750000',
              'GoLiveDate': '2026-05-12',
              'DeactivateDate': '2026-12-31',
              'SpocPerson': 'Alice',
              'SpocManager': 'Bob',
              'UnitHead': 'Charlie',
              'Priority': 'High',
              'NumberOfOutputs': 3,
              'SourceList': '1',
            },
          ],
          'OutputFormats': [
            {'TemplateTempId': null, 'FormatName': 'Unimailing'},
          ],
          'Approvals': [
            {
              'TemplateTempId': null,
              'Approval_Type': 'UAT test',
              'ApprovalFile': 'finance_dynamic_approval.pdf',
            },
          ],
          'CreatedBy': 'J3216',
          'jsonData': '',
          'DepartmentName': 'Finance',
          'SourceListNames': 'Manual',
          'SourceCount': '3',
          'SourceType': '1',
          'DynamicTemplate': [
            {
              'SourceList': '1',
              'SourceListNames': 'Manual',
              'SourceCount': '2',
              'SourceType': '3',
            },
            {
              'SourceList': '1,2',
              'SourceListNames': 'Manual,QDRS',
              'SourceCount': '2',
              'SourceType': '3',
            },
            {
              'SourceList': '1,2,3',
              'SourceListNames': 'Manual,QDRS,Core Banking',
              'SourceCount': '3',
              'SourceType': '3',
            },
          ],
        }),
      },
      {
        'templateId': '107',
        'departmentId': '7',
        'templateName': 'dynamci+uni',
        'departmentName': 'RETAIL ASSETS',
        'makerBy': 'J3216',
        'makerDate': '25/05/2026 6:36:56 PM',
        'jsonData': jsonEncode({
          'TemplateType': '3',
          'TemplateTypeName': '2-Dynamic',
          'Template': [
            {
              'TemplateName': 'dynamci+uni',
              'Department': '7',
              'Frequency': 'Monthly',
              'NormalVolume': 1,
              'PeakVolume': 1,
              'SourceCount': 3,
              'BenefitType': 'Revenue Generation',
              'BenefitAmount': 2,
              'BenefitInTat': '2',
              'GoLiveDate': '2026-05-25',
              'DeactivateDate': '2026-05-27',
              'SpocPerson': 'sdds',
              'SpocManager': 's',
              'UnitHead': 's',
              'Priority': 'Medium',
              'NumberOfOutputs': 2,
              'SourceList': '1',
            },
          ],
          'OutputFormats': [
            {'TemplateTempId': null, 'FormatName': 'Unimailing'},
          ],
          'Approvals': [
            {
              'TemplateTempId': null,
              'Approval_Type': 'UAT test',
              'ApprovalFile': 'image (4).png',
            },
          ],
          'CreatedBy': 'J3216',
          'jsonData': '',
          'DepartmentName': 'RETAIL ASSETS',
          'SourceListNames': 'Manual',
          'SourceCount': '3',
          'SourceType': '1',
          'DynamicTemplate': [
            {
              'SourceList': '1',
              'SourceListNames': 'Manual',
              'SourceCount': '2',
              'SourceType': '3',
            },
            {
              'SourceList': '1,2',
              'SourceListNames': 'Manual,QDRS',
              'SourceCount': '2',
              'SourceType': '3',
            },
            {
              'SourceList': '1,2',
              'SourceListNames': 'Manual,QDRS',
              'SourceCount': '2',
              'SourceType': '3',
            },
          ],
        }),
      },
    ];
    final mockItems = rawRows
        .where((r) => r['departmentId'].toString() == deptId)
        .map((r) => TemplateCheckerTrayItem.fromMap(
              r.map((k, v) => MapEntry(k.toString(), v)),
            ))
        .toList();
    return Response.json(body: mockItems.map((e) => e.toJson()).toList());
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
        .get(
          Uri.parse(
            '$kBaseUrl${ExternalApi.getTemplateCheckerTray}?DeptId=$deptId&flag=$flag',
          ),
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
            if (authHeader.isNotEmpty) 'Authorization': authHeader,
          },
        )
        .timeout(const Duration(seconds: 30));

    print('[TEMPLATE CHECKER TRAY] External API status: '
        '${externalResponse.statusCode}');

    if (externalResponse.statusCode >= 200 &&
        externalResponse.statusCode < 300) {
      final decoded = jsonDecode(externalResponse.body);
      final data =
          (decoded is Map<String, dynamic> && decoded.containsKey('data'))
              ? decoded['data']
              : decoded;

      if (data is List) {
        final items = data
            .whereType<Map>()
            .map((item) => TemplateCheckerTrayItem.fromMap(
                  item.map((k, v) => MapEntry(k.toString(), v)),
                ).toJson())
            .toList(growable: false);
        return Response.json(body: items);
      }
      return Response.json(body: data);
    }

    return Response.json(
      statusCode: externalResponse.statusCode,
      body: ApiResponse.error(
        message: 'Failed to fetch template checker tray',
      ).toJson(),
    );
  } catch (e) {
    return Response.json(
      statusCode: HttpStatus.internalServerError,
      body: ApiResponse.error(
        message: 'Template checker tray service unavailable: $e',
      ).toJson(),
    );
  }
}
