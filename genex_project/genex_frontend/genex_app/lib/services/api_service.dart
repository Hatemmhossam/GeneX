import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import '../core/constants.dart';
import '../core/secure_storage.dart';
import '../models/user_model.dart';

class ApiService {
  final Dio _dio;

  ApiService({Dio? dio})
      : _dio = dio ??
            Dio(
             BaseOptions(
            // ❌ OLD (The cause of the error):
            // baseUrl: baseUrl, 

            // ✅ NEW (The Fix for Web):
            baseUrl: 'http://127.0.0.1:8000/api/', 
            
            connectTimeout: const Duration(seconds: 10),
            receiveTimeout: const Duration(seconds: 10),
            headers: {'Content-Type': 'application/json'},
          ),
            );

  // --- Auth Helpers ---

  /// Reads token from storage and updates headers automatically
  Future<void> _refreshAuthHeader() async {
    final token = await SecureStorage.readToken();
    if (token != null && token.isNotEmpty) {
      _dio.options.headers['Authorization'] = 'Bearer $token';
    } else {
      _dio.options.headers.remove('Authorization');
    }
  }

  /// Used after login
  void setAuthToken(String token) {
    _dio.options.headers['Authorization'] = 'Bearer $token';
  }

  void removeAuthToken() {
    _dio.options.headers.remove('Authorization');
  }

  // --- Generic Helpers ---

  Future<Response> post(
    String path,
    Map<String, dynamic> data, {
    Map<String, dynamic>? headers,
  }) async {
    await _refreshAuthHeader();

    return _dio.post(
      path,
      data: data,
      options: Options(headers: headers),
    );
  }

  Future<Response> get(
    String path, {
    Map<String, dynamic>? headers,
  }) async {
    await _refreshAuthHeader();

    return _dio.get(
      path,
      options: Options(headers: headers),
    );
  }

  // --- Specific API Methods ---

  /// ✅ NEW: Search specifically for patients using the new endpoint
  Future<List<UserModel>> searchPatients(String query) async {
    try {
      await _refreshAuthHeader();

      final response = await _dio.get(
        'search-patients/', // Matches the URL defined in Django urls.py
        queryParameters: {
          'query': query,
        },
      );

      final data = response.data;

      // Handle List response directly
      if (response.statusCode == 200 && data is List) {
        return data.map((json) => UserModel.fromJson(json)).toList();
      }

      // Handle Paginated response (if your generic views add pagination)
      if (response.statusCode == 200 && data is Map && data['results'] is List) {
        return (data['results'] as List)
            .map((json) => UserModel.fromJson(json))
            .toList();
      }

      return [];
    } on DioException catch (e) {
      debugPrint("Search Error: ${e.response?.statusCode} - ${e.response?.statusMessage}");
      rethrow; 
    }
  }
  /// ✅ Restore this method:
  Future<List<UserModel>> searchUsersByUsername(
    String username, {
    String? role,
  }) async {
    await _refreshAuthHeader();

    final q = username.trim();
    if (q.isEmpty) return [];

    final queryParams = <String, dynamic>{
      'username': q,
    };

    if (role != null && role.trim().isNotEmpty) {
      queryParams['role'] = role.trim();
    }

    // Ensure 'api_user/' is the correct endpoint on your Django backend
    final response = await _dio.get(
      'api_user/', 
      queryParameters: queryParams,
    );

    final data = response.data;

    if (response.statusCode == 200 && data is List) {
      return data.map((json) => UserModel.fromJson(json)).toList();
    }

    if (response.statusCode == 200 && data is Map && data['results'] is List) {
      return (data['results'] as List)
          .map((json) => UserModel.fromJson(json))
          .toList();
    }

    return [];
  }

  /// Legacy method: Kept in case you use it elsewhere, but 'searchPatients' is preferred for the specific search page
  Future<List<UserModel>> getPatients({String? query}) async {
    try {
      await _refreshAuthHeader();

      final Map<String, dynamic> queryParams = {
        'role': 'patient',
      };

      if (query != null && query.trim().isNotEmpty) {
        queryParams['username'] = query.trim();
      }

      final response = await _dio.get(
        'api_user/',
        queryParameters: queryParams,
      );

      final data = response.data;

      if (response.statusCode == 200 && data is List) {
        return data.map((json) => UserModel.fromJson(json)).toList();
      }

      if (response.statusCode == 200 && data is Map && data['results'] is List) {
        return (data['results'] as List)
            .map((json) => UserModel.fromJson(json))
            .toList();
      }

      return [];
    } on DioException catch (e) {
      debugPrint("API Error Path: ${e.requestOptions.uri}");
      rethrow;
    }
  }

  Future<List<UserModel>> getDoctorPatients({String? username}) async {
    await _refreshAuthHeader();

    final q = username?.trim();
    final queryParams = <String, dynamic>{};
    if (q != null && q.isNotEmpty) {
      queryParams['username'] = q;
    }

    final response = await _dio.get(
      'doctor/patients/',
      queryParameters: queryParams.isEmpty ? null : queryParams,
    );

    final data = response.data;

    if (response.statusCode == 200 && data is List) {
      return data.map((json) => UserModel.fromJson(json)).toList();
    }

    if (response.statusCode == 200 && data is Map && data['results'] is List) {
      return (data['results'] as List)
          .map((json) => UserModel.fromJson(json))
          .toList();
    }

    return [];
  }
}