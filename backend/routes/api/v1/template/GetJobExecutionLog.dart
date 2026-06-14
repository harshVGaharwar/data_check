import 'dart:convert';
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

  if (kDevMode) {
    final mockData = [
      {
        'id': 1,
        'jobName': 'process_operations',
        'runId': 'RUN20260510_791',
        'templateId': 12,
        'requestId': null,
        'startTime': '2026-05-10T11:39:55.453',
        'endTime': null,
        'last_updated': '2026-05-10T16:22:53.547',
        'status': 'IN_PROGRESS',
        'total_steps': 3,
        'step': 1,
        'message': 'Data Processing started',
        'createdAt': null,
        'templateName': 'test template',
        'deptName': 'RETAIL ASSETS',
      },
      {
        'id': 2,
        'jobName': 'process_operations',
        'runId': 'RUN20260509_442',
        'templateId': 12,
        'requestId': 'REQ_00118',
        'startTime': '2026-05-09T09:15:00.000',
        'endTime': '2026-05-09T09:22:45.000',
        'last_updated': '2026-05-09T09:22:45.000',
        'status': 'SUCCESS',
        'total_steps': 3,
        'step': 3,
        'message': 'All steps completed successfully',
        'createdAt': '2026-05-09T09:15:00.000',
        'templateName': 'test template',
        'deptName': 'RETAIL ASSETS',
      },
      {
        'id': 3,
        'jobName': 'process_operations',
        'runId': 'RUN20260508_115',
        'templateId': 12,
        'requestId': 'REQ_00110',
        'startTime': '2026-05-08T14:05:30.000',
        'endTime': '2026-05-08T14:06:12.000',
        'last_updated': '2026-05-08T14:06:12.000',
        'status': 'FAILED',
        'total_steps': 3,
        'step': 2,
        'message': 'Validation error: missing required column',
        'createdAt': '2026-05-08T14:05:30.000',
        'templateName': 'test template',
        'deptName': 'RETAIL ASSETS',
      },
    ];
    return Response.json(body: mockData);
  }

  try {
    final httpClient = HttpClient()
      ..badCertificateCallback = (cert, host, port) => true;
    final client = IOClient(httpClient);

    final authHeader = context.request.headers['Authorization'] ??
        context.request.headers['authorization'] ??
        '';

    final templateId =
        context.request.uri.queryParameters['templateId'] ?? '';

    final externalResponse = await client
        .get(
          Uri.parse(
            '$kBaseUrl${ExternalApi.getJobExecutionLog}?templateId=$templateId',
          ),
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
            if (authHeader.isNotEmpty) 'Authorization': authHeader,
          },
        )
        .timeout(const Duration(seconds: 30));

    print(
      '[GET JOB EXECUTION LOG] External API status: ${externalResponse.statusCode}',
    );

    if (externalResponse.statusCode >= 200 &&
        externalResponse.statusCode < 300) {
      final decoded = jsonDecode(externalResponse.body);
      final data =
          (decoded is Map<String, dynamic> && decoded.containsKey('data'))
              ? decoded['data']
              : decoded;
      return Response.json(body: data);
    }

    return Response.json(
      statusCode: externalResponse.statusCode,
      body:
          ApiResponse.error(message: 'Failed to fetch job execution log')
              .toJson(),
    );
  } catch (e) {
    return Response.json(
      statusCode: HttpStatus.internalServerError,
      body: ApiResponse.error(
        message: 'Job execution log service unavailable: $e',
      ).toJson(),
    );
  }
}
