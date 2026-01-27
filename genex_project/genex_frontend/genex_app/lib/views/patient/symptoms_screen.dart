import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import '../../core/secure_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart'; // <--- MUST HAVE THIS
import '../../viewmodels/providers.dart'; 


class SymptomReportScreen extends ConsumerStatefulWidget {
  const SymptomReportScreen({super.key});

  @override
  ConsumerState<SymptomReportScreen> createState() => _SymptomReportScreenState();
}

class _SymptomReportScreenState extends ConsumerState<SymptomReportScreen> {
  // Use localhost for Chrome development
  final Dio _dio = Dio(BaseOptions(baseUrl: "http://localhost:8000/api/"));
  
  final _formKey = GlobalKey<FormState>();
  final _notesController = TextEditingController();
  
  bool _isAdding = false;
  String? _selectedSymptom;
  String _selectedFrequency = 'Occasionally';
  double _severity = 5.0; // Scale 0-10

  // Autoimmune specific symptoms
  final List<String> _autoimmuneSymptoms = [
    'Joint Pain / Stiffness',
    'Chronic Fatigue',
    'Muscle Weakness',
    'Skin Rash / Inflammation',
    'Digestive Issues (IBD)',
    'Brain Fog / Memory Loss',
    'Numbness / Tingling',
    'Sensitivity to Light',
    'Hair Loss',
  ];

  final List<String> _frequencies = ['Constantly', 'Daily', 'Occasionally', 'Rarely'];

  Future<void> _submitReport() async {
    if (!_formKey.currentState!.validate() || _selectedSymptom == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select a symptom")),
      );
      return;
    }

    setState(() => _isAdding = true);
    final token = await SecureStorage.readToken();

    try {
      final response = await _dio.post(
        'symptoms/',
        data: {
          "symptom_name": _selectedSymptom,
          "severity": _severity.toInt(),
          "frequency": _selectedFrequency,
          "notes": _notesController.text.trim(),
        },
        options: Options(headers: {"Authorization": "Bearer $token"}),
      );

      if (response.statusCode == 201) {
        ref.invalidate(symptomsProvider);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Symptom reported successfully")),
        );
        _notesController.clear();
        setState(() {
          _selectedSymptom = null;
          _severity = 5.0;
        });
      }
    } catch (e) {
      debugPrint("Symptom Add Error: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Failed to save report. Check connection.")),
      );
    } finally {
      setState(() => _isAdding = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Daily Symptom Tracker",
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const Text(
              "Tracking symptoms daily helps our AI calculate your risk score accurately.",
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 30),

            // Symptom Selection
            DropdownButtonFormField<String>(
              value: _selectedSymptom,
              decoration: InputDecoration(
                labelText: "What are you experiencing?",
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                prefixIcon: const Icon(Icons.sick),
              ),
              items: _autoimmuneSymptoms.map((s) {
                return DropdownMenuItem(value: s, child: Text(s));
              }).toList(),
              onChanged: (val) => setState(() => _selectedSymptom = val),
            ),
            const SizedBox(height: 25),

            // Severity Slider
            Text(
              "Severity Level: ${_severity.toInt()}/10",
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            

// [Image of visual analog scale for pain assessment]

            Slider(
              value: _severity,
              min: 0,
              max: 10,
              divisions: 10,
              label: _severity.round().toString(),
              activeColor: _severity > 7 ? Colors.red : Colors.teal,
              onChanged: (val) => setState(() => _severity = val),
            ),
            const Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("Mild", style: TextStyle(color: Colors.grey)),
                Text("Unbearable", style: TextStyle(color: Colors.grey)),
              ],
            ),
            const SizedBox(height: 25),

            // Frequency
            DropdownButtonFormField<String>(
              value: _selectedFrequency,
              decoration: InputDecoration(
                labelText: "How often?",
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                prefixIcon: const Icon(Icons.timer),
              ),
              items: _frequencies.map((f) {
                return DropdownMenuItem(value: f, child: Text(f));
              }).toList(),
              onChanged: (val) => setState(() => _selectedFrequency = val!),
            ),
            const SizedBox(height: 25),

            // Additional Notes
            TextFormField(
              controller: _notesController,
              maxLines: 3,
              decoration: InputDecoration(
                labelText: "Additional Notes (Triggers, duration, etc.)",
                hintText: "Example: Pain increases after eating gluten...",
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
            const SizedBox(height: 30),

            // Submit Button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: _isAdding ? null : _submitReport,
                child: _isAdding 
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text("Log Symptom", style: TextStyle(color: Colors.white, fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}