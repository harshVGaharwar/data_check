import 'dart:convert';
import 'dart:io';
import 'package:dart_frog/dart_frog.dart';
import '../../../../lib/services/database.dart';
import '../../../../lib/models/models.dart';

Future<Response> onRequest(RequestContext context) async {
  if (context.request.method != HttpMethod.post) {
    return Response.json(
      statusCode: HttpStatus.methodNotAllowed,
      body: ApiResponse.error(message: 'Only POST allowed').toJson(),
    );
  }

  final body = await context.request.json() as Map<String, dynamic>;

  final sources = body['sources'] as List? ?? [];
  final joinMappings = body['joinMappings'] as List? ?? [];
  final edges = body['edges'] as List? ?? [];

  // Validation
  if (sources.isEmpty) {
    return Response.json(
      statusCode: HttpStatus.badRequest,
      body: ApiResponse.error(message: 'At least one source required').toJson(),
    );
  }

  final db = Database();
  final id = db.newId('CFG');

  final config = PipelineConfig(
    id: id,
    sources: sources.map((e) => Map<String, dynamic>.from(e as Map)).toList(),
    joinMappings: joinMappings.map((e) => Map<String, dynamic>.from(e as Map)).toList(),
    edges: edges.map((e) => Map<String, dynamic>.from(e as Map)).toList(),
  );
  db.pipelineConfigs[id] = config;

  print('[PIPELINE CONFIG SAVED] $id');
  print(const JsonEncoder.withIndent('  ').convert(body));

  return Response.json(
    statusCode: HttpStatus.created,
    body: ApiResponse.success(
      message: 'Pipeline configuration saved successfully',
      data: {'configurationId': id},
    ).toJson(),
  );
}
