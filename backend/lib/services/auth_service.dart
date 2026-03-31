import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:uuid/uuid.dart';
import 'database.dart';
import '../models/models.dart';

class AuthService {
  final Database _db;
  final _uuid = const Uuid();

  AuthService(this._db);

  /// Login — returns token + user info
  Map<String, dynamic>? login(String username, String password) {
    final user = _db.findUserByUsername(username);
    if (user == null || user.password != password) return null;

    // Generate token (simple hash — replace with JWT in production)
    final raw = '${user.id}:${_uuid.v4()}:${DateTime.now().millisecondsSinceEpoch}';
    final token = sha256.convert(utf8.encode(raw)).toString().substring(0, 48);

    _db.tokens[token] = user.id;

    return {
      'token': token,
      ...user.toPublicJson(),
    };
  }

  /// Logout — invalidate token
  void logout(String token) {
    _db.tokens.remove(token);
  }

  /// Verify token — returns User or null
  User? verify(String? token) {
    if (token == null || token.isEmpty) return null;
    return _db.findUserByToken(token);
  }
}
