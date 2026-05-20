import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';

import '../services/api_service.dart';
import '../services/chat_service.dart';
import '../repositories/auth_repository.dart';
import '../repositories/user_repository.dart';
import '../core/secure_storage.dart';
import 'auth_viewmodel.dart';
import 'auth_state.dart';
import 'user_search_viewmodel.dart';
import 'user_search_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final dashboardIndexProvider = StateProvider<int>((ref) => 0);

final apiServiceProvider = Provider<ApiService>((ref) => ApiService());

final userRepositoryProvider = Provider<UserRepository>((ref) {
  final api = ref.watch(apiServiceProvider);
  return UserRepository(api);
});

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final api = ref.read(apiServiceProvider);
  return AuthRepository(api);
});

final authViewModelProvider =
    StateNotifierProvider<AuthViewModel, AuthState>((ref) {
      final repo = ref.read(authRepositoryProvider);
      final api = ref.read(apiServiceProvider);
      return AuthViewModel(repository: repo, api: api);
    });

final userSearchViewModelProvider =
    StateNotifierProvider<UserSearchViewModel, UserSearchState>((ref) {
      final repo = ref.read(userRepositoryProvider);
      return UserSearchViewModel(repo);
    });

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

final geneReportsProvider = FutureProvider<List<dynamic>>((ref) async {
  final token = await SecureStorage.readToken();

  final dio = Dio(
    BaseOptions(
      baseUrl: "http://127.0.0.1:8000/api/",
      headers: {
        "Authorization": "Bearer $token",
        "Content-Type": "application/json",
      },
    ),
  );

  try {
    final response = await dio.get('gene-reports/');
    print("FINAL URL => ${response.realUri}");
    print("STATUS => ${response.statusCode}");
    return response.data as List<dynamic>;
  } on DioException catch (e) {
    print("ERROR URL => ${e.requestOptions.uri}");
    print("ERROR STATUS => ${e.response?.statusCode}");
    print("ERROR DATA => ${e.response?.data}");
    rethrow;
  }
});

final chatServiceProvider = Provider<ChatService>((ref) {
  return ChatService();
});

final themeProvider = StateProvider<ThemeMode>((ref) {
  return ThemeMode.system;
});
final localeProvider = StateProvider<Locale?>((ref) {
  return null;
});
