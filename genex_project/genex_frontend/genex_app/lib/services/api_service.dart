// lib/services/api_service.dart
import 'package:dio/dio.dart';
import '../core/constants.dart';
import '../models/user_model.dart'; // <--- ADD THIS IMPORT

class ApiService {
  final Dio _dio;

  ApiService({Dio? dio})
      : _dio = dio ??
            Dio(BaseOptions(
              baseUrl: baseUrl, // Ensure this is defined in your constants.dart
              connectTimeout: const Duration(seconds: 10),
              receiveTimeout: const Duration(seconds: 10),
            ));

  // --- Generic Helpers ---

  Future<Response> post(String path, Map<String, dynamic> data,
      {Map<String, dynamic>? headers}) {
    return _dio.post(path, data: data, options: Options(headers: headers));
  }

  Future<Response> get(String path, {Map<String, dynamic>? headers}) {
    return _dio.get(path, options: Options(headers: headers));
  }

  // --- Auth Helpers ---

  void setAuthToken(String token) {
    _dio.options.headers['Authorization'] = 'Bearer $token';
  }

  void removeAuthToken() {
    _dio.options.headers.remove('Authorization');
  }

  // --- Specific API Methods ---

  /// Fetches the list of patients, optionally filtering by a search query.
  /// Hits the Django endpoint: /doctor/patients/
  Future<List<UserModel>> getPatients({String? query}) async {
    try {
      // 1. Prepare params
      Map<String, dynamic>? queryParams;
      if (query != null && query.isNotEmpty) {
        queryParams = {'search': query};
      }

      // 2. Make Request
      final response = await _dio.get(
        '/doctor/patients/', 
        queryParameters: queryParams,
      );

      // 3. Parse Data
      // Django returns a List of JSON objects. We map them to UserModels.
      if (response.statusCode == 200 && response.data is List) {
        return (response.data as List)
            .map((json) => UserModel.fromJson(json))
            .toList();
      }
      
      // Return empty list if format is unexpected but success
      return [];

    } catch (e) {
      // Pass the error up to the UI/Provider to handle
      rethrow; 
    }
  }
}