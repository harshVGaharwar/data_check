import 'dart:convert';
import 'dart:io';
import 'package:dart_frog/dart_frog.dart';
import 'package:http/io_client.dart';
import '../../../../lib/config/api_config.dart';
import '../../../../lib/models/models.dart';
import '../../../../lib/services/database.dart';

Future<Response> onRequest(RequestContext context) async {
  // Returns the flat list of all created templates across departments,
  // shaped for the Template Creation list page (mirrors the Checker
  // Module list rows so the same view page can render the payload).
  if (context.request.method != HttpMethod.get) {
    return Response.json(
      statusCode: HttpStatus.methodNotAllowed,
      body: ApiResponse.error(message: 'Only GET allowed').toJson(),
    );
  }

  if (kDevMode) {
    final db = Database();
    final flat = <Map<String, dynamic>>[];
    var i = 0;
    db.templatesByDept.forEach((deptId, list) {
      for (final t in list) {
        final templateId = t['templateId'];
        final templateName = (t['templateName'] ?? '').toString();
        final departmentName = (t['department'] ?? '').toString();
        final frequency = (t['frequency'] ?? 'Monthly').toString();
        final priority = (t['priority'] ?? 'Medium').toString();
        final sourceCount = t['sourceCount'] ?? 1;
        final numberOfOutputs = t['numberOfOutputs'] ?? 1;
        final normalVolume = t['normalVolume'] ?? 100;
        final peakVolume = t['peakVolume'] ?? 200;
        final benefitType = (t['benefitType'] ?? 'Efficiency').toString();
        final benefitAmount = t['benefitAmount'] ?? 0;
        final outputFormats =
            (t['outputFormats'] as List?)?.map((e) => e.toString()).toList() ??
                const ['CSV'];

        final makers = ['j3216', 'k4521', 'm7890', 'r2341', 'sc1001'];
        final makerBy = makers[i % makers.length];
        final hour = (8 + (i % 8)).toString().padLeft(2, '0');
        final minute = ((i * 7) % 60).toString().padLeft(2, '0');
        final day = (10 + (i % 18)).toString().padLeft(2, '0');
        final makerDate = '2026-04-${day}T$hour:$minute:00.00';
        final reqId = 'REQ_TC_${(20000 + i).toString()}';

        final responseData = <String, dynamic>{
          'templateId': '$templateId',
          'templateName': templateName,
          'departmentId': '$deptId',
          'departmentName': departmentName,
          'Template': [
            {
              'TemplateName': templateName,
              'Department': departmentName,
              'Frequency': frequency,
              'NormalVolume': normalVolume,
              'PeakVolume': peakVolume,
              'SourceCount': sourceCount,
              'NumberOfOutputs': numberOfOutputs,
              'BenefitType': benefitType,
              'BenefitAmount': benefitAmount,
              'BenefitInTat': '1 day',
              'GoLiveDate': '2026-05-01',
              'DeactivateDate': null,
              'SpocPerson': 'spoc_$makerBy',
              'SpocManager': 'mgr_$makerBy',
              'UnitHead': 'head_$makerBy',
              'Priority': priority,
              'SourceList': '1,2',
            },
          ],
          'OutputFormats': outputFormats
              .map((f) => {'TemplateTempId': null, 'FormatName': f})
              .toList(),
          'Approvals': [
            {
              'TemplateTempId': null,
              'Approval_Type': 'Unit Head',
              'ApprovalFile': 'approval_${i + 1}.pdf',
            },
          ],
        };

        flat.add({
          'requestId': reqId,
          'template_id': '$templateId',
          'templateId': templateId,
          'templateName': templateName,
          'departmentId': deptId,
          'department_id': '$deptId',
          'departmentName': departmentName,
          'makerBy': makerBy,
          'makerDate': makerDate,
          'module': '1',
          'payload': responseData,
          'payloadJson': jsonEncode(responseData),
          'responseData': responseData,
        });
        i++;
      }
    });
    return Response.json(body: flat);
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
        .get(
          Uri.parse('$kBaseUrl${ExternalApi.getTemplateCreationList}'),
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
            if (authHeader.isNotEmpty) 'Authorization': authHeader,
          },
        )
        .timeout(const Duration(seconds: 30));

    print('[TEMPLATE CREATION LIST] External API status: '
        '${externalResponse.statusCode}');

    if (externalResponse.statusCode >= 200 &&
        externalResponse.statusCode < 300) {
      final decoded = jsonDecode(externalResponse.body);
      final data = (decoded is Map<String, dynamic> && decoded.containsKey('data'))
          ? decoded['data']
          : decoded;
      if (data is List) {
        final normalized = data.whereType<Map>().map((item) {
          final map = item.map((k, v) => MapEntry(k.toString(), v));
          final existingPayload = map['payload'];
          final existingPayloadJson = map['payloadJson'];
          final existingResponseData = map['responseData'];
          Map<String, dynamic>? payload;
          String? payloadJson;
          Map<String, dynamic>? responseData;

          if (existingPayload is Map<String, dynamic>) {
            payload = existingPayload;
            payloadJson = jsonEncode(existingPayload);
          } else if (existingPayload is Map) {
            payload = existingPayload.map((k, v) => MapEntry(k.toString(), v));
            payloadJson = jsonEncode(payload);
          } else if (existingPayloadJson is String &&
              existingPayloadJson.trim().isNotEmpty) {
            payloadJson = existingPayloadJson;
            try {
              final dec = jsonDecode(existingPayloadJson);
              if (dec is Map<String, dynamic>) payload = dec;
              if (dec is Map) {
                payload = dec.map((k, v) => MapEntry(k.toString(), v));
              }
            } catch (_) {}
          }

          if (existingResponseData is Map<String, dynamic>) {
            responseData = existingResponseData;
          } else if (existingResponseData is Map) {
            responseData = existingResponseData.map(
              (k, v) => MapEntry(k.toString(), v),
            );
          }

          return {
            ...map,
            'module': map['module']?.toString() ?? '1',
            'payload': payload,
            'payloadJson': payloadJson,
            'responseData': responseData,
          };
        }).toList(growable: false);
        return Response.json(body: normalized);
      }
      return Response.json(body: data);
    }

    return Response.json(
      statusCode: externalResponse.statusCode,
      body: ApiResponse.error(
        message: 'Failed to fetch template creation list',
      ).toJson(),
    );
  } catch (e) {
    return Response.json(
      statusCode: HttpStatus.internalServerError,
      body: ApiResponse.error(
        message: 'Template creation list service unavailable: $e',
      ).toJson(),
    );
  }
}
