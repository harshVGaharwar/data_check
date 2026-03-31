import 'dart:io';
import 'package:dart_frog/dart_frog.dart';
import '../services/database.dart';
import '../services/auth_service.dart';

/// CORS middleware — allows Flutter web frontend to call API
Middleware corsMiddleware() {
  return (handler) {
    return (context) async {
      // Handle preflight — return immediately, no auth check
      if (context.request.method == HttpMethod.options) {
        return Response(
          statusCode: HttpStatus.ok,
          headers: _corsHeaders,
        );
      }

      final response = await handler(context);

      return response.copyWith(
        headers: {...response.headers, ..._corsHeaders},
      );
    };
  };
}

const _corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Methods': 'GET, POST, PUT, DELETE, OPTIONS',
  'Access-Control-Allow-Headers': 'Content-Type, Authorization, Accept',
  'Access-Control-Max-Age': '86400',
};

/// Auth middleware — validates Bearer token
/// Skips auth for login, logout, health check, and OPTIONS preflight
Middleware authMiddleware() {
  return (handler) {
    return (context) async {
      // Skip auth for OPTIONS (preflight handled by CORS middleware)
      if (context.request.method == HttpMethod.options) {
        return handler(context);
      }

      final path = context.request.uri.path;

      // Skip auth for public endpoints
      if (path.endsWith('/auth/login') ||
          path.endsWith('/auth/logout') ||
          path == '/' ||
          path == '/api/v1') {
        return handler(context);
      }

      final authHeader = context.request.headers['Authorization'] ?? context.request.headers['authorization'];
      if (authHeader == null || !authHeader.startsWith('Bearer ')) {
        return Response.json(
          statusCode: HttpStatus.unauthorized,
          headers: _corsHeaders,
          body: {'status': 'error', 'message': 'Missing or invalid authorization token'},
        );
      }

      final token = authHeader.substring(7);
      final db = Database();
      final authService = AuthService(db);
      final user = authService.verify(token);

      if (user == null) {
        return Response.json(
          statusCode: HttpStatus.unauthorized,
          headers: _corsHeaders,
          body: {'status': 'error', 'message': 'Invalid or expired token'},
        );
      }

      // Inject user into context
      return handler(context.provide<String>(() => user.id));
    };
  };
}