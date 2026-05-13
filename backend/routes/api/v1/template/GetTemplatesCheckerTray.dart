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
    // flag=4 → Template Creation, flag=5 → Template Configuration
    if (flag == 4) {
      return Response.json(body: [
        {
          'templateId': '21',
          'departmentId': '7',
          'templateName': 'asd',
          'departmentName': 'RETAIL ASSETS',
          'makerBy': 'J3216',
          'makerDate': '11/05/2026 3:21:50 PM',
          'jsonData': {
            'Template': [
              {
                'TemplateName': 'asd',
                'Department': '7',
                'Frequency': 'Bi-Weekly',
                'NormalVolume': 1,
                'PeakVolume': 1,
                'SourceCount': 5,
                'NumberOfOutputs': 2,
                'BenefitType': 'Efficiency Improvement',
                'BenefitAmount': 1,
                'BenefitInTat': '2',
                'GoLiveDate': '2026-05-11',
                'DeactivateDate': '2026-05-27',
                'SpocPerson': 's',
                'SpocManager': 's',
                'UnitHead': 's',
                'Priority': 'Medium',
                'SourceList': 'J1',
              },
            ],
            'Approvals': [
              {'TemplateTempId': null, 'FormatName': 'Unimailing'},
            ],
            'ApprovalType': 'UAT test',
            'ApprovalFile': 'bank_logo.png',
            'CreatedBy': 'J3216',
            'JsonData': '',
            'DepartmentName': 'RETAIL ASSETS',
            'SourceListNames': 'csdccsd',
          },
        },
      ]);
    }

    // flag=5: Template Configuration
    return Response.json(body: [
      {
        'templateId': 18,
        'departmentId': 7,
        'templateName': 'Test 1',
        'departmentName': 'RETAIL ASSETS',
        'makerBy': 'J3216',
        'makerDate': '11/05/2026 1:24:10 PM',
        'jsonData': {
          'TemplateId': 18,
          'createdBy': 'J3216',
          'templateMode': 0,
          'Sources': [
            {
              'TemplateId': 18,
              'SourceId': '1',
              'SourceName': 'huiu',
              'SourceType': '1',
              'Department': '7',
              'Template': '18 - Test 1',
              'Separator': '\t',
              'ColumnFile': 'customers_csvdatatesttab.csv',
              'QueryFile': '',
              'Columns': 'ID,NAME',
              'SelectedColumns': 'NAME',
              'SourceSeqNo': null,
            },
            {
              'TemplateId': 18,
              'SourceId': '1',
              'SourceName': 'kjn',
              'SourceType': '1',
              'Department': '7',
              'Template': '18 - Test 1',
              'Separator': '\t',
              'ColumnFile': 'customers_csvdatatesttab.csv',
              'QueryFile': '',
              'Columns': 'ID,NAME',
              'SelectedColumns': '',
              'SourceSeqNo': null,
            },
          ],
          'JoinMappings': [
            {
              'Id': 0,
              'TemplateId': 18,
              'Department': '7',
              'JoinNodeId': 'n3',
              'LeftSourceId': 'n1',
              'LeftSourceName': 'huiu',
              'LeftColumn': 'ID',
              'JoinType': 'left_join',
              'RightSourceId': 'n2',
              'RightSourceName': 'kjn',
              'RightColumn': 'ID',
              'CreatedOn': '2026-05-11T00:00:00',
            },
          ],
          'Edges': [
            {'template_id': 18, 'department': '7', 'From': 'n1', 'To': 'n3'},
            {'template_id': 18, 'department': '7', 'From': 'n2', 'To': 'n3'},
          ],
          'connectedSources': [
            {'TemplateId': 18, 'Department': '7', 'JoinNodeId': 'n3', 'SourceId': 'n1'},
            {'TemplateId': 18, 'Department': '7', 'JoinNodeId': 'n3', 'SourceId': 'n2'},
          ],
          'outputColumns': [
            {
              'template_id': 18,
              'department': '7',
              'sourceid': '1',
              'sourceName': 'huiu',
              'SourceColName': 'NAME',
              'ColumnName': 'name',
            },
          ],
          'Jsondata': null,
        },
      },
    ]);
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
