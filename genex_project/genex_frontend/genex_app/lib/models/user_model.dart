// lib/models/user_model.dart
class UserModel {
  final String id;
  final String name;
  final String email;
  final String role; // "patient" or "doctor"

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) => UserModel(
        id: json['id'].toString(),
        name: json['name'] ?? json['full_name'] ?? '',
        email: json['email'] ?? '',
        role: json['role'] ?? '',
      );
}
