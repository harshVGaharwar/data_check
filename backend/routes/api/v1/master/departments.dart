import 'dart:io';
import 'package:dart_frog/dart_frog.dart';
import '../../../../lib/services/database.dart';
import '../../../../lib/models/models.dart';

Response onRequest(RequestContext context) {
  if (context.request.method != HttpMethod.get) {
    return Response.json(
      statusCode: HttpStatus.methodNotAllowed,
      body: ApiResponse.error(message: 'Only GET allowed').toJson(),
    );
  }

  final db = Database();
  return Response.json(
    body: ApiResponse.success(
      data: db.departments.map((d) => d.toJson()).toList(),
    ).toJson(),
  );
}
