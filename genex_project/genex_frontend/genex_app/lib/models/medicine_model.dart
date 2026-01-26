// lib/models/medicine_model.dart
class MedicineHistory {
  final String name;
  // final String dosage;
  // final String startDate;
  // final String endDate;

  MedicineHistory({
    required this.name,
    // required this.dosage,
    // required this.startDate,
    // required this.endDate,
  });

  // Factory method to create MedicineHistory from JSON
  factory MedicineHistory.fromJson(Map<String, dynamic> json) {
    return MedicineHistory(
      name: json['name'],
      // dosage: json['dosage'],
      // startDate: json['start_date'],
      // endDate: json['end_date'] ?? '',
    );
  }

  // Method to convert MedicineHistory to JSON
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      // 'dosage': dosage,
      // 'start_date': startDate,
      // 'end_date': endDate,
    };
  }
}
