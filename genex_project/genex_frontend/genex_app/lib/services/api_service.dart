// lib/services/api_service.dart
import 'package:dio/dio.dart';
import '../core/constants.dart';

class ApiService {

 /* final Dio _dio = Dio(BaseOptions(
    baseUrl: "http://127.0.0.1:8000/api", // OR your server URL
    headers: {"Content-Type": "application/json"},
  ));*/   
  //msh 3arfa lesa haghyar deh wala laa 
  // mafrood deh w kam edit kman 3shan ykahly Flutter app automatically sends JWT to Django.

  final Dio _dio;

  ApiService({Dio? dio})
      : _dio = dio ??
            Dio(BaseOptions(
              baseUrl: baseUrl,
              connectTimeout: const Duration(seconds: 10),
              receiveTimeout: const Duration(seconds: 10),
            ));

  Future<Response> post(
    String path,
    Map<String, dynamic> data, {
    Map<String, dynamic>? headers,
  }) {
    return _dio.post(
      path,
      data: data,
      options: Options(headers: headers),
    );
  }

  // TWIN SIMULATION API
  Future<Map<String, dynamic>> evaluateTwinSimulation({
    required String filePath,
    required String drug1,
    String? drug2,
  }) async {
    FormData formData = FormData.fromMap({
      "file": await MultipartFile.fromFile(filePath),
      "drug1": drug1,
      if (drug2 != null && drug2.isNotEmpty) "drug2": drug2,
    });

    final response = await _dio.post(
      "/evaluate/",
      data: formData,
      options: Options(
        headers: {
          "Content-Type": "multipart/form-data",
        },
      ),
    );

    return Map<String, dynamic>.from(response.data);
  }

  void setAuthToken(String token) {
    _dio.options.headers['Authorization'] = 'Bearer $token';
  }

  void removeAuthToken() {
    _dio.options.headers.remove('Authorization');
  }
}
