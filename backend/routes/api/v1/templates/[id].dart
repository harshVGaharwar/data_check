import 'dart:io';
import 'package:dart_frog/dart_frog.dart';
import '../../../../lib/services/database.dart';
import '../../../../lib/models/models.dart';

Response onRequest(RequestContext context, String id) {
  if (context.request.method != HttpMethod.get) {
    return Response.json(
      statusCode: HttpStatus.methodNotAllowed,
      body: ApiResponse.error(message: 'Only GET allowed').toJson(),
    );
  }

  final db = Database();
  final template = db.templates[id];

  if (template == null) {
    return Response.json(
      statusCode: HttpStatus.notFound,
      body: ApiResponse.error(message: 'Template not found: $id').toJson(),
    );
  }

  return Response.json(
    body: ApiResponse.success(data: template.toJson()).toJson(),
  );
}
