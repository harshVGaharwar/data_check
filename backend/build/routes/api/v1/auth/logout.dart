import 'dart:io';
import 'package:dart_frog/dart_frog.dart';
import '../../../../lib/services/database.dart';
import '../../../../lib/services/auth_service.dart';
import '../../../../lib/models/models.dart';

Future<Response> onRequest(RequestContext context) async {
  if (context.request.method != HttpMethod.post) {
    return Response.json(
      statusCode: HttpStatus.methodNotAllowed,
      body: ApiResponse.error(message: 'Only POST allowed').toJson(),
    );
  }

  final authHeader = context.request.headers['Authorization'] ?? '';
  if (authHeader.startsWith('Bearer ')) {
    final token = authHeader.substring(7);
    final db = Database();
    AuthService(db).logout(token);
  }

  return Response.json(
    body: ApiResponse.success(message: 'Logged out successfully').toJson(),
  );
}
