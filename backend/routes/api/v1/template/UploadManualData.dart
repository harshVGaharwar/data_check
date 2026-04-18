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

  Map<String, dynamic> body;
  try {
    final raw = await context.request.body();
    body = jsonDecode(raw) as Map<String, dynamic>;
  } catch (_) {
    return Response.json(
      statusCode: HttpStatus.badRequest,
      body: ApiResponse.error(message: 'Invalid JSON body').toJson(),
    );
  }

  final list = body['manualFileUploadslist'];
  if (list is! List || list.isEmpty) {
    return Response.json(
      statusCode: HttpStatus.badRequest,
      body: ApiResponse.error(message: 'manualFileUploadslist is required and must be non-empty').toJson(),
    );
  }

  // Dev mode: store in local in-memory DB and return success
  if (kDevMode) {
    final db = Database();
    final nextId = (db.manualUploads.map((m) => m['id'] as int? ?? 0).fold(0, (a, b) => a > b ? a : b)) + 1;
    for (final entry in list) {
      if (entry is Map<String, dynamic>) {
        db.manualUploads.add({...entry, 'id': nextId, 'uploadedOn': DateTime.now().toIso8601String()});
      }
    }
    print('[UPLOAD MANUAL DATA] Saved ${list.length} entries, reqID=$nextId');
    return Response.json(body: {'status': 'Success', 'reqID': nextId});
  }

  // Production: forward to external API
  try {
    final httpClient = HttpClient()
      ..badCertificateCallback = (cert, host, port) => true;
    final client = IOClient(httpClient);

    final authHeader = context.request.headers['Authorization'] ??
        context.request.headers['authorization'] ??
        '';

    final externalResponse = await client
        .post(
          Uri.parse('$kBaseUrl${ExternalApi.uploadManualData}'),
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
            if (authHeader.isNotEmpty) 'Authorization': authHeader,
          },
          body: jsonEncode(body),
        )
        .timeout(const Duration(seconds: 30));

    print('[UPLOAD MANUAL DATA] External API status: ${externalResponse.statusCode}');

    if (externalResponse.statusCode >= 200 && externalResponse.statusCode < 300) {
      return Response.json(body: jsonDecode(externalResponse.body));
    }

    return Response.json(
      statusCode: externalResponse.statusCode,
      body: ApiResponse.error(message: 'Failed to upload manual data').toJson(),
    );
  } catch (e) {
    return Response.json(
      statusCode: HttpStatus.internalServerError,
      body: ApiResponse.error(message: 'Manual data upload service unavailable: $e').toJson(),
    );
  }
}
