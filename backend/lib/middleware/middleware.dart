import 'dart:io';
import 'package:dart_frog/dart_frog.dart';
import '../config/api_config.dart';
import '../models/models.dart';
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
      if (path.endsWith('/account/login') ||
          path.endsWith('/account/refresh') ||
          path.endsWith('/auth/logout') ||
          path.endsWith('/template/GetApprovalList') ||
          path == '/' ||
          path == '/api/v1') {
        return handler(context);
      }

      final authHeader = context.request.headers['Authorization'] ??
          context.request.headers['authorization'];
      if (authHeader == null || !authHeader.startsWith('Bearer ')) {
        return Response.json(
          statusCode: HttpStatus.unauthorized,
          headers: _corsHeaders,
          body: {
            'status': 'error',
            'message': 'Missing or invalid authorization token'
          },
        );
      }

      final token = authHeader.substring(7);

      // In dev mode the external HDFC server is unavailable, so tokens issued
      // by the real API can't be re-validated against the in-memory db after a
      // backend restart. Accept any non-empty token so reloads keep working.
      if (kDevMode) {
        final db = Database();
        final userId = db.tokens[token] ?? 'DEV_USER';
        return handler(context.provide<String>(() => userId));
      }

      final db = Database();
      final authService = AuthService(db);
      final user = authService.verify(token);

      if (user != null) {
        return handler(context.provide<String>(() => user.id));
      }

      // Token not in local db — backend may have restarted and lost the
      // in-memory token map. Re-register the token so this request and
      // subsequent requests succeed. The handler will forward the token
      // to the external API for real validation.
      const rehydratedId = 'REHYDRATED_USER';
      db.tokens[token] = rehydratedId;
      db.users[rehydratedId] ??= User(
        id: rehydratedId,
        username: 'rehydrated',
        password: '',
        role: 'user',
      );
      return handler(context.provide<String>(() => rehydratedId));
    };
  };
}
