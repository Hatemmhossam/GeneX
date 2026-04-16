import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../../services/api_service.dart';

//dahhh akherrr hagaaa
class TwinSimulationScreen extends StatefulWidget {
  const TwinSimulationScreen({super.key});

  @override
  State<TwinSimulationScreen> createState() => _TwinSimulationScreenState();
}

class _TwinSimulationScreenState extends State<TwinSimulationScreen> {
  String? filePath;

  final TextEditingController drug1Controller = TextEditingController();
  final TextEditingController drug2Controller = TextEditingController();

  Map<String, dynamic>? result;
  bool loading = false;

  // ✅ ADD API SERVICE
  final ApiService apiService = ApiService();

  // -------------------------
  // PICK CSV FILE
  // -------------------------
  Future<void> pickFile() async {
    final picked = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['csv', 'txt'],
    );

    if (picked != null) {
      setState(() {
        filePath = picked.files.single.path;
      });
    }
  }

  // -------------------------
  // SEND TO DJANGO
  // -------------------------
  Future<void> evaluate() async {
    if (filePath == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please upload patient CSV first")),
      );
      return;
    }

    if (drug1Controller.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter at least Drug 1")),
      );
      return;
    }

    setState(() => loading = true);

    try {
      // ✅ FIXED CALL (NO TwinService ANYMORE)
      final res = await apiService.evaluateTwinSimulation(
        filePath: filePath!,
        drug1: drug1Controller.text.trim(),
        drug2: drug2Controller.text.trim(),
      );

      setState(() {
        result = res;
        loading = false;
      });
    } catch (e) {
      setState(() => loading = false);

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error: $e")));
    }
  }

  // -------------------------
  // UI
  // -------------------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Twin Simulation")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            ElevatedButton(
              onPressed: pickFile,
              child: const Text("Upload Patient CSV"),
            ),

            const SizedBox(height: 10),

            if (filePath != null)
              Text(
                "Selected file loaded ✔",
                style: const TextStyle(fontSize: 12),
              ),

            const SizedBox(height: 20),

            TextField(
              controller: drug1Controller,
              decoration: const InputDecoration(
                labelText: "Drug 1",
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 10),

            TextField(
              controller: drug2Controller,
              decoration: const InputDecoration(
                labelText: "Drug 2 (optional)",
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 20),

            ElevatedButton(onPressed: evaluate, child: const Text("Evaluate")),

            const SizedBox(height: 20),

            if (loading) const CircularProgressIndicator(),

            if (result != null)
              Expanded(
                child: SingleChildScrollView(
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(
                        result.toString(),
                        style: const TextStyle(fontSize: 14),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
