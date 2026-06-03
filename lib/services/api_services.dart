import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shieldconnect_app/model/user_model.dart';

class ApiService {
  static const String baseUrl =
      "https://shield-connect-api-new-production.up.railway.app/api";

  static const String mediaBaseUrl =
      "https://shield-connect-api-new-production.up.railway.app";

  static String getImageUrl(String? path, {bool isGroup = false}) {
    if (path == null || path.isEmpty) {
      return isGroup
          ? 'https://cdn-icons-png.flaticon.com/512/166/166258.png' // Group placeholder
          : ''; // User placeholder
    }
    if (path.startsWith('http')) return path;
    if (path.startsWith('/')) return "$mediaBaseUrl$path";
    return "$mediaBaseUrl/$path";
  }

  final Dio _dio = Dio(
    BaseOptions(
      baseUrl: baseUrl,
      contentType: "application/json",
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 15),
    ),
  );

  Future<Map<String, String>> _getHeaders() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? sessionStr = prefs.getString('user_session');
    if (sessionStr != null) {
      final Map<String, dynamic> userMap = jsonDecode(sessionStr);
      final UserModel user = UserModel.fromJson(userMap);
      if (user.token != null && user.token!.isNotEmpty) {
        return {'Authorization': 'Bearer ${user.token}'};
      }
    }
    return {};
  }

  Future<Response> post(String url, {dynamic data, Options? options, ProgressCallback? onSendProgress}) async {
    try {
      final headers = await _getHeaders();
      final mergedHeaders = {...headers, ...?(options?.headers)};
      final requestOptions = (options ?? Options()).copyWith(
        headers: mergedHeaders,
      );
      if (data is FormData) {
        requestOptions.contentType = null; // Clear application/json to let Dio set boundary
      }
      final response = await _dio.post(url, data: data, options: requestOptions, onSendProgress: onSendProgress);
      return response;
    } on DioException catch (e) {
      if (e.response != null) {
        return e.response!;
      }
      rethrow;
    }
  }

  Future<Response> get(String url) async {
    try {
      final headers = await _getHeaders();
      final response = await _dio.get(url, options: Options(headers: headers));
      return response;
    } on DioException catch (e) {
      if (e.response != null) {
        return e.response!;
      }
      rethrow;
    }
  }

  Future<Response> put(String url, {dynamic data, Options? options}) async {
    try {
      final headers = await _getHeaders();
      final mergedHeaders = {...headers, ...?(options?.headers)};
      final requestOptions = (options ?? Options()).copyWith(
        headers: mergedHeaders,
      );
      if (data is FormData) {
        requestOptions.contentType = null;
      }
      final response = await _dio.put(url, data: data, options: requestOptions);
      return response;
    } on DioException catch (e) {
      if (e.response != null) {
        return e.response!;
      }
      rethrow;
    }
  }

  Future<Response> delete(String url, {dynamic data, Options? options}) async {
    try {
      final headers = await _getHeaders();
      final mergedHeaders = {...headers, ...?(options?.headers)};
      final requestOptions = (options ?? Options()).copyWith(
        headers: mergedHeaders,
      );
      final response = await _dio.delete(url, data: data, options: requestOptions);
      return response;
    } on DioException catch (e) {
      if (e.response != null) {
        return e.response!;
      }
      rethrow;
    }
  }
}
