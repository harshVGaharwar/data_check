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
    // Fixed mock data — mirrors the real external API response format.
    // jsonData arrives as a JSON-encoded string from the real API;
    // items without data use an empty string.
    final mockRows = [
      {
        'templateId': '6',
        'departmentId': '7',
        'templateName': 'akj',
        'departmentName': 'RETAIL ASSETS',
        'makerBy': 'J3216',
        'makerDate': '02/05/2026 5:56:38 PM',
        'jsonData': '',
      },
      {
        'templateId': '7',
        'departmentId': '7',
        'templateName': 'akj',
        'departmentName': 'RETAIL ASSETS',
        'makerBy': 'J3216',
        'makerDate': '02/05/2026 6:24:14 PM',
        'jsonData': '',
      },
      {
        'templateId': '11',
        'departmentId': '7',
        'templateName': 'test',
        'departmentName': 'RETAIL ASSETS',
        'makerBy': 'J3216',
        'makerDate': '02/05/2026 6:34:07 PM',
        'jsonData': '',
      },
      {
        'templateId': '13',
        'departmentId': '7',
        'templateName': 'Test Manual',
        'departmentName': 'RETAIL ASSETS',
        'makerBy': 'J3216',
        'makerDate': '04/05/2026 12:18:38 PM',
        'jsonData': jsonEncode({
          'Template': {
            'TemplateName': 'Test Manual',
            'Department': '7',
            'Frequency': 'Daily',
            'NormalVolume': 1000,
            'PeakVolume': 10000,
            'SourceCount': 2,
            'NumberOfOutput': 1,
          },
          'Benefit': {
            'BenefitAmount': 10000,
            'BenefitInTAT': '1%',
          },
          'OutputFormats': [
            {'TemplateTempId': null, 'FormatName': 'User Defined'},
          ],
          'AdditionalData': {'ActivatedDate': '2026-05-04'},
          'SpocPerson': 'Abc',
          'SpocManager': 'abd',
          'UnitHead': 'doli',
          'Priority': 'Medium',
          'Approvals': [
            {
              'TemplateTempId': null,
              'Approval_Type': 'UAT test',
              'ApprovalFile': 'uatApproval.pdf',
            },
          ],
          'createdBy': 'J3216',
        }),
      },
    ];
    return Response.json(body: mockRows);
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
        final normalized = data.whereType<Map>().map((item) {
          final map = item.map((k, v) => MapEntry(k.toString(), v));
          final rawJsonData = map['jsonData'];
          dynamic jsonData;

          if (rawJsonData is Map<String, dynamic>) {
            jsonData = rawJsonData;
          } else if (rawJsonData is Map) {
            jsonData = rawJsonData.map((k, v) => MapEntry(k.toString(), v));
          } else if (rawJsonData is String && rawJsonData.trim().isNotEmpty) {
            try {
              jsonData = jsonDecode(rawJsonData);
            } catch (_) {
              jsonData = rawJsonData;
            }
          } else {
            jsonData = rawJsonData ?? '';
          }

          return {...map, 'jsonData': jsonData};
        }).toList(growable: false);
        return Response.json(body: normalized);
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
