import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class PatientMedicalHistoryScreen extends StatefulWidget {
  final int patientId;
  final String patientName;

  const PatientMedicalHistoryScreen({
    super.key, 
    required this.patientId, 
    required this.patientName
  });

  @override
  State<PatientMedicalHistoryScreen> createState() => _PatientMedicalHistoryScreenState();
}

class _PatientMedicalHistoryScreenState extends State<PatientMedicalHistoryScreen> {
  List<dynamic> medicines = [];
  List<dynamic> symptoms = []; 
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchPatientData();
  }

  // --- 1. FETCH DATA FROM DJANGO ---
  Future<void> _fetchPatientData() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    // ⚠️ IMPORTANT: If using Android Emulator, use '10.0.2.2'. If Real Device, use your PC's IP.
    final url = Uri.parse('http://127.0.0.1:8000/api/doctor/patient-records/${widget.patientId}/');

    try {
      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          medicines = data['medicines'] ?? [];
          symptoms = data['symptoms'] ?? [];
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = "Access Denied or Error: ${response.statusCode}";
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = "Connection Error: $e";
        _isLoading = false;
      });
    }
  }

  // --- 2. SHOW DIALOG TO WRITE NOTE ---
  Future<void> _showNoteDialog(int symptomId, String currentNotes) async {
    TextEditingController noteController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Add Doctor Note"),
          content: TextField(
            controller: noteController,
            decoration: const InputDecoration(
              hintText: "Enter instructions or observations...",
              border: OutlineInputBorder(),
            ),
            maxLines: 3,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () async {
                if (noteController.text.isNotEmpty) {
                  Navigator.pop(context); // Close dialog first
                  await _saveDoctorNote(symptomId, noteController.text);
                }
              },
              child: const Text("Save"),
            ),
          ],
        );
      },
    );
  }

  // --- 3. SEND NOTE TO API ---
  Future<void> _saveDoctorNote(int symptomId, String note) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    
    // ✅ Ensure this URL matches your Django urls.py
    final url = Uri.parse('http://127.0.0.1:8000/api/doctor/add-note/$symptomId/');

    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'note': note}),
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Note Saved!")));
        // Refresh data to show the new note immediately
        _fetchPatientData(); 
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: ${response.statusCode}")));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Connection Error: $e")));
    }
  }

  // --- 4. BUILD UI ---
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Medical Records: ${widget.patientName}")),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(child: Text(_errorMessage!, style: const TextStyle(color: Colors.red)))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // --- MEDICINES SECTION ---
                      const Text("💊 Medicines", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 10),
                      medicines.isEmpty
                          ? const Text("No medicines recorded.")
                          : ListView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: medicines.length,
                              itemBuilder: (context, index) {
                                final med = medicines[index];
                                return Card(
                                  elevation: 2,
                                  margin: const EdgeInsets.only(bottom: 8),
                                  child: ListTile(
                                    leading: const Icon(Icons.medication, color: Colors.blue),
                                    title: Text(med['name'] ?? 'Unknown Drug', style: const TextStyle(fontWeight: FontWeight.bold)),
                                    subtitle: Text("Added: ${med['added_at']?.toString().split('T')[0]}"),
                                  ),
                                );
                              },
                            ),

                      const SizedBox(height: 25),
                      const Divider(thickness: 2),
                      const SizedBox(height: 10),

                      // --- SYMPTOMS SECTION ---
                      const Text("⚠️ Symptoms", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 10),
                      symptoms.isEmpty
                          ? const Text("No symptoms reported.")
                          : ListView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: symptoms.length,
                              itemBuilder: (context, index) {
                                final sym = symptoms[index];
                                return Card(
                                  color: Colors.orange.shade50,
                                  elevation: 2,
                                  margin: const EdgeInsets.only(bottom: 8),
                                  child: Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: Column(
                                      children: [
                                        ListTile(
                                          leading: const Icon(Icons.warning_amber_rounded, color: Colors.orange),
                                          title: Text(
                                            sym['symptom_name'] ?? sym['symptom'] ?? 'Unknown',
                                            style: const TextStyle(fontWeight: FontWeight.bold),
                                          ),
                                          subtitle: Text("Severity: ${sym['severity']}/10"),
                                          // ✅ EDIT BUTTON
                                          trailing: IconButton(
                                            icon: const Icon(Icons.edit_note, color: Colors.blue, size: 30),
                                            onPressed: () {
                                              _showNoteDialog(sym['id'], sym['notes'] ?? "");
                                            },
                                          ),
                                        ),
                                        
                                        // ✅ DISPLAY NOTES IF THEY EXIST
                                        if (sym['notes'] != null && sym['notes'].toString().isNotEmpty)
                                          Container(
                                            width: double.infinity,
                                            margin: const EdgeInsets.only(top: 5, left: 10, right: 10),
                                            padding: const EdgeInsets.all(8),
                                            decoration: BoxDecoration(
                                              color: Colors.white,
                                              borderRadius: BorderRadius.circular(8),
                                              border: Border.all(color: Colors.grey.shade300),
                                            ),
                                            child: Text(
                                              "📝 Notes:\n${sym['notes']}", 
                                              style: TextStyle(color: Colors.grey[800], fontSize: 13),
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                    ],
                  ),
                ),
    );
  }
}