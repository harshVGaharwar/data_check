import 'dart:convert';
import 'dart:io';
import 'package:dart_frog/dart_frog.dart';
import 'package:http/io_client.dart';
import '../../../../lib/config/api_config.dart';
import '../../../../lib/models/models.dart';
import '../../../../lib/services/database.dart';

Future<Response> onRequest(RequestContext context) async {
  if (context.request.method != HttpMethod.post) {
    return Response.json(
      statusCode: HttpStatus.methodNotAllowed,
      body: ApiResponse.error(message: 'Only POST allowed').toJson(),
    );
  }

  final body = await context.request.json() as Map<String, dynamic>;
  final token = body['token'] as String? ?? '';
  final userId = body['userId'] as String? ?? '';
  final expiryDate = body['expiryDate'] as String? ?? '';
  final isRevoked = body['isRevoked'] as bool? ?? false;

  if (token.isEmpty) {
    return Response.json(
      statusCode: HttpStatus.badRequest,
      body: ApiResponse.error(message: 'token is required').toJson(),
    );
  }

  // Dev mode — return a mock refreshed token
  if (kDevMode) {
    final db = Database();
    final newAccessToken = 'dev-token-refreshed-${DateTime.now().millisecondsSinceEpoch}';
    final newRefreshToken = 'dev-refresh-${DateTime.now().millisecondsSinceEpoch}';
    final existingUserId = db.tokens[token] ?? 'DEV_USER';
    db.tokens[newAccessToken] = existingUserId;
    db.tokens.remove(token);
    return Response.json(
      body: {
        'accessToken': newAccessToken,
        'refreshToken': newRefreshToken,
      },
    );
  }

  try {
    final httpClient = HttpClient()
      ..badCertificateCallback = (cert, host, port) => true;
    final client = IOClient(httpClient);

    final hdfcResponse = await client
        .post(
          Uri.parse('$kBaseUrl${ExternalApi.refreshToken}'),
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
          body: jsonEncode({
            'token': token,
            'userId': userId,
            'expiryDate': expiryDate,
            'isRevoked': isRevoked,
          }),
        )
        .timeout(const Duration(seconds: 30));

    if (hdfcResponse.statusCode == 200) {
      final data = jsonDecode(hdfcResponse.body) as Map<String, dynamic>;
      final newAccessToken = data['accessToken'] as String? ?? '';
      final newRefreshToken = data['refreshToken'] as String? ?? '';

      if (newAccessToken.isNotEmpty) {
        final db = Database();
        final existingUserId = db.tokens[token] ?? 'HDFC_USER';
        db.tokens[newAccessToken] = existingUserId;
        db.tokens.remove(token);
      }

      return Response.json(
        body: {
          'accessToken': newAccessToken,
          'refreshToken': newRefreshToken,
        },
      );
    }

    return Response.json(
      statusCode: HttpStatus.unauthorized,
      body: ApiResponse.error(message: 'Token refresh failed').toJson(),
    );
  } catch (e) {
    return Response.json(
      statusCode: HttpStatus.internalServerError,
      body: ApiResponse.error(message: 'Refresh service unavailable: $e').toJson(),
    );
  }
}
