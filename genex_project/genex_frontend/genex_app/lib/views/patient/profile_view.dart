import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../core/secure_storage.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  // Controllers to hold and display the medical data
  final nameController = TextEditingController();
  final ageController = TextEditingController();
  final genderController = TextEditingController();
  final weightController = TextEditingController();
  final heightController = TextEditingController();

  bool isSaving = false;
  bool isFetching = true;

  @override
  void initState() {
    super.initState();
    fetchProfile();
  }

  @override
  void dispose() {
    nameController.dispose();
    ageController.dispose();
    genderController.dispose();
    weightController.dispose();
    heightController.dispose();
    super.dispose();
  }

  Future<void> fetchProfile() async {
    // Uses the same key as your AuthViewModel
    final token = await SecureStorage.readToken();
    
    if (token == null) {
      debugPrint("DEBUG: No token found. Please log in again.");
      if (mounted) setState(() => isFetching = false);
      return;
    }

    try {
      // Using localhost for Chrome/Web and 127.0.0.1 for Desktop/Mobile
      final url = Uri.parse('http://localhost:8000/api/profile/');
      
      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $token', 
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (mounted) {
          setState(() {
            // Mapping Django User model fields to Controllers
            nameController.text = data['first_name']?.toString() ?? '';
            genderController.text = data['gender']?.toString() ?? '';
            ageController.text = data['age']?.toString() ?? '';
            weightController.text = data['weight']?.toString() ?? '';
            heightController.text = data['height']?.toString() ?? '';
          });
        }
      } else {
        debugPrint("DEBUG: Server Error ${response.statusCode}");
      }
    } catch (e) {
      debugPrint("DEBUG: Fetching failed: $e");
    } finally {
      if (mounted) setState(() => isFetching = false);
    }
  }

  Future<void> saveProfile() async {
    final token = await SecureStorage.readToken();
    if (token == null) return;

    setState(() => isSaving = true);

    try {
      final response = await http.patch(
        Uri.parse('http://localhost:8000/api/profile/'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'first_name': nameController.text,
          'age': int.tryParse(ageController.text),
          'gender': genderController.text,
          'weight': double.tryParse(weightController.text),
          'height': double.tryParse(heightController.text),
        }),
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Medical Record Updated Successfully')),
        );
      }
    } catch (e) {
      debugPrint("DEBUG: Update failed: $e");
    } finally {
      if (mounted) setState(() => isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isFetching) {
      return const Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text("Syncing with Clinical Records...", style: TextStyle(color: Colors.blueGrey)),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(title: const Text('Patient Medical File'), elevation: 0),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 900),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Core Health Metrics",
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF0057B7)),
                ),
                const SizedBox(height: 24),
                LayoutBuilder(
                  builder: (context, constraints) {
                    return GridView(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: constraints.maxWidth > 600 ? 2 : 1,
                        crossAxisSpacing: 20,
                        mainAxisExtent: 85,
                      ),
                      children: [
                        _buildField(nameController, 'Full Name', Icons.person_outline),
                        _buildField(genderController, 'Gender Identity', Icons.wc_outlined),
                        _buildField(ageController, 'Current Age', Icons.calendar_today_outlined, isNumber: true),
                        _buildField(weightController, 'Body Weight (kg)', Icons.monitor_weight_outlined, isNumber: true),
                        _buildField(heightController, 'Patient Height (cm)', Icons.height_outlined, isNumber: true),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 40),
                Center(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0057B7),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 18),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    onPressed: isSaving ? null : saveProfile,
                    icon: isSaving ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Icon(Icons.check_circle_outline),
                    label: Text(isSaving ? 'Saving...' : 'Confirm Update'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildField(TextEditingController controller, String label, IconData icon, {bool isNumber = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: controller,
        keyboardType: isNumber ? TextInputType.number : TextInputType.text,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, color: const Color(0xFF0057B7)),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          filled: true,
          fillColor: Colors.white,
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
        ),
      ),
    );
  }
}