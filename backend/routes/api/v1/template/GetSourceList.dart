import 'dart:convert';
import 'dart:io';
import 'package:dart_frog/dart_frog.dart';
import 'package:http/io_client.dart';
import '../../../../lib/config/api_config.dart';
import '../../../../lib/models/models.dart';
import '../../../../lib/services/database.dart';

Future<Response> onRequest(RequestContext context) async {
  if (context.request.method != HttpMethod.get) {
    return Response.json(
      statusCode: HttpStatus.methodNotAllowed,
      body: ApiResponse.error(message: 'Only GET allowed').toJson(),
    );
  }

  final params = context.request.uri.queryParameters;
  final deptIdStr = params['DeptId'] ?? '';
  final templateIdStr = params['TemplateId'] ?? '';

  final deptId = int.tryParse(deptIdStr);
  final templateId = int.tryParse(templateIdStr);

  if (deptId == null || templateId == null) {
    return Response.json(
      statusCode: HttpStatus.badRequest,
      body: ApiResponse.error(
        message: 'DeptId and TemplateId query parameters are required',
      ).toJson(),
    );
  }

  // Dev mode: return seeded records keyed by "deptId_templateId"
  if (kDevMode) {
    final db = Database();
    final key = '${deptId}_$templateId';
    final sources = db.sourceListByDeptTemplate[key] ?? [];
    return Response.json(body: sources);
  }

  // Production: forward to external API
  try {
    final httpClient = HttpClient()
      ..badCertificateCallback = (cert, host, port) => true;
    final client = IOClient(httpClient);

    final authHeader = context.request.headers['Authorization'] ??
        context.request.headers['authorization'] ??
        '';

    final uri = Uri.parse('$kBaseUrl${ExternalApi.getSourceList}')
        .replace(queryParameters: {
      'DeptId': '$deptId',
      'TemplateId': '$templateId',
    });

    final externalResponse = await client
        .get(
          uri,
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
            if (authHeader.isNotEmpty) 'Authorization': authHeader,
          },
        )
        .timeout(const Duration(seconds: 30));

    print('[GET SOURCE LIST] External API status: ${externalResponse.statusCode}');

    if (externalResponse.statusCode >= 200 &&
        externalResponse.statusCode < 300) {
      final decoded = jsonDecode(externalResponse.body);
      final data = (decoded is Map<String, dynamic> && decoded.containsKey('data'))
          ? decoded['data']
          : decoded;
      return Response.json(body: data);
    }

    return Response.json(
      statusCode: externalResponse.statusCode,
      body: ApiResponse.error(message: 'Failed to fetch source list').toJson(),
    );
  } catch (e) {
    return Response.json(
      statusCode: HttpStatus.internalServerError,
      body: ApiResponse.error(message: 'Source list service unavailable: $e').toJson(),
    );
  }
}
