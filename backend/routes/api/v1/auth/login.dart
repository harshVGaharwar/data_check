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

  final body = await context.request.json() as Map<String, dynamic>;
  final username = body['username'] as String? ?? '';
  final password = body['password'] as String? ?? '';

  if (username.isEmpty || password.isEmpty) {
    return Response.json(
      statusCode: HttpStatus.badRequest,
      body: ApiResponse.error(message: 'Username and password required').toJson(),
    );
  }

  final db = Database();
  final authService = AuthService(db);
  final result = authService.login(username, password);

  if (result == null) {
    return Response.json(
      statusCode: HttpStatus.unauthorized,
      body: ApiResponse.error(message: 'Invalid username or password').toJson(),
    );
  }

  return Response.json(
    body: ApiResponse.success(message: 'Login successful', data: result).toJson(),
  );
}
