// lib/viewmodels/medicine_viewmodel.dart
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../models/medicine_model.dart';
import '../repositories/medicine_repository.dart';


class MedicineViewModel extends ChangeNotifier {
  final MedicineRepository medicineRepository;
  List<MedicineHistory> _medicines = [];

  MedicineViewModel({required this.medicineRepository});

  List<MedicineHistory> get medicines => _medicines;

  // Fetch medicines
  Future<void> fetchMedicines(String token) async {
    try {
      _medicines = await medicineRepository.fetchMedicines(token);
      notifyListeners();
    } catch (e) {
      print('Fetch medicines error: $e');
    }
  }

  // Add a new medicine
  Future<void> addMedicine(String token, MedicineHistory medicine) async {
    try {
      await medicineRepository.addMedicine(token, medicine);
      _medicines.add(medicine);  // Update state after adding
      notifyListeners();
    } catch (e) {
      print('Add medicine error: $e');
    }
  }
}
