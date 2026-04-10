import 'dart:convert';
import 'dart:io';
import 'package:dart_frog/dart_frog.dart';
import 'package:http/io_client.dart';
import '../../../../lib/config/api_config.dart';
import '../../../../lib/models/models.dart';
import '../../../../lib/services/database.dart';

// Dev test users — bypasses HDFC API for local testing
const _devUsers = <String, Map<String, dynamic>>{
  'admin': {
    'password': 'admin123',
    'token': 'dev-token-admin',
    'refreshToken': 'dev-refresh-admin',
    'user': {
      'id': 0,
      'name': 'Admin User',
      'employeeCode': 'ADM001',
      'email': 'admin@hdfcbank.com',
      'location': '',
      'locationcode': '',
      'city': '',
      'department': '',
      'contactNumber': '',
      'role': '1',
      'ipAddress': '127.0.0.1',
      'profileDescription': '',
      'profileId': '1',
    },
    'applist': <dynamic>[
      {
        'appname': 'QDRS',
        'dbVault':
            'Data Source=10.225.213.229,1989;Initial Catalog=QRS;User ID=BTG_APPUAT;Password=Tfr#\$654;Max Pool Size=1200;TrustServerCertificate=true',
        'sValues': ['WebApp', 'QDRS'],
        'itgrcCode': 1394833,
      },
      {
        'appname': 'Unimailing System',
        'dbVault':
            'Data Source=10.229.193.157,1989;Initial Catalog=Unimailing_System_UAT;User ID=BTG_APPUAT;Password=Tfr#\$654;Max Pool Size=1200;TrustServerCertificate=true',
        'sValues': ['App_Exe', 'UnimailingSystem_Web'],
        'itgrcCode': 1403254,
      },
    ],
  },
};

Future<Response> onRequest(RequestContext context) async {
  if (context.request.method != HttpMethod.post) {
    return Response.json(
      statusCode: HttpStatus.methodNotAllowed,
      body: ApiResponse.error(message: 'Only POST allowed').toJson(),
    );
  }

  final body = await context.request.json() as Map<String, dynamic>;
  final name = body['Name'] as String? ?? '';
  final password = body['password'] as String? ?? '';

  // Dev bypass
  final devUser = _devUsers[name];
  if (devUser != null && devUser['password'] == password) {
    final token = devUser['token'] as String;
    // Register token in db so auth middleware can validate it
    final db = Database();
    final dbUser = db.findUserByUsername(name);
    if (dbUser != null) db.tokens[token] = dbUser.id;

    return Response.json(
      body: {
        'token': token,
        'refreshToken': devUser['refreshToken'],
        'user': devUser['user'],
      },
    );
  }

  try {
    final httpClient = HttpClient()
      ..badCertificateCallback = (cert, host, port) => true;
    final client = IOClient(httpClient);

    final hdfcResponse = await client
        .post(
          Uri.parse('$kBaseUrl${ExternalApi.login}'),
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json'
          },
          body: jsonEncode(body),
        )
        .timeout(const Duration(seconds: 30));

    if (hdfcResponse.statusCode == 200) {
      final data = jsonDecode(hdfcResponse.body) as Map<String, dynamic>;
      print('[LOGIN] HDFC response keys: ${data.keys.toList()}');

      final hdfcToken = data['token'] ?? data['Token'] ?? '';
      final userMap = (data['user'] ?? data['User'] ?? {}) as Map<String, dynamic>;

      // Register HDFC token in local db so auth middleware can validate it
      if (hdfcToken.isNotEmpty) {
        final db = Database();
        final empCode = userMap['employeeCode'] ?? 'HDFC_USER';
        final userId = 'HDFC-$empCode';
        db.users[userId] = User(
          id: userId,
          username: userMap['name'] ?? name,
          password: '',
          role: userMap['role'] ?? 'user',
        );
        db.tokens[hdfcToken] = userId;
      }

      return Response.json(
        body: {
          'token': hdfcToken,
          'refreshToken': data['refreshToken'] ?? data['RefreshToken'] ?? '',
          'user': userMap,
        },
      );
    }

    return Response.json(
      statusCode: HttpStatus.unauthorized,
      body: ApiResponse.error(message: 'Invalid credentials').toJson(),
    );
  } catch (e) {
    return Response.json(
      statusCode: HttpStatus.internalServerError,
      body: ApiResponse.error(message: 'Authentication service unavailable: $e')
          .toJson(),
    );
  }
}
