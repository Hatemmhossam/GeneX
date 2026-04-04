import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

// ✅ IMPORT the new screen we made (Make sure this file exists!)
import 'patient_medical_history.dart'; 

// ✅ MODEL: Patient Data
class PatientProfile {
  final int? id; // <--- ADDED THIS FIELD
  final String name;
  final String email;
  final int? age;
  final String? gender;
  final double? weight;
  final double? height;

  PatientProfile({
    this.id, // <--- ADDED TO CONSTRUCTOR
    required this.name,
    required this.email,
    this.age,
    this.gender,
    this.weight,
    this.height,
  });

  factory PatientProfile.fromJson(Map<String, dynamic> json) {
    return PatientProfile(
      id: json['id'], // <--- CAPTURE ID FROM SERVER
      name: json['name'] ?? 'Unknown',
      email: json['email'] ?? '',
      age: json['age'],
      gender: json['gender'],
      weight: json['weight'],
      height: json['height'],
    );
  }
}

class DoctorDashboardScreen extends StatefulWidget {
  const DoctorDashboardScreen({super.key});

  @override
  State<DoctorDashboardScreen> createState() => _DoctorDashboardScreenState();
}

class _DoctorDashboardScreenState extends State<DoctorDashboardScreen> {
  List<PatientProfile> patients = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchMyPatients();
  }

  Future<void> _fetchMyPatients() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    // ✅ URL for Chrome/Web
    final url = Uri.parse('http://127.0.0.1:8000/api/doctor/my-patients/');

    try {
      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        setState(() {
          patients = data.map((json) => PatientProfile.fromJson(json)).toList();
          _isLoading = false;
        });
      } else {
        debugPrint("Error: ${response.body}");
        setState(() => _isLoading = false);
      }
    } catch (e) {
      debugPrint("Connection Error: $e");
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("My Patients")),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : patients.isEmpty
              ? const Center(child: Text("No accepted patients yet."))
              : Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: GridView.builder(
                    gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                      maxCrossAxisExtent: 400,
                      childAspectRatio: 3 / 2,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                    ),
                    itemCount: patients.length,
                    itemBuilder: (context, index) {
                      final p = patients[index];
                      return Card(
                        elevation: 4,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  CircleAvatar(
                                    backgroundColor: Colors.blueAccent,
                                    child: Text(p.name[0].toUpperCase(), style: const TextStyle(color: Colors.white)),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(p.name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                                        Text(p.email, style: const TextStyle(color: Colors.grey, fontSize: 12)),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const Divider(height: 24),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  _infoBadge("Age", "${p.age ?? '-'}"),
                                  _infoBadge("Gender", p.gender ?? '-'),
                                  _infoBadge("Kg", "${p.weight ?? '-'}"),
                                ],
                              ),
                              const Spacer(),
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton(
                                  onPressed: () {
                                    // ✅ NAVIGATE TO MEDICAL RECORDS
                                    if (p.id != null) {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => PatientMedicalHistoryScreen(
                                            patientId: p.id!,
                                            patientName: p.name,
                                          ),
                                        ),
                                      );
                                    } else {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(content: Text("Error: Patient ID is missing"))
                                      );
                                    }
                                  },
                                  child: const Text("View Medical Records"),
                                ),
                              )
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
    );
  }

  Widget _infoBadge(String label, String value) {
    return Column(
      children: [
        Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
      ],
    );
  }
}