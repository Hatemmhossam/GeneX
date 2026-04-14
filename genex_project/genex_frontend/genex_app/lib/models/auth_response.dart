import 'user_model.dart';

class AuthResponse {
  final String token;
  final UserModel user;

  AuthResponse({required this.token, required this.user});

  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    final token = (json['token'] ?? json['access']) as String?;

    if (token == null) {
      throw FormatException('AuthResponse missing token/access field');
    }

    final userJson = (json['user'] is Map<String, dynamic>)
        ? (json['user'] as Map<String, dynamic>)
        : json;

    return AuthResponse(
      token: token,
      user: UserModel.fromJson(userJson),
    );
  }
}
