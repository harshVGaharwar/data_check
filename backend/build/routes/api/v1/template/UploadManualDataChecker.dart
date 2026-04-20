import 'dart:convert';
import 'dart:io';
import 'package:dart_frog/dart_frog.dart';
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

  final templateId = body['Template_id']?.toString() ?? '';
  final departmentId = body['department_id']?.toString() ?? '';
  final requestId = body['Request_id']?.toString() ?? '';
  final checkerBy = body['CheckerBy']?.toString() ?? '';
  final remark = body['Remart']?.toString() ?? '';
  final isApproved = body['isApproved']?.toString() ?? '';

  if (templateId.isEmpty || departmentId.isEmpty || requestId.isEmpty) {
    return Response.json(
      statusCode: HttpStatus.badRequest,
      body: ApiResponse.error(
        message: 'Template_id, department_id and Request_id are required',
      ).toJson(),
    );
  }
  if (remark.isEmpty) {
    return Response.json(
      statusCode: HttpStatus.badRequest,
      body: ApiResponse.error(message: 'Remart (remark) is required').toJson(),
    );
  }

  // Dev mode: return success mock
  if (kDevMode) {
    final reqId = DateTime.now().millisecondsSinceEpoch % 100000;
    print(
      '[CHECKER APPROVAL] templateId=$templateId deptId=$departmentId '
      'requestId=$requestId checkerBy=$checkerBy isApproved=$isApproved remark=$remark',
    );
    return Response.json(body: {'status': 'Success', 'reqID': reqId});
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
          Uri.parse('$kBaseUrl${ExternalApi.uploadManualDataChecker}'),
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
            if (authHeader.isNotEmpty) 'Authorization': authHeader,
          },
          body: jsonEncode(body),
        )
        .timeout(const Duration(seconds: 30));

    print(
      '[CHECKER APPROVAL] External API status: ${externalResponse.statusCode}',
    );

    if (externalResponse.statusCode >= 200 &&
        externalResponse.statusCode < 300) {
      return Response.json(body: jsonDecode(externalResponse.body));
    }

    return Response.json(
      statusCode: externalResponse.statusCode,
      body: ApiResponse.error(
        message: 'Failed to submit checker approval',
      ).toJson(),
    );
  } catch (e) {
    return Response.json(
      statusCode: HttpStatus.internalServerError,
      body: ApiResponse.error(
        message: 'Checker approval service unavailable: $e',
      ).toJson(),
    );
  }
}
