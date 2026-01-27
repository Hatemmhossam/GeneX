class MedicineHistory {
  final int? id; // Database ID from Django
  final String name;
  final String? date; // added_at from Django

  MedicineHistory({this.id, required this.name, this.date});

  // Factory method to create MedicineHistory from JSON
  factory MedicineHistory.fromJson(Map<String, dynamic> json) {
    return MedicineHistory(
      id: json['id'],
      name: json['name'],
      date: json['added_at'],
    );
  }

  // Method to convert MedicineHistory to JSON for POST requests
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'added_at': date,
    };
  }
}