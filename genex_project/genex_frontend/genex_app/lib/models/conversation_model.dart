class ConversationModel {
  final int id;
  final int doctorId;
  final int patientId;
  final String doctorUsername;
  final String patientUsername;

  ConversationModel({
    required this.id,
    required this.doctorId,
    required this.patientId,
    required this.doctorUsername,
    required this.patientUsername,
  });

  factory ConversationModel.fromJson(Map<String, dynamic> json) {
    return ConversationModel(
      id: json['id'],
      doctorId: json['doctor_id'],
      patientId: json['patient_id'],
      doctorUsername: json['doctor_username'] ?? '',
      patientUsername: json['patient_username'] ?? '',
    );
  }
}