import 'dart:convert';
import 'dart:io';
import 'package:dart_frog/dart_frog.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:mime/mime.dart';
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

  final contentTypeHeader = context.request.headers['content-type'] ?? '';
  if (!contentTypeHeader.contains('multipart/form-data')) {
    return Response.json(
      statusCode: HttpStatus.badRequest,
      body: ApiResponse.error(message: 'Expected multipart/form-data').toJson(),
    );
  }

  // ── Parse multipart manually to support multiple files with same key ──
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

  // Dev mode: save locally and return mock response
  if (kDevMode) {
    final db = Database();
    final id = db.newId('CFG');
    final templateId = body['TemplateId'] ?? 0;

    print('[PIPELINE CONFIG SAVED - DEV] $id');
    print(const JsonEncoder.withIndent('  ').convert(body));
    print('[FILES] ${uploadedFiles.map((f) => f.filename).toList()}');

    return Response.json(
      statusCode: HttpStatus.ok,
      body: {
        'status': 'Success',
        'templateId': templateId,
        'configId': int.tryParse(id.replaceAll(RegExp(r'[^0-9]'), '')) ?? 1,
      },
    );
  }

  // ── Forward to external API as multipart ──
  try {
    final authHeader = context.request.headers['Authorization'] ??
        context.request.headers['authorization'] ??
        '';

    final uri = Uri.parse('$kBaseUrl${ExternalApi.addTemplateConfig}');
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

    final streamed = await request.send().timeout(const Duration(seconds: 60));
    final responseBody = await streamed.stream.bytesToString();

    print('[SUBMIT MAPPING] External API status: ${streamed.statusCode}');
    print('[SUBMIT MAPPING] Response: $responseBody');

    if (streamed.statusCode >= 200 && streamed.statusCode < 300) {
      final decoded = jsonDecode(responseBody);
      return Response.json(body: decoded);
    }

    return Response.json(
      statusCode: streamed.statusCode,
      body:
          ApiResponse.error(message: 'External API error: $responseBody').toJson(),
    );
  } catch (e) {
    return Response.json(
      statusCode: HttpStatus.internalServerError,
      body: ApiResponse.error(message: 'Submit mapping failed: $e').toJson(),
    );
  }
}
