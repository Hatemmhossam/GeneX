// lib/viewmodels/providers.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/api_service.dart';
import '../repositories/auth_repository.dart';
import 'auth_viewmodel.dart';
import 'auth_state.dart';

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
