import 'dart:async';
import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../config/api_config.dart';
import '../models/api_response.dart';

typedef AccessTokenRefresher = Future<String?> Function();
typedef LogoutAndRedirect = Future<void> Function();
typedef ShowMessage = void Function(String);

/// Base HTTP service — all API calls go through here.
/// Uses Dio with an interceptor for automatic 401 → token-refresh → retry flow.
class ApiService {
  // Injected callbacks (set via configure() after login setup)
  AccessTokenRefresher? _refreshFn;
  LogoutAndRedirect? _logoutFn;
  ShowMessage? _showMessage;

  void configure({
    AccessTokenRefresher? refreshFn,
    LogoutAndRedirect? logoutFn,
    ShowMessage? showMessage,
  }) {
    _refreshFn = refreshFn;
    _logoutFn = logoutFn;
    _showMessage = showMessage;
  }

  // Token management
  String? _authToken;
  void setToken(String? token) => _authToken = token;
  String? get token => _authToken;
  bool get isAuthenticated => _authToken != null && _authToken!.isNotEmpty;

  // Dio & timeouts
  late final Dio _dio;
  final _timeout = Duration(seconds: kDebugMode ? 60 : 120);

  // Refresh synchronisation — prevents multiple simultaneous refresh calls
  bool _isRefreshing = false;
  final List<Completer<void>> _refreshWaiters = [];

  ApiService() {
    _dio = Dio(
      BaseOptions(
        baseUrl: ApiConfig.baseUrl,
        contentType: Headers.jsonContentType,
        connectTimeout: _timeout,
        receiveTimeout: _timeout,
        sendTimeout: _timeout,
      ),
    );

    _dio.interceptors.add(
      InterceptorsWrapper(
        // Attach Bearer token + log request
        onRequest: (options, handler) {
          if (_authToken != null && _authToken!.isNotEmpty) {
            debugPrint('┌─ [API REQUEST] ${options.method} ${options.uri}');
            options.headers['Authorization'] = 'Bearer $_authToken';

            debugPrint('┌─ [API Token] $_authToken');
          }
          debugPrint('┌─ [API REQUEST] ${options.method} ${options.uri}');
          if (options.data != null) {
            debugPrint('│  Body: ${options.data}');
          }
          debugPrint('└─────────────────────────────────');
          return handler.next(options);
        },

        // 401 → refresh → retry once
        onError: (DioException error, handler) async {
          final status = error.response?.statusCode;
          final path = error.requestOptions.path;
          debugPrint(
            '┌─ [API ERROR] ${error.requestOptions.method} ${error.requestOptions.uri} → $status',
          );
          debugPrint('│  ${error.response?.data ?? error.message}');
          debugPrint('└─────────────────────────────────');

          // Skip refresh for login / refresh endpoints (avoid infinite loop)
          final isAuthEndpoint =
              path.contains('login') || path.contains('refresh');

          if (status == 401 && !isAuthEndpoint) {
            final alreadyRetried = error.requestOptions.extra['__ret'] == true;

            try {
              if (!_isRefreshing) {
                // Only one refresh at a time
                _isRefreshing = true;
                final ok = await _performTokenRefresh();
                _isRefreshing = false;

                // Wake up any requests that were waiting for refresh
                for (final c in _refreshWaiters) {
                  if (!c.isCompleted) c.complete();
                }
                _refreshWaiters.clear();

                if (!ok) {
                  _showMessage?.call('Session expired. Please login again.');
                  await _logoutAndClear();
                  return handler.resolve(
                    Response(
                      requestOptions: error.requestOptions,
                      statusCode: 401,
                    ),
                  );
                }
              } else {
                // Another request is already refreshing — wait for it
                final waiter = Completer<void>();
                _refreshWaiters.add(waiter);
                await waiter.future;
              }

              // Retry the original request once with the new token
              if (!alreadyRetried) {
                error.requestOptions.extra['__ret'] = true;
                final retried = await _retry(error.requestOptions);
                return handler.resolve(retried);
              }

              // Already retried → propagate the error
              return handler.next(error);
            } catch (e) {
              await _logoutAndClear();
              return handler.resolve(
                Response(requestOptions: error.requestOptions, statusCode: 401),
              );
            }
          }

          return handler.next(error);
        },

        onResponse: (response, handler) {
          debugPrint(
            '┌─ [API RESPONSE] ${response.requestOptions.method} ${response.requestOptions.uri} → ${response.statusCode}',
          );
          debugPrint('│  ${response.data}');
          debugPrint('└─────────────────────────────────');
          return handler.next(response);
        },
      ),
    );
  }

