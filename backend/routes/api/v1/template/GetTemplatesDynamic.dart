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

  final deptIdStr = context.request.uri.queryParameters['deptId'] ?? '';
  final flagStr = context.request.uri.queryParameters['flag'];
  final deptId = int.tryParse(deptIdStr);

  if (deptId == null) {
    return Response.json(
      statusCode: HttpStatus.badRequest,
      body: ApiResponse.error(message: 'deptId query parameter is required').toJson(),
    );
  }

  // Dev mode: return from local in-memory DB
  if (kDevMode) {
    final db = Database();
    final all = db.templatesByDept[deptId] ?? [];
    // Dev mode: return all templates regardless of flag so every created
    // template (Static or Dynamic) is visible in the sidebar.
    print('[GetTemplatesDynamic] deptId=$deptId flag=$flagStr → returning ${all.length} templates: ${all.map((t) => '${t['TemplateId'] ?? t['templateId']}:${t['TemplateType'] ?? t['templateType']}').toList()}');
    return Response.json(body: all);
  }

  try {
    final httpClient = HttpClient()
      ..badCertificateCallback = (cert, host, port) => true;
    final client = IOClient(httpClient);

    final authHeader = context.request.headers['Authorization'] ??
        context.request.headers['authorization'] ??
        '';

    final uri = Uri.parse('$kBaseUrl${ExternalApi.getTemplatesDynamic}').replace(
      queryParameters: {
        'DeptID': '$deptId',
        if (flagStr != null) 'flag': flagStr,
      },
    );

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

    print('[TEMPLATES_DYNAMIC] External API status: ${externalResponse.statusCode}');

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
      body: ApiResponse.error(message: 'Failed to fetch dynamic templates').toJson(),
    );
  } catch (e) {
    return Response.json(
      statusCode: HttpStatus.internalServerError,
      body: ApiResponse.error(message: 'Templates service unavailable: $e')
          .toJson(),
    );
  }
}
