import 'package:flutter/material.dart';
import '../models/login_request.dart';
import '../models/login_response.dart';
import '../services/auth_service.dart';
import '../services/storage_service.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _authService;
  final StorageService _storage;

  AuthProvider(this._authService, this._storage) {
    _tryAutoLogin();
  }

  bool _initialized = false;
  bool _loading = false;
  String? _error;
  LoginResponse? _user;

  bool get initialized => _initialized;
  bool get loading => _loading;
  String? get error => _error;
  LoginResponse? get user => _user;
  bool get isLoggedIn => _user != null && _authService.isLoggedIn;

  Future<void> _tryAutoLogin() async {
    try {
      final session = await _storage.loadSession();
      if (session != null && session.token.isNotEmpty) {
        _authService.setToken(session.token);
        _user = session;
      }
    } catch (_) {
      // Storage read failed — proceed to login screen
    }
    _initialized = true;
    notifyListeners();
  }

  Future<bool> login(String username, String password) async {
    _loading = true;
    _error = null;
    notifyListeners();

    final response = await _authService.login(
      LoginRequest(name: username, password: password),
    );

    _loading = false;

    if (response.success && response.data != null) {
      _user = response.data;
      await _storage.saveSession(response.data!);
      notifyListeners();
      return true;
    } else {
      _error = response.message.isNotEmpty ? response.message : 'Login failed';
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    await _authService.logout();
    await _storage.clearSession();
    _user = null;
    notifyListeners();
  }
}
