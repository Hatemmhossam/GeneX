// lib/repositories/medicine_repository.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/medicine_model.dart';

class MedicineRepository {
  final String baseUrl;

  MedicineRepository({required this.baseUrl});

  // Fetch medicines for the authenticated user
  Future<List<MedicineHistory>> fetchMedicines(String token) async {
    final response = await http.get(
      Uri.parse('$baseUrl/medicines/'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      List<dynamic> data = jsonDecode(response.body);
      return data.map((medicine) => MedicineHistory.fromJson(medicine)).toList();
    } else {
      throw Exception('Failed to load medicines');
    }
  }

  // Add a new medicine for the patient
  Future<void> addMedicine(String token, MedicineHistory medicine) async {
    final response = await http.post(
      Uri.parse('$baseUrl/medicines/'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(medicine.toJson()),
    );

    if (response.statusCode != 201) {
      throw Exception('Failed to add medicine: ${response.statusCode} ${response.body}',);
    }
  }
}
