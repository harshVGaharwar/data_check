import 'dart:io';
import 'package:dart_frog/dart_frog.dart';
import '../../../../lib/services/database.dart';
import '../../../../lib/models/models.dart';

Future<Response> onRequest(RequestContext context) async {
  switch (context.request.method) {
    case HttpMethod.get:
      return _list(context);
    case HttpMethod.post:
      return _create(context);
    default:
      return Response.json(
        statusCode: HttpStatus.methodNotAllowed,
        body: ApiResponse.error(message: 'Only GET and POST allowed').toJson(),
      );
  }
}

/// GET /api/v1/templates — list all templates
Response _list(RequestContext context) {
  final db = Database();
  final list = db.templates.values.map((t) => t.toJson()).toList();
  return Response.json(
    body: ApiResponse.success(data: list).toJson(),
  );
}

/// POST /api/v1/templates — create new template
Future<Response> _create(RequestContext context) async {
  final body = await context.request.json() as Map<String, dynamic>;

  // Validation
  final errors = <String, String>{};
  if ((body['templateName'] ?? '').toString().isEmpty) errors['templateName'] = 'Required';
  if ((body['department'] ?? '').toString().isEmpty) errors['department'] = 'Required';
  if ((body['frequency'] ?? '').toString().isEmpty) errors['frequency'] = 'Required';
  if ((body['spocPerson'] ?? '').toString().isEmpty) errors['spocPerson'] = 'Required';

  if (errors.isNotEmpty) {
    return Response.json(
      statusCode: HttpStatus.badRequest,
      body: {
        'status': 'error',
        'message': 'Validation failed',
        'errors': errors,
      },
    );
  }

  final db = Database();
  final id = db.newId('TPL');
  final template = Template.fromJson(id, body);
  db.templates[id] = template;

  print('[TEMPLATE CREATED] $id — ${template.templateName}');

  return Response.json(
    statusCode: HttpStatus.created,
    body: ApiResponse.success(
      message: 'Template created successfully',
      data: {'templateId': id, ...template.toJson()},
    ).toJson(),
  );
}
