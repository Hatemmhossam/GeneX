// lib/viewmodels/auth_state.dart
import '../models/user_model.dart';

enum AuthStatus { unauthenticated, authenticating, authenticated, error }

class AuthState {
  final AuthStatus status;
  final UserModel? user;
  final String? token;
  final String? errorMessage;

  AuthState({
    required this.status,
    this.user,
    this.token,
    this.errorMessage,
  });

  factory AuthState.initial() =>
      AuthState(status: AuthStatus.unauthenticated);

  AuthState copyWith({
    AuthStatus? status,
    UserModel? user,
    String? token,
    String? errorMessage,
  }) {
    return AuthState(
      status: status ?? this.status,
      user: user ?? this.user,
      token: token ?? this.token,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}
