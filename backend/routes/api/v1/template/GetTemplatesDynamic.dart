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
    // Include jsonData only for edit-configuration mode (flag=1).
    // All other callers (template configuration sidebar) receive templates
    // without the heavy canvas payload.
    final isEditMode = flagStr == '1';
    final result = all.map((t) {
      final copy = Map<String, dynamic>.from(t);
      if (!isEditMode) copy['jsonData'] = null;

      // Enrich dynamicTemplate entries with sourceMasterList if not already set.
      // AddTemplate saves only SourceList IDs; GetTemplatesDynamic must resolve them.
      final dynKey = copy.containsKey('DynamicTemplate') ? 'DynamicTemplate' : 'dynamicTemplate';
      final dynTemplates = copy[dynKey] as List?;
      if (dynTemplates != null) {
        copy[dynKey] = dynTemplates.map((entry) {
          final e = Map<String, dynamic>.from(entry as Map);
          if (e['sourceMasterList'] == null) {
            final sourceListStr =
                (e['SourceList'] ?? e['sourceList'])?.toString() ?? '';
            final ids = sourceListStr
                .split(',')
                .map((s) => int.tryParse(s.trim()))
                .whereType<int>()
                .toSet();
            e['sourceMasterList'] = db.sourceMasterList
                .where((item) {
                  final itemId = item['id'];
                  return itemId is int && ids.contains(itemId);
                })
                .toList();
          }
          return e;
        }).toList();
      }
      return copy;
    }).toList();
    print('[GetTemplatesDynamic] deptId=$deptId flag=$flagStr isEditMode=$isEditMode → returning ${result.length} templates');
    return Response.json(body: result);
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
