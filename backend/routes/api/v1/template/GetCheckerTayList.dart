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

  // Dev mode: return seeded mock data
  if (kDevMode) {
    final mockData = [
      {
        'template_id': 14,
        'templateName': 'test template',
        'department_id': 7,
        'filename': 'orders_csvdata1.csv',
        'makerBy': 'J3216',
        'makerDate': '2026-05-11T17:34:31.41',
        'source_id': null,
        'requestId': 'REQ_00120',
        'departmentName': 'RETAIL ASSETS',
      },
      {
        'template_id': 14,
        'templateName': 'test template',
        'department_id': 7,
        'filename': 'customers_csv.csv',
        'makerBy': 'J3216',
        'makerDate': '2026-05-11T17:34:31.41',
        'source_id': null,
        'requestId': 'REQ_00120',
        'departmentName': 'RETAIL ASSETS',
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
