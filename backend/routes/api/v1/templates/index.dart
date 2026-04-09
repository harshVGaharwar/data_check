import 'dart:convert';
import 'dart:io';
import 'package:dart_frog/dart_frog.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:mime/mime.dart';
import '../../../../lib/config/api_config.dart';
import '../../../../lib/models/models.dart';

Future<Response> onRequest(RequestContext context) async {
  if (context.request.method != HttpMethod.post) {
    return Response.json(
      statusCode: HttpStatus.methodNotAllowed,
      body: ApiResponse.error(message: 'Only POST allowed').toJson(),
    );
  }

  final contentTypeHeader = context.request.headers['content-type'] ?? '';
  if (!contentTypeHeader.contains('multipart/form-data')) {
    return Response.json(
      statusCode: HttpStatus.badRequest,
      body: ApiResponse.error(message: 'Expected multipart/form-data').toJson(),
    );
  }

  // ── Parse multipart to support multiple files under "Files" key ──
  final mediaType = MediaType.parse(contentTypeHeader);
  final boundary = mediaType.parameters['boundary'];
  if (boundary == null) {
    return Response.json(
      statusCode: HttpStatus.badRequest,
      body: ApiResponse.error(message: 'Missing multipart boundary').toJson(),
    );
  }

  String configJson = '';
  final uploadedFiles = <({String filename, List<int> bytes})>[];

  final rawBytes = context.request.bytes();
  final transformer = MimeMultipartTransformer(boundary);

  await for (final part in transformer.bind(rawBytes)) {
    final disposition = part.headers['content-disposition'] ?? '';
    final nameMatch = RegExp(r'name="([^"]+)"').firstMatch(disposition);
    final filenameMatch = RegExp(r'filename="([^"]+)"').firstMatch(disposition);
    final fieldName = nameMatch?.group(1) ?? '';

    final partBytes =
        (await part.toList()).fold<List<int>>([], (p, e) => p..addAll(e));

    if (filenameMatch != null) {
      uploadedFiles.add((
        filename: filenameMatch.group(1)!,
        bytes: partBytes,
      ));
    } else if (fieldName == 'Config') {
      configJson = utf8.decode(partBytes);
    }
  }

  Map<String, dynamic> body;
  try {
    body = jsonDecode(configJson) as Map<String, dynamic>;
  } catch (_) {
    return Response.json(
      statusCode: HttpStatus.badRequest,
      body: ApiResponse.error(message: 'Invalid Config JSON').toJson(),
    );
  }

  final authHeader = context.request.headers['Authorization'] ??
      context.request.headers['authorization'] ??
      '';

  // Dev mode: return mock response
  if (kDevMode) {
    print('[TEMPLATE CREATE - DEV] Config: ${const JsonEncoder.withIndent('  ').convert(body)}');
    print('[TEMPLATE CREATE - DEV] Files: ${uploadedFiles.map((f) => f.filename).toList()}');
    return Response.json(
      body: ApiResponse.success(
        message: 'Template created successfully (dev mock)',
        data: {'templateId': 'MOCK-${DateTime.now().millisecondsSinceEpoch}'},
      ).toJson(),
    );
  }

  // ── Forward to external API as multipart ──
  try {
    final uri = Uri.parse('$kBaseUrl${ExternalApi.templateCreate}');
    final request = http.MultipartRequest('POST', uri);

    if (authHeader.isNotEmpty) {
      request.headers['Authorization'] = authHeader;
    }
    request.fields['Config'] = configJson;

    for (final file in uploadedFiles) {
      request.files.add(
        http.MultipartFile.fromBytes('Files', file.bytes, filename: file.filename),
      );
    }

    final streamed = await request.send().timeout(const Duration(seconds: 30));
    final responseBody = await streamed.stream.bytesToString();

    print('[TEMPLATE] External API status: ${streamed.statusCode}');
    print('[TEMPLATE] External API body: $responseBody');

    Map<String, dynamic>? data;
    try {
      data = jsonDecode(responseBody) as Map<String, dynamic>;
    } catch (_) {
      return Response.json(
        statusCode: HttpStatus.badGateway,
        body: ApiResponse.error(
          message: 'Invalid response from template service (status ${streamed.statusCode})',
        ).toJson(),
      );
    }

    if (streamed.statusCode >= 200 && streamed.statusCode < 300) {
      return Response.json(
        body: ApiResponse.success(
          message: 'Template created successfully',
          data: data,
        ).toJson(),
      );
    }

    return Response.json(
      statusCode: streamed.statusCode,
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
