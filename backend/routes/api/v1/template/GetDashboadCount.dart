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
    final mockData = {
      'dashboardCount': [
        {
          'count': '12',
          'label': 'Total Templates',
          'lightColor': '#E3F2FD',
          'icon': '0xe318',
          'darkColor': '#1565C0',
        },
        {
          'count': '5',
          'label': 'Pending Approvals',
          'lightColor': '#FFF8E1',
          'icon': '0xe425',
          'darkColor': '#F57F17',
        },
        {
          'count': '3',
          'label': 'Active Jobs',
          'lightColor': '#E8F5E9',
          'icon': '0xe1b1',
          'darkColor': '#2E7D32',
        },
        {
          'count': '8',
          'label': 'Reports Generated',
          'lightColor': '#FCE4EC',
          'icon': '0xe873',
          'darkColor': '#880E4F',
        },
      ],
    };
    return Response.json(body: mockData);
  }

  try {
    final httpClient = HttpClient()
      ..badCertificateCallback = (cert, host, port) => true;
    final client = IOClient(httpClient);

    final authHeader = context.request.headers['Authorization'] ??
        context.request.headers['authorization'] ??
        '';

    final val1 = context.request.uri.queryParameters['val1'] ?? '1';
    final val2 = context.request.uri.queryParameters['val2'] ?? '2';
    final val3 = context.request.uri.queryParameters['val3'] ?? '3';
    final val4 = context.request.uri.queryParameters['val4'] ?? '4';

    final externalResponse = await client
        .get(
          Uri.parse(
            '$kBaseUrl${ExternalApi.getDashboardCount}?val1=$val1&val2=$val2&val3=$val3&val4=$val4',
          ),
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
            if (authHeader.isNotEmpty) 'Authorization': authHeader,
          },
        )
        .timeout(const Duration(seconds: 30));

    print(
      '[GET DASHBOARD COUNT] External API status: ${externalResponse.statusCode}',
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
      body: ApiResponse.error(message: 'Failed to fetch dashboard count')
          .toJson(),
    );
  } catch (e) {
    return Response.json(
      statusCode: HttpStatus.internalServerError,
      body: ApiResponse.error(
        message: 'Dashboard count service unavailable: $e',
      ).toJson(),
    );
  }
}
