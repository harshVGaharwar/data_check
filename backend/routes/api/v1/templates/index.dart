import 'dart:convert';
import 'dart:io';
import 'package:dart_frog/dart_frog.dart';
import 'package:http/http.dart' as http;
import 'package:http/io_client.dart';
import '../../../../lib/config/api_config.dart';
import '../../../../lib/models/models.dart';

Future<Response> onRequest(RequestContext context) async {
  if (context.request.method != HttpMethod.post) {
    return Response.json(
      statusCode: HttpStatus.methodNotAllowed,
      body: ApiResponse.error(message: 'Only POST allowed').toJson(),
    );
  }

  final body = await context.request.json() as Map<String, dynamic>;
  final authHeader = context.request.headers['Authorization'] ??
      context.request.headers['authorization'] ?? '';

  // Dev mode: return mock response without hitting external API
  if (kDevMode) {
    return Response.json(
      body: ApiResponse.success(
        message: 'Template created successfully (dev mock)',
        data: {'templateId': 'MOCK-${DateTime.now().millisecondsSinceEpoch}'},
      ).toJson(),
    );
  }

  try {
    final httpClient = HttpClient()
      ..badCertificateCallback = (cert, host, port) => true;
    final client = IOClient(httpClient);

    final externalResponse = await client.post(
      Uri.parse('$kBaseUrl${ExternalApi.templateCreate}'),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        if (authHeader.isNotEmpty) 'Authorization': authHeader,
      },
      body: jsonEncode(body),
    ).timeout(const Duration(seconds: 30));

    print('[TEMPLATE] External API status: ${externalResponse.statusCode}');
    print('[TEMPLATE] External API body: ${externalResponse.body}');

    Map<String, dynamic>? data;
    try {
      data = jsonDecode(externalResponse.body) as Map<String, dynamic>;
    } catch (_) {
      return Response.json(
        statusCode: HttpStatus.badGateway,
        body: ApiResponse.error(
          message: 'Invalid response from template service (status ${externalResponse.statusCode})',
        ).toJson(),
      );
    }

    if (externalResponse.statusCode >= 200 && externalResponse.statusCode < 300) {
      return Response.json(
        body: ApiResponse.success(
          message: 'Template created successfully',
          data: data,
        ).toJson(),
      );
    }

    return Response.json(
      statusCode: externalResponse.statusCode,
      body: ApiResponse.error(
        message: data['message'] ?? data['Message'] ?? 'Template creation failed',
      ).toJson(),
    );
  } catch (e) {
    return Response.json(
      statusCode: HttpStatus.internalServerError,
      body: ApiResponse.error(message: 'Template service unavailable: $e').toJson(),
    );
  }
}
