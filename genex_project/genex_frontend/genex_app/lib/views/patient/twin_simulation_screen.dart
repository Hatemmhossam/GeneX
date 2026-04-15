<<<<<<< Updated upstream
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:model_viewer_plus/model_viewer_plus.dart';

=======
//Twin Simulation screen (placeholder)
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../../services/api_service.dart';
>>>>>>> Stashed changes
class TwinSimulationScreen extends StatefulWidget {
  const TwinSimulationScreen({super.key});

  @override
<<<<<<< Updated upstream
  State<TwinSimulationScreen> createState() => _TwinSimulationScreenState();
}

class _TwinSimulationScreenState extends State<TwinSimulationScreen> {
  final TextEditingController drugController = TextEditingController();

  String drugName = "No drug selected";
  String bestModel = "Unknown";
  String message = "";
  String fileUsed = "";

  double? combinedScore;
  double? rankScore;
  double? ic50;
  double? twinReduction;

  bool isLoading = false;
  String errorMessage = "";

  double markerX = 170;
  double markerY = 220;

  Future<void> analyzeDrug() async {
    final drug = drugController.text.trim();

    if (drug.isEmpty) {
      setState(() {
        errorMessage = "Please enter a drug name.";
      });
      return;
    }

    setState(() {
      isLoading = true;
      errorMessage = "";
    });

    try {
      final response = await http.post(
        Uri.parse('http://127.0.0.1:8000/api/analyze-drug/'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          "user_id": 2,
          "drug": drug,
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        setState(() {
          drugName = data['drug']?.toString() ?? drug;
          bestModel = data['best_model']?.toString() ?? "Unknown";
          message = data['message']?.toString() ?? "";
          fileUsed = data['file_used']?.toString() ?? "";

          combinedScore = data['combined_score'] != null
              ? double.tryParse(data['combined_score'].toString())
              : null;

          rankScore = data['rank_score'] != null
              ? double.tryParse(data['rank_score'].toString())
              : null;

          ic50 = data['ic50'] != null
              ? double.tryParse(data['ic50'].toString())
              : null;

          twinReduction = data['twin_reduction'] != null
              ? double.tryParse(data['twin_reduction'].toString())
              : null;

          markerX = (data['marker_x'] ?? 170).toDouble();
          markerY = (data['marker_y'] ?? 220).toDouble();
        });
      } else {
        setState(() {
          errorMessage = data['error']?.toString() ?? "Request failed.";
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = "Connection error: $e";
      });
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  Color getScoreColor() {
    if (combinedScore == null) return Colors.grey;
    if (combinedScore! >= 0.8) return Colors.green;
    if (combinedScore! >= 0.5) return Colors.orange;
    return Colors.red;
  }

  @override
  void dispose() {
    drugController.dispose();
    super.dispose();
  }

=======
  State<TwinSimulationScreen> createState() =>
      _TwinSimulationScreenState();
}

class _TwinSimulationScreenState
    extends State<TwinSimulationScreen> {
  String? filePath;

  final TextEditingController drug1Controller =
      TextEditingController();
  final TextEditingController drug2Controller =
      TextEditingController();

  Map<String, dynamic>? result;
  bool loading = false;

  // -------------------------
  // PICK CSV FILE
  // -------------------------
  Future<void> pickFile() async {
    final picked = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['csv'],
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
        const SnackBar(
          content: Text("Please upload patient CSV first"),
        ),
      );
      return;
    }

    if (drug1Controller.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please enter at least Drug 1"),
        ),
      );
      return;
    }

    setState(() => loading = true);

    try {
      final res = await ApiService().evaluateTwinSimulation(
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

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    }
  }

  // -------------------------
  // UI
  // -------------------------
>>>>>>> Stashed changes
  @override
  Widget build(BuildContext context) {
    final scoreColor = getScoreColor();

    return Scaffold(
      appBar: AppBar(
<<<<<<< Updated upstream
        title: const Text('Genetic Twin Simulation'),
      ),
      body: Stack(
        children: [
          ModelViewer(
            src: 'assets/models/dna.glb',
            variantName: 'red',
            alt: "DNA Model",
            backgroundColor: Colors.white,
            autoRotate: true,
            cameraControls: true,
            disableZoom: false,
            cameraOrbit: "0deg 75deg 10m",
            fieldOfView: "45deg",
          ),

          Positioned(
            top: markerY,
            left: markerX,
            child: Tooltip(
              message: drugName,
              child: Icon(
                Icons.location_on,
                color: scoreColor,
                size: 36,
              ),
            ),
          ),

          Positioned(
            top: 20,
            left: 20,
            right: 20,
            child: Material(
              elevation: 4,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.95),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: drugController,
                        onSubmitted: (_) => analyzeDrug(),
                        decoration: const InputDecoration(
                          hintText: "Enter drug name",
                          border: InputBorder.none,
                        ),
                      ),
                    ),
                    isLoading
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : IconButton(
                            icon: const Icon(Icons.search),
                            onPressed: analyzeDrug,
                          ),
                  ],
                ),
              ),
            ),
          ),

          if (errorMessage.isNotEmpty)
            Positioned(
              top: 95,
              left: 20,
              right: 20,
              child: Material(
                elevation: 2,
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.red.shade200),
                  ),
                  child: Text(
                    errorMessage,
                    style: TextStyle(color: Colors.red.shade700),
                  ),
                ),
              ),
            ),

          Positioned(
            bottom: 20,
            left: 20,
            right: 20,
            child: Card(
              color: Colors.white.withOpacity(0.95),
              elevation: 6,
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Drug: $drugName",
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text("Combined Score: ${combinedScore?.toStringAsFixed(4) ?? '-'}"),
                    const SizedBox(height: 6),
                    Text("Rank Score: ${rankScore?.toStringAsFixed(4) ?? '-'}"),
                    const SizedBox(height: 6),
                    Text("IC50: ${ic50?.toStringAsFixed(4) ?? '-'}"),
                    const SizedBox(height: 6),
                    Text("Twin Reduction: ${twinReduction?.toStringAsFixed(3) ?? '-'}%"),
                    const SizedBox(height: 6),
                    Text("Best Model: $bestModel"),
                    if (message.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text("Message: $message"),
                    ],
                    const SizedBox(height: 6),
                    Text(
                      "File: $fileUsed",
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
=======
        title: const Text("Twin Simulation"),
      ),
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
                "Selected: $filePath",
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

            ElevatedButton(
              onPressed: evaluate,
              child: const Text("Evaluate"),
            ),

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
                        style: const TextStyle(fontSize: 16),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
>>>>>>> Stashed changes
      ),
    );
  }
}