// lib/models/user_model.dart
class UserModel {
  final String id;
  final String username;
  final String name;
  final String email;
  final String role; // "patient" or "doctor"

  UserModel({
    required this.id,
    required this.username,
    required this.name,
    required this.email,
    required this.role,
  });

factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'].toString(),
      // Django almost always sends 'username'
      username: json['username'] ?? '', 
      // Django stores names in 'first_name', so we must check for it
      name: json['name'] ?? json['first_name'] ?? json['full_name'] ?? '',
      email: json['email'] ?? '',
      role: json['role'] ?? 'patient',
    );
    
  }


}
