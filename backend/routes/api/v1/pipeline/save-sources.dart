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

  if (sources.isEmpty) {
    return Response.json(
      statusCode: HttpStatus.badRequest,
      body: ApiResponse.error(message: 'At least one source required').toJson(),
    );
  }

  final db = Database();
  final id = db.newId('SRC');
  db.sourceConfigs[id] = body;

  print('[SOURCE CONFIG SAVED] $id — ${sources.length} source(s)');
  print(const JsonEncoder.withIndent('  ').convert(body));

  return Response.json(
    statusCode: HttpStatus.created,
    body: ApiResponse.success(
      message: '${sources.length} source configuration(s) saved successfully',
      data: {'sourceConfigId': id},
    ).toJson(),
  );
}
