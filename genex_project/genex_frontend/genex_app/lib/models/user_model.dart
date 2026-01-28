// // lib/models/user_model.dart
// class UserModel {
//   final String id;
//   final String name;
//   final String email;
//   final String role; // "patient" or "doctor"

//   UserModel({
//     required this.id,
//     required this.name,
//     required this.email,
//     required this.role,
//   });

//   factory UserModel.fromJson(Map<String, dynamic> json) => UserModel(
//         id: json['id'].toString(),
//         name: json['name'] ?? json['full_name'] ?? '',
//         email: json['email'] ?? '',
//         role: json['role'] ?? '',
//       );
// }

class UserModel {
  final String id;
  final String displayName; // A helper for the UI
  final String email;
  final String role;
  final int? age;
  final double? weight;
  final double? height;
  final String? gender;

  UserModel({
    required this.id,
    required this.displayName,
    required this.email,
    required this.role,
    this.age,
    this.weight,
    this.height,
    this.gender,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    // Logic to pick the best name to show in the UI
    String nameToDisplay = json['first_name'] != null && json['first_name'].toString().isNotEmpty
        ? json['first_name']
        : json['username'] ?? 'User';

    return UserModel(
      id: json['id'].toString(),
      displayName: nameToDisplay,
      email: json['email'] ?? '',
      role: json['role'] ?? 'patient',
      age: json['age'] as int?,
      weight: (json['weight'] as num?)?.toDouble(), 
      height: (json['height'] as num?)?.toDouble(),
      gender: json['gender'],
    );
  }
}