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

  if (deptId.isEmpty) {
    return Response.json(
      statusCode: HttpStatus.badRequest,
      body: ApiResponse.error(message: 'DeptId is required').toJson(),
    );
  }

  if (kDevMode) {
    final mockRows = [
      {
        'departmentId': 7,
        'sourceName': 'test name',
        'sourceID': 4,
        'departmentName': 'RETAIL ASSETS',
        'makerBy': 'J3216',
        'makerDate': '11/05/2026 11:35:40 AM',
        'sourceType': 1,
        'appName': 'test app name',
        'itgrc': 91729,
        'dbVault': 'test db',
        'sourceTypeName': 'Manual',
      },
      {
        'departmentId': 7,
        'sourceName': 'Test Source',
        'sourceID': 5,
        'departmentName': 'RETAIL ASSETS',
        'makerBy': 'J3216',
        'makerDate': '11/05/2026 2:56:37 PM',
        'sourceType': 1,
        'appName': 'Test app name',
        'itgrc': 1872197,
        'dbVault': 'dbvault',
        'sourceTypeName': 'Manual',
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
            '$kBaseUrl${ExternalApi.getSourceMasterCheckerTray}?DeptId=$deptId',
          ),
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
            if (authHeader.isNotEmpty) 'Authorization': authHeader,
          },
        )
        .timeout(const Duration(seconds: 30));

    print('[SOURCE MASTER CHECKER TRAY] External API status: '
        '${externalResponse.statusCode}');

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
      body: ApiResponse.error(
        message: 'Failed to fetch source master checker tray',
      ).toJson(),
    );
  } catch (e) {
    return Response.json(
      statusCode: HttpStatus.internalServerError,
      body: ApiResponse.error(
        message: 'Source master checker tray service unavailable: $e',
      ).toJson(),
    );
  }
}