  /// Re-issues the original request with the refreshed token in the header.
  Future<Response<dynamic>> _retry(RequestOptions req) async {
    final headers = Map<String, dynamic>.from(req.headers);
    if (_authToken != null && _authToken!.isNotEmpty) {
      headers['Authorization'] = 'Bearer $_authToken';
    } else {
      headers.remove('Authorization');
    }

    return _dio.request<dynamic>(
      req.path,
      data: req.data,
      queryParameters: req.queryParameters,
      options: Options(
        method: req.method,
        headers: headers,
        responseType: req.responseType,
        followRedirects: req.followRedirects,
        receiveTimeout: req.receiveTimeout,
        sendTimeout: req.sendTimeout,
      ),
    );
  }

  /// Calls the injected refresher to get a new access token.
  Future<bool> _performTokenRefresh() async {
    try {
      if (_refreshFn == null) return false;
      final newToken = await _refreshFn!.call();
      if (newToken != null && newToken.isNotEmpty) {
        _authToken = newToken;
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('[ApiService] Token refresh error: $e');
      return false;
    }
  }

  /// Clears token and calls the injected logout callback.
  Future<void> _logoutAndClear() async {
    _authToken = null;
    await _logoutFn?.call();
  }

  // ── Public request API (same interface as before) ──────────────────────────

  Future<ApiResponse<T>> get<T>(
    String endpoint, {
    T Function(Map<String, dynamic>)? fromData,
    Map<String, dynamic>? queryParameters,
  }) async {
    try {
      debugPrint('[API GET] ${ApiConfig.baseUrl}$endpoint');
      final res = await _dio.get(endpoint, queryParameters: queryParameters);
      return _handleResponse<T>(res, fromData: fromData);
    } on DioException catch (e) {
      debugPrint('[API ERROR] GET $endpoint: $e');
      return ApiResponse.error(_errorMessage(e));
    }
  }

  Future<ApiResponse<T>> post<T>(
    String endpoint,
    Map<String, dynamic> body, {
    T Function(Map<String, dynamic>)? fromData,
  }) async {
    try {
      debugPrint('[API POST] ${ApiConfig.baseUrl}$endpoint');
      final res = await _dio.post(endpoint, data: jsonEncode(body));
      return _handleResponse<T>(res, fromData: fromData);
    } on DioException catch (e) {
      debugPrint('[API ERROR] POST $endpoint: $e');
      return ApiResponse.error(_errorMessage(e));
    }
  }

  Future<ApiResponse<T>> put<T>(
    String endpoint,
    Map<String, dynamic> body, {
    T Function(Map<String, dynamic>)? fromData,
  }) async {
    try {
      debugPrint('[API PUT] ${ApiConfig.baseUrl}$endpoint');
      final res = await _dio.put(endpoint, data: jsonEncode(body));
      return _handleResponse<T>(res, fromData: fromData);
    } on DioException catch (e) {
      debugPrint('[API ERROR] PUT $endpoint: $e');
      return ApiResponse.error(_errorMessage(e));
    }
  }

  Future<ApiResponse<T>> delete<T>(
    String endpoint, {
    T Function(Map<String, dynamic>)? fromData,
  }) async {
    try {
      debugPrint('[API DELETE] ${ApiConfig.baseUrl}$endpoint');
      final res = await _dio.delete(endpoint);
      return _handleResponse<T>(res, fromData: fromData);
    } on DioException catch (e) {
      debugPrint('[API ERROR] DELETE $endpoint: $e');
      return ApiResponse.error(_errorMessage(e));
    }
  }

  /// Upload multipart form-data where multiple files may share the same key.
  /// [fileEntries] is a list of (fieldKey, bytes, filename) records.
  Future<ApiResponse<T>> postMultipart<T>(
    String endpoint, {
    required Map<String, String> fields,
    required List<({String key, List<int> bytes, String filename})> fileEntries,
    T Function(Map<String, dynamic>)? fromData,
  }) async {
    try {
      debugPrint('[API MULTIPART] ${ApiConfig.baseUrl}$endpoint');
      final formData = FormData();
      formData.fields.addAll(
        fields.entries.map((e) => MapEntry(e.key, e.value)),
      );
      for (final f in fileEntries) {
        formData.files.add(
          MapEntry(
            f.key,
            MultipartFile.fromBytes(f.bytes, filename: f.filename),
          ),
        );
      }
      final res = await _dio.post(
        endpoint,
        data: formData,
        options: Options(
          contentType: 'multipart/form-data; boundary=${formData.boundary}',
        ),
      );
      return _handleResponse<T>(res, fromData: fromData);
    } on DioException catch (e) {
      debugPrint('[API ERROR] MULTIPART $endpoint: $e');
      return ApiResponse.error(_errorMessage(e));
    }
  }

  Future<ApiResponse<T>> uploadMultipart<T>(
    String endpoint, {
    required Map<String, String> fields,
    required Map<String, List<int>> files,
    required Map<String, String> fileNames,
    T Function(Map<String, dynamic>)? fromData,
  }) async {
    try {
      debugPrint('[API UPLOAD] ${ApiConfig.baseUrl}$endpoint');
      final formData = FormData();
      formData.fields.addAll(
        fields.entries.map((e) => MapEntry(e.key, e.value)),
      );
      for (final entry in files.entries) {
        formData.files.add(
          MapEntry(
            entry.key,
            MultipartFile.fromBytes(
              entry.value,
              filename: fileNames[entry.key] ?? 'file',
            ),
          ),
        );
      }
      final res = await _dio.post(
        endpoint,
        data: formData,
        options: Options(contentType: 'multipart/form-data'),
      );
      return _handleResponse<T>(res, fromData: fromData);
    } on DioException catch (e) {
      debugPrint('[API ERROR] UPLOAD $endpoint: $e');
      return ApiResponse.error(_errorMessage(e));
    }
  }

  Future<dynamic> getRawData(String endpoint) async {
    try {
      debugPrint('[API GET RAW] ${ApiConfig.baseUrl}$endpoint');
      final res = await _dio.get(endpoint);
      return res.data;
    } on DioException catch (e) {
      debugPrint('[API ERROR] getRawData $endpoint: $e');
    }
    return null;
  }

  Future<dynamic> postRawData(
    String endpoint, [
    Map<String, dynamic>? body,
  ]) async {
    try {
      debugPrint('[API POST RAW] ${ApiConfig.baseUrl}$endpoint');
      final res = await _dio.post(endpoint, data: jsonEncode(body ?? {}));
      return res.data;
    } on DioException catch (e) {
      debugPrint('[API ERROR] postRawData $endpoint: $e');
    }
    return null;
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  ApiResponse<T> _handleResponse<T>(
    Response res, {
    T Function(Map<String, dynamic>)? fromData,
  }) {
    debugPrint('[API RESPONSE] ${res.statusCode}');
    try {
      final data = res.data;
      final isSuccess =
          res.statusCode != null &&
          res.statusCode! >= 200 &&
          res.statusCode! < 300;
      if (isSuccess) {
        if (data is Map<String, dynamic>) {
          return ApiResponse.fromJson(data, fromData: fromData);
        }
        return ApiResponse(
          success: true,
          message: 'Success',
          statusCode: res.statusCode ?? 200,
        );
      }
      final msg = data is Map
          ? (data['message'] ?? 'Request failed')
          : 'Request failed';
      return ApiResponse.error(
        msg.toString(),
        statusCode: res.statusCode ?? 500,
      );
    } catch (e) {
      final isSuccess =
          res.statusCode != null &&
          res.statusCode! >= 200 &&
          res.statusCode! < 300;
      if (isSuccess) {
        return ApiResponse(
          success: true,
          message: 'Success',
          statusCode: res.statusCode ?? 200,
        );
      }
      return ApiResponse.error(
        'Parse error: $e',
        statusCode: res.statusCode ?? 500,
      );
    }
  }

  String _errorMessage(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.sendTimeout:
        return 'Request timed out';
      default:
        final data = e.response?.data;
        if (data is Map) return data['message']?.toString() ?? 'Request failed';
        return 'Network error: ${e.message}';
    }
  }

  void dispose() {}
}
