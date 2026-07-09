import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

class AppConfig {
  AppConfig._internal();

  static final AppConfig _instance = AppConfig._internal();

  static AppConfig get instance => _instance;

  late String baseUrl;

  static Future<void> load() async {
    try {
      final response = await Dio().get('config.json');

      if (response.statusCode != 200 || response.data == null) {
        throw Exception('Failed to load config.json');
      }

      final Map<String, dynamic> data = response.data is String
          ? json.decode(response.data)
          : Map<String, dynamic>.from(response.data);

      _instance.baseUrl =
          (data['baseUrl'] as String?)?.trim() ?? _fallbackBaseUrl();

      if (kDebugMode) {
        print('[AppConfig] baseUrl: ${_instance.baseUrl}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('[AppConfig] load failed: $e');
      }

      _instance.baseUrl = _fallbackBaseUrl();
    }
  }

  static String _fallbackBaseUrl() =>
      'https://hbenetppuatdb01.hdfcbankuat.com/DataORCAPIdemo/api/';
}
