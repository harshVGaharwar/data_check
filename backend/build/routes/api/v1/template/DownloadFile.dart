import 'dart:io';
import 'package:dart_frog/dart_frog.dart';
import 'package:http/io_client.dart';
import '../../../../lib/config/api_config.dart';
import '../../../../lib/models/models.dart';

Future<Response> onRequest(RequestContext context) async {
  if (context.request.method != HttpMethod.get) {
    return Response.json(
      statusCode: HttpStatus.methodNotAllowed,
      body: ApiResponse.error(message: 'Only GET allowed').toJson(),
    );
  }

  final params = context.request.uri.queryParameters;
  final filename = params['filename'] ?? '';
  final templateId = params['template_id'] ?? '';

  if (filename.isEmpty || templateId.isEmpty) {
    return Response.json(
      statusCode: HttpStatus.badRequest,
      body: ApiResponse.error(
        message: 'filename and template_id query params are required',
      ).toJson(),
    );
  }

  // Dev mode: return a plain-text mock file
  if (kDevMode) {
    print('[DOWNLOAD FILE] Dev mock: filename=$filename template_id=$templateId');
    return Response(
      statusCode: HttpStatus.ok,
      headers: {
        HttpHeaders.contentTypeHeader: 'application/octet-stream',
        'content-disposition':
            'attachment; filename="$filename"',
      },
      body: 'Mock file content for $filename (template_id=$templateId)',
    );
  }

  // Production: proxy from external API
  try {
    final httpClient = HttpClient()
      ..badCertificateCallback = (cert, host, port) => true;
    final client = IOClient(httpClient);

    final authHeader = context.request.headers['Authorization'] ??
        context.request.headers['authorization'] ??
        '';

    final uri = Uri.parse(
      '$kBaseUrl${ExternalApi.downloadFile}',
    ).replace(
      queryParameters: {
        'filename': filename,
        'template_id': templateId,
      },
    );

    final externalResponse = await client
        .get(
          uri,
          headers: {
            'Accept': '*/*',
            if (authHeader.isNotEmpty) 'Authorization': authHeader,
          },
        )
        .timeout(const Duration(seconds: 60));

    print('[DOWNLOAD FILE] External API status: ${externalResponse.statusCode}');

    if (externalResponse.statusCode >= 200 &&
        externalResponse.statusCode < 300) {
      final contentType =
          externalResponse.headers['content-type'] ?? 'application/octet-stream';
      final contentDisposition =
          externalResponse.headers['content-disposition'] ??
              'attachment; filename="$filename"';

      return Response(
        statusCode: HttpStatus.ok,
        headers: {
          HttpHeaders.contentTypeHeader: contentType,
          'content-disposition': contentDisposition,
          'Access-Control-Expose-Headers': 'Content-Disposition',
        },
        body: externalResponse.body,
      );
    }

    return Response.json(
      statusCode: externalResponse.statusCode,
      body: ApiResponse.error(message: 'Failed to download file').toJson(),
    );
  } catch (e) {
    return Response.json(
      statusCode: HttpStatus.internalServerError,
      body: ApiResponse.error(
        message: 'File download service unavailable: $e',
      ).toJson(),
    );
  }
}
