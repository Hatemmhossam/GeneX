class UserModel {
  final String id;
  final String displayName;
  final String email;
  final String username;
  final String role;
  final int? age;
  final double? weight;
  final double? height;
  final String? gender;

  UserModel({
    required this.id,
    required this.displayName,
    required this.email,
    required this.username,
    required this.role,
    this.age,
    this.weight,
    this.height,
    this.gender,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    String nameToDisplay;

    if (json['first_name'] != null &&
        json['first_name'].toString().trim().isNotEmpty) {
      nameToDisplay = json['first_name'].toString();
    } else if (json['full_name'] != null &&
        json['full_name'].toString().trim().isNotEmpty) {
      nameToDisplay = json['full_name'].toString();
    } else if (json['name'] != null &&
        json['name'].toString().trim().isNotEmpty) {
      nameToDisplay = json['name'].toString();
    } else {
      nameToDisplay = json['username']?.toString() ?? 'User';
    }

    return UserModel(
      id: json['id']?.toString() ?? '',
      displayName: nameToDisplay,
      email: json['email']?.toString() ?? '',
      username: json['username']?.toString() ?? '',
      role: (json['role'] ?? json['user_type'] ?? json['type'] ?? 'patient')
          .toString()
          .toLowerCase(),
      age: json['age'] is int ? json['age'] : int.tryParse('${json['age']}'),
      weight: (json['weight'] as num?)?.toDouble(),
      height: (json['height'] as num?)?.toDouble(),
      gender: json['gender']?.toString(),
    );
  }
}