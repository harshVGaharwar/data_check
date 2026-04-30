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

  final deptIdStr = context.request.uri.queryParameters['DeptId'] ?? '';
  final deptId = int.tryParse(deptIdStr);

  if (deptId == null) {
    return Response.json(
      statusCode: HttpStatus.badRequest,
      body: ApiResponse.error(message: 'DeptId query parameter is required').toJson(),
    );
  }

  // Dev mode: return only templates that have a saved config in sourceConfigs.
  if (kDevMode) {
    final db = Database();
    final allTemplates = db.templatesByDept[deptId] ?? [];
    final configured = allTemplates.where((t) {
      final key = '${t['templateId']}_$deptId';
      return db.sourceConfigs.containsKey(key);
    }).toList();
    return Response.json(body: configured);
  }

  try {
    final httpClient = HttpClient()
      ..badCertificateCallback = (cert, host, port) => true;
    final client = IOClient(httpClient);

    final authHeader = context.request.headers['Authorization'] ??
        context.request.headers['authorization'] ??
        '';

    final uri = Uri.parse('$kBaseUrl${ExternalApi.getApprovedTemplates}')
        .replace(queryParameters: {'DeptID': '$deptId'});

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
      body: ApiResponse.error(message: 'Failed to fetch approved templates').toJson(),
    );
  } catch (e) {
    return Response.json(
      statusCode: HttpStatus.internalServerError,
      body: ApiResponse.error(message: 'Approved templates service unavailable: $e').toJson(),
    );
  }
}
