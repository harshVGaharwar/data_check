import 'dart:convert';
import 'dart:io';
import 'package:dart_frog/dart_frog.dart';
import 'package:http/io_client.dart';
import '../../../../lib/config/api_config.dart';
import '../../../../lib/models/models.dart';
import '../../../../lib/services/database.dart';

Future<Response> onRequest(RequestContext context) async {
  // Returns the flat list of all configured templates across departments.
  if (context.request.method != HttpMethod.get) {
    return Response.json(
      statusCode: HttpStatus.methodNotAllowed,
      body: ApiResponse.error(message: 'Only GET allowed').toJson(),
    );
  }

  // Dev mode: combine sourceConfigs with template metadata
  if (kDevMode) {
    final db = Database();
    final list = <Map<String, dynamic>>[];

    db.sourceConfigs.forEach((key, cfg) {
      final parts = key.split('_');
      if (parts.length != 2) return;
      final templateId = int.tryParse(parts[0]);
      final deptId = int.tryParse(parts[1]);
      if (templateId == null || deptId == null) return;

      final templates = db.templatesByDept[deptId] ?? const [];
      final template = templates.firstWhere(
        (t) => t['templateId'] == templateId,
        orElse: () => <String, dynamic>{},
      );
      final sources = (cfg['Sources'] as List?) ?? const [];
      final joins = (cfg['JoinMappings'] as List?) ?? const [];
      final outputs = (cfg['outputColumns'] as List?) ?? const [];

      list.add({
        'templateId': templateId,
        'templateName': template['templateName'] ?? '—',
        'department': template['department'] ?? '—',
        'departmentId': deptId,
        'frequency': template['frequency'] ?? '—',
        'sourceCount': sources.length,
        'joinCount': joins.length,
        'outputCount': outputs.length,
        'createdBy': cfg['createdBy'] ?? '—',
      });
    });

    return Response.json(body: list);
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
          Uri.parse('$kBaseUrl${ExternalApi.getTemplateConfigurationList}'),
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
            if (authHeader.isNotEmpty) 'Authorization': authHeader,
          },
        )
        .timeout(const Duration(seconds: 30));

    print('[TEMPLATE CONFIGURATION LIST] External API status: '
        '${externalResponse.statusCode}');

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
      body: ApiResponse.error(
        message: 'Failed to fetch template configuration list',
      ).toJson(),
    );
  } catch (e) {
    return Response.json(
      statusCode: HttpStatus.internalServerError,
      body: ApiResponse.error(
        message: 'Template configuration list service unavailable: $e',
      ).toJson(),
    );
  }
}
