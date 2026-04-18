import 'dart:convert';
import 'dart:io';
import 'package:dart_frog/dart_frog.dart';
import 'package:http/io_client.dart';
import '../../../lib/config/api_config.dart';
import '../../../lib/models/models.dart';
import '../../../lib/services/database.dart';

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

  // Validate required fields
  final sourceType = body['sourceType']?.toString().trim() ?? '';
  final name = body['Name']?.toString().trim() ?? '';
  final dbVault = body['DBVault']?.toString().trim() ?? '';
  final itgrc = body['ITGRC'];

  if (sourceType.isEmpty || name.isEmpty || dbVault.isEmpty || itgrc == null) {
    return Response.json(
      statusCode: HttpStatus.badRequest,
      body: ApiResponse.error(
        message: 'sourceType, Name, DBVault and ITGRC are required',
      ).toJson(),
    );
  }

  // Dev mode: store in local in-memory DB and return success
  if (kDevMode) {
    final db = Database();
    final newRecord = {
      'id': (db.sourceMasterList
              .map((m) => m['id'] as int? ?? 0)
              .fold(0, (a, b) => a > b ? a : b)) +
          1,
      'sourceType': sourceType,
      'AppName': body['AppName']?.toString() ?? '',
      'ITGRC': itgrc,
      'Name': name,
      'DBVault': dbVault,
      'Createdby': body['Createdby']?.toString() ?? '',
      'createdOn': DateTime.now().toIso8601String(),
    };
    db.sourceMasterList.add(newRecord);

    print('[ADD SOURCE MASTER] Saved: $newRecord');

    return Response.json(
      body: {
        'status': 'Success',
        'reqID': newRecord['id'],
      },
    );
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
          Uri.parse('$kBaseUrl${ExternalApi.addSourceMaster}'),
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
            if (authHeader.isNotEmpty) 'Authorization': authHeader,
          },
          body: jsonEncode(body),
        )
        .timeout(const Duration(seconds: 30));

    print(
        '[ADD SOURCE MASTER] External API status: ${externalResponse.statusCode}');

    if (externalResponse.statusCode >= 200 &&
        externalResponse.statusCode < 300) {
      final data = jsonDecode(externalResponse.body);
      return Response.json(body: data);
    }

    return Response.json(
      statusCode: externalResponse.statusCode,
      body: ApiResponse.error(message: 'Failed to add source master').toJson(),
    );
  } catch (e) {
    return Response.json(
      statusCode: HttpStatus.internalServerError,
      body: ApiResponse.error(message: 'Source master service unavailable: $e')
          .toJson(),
    );
  }
}
