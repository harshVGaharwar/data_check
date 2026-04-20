import 'package:test/test.dart';
import '../lib/services/auth_service.dart';
import '../lib/services/database.dart';

void main() {
  late Database db;
  late AuthService authService;

  setUp(() {
    db = Database();
    // Reset tokens to known state before each test
    db.tokens
      ..clear()
      ..addAll({
        'dev-token-admin': 'USR-001',
        'dev-token-harsh': 'USR-002',
        'dev-token-demo': 'USR-003',
      });
    authService = AuthService(db);
  });

  group('AuthService.login', () {
    test('returns token and user info for valid admin credentials', () {
      final result = authService.login('admin', 'admin123');

      expect(result, isNotNull);
      expect(result!['token'], isA<String>());
      expect((result['token'] as String).length, equals(48));
      expect(result['userId'], equals('USR-001'));
      expect(result['username'], equals('admin'));
      expect(result['role'], equals('admin'));
    });

    test('returns token and user info for valid developer credentials', () {
      final result = authService.login('harsh', 'harsh123');

      expect(result, isNotNull);
      expect(result!['token'], isA<String>());
      expect(result['userId'], equals('USR-002'));
      expect(result['username'], equals('harsh'));
      expect(result['role'], equals('developer'));
    });

    test('returns null for unknown username', () {
      final result = authService.login('unknown_user', 'somepassword');
      expect(result, isNull);
    });

    test('returns null for correct username but wrong password', () {
      final result = authService.login('admin', 'wrongpassword');
      expect(result, isNull);
    });

    test('returns null for empty username', () {
      final result = authService.login('', 'admin123');
      expect(result, isNull);
    });

    test('returns null for empty password', () {
      final result = authService.login('admin', '');
      expect(result, isNull);
    });

    test('is case-sensitive for username', () {
      final result = authService.login('Admin', 'admin123');
      expect(result, isNull);
    });

    test('is case-sensitive for password', () {
      final result = authService.login('admin', 'Admin123');
      expect(result, isNull);
    });

    test('registers token in database on successful login', () {
      final result = authService.login('admin', 'admin123');
      expect(result, isNotNull);

      final token = result!['token'] as String;
      expect(db.tokens.containsKey(token), isTrue);
      expect(db.tokens[token], equals('USR-001'));
    });

    test('generates unique tokens for separate logins', () {
      final result1 = authService.login('admin', 'admin123');
      final result2 = authService.login('admin', 'admin123');

      expect(result1, isNotNull);
      expect(result2, isNotNull);
      expect(result1!['token'], isNot(equals(result2!['token'])));
    });

    test('does not include password in returned data', () {
      final result = authService.login('admin', 'admin123');
      expect(result, isNotNull);
      expect(result!.containsKey('password'), isFalse);
    });
  });

  group('AuthService.logout', () {
    test('removes token from database', () {
      final result = authService.login('admin', 'admin123');
      final token = result!['token'] as String;

      expect(db.tokens.containsKey(token), isTrue);
      authService.logout(token);
      expect(db.tokens.containsKey(token), isFalse);
    });

    test('is no-op for non-existent token', () {
      // Should not throw
      expect(() => authService.logout('nonexistent-token'), returnsNormally);
    });

    test('does not affect other active tokens', () {
      final result1 = authService.login('admin', 'admin123');
      final result2 = authService.login('harsh', 'harsh123');
      final token1 = result1!['token'] as String;
      final token2 = result2!['token'] as String;

      authService.logout(token1);

      expect(db.tokens.containsKey(token1), isFalse);
      expect(db.tokens.containsKey(token2), isTrue);
    });
  });

  group('AuthService.verify', () {
    test('returns user for valid token', () {
      final result = authService.login('admin', 'admin123');
      final token = result!['token'] as String;

      final user = authService.verify(token);
      expect(user, isNotNull);
      expect(user!.username, equals('admin'));
    });

    test('returns null for invalid token', () {
      final user = authService.verify('invalid-token');
      expect(user, isNull);
    });

    test('returns null for null token', () {
      final user = authService.verify(null);
      expect(user, isNull);
    });

    test('returns null for empty token', () {
      final user = authService.verify('');
      expect(user, isNull);
    });

    test('returns null after token is logged out', () {
      final result = authService.login('admin', 'admin123');
      final token = result!['token'] as String;

      authService.logout(token);
      final user = authService.verify(token);
      expect(user, isNull);
    });

    test('validates pre-registered dev tokens', () {
      final user = authService.verify('dev-token-admin');
      expect(user, isNotNull);
      expect(user!.username, equals('admin'));
    });
  });

  group('Database.findUserByUsername', () {
    test('finds existing user by username', () {
      final user = db.findUserByUsername('admin');
      expect(user, isNotNull);
      expect(user!.id, equals('USR-001'));
      expect(user.role, equals('admin'));
    });

    test('returns null for non-existent username', () {
      final user = db.findUserByUsername('nonexistent');
      expect(user, isNull);
    });
  });

  group('Database.findUserByToken', () {
    test('finds user by pre-registered dev token', () {
      final user = db.findUserByToken('dev-token-admin');
      expect(user, isNotNull);
      expect(user!.username, equals('admin'));
    });

    test('returns null for unknown token', () {
      final user = db.findUserByToken('unknown-token');
      expect(user, isNull);
    });
  });
}
