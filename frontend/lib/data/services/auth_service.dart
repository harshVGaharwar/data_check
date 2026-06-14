import 'package:vizualizer/core/config/api_config.dart';
import 'package:vizualizer/data/models/api_response.dart';
import 'package:vizualizer/data/models/login_request.dart';
import 'package:vizualizer/data/models/login_response.dart';
import 'package:vizualizer/data/services/api_service.dart';
import 'package:vizualizer/data/services/storage_service.dart';

class AuthService {
  final ApiService _api;

  AuthService(this._api);

  Future<ApiResponse<LoginResponse>> login(LoginRequest request) async {
    final response = await _api.post<LoginResponse>(
      ApiConfig.loginEndpoint,
      request.toJson(),
      fromData: (json) => LoginResponse.fromJson(json),
    );

    // Store token on success
    if (response.success && response.data != null) {
      _api.setToken(response.data!.token);
    }

    return response;
  }

  Future<ApiResponse> logout() async {
    final response = await _api.post(ApiConfig.logoutEndpoint, {});
    _api.setToken(null);
    return response;
  }

  Future<String?> refreshToken({
    required String token,
    required String userId,
    required StorageService storage,
  }) async {
    final response = await _api
        .post<Map<String, dynamic>>(ApiConfig.refreshEndpoint, {
          'token': token,
          'userId': userId,
          'expiryDate': '2026-02-27T18:39:23.527Z',
          'isRevoked': false,
        }, fromData: (json) => json);
    if (response.success && response.data != null) {
      final newAccessToken = response.data!['accessToken'] as String? ?? '';
      final newRefreshToken = response.data!['refreshToken'] as String? ?? '';
      if (newAccessToken.isNotEmpty) {
        _api.setToken(newAccessToken);
        await storage.updateTokens(
          accessToken: newAccessToken,
          refreshToken: newRefreshToken,
        );
        return newAccessToken;
      }
    }
    return null;
  }

  void setToken(String token) => _api.setToken(token);
  bool get isLoggedIn => _api.isAuthenticated;
}
