// lib/viewmodels/providers.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/api_service.dart';
import '../repositories/auth_repository.dart';
import 'auth_viewmodel.dart';
import 'auth_state.dart';
import 'package:dio/dio.dart';
import '../core/secure_storage.dart';

// api service provider (singleton)
final apiServiceProvider = Provider<ApiService>((ref) => ApiService());

// auth repository
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final api = ref.read(apiServiceProvider);
  return AuthRepository(api);
});

// auth viewmodel provider (StateNotifierProvider)
final authViewModelProvider =
    StateNotifierProvider<AuthViewModel, AuthState>((ref) {
  final repo = ref.read(authRepositoryProvider);
  final api = ref.read(apiServiceProvider);
  return AuthViewModel(repository: repo, api: api);
});


// Provider to fetch the list of medicines
final medicinesProvider = FutureProvider<List<dynamic>>((ref) async {
  final token = await SecureStorage.readToken();
  final dio = Dio(BaseOptions(baseUrl: "http://localhost:8000/api/"));
  
  final response = await dio.get(
    'medicines/',
    options: Options(headers: {"Authorization": "Bearer $token"}),
  );

  if (response.statusCode == 200) {
    return response.data as List<dynamic>;
  } else {
    throw Exception('Failed to load medicines');
  }
});

// Provider to fetch the list of symptoms
final symptomsProvider = FutureProvider<List<dynamic>>((ref) async {
  final token = await SecureStorage.readToken();
  final dio = Dio(BaseOptions(baseUrl: "http://127.0.0.1:8000/api/"));
  
  final response = await dio.get(
    'symptoms/',
    options: Options(headers: {"Authorization": "Bearer $token"}),
  );

  if (response.statusCode == 200) {
    return response.data as List<dynamic>;
  } else {
    throw Exception('Failed to load symptoms');
  }
});