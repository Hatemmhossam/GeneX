// lib/repositories/auth_repository.dart
import 'package:dio/dio.dart';
import '../services/api_service.dart';
import '../models/auth_response.dart';
import '../models/user_model.dart';

const String baseUrl = "http://127.0.0.1:8000/api";

class AuthRepository {
  final ApiService api;

  AuthRepository(this.api);

 Future<AuthResponse> signup({
  required String name,
  required String email,
  required String password,
  required String role,
  required int age,
  required String gender,
  required double height,
  required double weight,
}) async {
  final response = await api.post('/signup/', {
    'name': name,
    'email': email,
    'password': password,
    'role': role,
    'age': age,
    'gender': gender,
    'height': height,
    'weight': weight,
  });

  return AuthResponse.fromJson(response.data);
}


  Future<AuthResponse> login({
    required String email,
    required String password,
  }) async {
    final resp = await api.post('$baseUrl/signin/', {
      "email": email,
      "password": password,
    });
    return AuthResponse.fromJson(resp.data);
  }
}
