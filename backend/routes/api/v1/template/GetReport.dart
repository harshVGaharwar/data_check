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

  if (kDevMode) {
    final mockData = [
      {
        'template_id': '14',
        'templateName': 'test template',
        'department_id': 'RETAIL ASSETS',
        'filename': 'finalreport_20260512_105058.csv',
        'requestId': 'REQ_00120',
        'makerBy': 'J3216',
        'makerDate': '11/05/2026 5:34:31 PM',
      },
      {
        'template_id': '14',
        'templateName': 'test template',
        'department_id': 'RETAIL ASSETS',
        'filename': 'finalreport_20260512_105058.csv',
        'requestId': 'REQ_00120',
        'makerBy': 'J3216',
        'makerDate': '11/05/2026 5:34:31 PM',
      },
      {
        'template_id': '14',
        'templateName': 'test template',
        'department_id': 'RETAIL ASSETS',
        'filename': 'invalid_rowsright_20260512_104956.csv',
        'requestId': 'REQ_00120',
        'makerBy': 'J3216',
        'makerDate': '11/05/2026 5:34:31 PM',
      },
    ];
    return Response.json(body: mockData);
  }

  try {
    final httpClient = HttpClient()
      ..badCertificateCallback = (cert, host, port) => true;
    final client = IOClient(httpClient);

    final authHeader = context.request.headers['Authorization'] ??
        context.request.headers['authorization'] ??
        '';

    final externalResponse = await client
        .post(
          Uri.parse('$kBaseUrl${ExternalApi.getReport}'),
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
            if (authHeader.isNotEmpty) 'Authorization': authHeader,
          },
          body: jsonEncode(body),
        )
        .timeout(const Duration(seconds: 30));

    print('[GET REPORT] External API status: ${externalResponse.statusCode}');

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
      body: ApiResponse.error(message: 'Failed to fetch report list').toJson(),
    );
  } catch (e) {
    return Response.json(
      statusCode: HttpStatus.internalServerError,
      body: ApiResponse.error(message: 'Report service unavailable: $e')
          .toJson(),
    );
  }
}
