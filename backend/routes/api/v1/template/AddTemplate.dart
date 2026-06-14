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
    } else if (fieldName == 'TemplateRuequest') {
      configJson = utf8.decode(partBytes);
    }
  }

  Map<String, dynamic> body;
  try {
    body = jsonDecode(configJson) as Map<String, dynamic>;
  } catch (_) {
    return Response.json(
      statusCode: HttpStatus.badRequest,
      body: ApiResponse.error(message: 'Invalid TemplateRuequest JSON').toJson(),
    );
  }

  // ── Validate required top-level fields ──
  final templateType = body['TemplateType']?.toString() ?? '';
  if (!['1', '2', '3'].contains(templateType)) {
    return Response.json(
      statusCode: HttpStatus.badRequest,
      body: ApiResponse.error(
        message: 'TemplateType must be "1" (Static+UserDefined), '
            '"2" (Static+UniMailing) or "3" (Dynamic+UniMailing)',
      ).toJson(),
    );
  }

  final templateArr = body['Template'];
  if (templateArr is! List || templateArr.isEmpty) {
    return Response.json(
      statusCode: HttpStatus.badRequest,
      body: ApiResponse.error(message: 'Template array is required').toJson(),
    );
  }

  final tplMap =
      Map<String, dynamic>.from(templateArr[0] as Map<dynamic, dynamic>);

  // Required fields inside Template[0]
  final requiredFields = [
    'TemplateName',
    'Department',
    'Frequency',
    'SpocPerson',
  ];
  for (final f in requiredFields) {
    if ((tplMap[f]?.toString() ?? '').isEmpty) {
      return Response.json(
        statusCode: HttpStatus.badRequest,
        body: ApiResponse.error(message: 'Template.$f is required').toJson(),
      );
    }
  }

  // For static (type 1/2) SourceList and SourceCount are required
  if (templateType != '3') {
    final sourceList = tplMap['SourceList']?.toString() ?? '';
    final sourceCount = tplMap['SourceCount'];
    if (sourceList.isEmpty) {
      return Response.json(
        statusCode: HttpStatus.badRequest,
        body: ApiResponse.error(message: 'Template.SourceList is required for static templates').toJson(),
      );
    }
    if (sourceCount == null || (int.tryParse(sourceCount.toString()) ?? 0) <= 0) {
      return Response.json(
        statusCode: HttpStatus.badRequest,
        body: ApiResponse.error(message: 'Template.SourceCount must be > 0').toJson(),
      );
    }
  }

  // For dynamic (type 3) DynamicTemplate array is required
  if (templateType == '3') {
    final dynArr = body['DynamicTemplate'];
    if (dynArr is! List || dynArr.isEmpty) {
      return Response.json(
        statusCode: HttpStatus.badRequest,
        body: ApiResponse.error(
          message: 'DynamicTemplate array is required for TemplateType "3"',
        ).toJson(),
      );
    }
  }

  if ((body['OutputFormats'] as List?)?.isEmpty ?? true) {
    return Response.json(
      statusCode: HttpStatus.badRequest,
      body: ApiResponse.error(message: 'OutputFormats is required').toJson(),
    );
  }

  if ((body['Approvals'] as List?)?.isEmpty ?? true) {
    return Response.json(
      statusCode: HttpStatus.badRequest,
      body: ApiResponse.error(message: 'Approvals is required').toJson(),
    );
  }

  final authHeader = context.request.headers['Authorization'] ??
      context.request.headers['authorization'] ??
      '';

  // ── Dev mode: save to in-memory DB ──
  if (kDevMode) {
    final db = Database();

    final deptId = int.tryParse(tplMap['Department']?.toString() ?? '') ?? 0;

    final allIds = db.templatesByDept.values
        .expand((list) => list)
        .map((t) => t['TemplateId'] as int? ?? 0)
        .toList();
    final newTemplateId =
        (allIds.isEmpty ? 0 : allIds.reduce((a, b) => a > b ? a : b)) + 1;

    final savedEntry = <String, dynamic>{
      ...tplMap,
      'TemplateId': newTemplateId,
      'TemplateType': templateType,
      'OutputFormats': body['OutputFormats'] ?? [],
      'Approvals': body['Approvals'] ?? [],
      'CreatedBy': body['CreatedBy'] ?? '',
      'jsonData': body['jsonData'] ?? '',
      'DepartmentName': body['DepartmentName'] ?? '',
      'SourceListNames': body['SourceListNames'] ?? '',
      'DynamicTemplate': body['DynamicTemplate'] ?? [],
    };

    db.persistTemplate(deptId, savedEntry);

    print('[TEMPLATE CREATE] templateId=$newTemplateId  type=$templateType  dept=$deptId');
    print('[TEMPLATE CREATE] ${const JsonEncoder.withIndent('  ').convert(savedEntry)}');
    print('[TEMPLATE CREATE] files=${uploadedFiles.map((f) => f.filename).toList()}');

    return Response.json(
      body: ApiResponse.success(
        message: 'Template created successfully',
        data: {'templateId': newTemplateId},
      ).toJson(),
    );
  }

  // ── Production: forward to external API as multipart ──
  // Strip sourceMasterList from DynamicTemplate entries — production API doesn't expect it.
  final productionBody = Map<String, dynamic>.from(body);
  final dynArr = productionBody['DynamicTemplate'];
  if (dynArr is List) {
    productionBody['DynamicTemplate'] = dynArr.map((e) {
      if (e is Map) {
        final entry = Map<String, dynamic>.from(e);
        return {
          if (entry.containsKey('sourceList')) 'SourceList': entry['sourceList'],
          if (entry.containsKey('sourceCount')) 'SourceCount': entry['sourceCount'],
          if (entry.containsKey('sourceType')) 'SourceType': entry['sourceType'],
        };
      }
      return e;
    }).toList();
  }
  final productionJson = jsonEncode(productionBody);

  try {
    final uri = Uri.parse('$kBaseUrl${ExternalApi.templateCreate}');
    final request = http.MultipartRequest('POST', uri);

    if (authHeader.isNotEmpty) {
      request.headers['Authorization'] = authHeader;
    }
    request.fields['TemplateRuequest'] = productionJson;

    for (final file in uploadedFiles) {
      request.files.add(
        http.MultipartFile.fromBytes(
          'Files',
          file.bytes,
          filename: file.filename,
        ),
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
          message:
              'Invalid response from template service (status ${streamed.statusCode})',
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
