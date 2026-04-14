// lib/repositories/auth_repository.dart
import '../services/api_service.dart';
import '../models/auth_response.dart';
import '../models/user_model.dart';

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
  required String username,
  required String password,
}) async {
  final resp = await api.post('/signin/', {
    "username": username,
    "password": password,
  });
  return AuthResponse.fromJson(resp.data);
}


  
  // ✅ NEW: used for auto-login / role restore
  Future<UserModel> getProfile() async {
    final resp = await api.get('/profile/');
    return UserModel.fromJson(resp.data);
  }
}
