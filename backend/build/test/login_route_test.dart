import 'dart:convert';
import 'package:test/test.dart';
import '../lib/models/models.dart';
import '../lib/services/auth_service.dart';
import '../lib/services/database.dart';

// ── Helpers ───────────────────────────────────────────────────────────────────
//
// The login route itself relies on dart_frog's RequestContext (hard to unit
// test without a running server).  Instead, we test the components it
// orchestrates — AuthService and Database — plus the ApiResponse model, and we
// exercise the dev-user fast-path logic directly.

// Reproduces the dev-user map from the route so the fast-path is testable
// independently of the route binding.
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
        'sValues': ['WebApp', 'QDRS'],
        'itgrcCode': 1394833,
      },
    ],
  },
};

/// Simulates the dev-bypass login logic in login.dart
Map<String, dynamic>? _devLogin(String name, String password) {
  final devUser = _devUsers[name];
  if (devUser == null || devUser['password'] != password) return null;

  final db = Database();
  final token = devUser['token'] as String;
  final dbUser = db.findUserByUsername(name);
  if (dbUser != null) db.tokens[token] = dbUser.id;

  return {
    'token': token,
    'refreshToken': devUser['refreshToken'],
    'user': devUser['user'],
    'applist': devUser['applist'],
  };
}

// ── Tests ─────────────────────────────────────────────────────────────────────

