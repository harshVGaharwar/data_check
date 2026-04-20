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

  final templateId = body['template_id']?.toString() ?? '';
  final departmentId = body['department_id']?.toString() ?? '';

  if (kDevMode) {
    if (templateId.isEmpty || departmentId.isEmpty) {
      return Response.json(body: <dynamic>[]);
    }
    final db = Database();
    final result = db.sourceMasterList.map((item) => {
      ...item,
      'template_id': templateId,
      'department_id': departmentId,
    }).toList();
    return Response.json(body: result);
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
          Uri.parse('$kBaseUrl${ExternalApi.getSourceMasterListFilterwise}'),
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
            if (authHeader.isNotEmpty) 'Authorization': authHeader,
          },
          body: jsonEncode(body),
        )
        .timeout(const Duration(seconds: 30));

    print(
      '[GET SOURCE MASTER FILTERWISE] External API status: ${externalResponse.statusCode}',
    );

    if (externalResponse.statusCode >= 200 &&
        externalResponse.statusCode < 300) {
      final data = jsonDecode(externalResponse.body);
      return Response.json(body: data);
    }

    return Response.json(
      statusCode: externalResponse.statusCode,
      body: ApiResponse.error(
        message: 'Failed to fetch filtered source master list',
      ).toJson(),
    );
  } catch (e) {
    return Response.json(
      statusCode: HttpStatus.internalServerError,
      body: ApiResponse.error(
        message: 'Filtered source master list service unavailable: $e',
      ).toJson(),
    );
  }
}
