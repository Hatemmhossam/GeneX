// lib/viewmodels/auth_viewmodel.dart
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../repositories/auth_repository.dart';
import '../core/secure_storage.dart';
import 'auth_state.dart';
import '../services/api_service.dart';
import '../models/user_model.dart';
import 'package:flutter/foundation.dart'; // ADD THIS LINE
class AuthViewModel extends StateNotifier<AuthState> {
  final AuthRepository repository;
  final ApiService api;

  AuthViewModel({required this.repository, required this.api})
      : super(AuthState.initial()) {
    _loadToken();
  }

  Future<void> _loadToken() async {
  final token = await SecureStorage.readToken();
  if (token != null) {
    api.setAuthToken(token);

    try {
      final user = await repository.getProfile();

      state = state.copyWith(
        status: AuthStatus.authenticated,
        token: token,
        user: user,
      );

      debugPrint('Auto-login. Role: ${user.role}');
    } catch (_) {
      // token invalid/expired
      await SecureStorage.removeToken();
      api.removeAuthToken();
      state = AuthState.initial();
    }
  }
}


  Future<void> signup({
    required String name,
    required String email,
    required String password,
    required String role,
    required int age,
    required String gender,
    required double weight,
    required double height,
    Map<String, dynamic>? extraFields,
  }) async {
    try {
      state = state.copyWith(status: AuthStatus.authenticating, errorMessage: null);
              final response = await repository.signup(
                name: name,
                email: email,
                password: password,
                role: role,
                age: age,
                gender: gender,
                height: height,
                weight: weight,
              );
              
      await SecureStorage.saveToken(response.token);
      api.setAuthToken(response.token);
      state = state.copyWith(
        status: AuthStatus.authenticated,
        user: response.user,
        token: response.token,
      );
    } catch (e) {
      state = state.copyWith(
        status: AuthStatus.error,
        errorMessage: _extractError(e),
      );
    }
  }

  Future<void> login({
  required String username,
  required String password,
}) async {
  try {
    state = state.copyWith(status: AuthStatus.authenticating, errorMessage: null);
    final response = await repository.login(
      username: username,
      password: password,
    );

    await SecureStorage.saveToken(response.token);
    api.setAuthToken(response.token);

    state = state.copyWith(
      status: AuthStatus.authenticated,
      user: response.user,
      token: response.token,
    );
  } catch (e) {
    state = state.copyWith(
      status: AuthStatus.error,
      errorMessage: _extractError(e),
    );
  }
}


  Future<void> logout() async {
    await SecureStorage.removeToken();
    api.removeAuthToken();
    state = AuthState.initial();
    debugPrint("User logged out successfully");
  }

  String _extractError(Object e) {
    if (e is DioException && e.response != null && e.response?.data != null) {
      try {
        final data = e.response!.data;
        if (data is Map && data['detail'] != null) return data['detail'].toString();
        if (data is Map && data['error'] != null) return data['error'].toString();
      } catch (_) {}
    }
    return e.toString();
  }
}
