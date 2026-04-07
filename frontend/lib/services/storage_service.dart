import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/login_response.dart';

class StorageService {
  static const _tokenKey = 'auth_token';
  static const _refreshTokenKey = 'auth_refresh_token';
  static const _userKey = 'auth_user';
  static const _pageIndexKey = 'nav_page_index';

  final FlutterSecureStorage _storage = const FlutterSecureStorage(
    webOptions: WebOptions(dbName: 'hdfc_pipeline', publicKey: 'hdfc_key'),
  );

  Future<void> saveSession(LoginResponse session) async {
    await Future.wait([
      _storage.write(key: _tokenKey, value: session.token),
      _storage.write(key: _refreshTokenKey, value: session.refreshToken),
      _storage.write(
        key: _userKey,
        value: jsonEncode({
          'id': session.user.id,
          'name': session.user.name,
          'employeeCode': session.user.employeeCode,
          'email': session.user.email,
          'location': session.user.location,
          'locationcode': session.user.locationCode,
          'city': session.user.city,
          'department': session.user.department,
          'contactNumber': session.user.contactNumber,
          'role': session.user.role,
          'ipAddress': session.user.ipAddress,
          'profileDescription': session.user.profileDescription,
          'profileId': session.user.profileId,
        }),
      ),
    ]);
  }

  Future<LoginResponse?> loadSession() async {
    final token = await _storage.read(key: _tokenKey);
    if (token == null || token.isEmpty) return null;

    final refreshToken = await _storage.read(key: _refreshTokenKey) ?? '';
    final userJson = await _storage.read(key: _userKey);

    if (userJson == null) return null;

    return LoginResponse.fromJson({
      'token': token,
      'refreshToken': refreshToken,
      'user': jsonDecode(userJson) as Map<String, dynamic>,
    });
  }

  Future<void> clearSession() async {
    await Future.wait([
      _storage.delete(key: _tokenKey),
      _storage.delete(key: _refreshTokenKey),
      _storage.delete(key: _userKey),
      _storage.delete(key: _pageIndexKey),
    ]);
  }

  Future<void> savePageIndex(int index) async {
    await _storage.write(key: _pageIndexKey, value: '$index');
  }

  Future<int> loadPageIndex() async {
    final value = await _storage.read(key: _pageIndexKey);
    return int.tryParse(value ?? '') ?? 0;
  }
}
