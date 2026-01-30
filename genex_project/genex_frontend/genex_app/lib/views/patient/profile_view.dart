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
  final nameController = TextEditingController();
  
  // State variables to hold dropdown values
  String selectedGender = 'male';
  int selectedAge = 18;
  int selectedHeight = 160;
  int selectedWeight = 60;

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
    super.dispose();
  }

  Future<void> fetchProfile() async {
    final token = await SecureStorage.readToken();
    if (token == null) {
      if (mounted) setState(() => isFetching = false);
      return;
    }

    try {
      final url = Uri.parse('http://localhost:8000/api/profile/');
      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (mounted) {
          setState(() {
            // Read-only name
            nameController.text = data['first_name']?.toString() ?? data['username'] ?? '';
            
            // Dropdown initial values from server (with null safety)
            selectedGender = data['gender']?.toString().toLowerCase() ?? 'male';
            selectedAge = data['age'] != null ? (data['age'] as int) : 18;
            selectedHeight = data['height'] != null ? (data['height'] as num).toInt() : 160;
            selectedWeight = data['weight'] != null ? (data['weight'] as num).toInt() : 60;
          });
        }
      }
    } catch (e) {
      debugPrint("Fetch error: $e");
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
          'age': selectedAge,
          'gender': selectedGender,
          'weight': selectedWeight.toDouble(),
          'height': selectedHeight.toDouble(),
          // first_name is not sent because it is read-only
        }),
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Medical Record Updated Successfully')),
        );
      }
    } catch (e) {
      debugPrint("Update error: $e");
    } finally {
      if (mounted) setState(() => isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isFetching) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
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
                
                // 1. Fixed Name Field (Read Only)
                _buildReadOnlyField(nameController, 'Full Name', Icons.lock_outline),
                
                const SizedBox(height: 20),

                // 2. Interactive Dropdowns
                LayoutBuilder(builder: (context, constraints) {
                  return GridView(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: constraints.maxWidth > 600 ? 2 : 1,
                      crossAxisSpacing: 20,
                      mainAxisExtent: 90,
                    ),
                    children: [
                      // GENDER
                      _buildDropdown<String>(
                        label: 'Gender Identity',
                        icon: Icons.wc_outlined,
                        value: selectedGender,
                        items: const ['male', 'female'],
                        onChanged: (val) => setState(() => selectedGender = val!),
                      ),
                      // AGE
                      _buildDropdown<int>(
                        label: 'Current Age',
                        icon: Icons.calendar_today_outlined,
                        value: selectedAge,
                        items: List.generate(83, (i) => i + 18),
                        onChanged: (val) => setState(() => selectedAge = val!),
                      ),
                      // HEIGHT
                      _buildDropdown<int>(
                        label: 'Patient Height (cm)',
                        icon: Icons.height_outlined,
                        value: selectedHeight,
                        items: List.generate(91, (i) => i + 120),
                        onChanged: (val) => setState(() => selectedHeight = val!),
                        suffix: ' cm',
                      ),
                      // WEIGHT
                      _buildDropdown<int>(
                        label: 'Body Weight (kg)',
                        icon: Icons.monitor_weight_outlined,
                        value: selectedWeight,
                        items: List.generate(141, (i) => i + 30),
                        onChanged: (val) => setState(() => selectedWeight = val!),
                        suffix: ' kg',
                      ),
                    ],
                  );
                }),

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
                    icon: isSaving 
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) 
                      : const Icon(Icons.check_circle_outline),
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

  // UI Helper for the Read Only Name
  Widget _buildReadOnlyField(TextEditingController controller, String label, IconData icon) {
    return TextField(
      controller: controller,
      readOnly: true,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: Colors.grey),
        filled: true,
        fillColor: Colors.grey.shade100,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        helperText: "Contact Admin to change legal name",
      ),
    );
  }

  // UI Helper for Dropdowns
  Widget _buildDropdown<T>({
    required String label,
    required IconData icon,
    required T value,
    required List<T> items,
    required ValueChanged<T?> onChanged,
    String suffix = "",
  }) {
    return DropdownButtonFormField<T>(
      value: value,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: const Color(0xFF0057B7)),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
        fillColor: Colors.white,
      ),
      items: items.map((item) {
        return DropdownMenuItem<T>(
          value: item,
          child: Text(item.toString() + suffix),
        );
      }).toList(),
      onChanged: onChanged,
    );
  }
}