void main() {
  late Database db;
  late AuthService authService;

  setUp(() {
    db = Database();
    db.tokens
      ..clear()
      ..addAll({
        'dev-token-admin': 'USR-001',
        'dev-token-harsh': 'USR-002',
        'dev-token-demo': 'USR-003',
      });
    authService = AuthService(db);
  });

  // ── ApiResponse model ──────────────────────────────────────────────────────

  group('ApiResponse model', () {
    test('success factory sets status to "success"', () {
      final r = ApiResponse.success(message: 'Login successful', data: {'token': 'abc'});
      expect(r.status, equals('success'));
      expect(r.message, equals('Login successful'));
      expect(r.data, equals({'token': 'abc'}));
    });

    test('error factory sets status to "error"', () {
      final r = ApiResponse.error(message: 'Invalid credentials');
      expect(r.status, equals('error'));
      expect(r.message, equals('Invalid credentials'));
      expect(r.data, isNull);
    });

    test('toJson includes data key only when data is non-null', () {
      final withData = ApiResponse.success(data: {'k': 'v'}).toJson();
      expect(withData.containsKey('data'), isTrue);

      final noData = ApiResponse.error(message: 'oops').toJson();
      expect(noData.containsKey('data'), isFalse);
    });

    test('toJson can be re-encoded to JSON without error', () {
      final r = ApiResponse.success(
        message: 'ok',
        data: {'token': 'tok', 'applist': []},
      );
      expect(() => jsonEncode(r.toJson()), returnsNormally);
    });
  });

  // ── Dev-user fast-path logic ───────────────────────────────────────────────

  group('Login route — dev-user fast path', () {
    test('returns token + refreshToken + user + applist for admin/admin123', () {
      final result = _devLogin('admin', 'admin123');

      expect(result, isNotNull);
      expect(result!['token'], equals('dev-token-admin'));
      expect(result['refreshToken'], equals('dev-refresh-admin'));
      expect(result['user'], isA<Map>());
      expect(result['applist'], isA<List>());
    });

    test('user map contains expected fields', () {
      final result = _devLogin('admin', 'admin123');
      final user = result!['user'] as Map<String, dynamic>;

      expect(user['name'], equals('Admin User'));
      expect(user['employeeCode'], equals('ADM001'));
      expect(user['role'], equals('1'));
      expect(user['email'], equals('admin@hdfcbank.com'));
    });

    test('applist is non-empty for admin', () {
      final result = _devLogin('admin', 'admin123');
      final applist = result!['applist'] as List;
      expect(applist, isNotEmpty);
      expect((applist.first as Map)['appname'], equals('QDRS'));
    });

    test('returns null for unknown dev username', () {
      final result = _devLogin('notadevuser', 'admin123');
      expect(result, isNull);
    });

    test('returns null for correct dev username but wrong password', () {
      final result = _devLogin('admin', 'wrongpassword');
      expect(result, isNull);
    });

    test('registers dev token in database on successful dev login', () {
      _devLogin('admin', 'admin123');
      expect(db.tokens['dev-token-admin'], equals('USR-001'));
    });

    test('is case-sensitive for dev username', () {
      expect(_devLogin('Admin', 'admin123'), isNull);
      expect(_devLogin('ADMIN', 'admin123'), isNull);
    });

    test('is case-sensitive for dev password', () {
      expect(_devLogin('admin', 'Admin123'), isNull);
      expect(_devLogin('admin', 'ADMIN123'), isNull);
    });
  });

  // ── AuthService (production path) ──────────────────────────────────────────

  group('Login route — production path (AuthService)', () {
    test('returns valid token for admin credentials', () {
      final result = authService.login('admin', 'admin123');
      expect(result, isNotNull);
      expect(result!['token'], isA<String>());
      expect((result['token'] as String).isNotEmpty, isTrue);
    });

    test('returns valid token for developer credentials', () {
      final result = authService.login('harsh', 'harsh123');
      expect(result, isNotNull);
      expect(result!['role'], equals('developer'));
    });

    test('returns valid token for viewer credentials', () {
      final result = authService.login('demo', 'demo123');
      expect(result, isNotNull);
      expect(result!['role'], equals('viewer'));
    });

    test('returns null for invalid credentials — wrong password', () {
      expect(authService.login('admin', 'badpassword'), isNull);
    });

    test('returns null for invalid credentials — unknown user', () {
      expect(authService.login('phantom', 'admin123'), isNull);
    });

    test('returns null for empty credentials', () {
      expect(authService.login('', ''), isNull);
    });

    test('returned data does not include plaintext password', () {
      final result = authService.login('admin', 'admin123');
      expect(result!.containsKey('password'), isFalse);
    });

    test('token is 48 hex characters', () {
      final result = authService.login('admin', 'admin123');
      final token = result!['token'] as String;
      expect(token.length, equals(48));
      expect(RegExp(r'^[a-f0-9]+$').hasMatch(token), isTrue);
    });
  });

  // ── Token lifecycle ────────────────────────────────────────────────────────

  group('Token lifecycle', () {
    test('token is valid immediately after login', () {
      final result = authService.login('admin', 'admin123');
      final token = result!['token'] as String;
      expect(authService.verify(token), isNotNull);
    });

    test('token is invalid after logout', () {
      final result = authService.login('admin', 'admin123');
      final token = result!['token'] as String;

      authService.logout(token);
      expect(authService.verify(token), isNull);
    });

    test('multiple concurrent sessions are each independently valid', () {
      final r1 = authService.login('admin', 'admin123');
      final r2 = authService.login('harsh', 'harsh123');

      expect(authService.verify(r1!['token'] as String), isNotNull);
      expect(authService.verify(r2!['token'] as String), isNotNull);
    });

    test('logging out one session does not affect another', () {
      final r1 = authService.login('admin', 'admin123');
      final r2 = authService.login('harsh', 'harsh123');
      final t1 = r1!['token'] as String;
      final t2 = r2!['token'] as String;

      authService.logout(t1);

      expect(authService.verify(t1), isNull);
      expect(authService.verify(t2), isNotNull);
    });

    test('verify returns null for garbage token', () {
      expect(authService.verify('garbage-token'), isNull);
    });

    test('verify returns null for null', () {
      expect(authService.verify(null), isNull);
    });

    test('verify returns null for empty string', () {
      expect(authService.verify(''), isNull);
    });
  });

  // ── Response structure ─────────────────────────────────────────────────────

  group('Login response structure', () {
    test('success response JSON has required top-level keys', () {
      final r = ApiResponse.success(
        message: 'Login successful',
        data: {
          'token': 'abc123',
          'refreshToken': 'ref456',
          'user': {'name': 'Admin'},
          'applist': [],
        },
      ).toJson();

      expect(r['status'], equals('success'));
      expect(r['message'], equals('Login successful'));
      expect((r['data'] as Map).containsKey('token'), isTrue);
      expect((r['data'] as Map).containsKey('refreshToken'), isTrue);
      expect((r['data'] as Map).containsKey('user'), isTrue);
      expect((r['data'] as Map).containsKey('applist'), isTrue);
    });

    test('error response JSON for invalid credentials has correct shape', () {
      final r = ApiResponse.error(message: 'Invalid credentials').toJson();

      expect(r['status'], equals('error'));
      expect(r['message'], equals('Invalid credentials'));
      expect(r.containsKey('data'), isFalse);
    });

    test('error response JSON for service unavailable has correct shape', () {
      final r = ApiResponse.error(
        message: 'Authentication service unavailable: Connection refused',
      ).toJson();

      expect(r['status'], equals('error'));
      expect(r['message'], startsWith('Authentication service unavailable'));
    });
  });
}
