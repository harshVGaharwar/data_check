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
  final templateIdStr = params['TemplateId'] ?? '';
  final deptIdStr = params['DeptId'] ?? '';

  if (templateIdStr.isEmpty || deptIdStr.isEmpty) {
    return Response.json(
      statusCode: HttpStatus.badRequest,
      body: ApiResponse.error(
        message: 'TemplateId and DeptId query parameters are required',
      ).toJson(),
    );
  }

  if (kDevMode) {
    final db = Database();
    final key = '${templateIdStr}_$deptIdStr';

    // 1. Return previously submitted config if it exists.
    final saved = db.sourceConfigs[key];
    if (saved != null) {
      print('[GetTemplateConfig] returning saved config for key=$key');
      return Response.json(body: saved);
    }

    // 2. Fall back to dynamically generated mock from template master data.
    final templateId = int.tryParse(templateIdStr) ?? 0;
    final deptId = int.tryParse(deptIdStr) ?? 0;

    final deptTemplates = db.templatesByDept[deptId] ?? [];
    Map<String, dynamic>? template;
    try {
      template = deptTemplates.firstWhere((t) => t['templateId'] == templateId);
    } catch (_) {
      template = null;
    }

    if (template == null) {
      return Response.json(
        statusCode: HttpStatus.notFound,
        body: ApiResponse.error(
          message: 'Template $templateId not found in dept $deptId.',
        ).toJson(),
      );
    }

    final sourceCount = (template['sourceCount'] as int?) ?? 2;
    final templateName = template['templateName']?.toString() ?? '';

    // Pick the first sourceCount entries from sourceMasterList.
    final availableSources = db.sourceMasterList.take(sourceCount).toList();
    if (availableSources.isEmpty) {
      return Response.json(
        statusCode: HttpStatus.notFound,
        body: ApiResponse.error(message: 'No sources available in dev DB.')
            .toJson(),
      );
    }

    const mockCols = 'id,name,amount,date,status,department';

    final sources = availableSources.asMap().entries.map((e) {
      final idx = e.key;
      final src = e.value as Map<String, dynamic>;
      return {
        'TemplateId': templateId,
        'SourceId': '${src['id']}',
        'SourceName': 'S${idx + 1}',
        'SourceType': '${src['sourceType'] ?? '1'}',
        'Department': '$deptId',
        'Template': templateName,
        'Separator': ',',
        'ColumnFile': 'data_${idx + 1}.csv',
        'QueryFile': '',
        'Columns': mockCols,
        'SelectedColumns': idx == 0 ? 'amount' : 'status',
        'SourceSeqNo': null,
      };
    }).toList();

    final joinNodeIdx = sources.length + 1; // e.g. n3 for 2 sources

    final joinMappings = <Map<String, dynamic>>[];
    if (sources.length >= 2) {
      joinMappings.add({
        'Id': 0,
        'TemplateId': templateId,
        'Department': '$deptId',
        'JoinNodeId': 'n$joinNodeIdx',
        'LeftSourceId': 'n1',
        'LeftSourceName': 'S1',
        'LeftColumn': 'id',
        'JoinType': 'left_join',
        'RightSourceId': 'n2',
        'RightSourceName': 'S2',
        'RightColumn': 'id',
        'CreatedOn': DateTime.now().toIso8601String(),
      });
    }

    final edges = sources
        .asMap()
        .entries
        .map((e) => {
              'template_id': templateId,
              'department': '$deptId',
              'From': 'n${e.key + 1}',
              'To': 'n$joinNodeIdx',
            })
        .toList();

    final connectedSources = sources
        .asMap()
        .entries
        .map((e) => {
              'TemplateId': templateId,
              'Department': '$deptId',
              'JoinNodeId': 'n$joinNodeIdx',
              'SourceId': 'n${e.key + 1}',
            })
        .toList();

    final outputColumns = [
      {
        'template_id': templateId,
        'department': '$deptId',
        'sourceid': '1',
        'sourceName': 'S1',
        'SourceColName': 'amount',
        'ColumnName': 'Amount',
      },
    ];

    final mock = {
      'TemplateId': templateId,
      'createdBy': 'ADM001',
      'Sources': sources,
      'JoinMappings': joinMappings,
      'Edges': edges,
      'connectedSources': connectedSources,
      'outputColumns': outputColumns,
    };

    print('[GetTemplateConfig] returning generated mock for key=$key');
    return Response.json(body: mock);
  }

  // ── Production: forward to external API ──
  try {
    final httpClient = HttpClient()
      ..badCertificateCallback = (cert, host, port) => true;
    final client = IOClient(httpClient);

    final authHeader = context.request.headers['Authorization'] ??
        context.request.headers['authorization'] ??
        '';

    final uri = Uri.parse('$kBaseUrl${ExternalApi.getTemplateConfig}')
        .replace(queryParameters: {
      'TemplateId': templateIdStr,
      'DeptId': deptIdStr,
    });

    final externalResponse = await client.get(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        if (authHeader.isNotEmpty) 'Authorization': authHeader,
      },
    ).timeout(const Duration(seconds: 30));

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
      body: ApiResponse.error(message: 'Failed to fetch template config')
          .toJson(),
    );
  } catch (e) {
    return Response.json(
      statusCode: HttpStatus.internalServerError,
      body: ApiResponse.error(
        message: 'Template config service unavailable: $e',
      ).toJson(),
    );
  }
}
