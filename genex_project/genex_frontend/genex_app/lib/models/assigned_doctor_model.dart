class AssignedDoctorModel {
  final int doctorId;
  final String doctorUsername;
  final String doctorName;

  AssignedDoctorModel({
    required this.doctorId,
    required this.doctorUsername,
    required this.doctorName,
  });

  factory AssignedDoctorModel.fromJson(Map<String, dynamic> json) {
    return AssignedDoctorModel(
      doctorId: json['doctor_id'],
      doctorUsername: json['doctor_username'] ?? '',
      doctorName: json['doctor_name'] ?? '',
    );
  }
}