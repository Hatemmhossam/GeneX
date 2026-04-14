import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:model_viewer_plus/model_viewer_plus.dart';
import 'package:flutter/foundation.dart';

class TwinSimulationScreen extends StatefulWidget {
  const TwinSimulationScreen({super.key});

  @override
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

  String dnaModelPath = 'assets/models/dna.glb';

  // ✅ DNA MODEL SWITCHING
  void updateDnaModel(double? risk) {
  String newPath;

  if (risk == null) {
    newPath = kIsWeb
        ? 'assets/assets/models/dna.glb'
        : 'assets/models/dna.glb';
  } else if (risk < 30) {
    newPath = kIsWeb
        ? 'assets/assets/models/dnagreen.glb'
        : 'assets/models/dnagreen.glb';
  } else if (risk <= 70) {
    newPath = kIsWeb
        ? 'assets/assets/models/dnaorange.glb'
        : 'assets/models/dnaorange.glb';
  } else {
    newPath = kIsWeb
        ? 'assets/assets/models/dnared.glb'
        : 'assets/models/dnared.glb';
  }

  print("RISK: $risk");
  print("NEW MODEL: $newPath");

  if (dnaModelPath != newPath) {
    setState(() {
      dnaModelPath = newPath;
    });
  }
}
  // ✅ FETCH RISK FROM DATABASE API
  Future<void> fetchUserRisk() async {
  try {
    final response = await http.get(
      Uri.parse('http://127.0.0.1:8000/api/get-user-risk/2/'),
    );

    // 1. Check if the status code is 200 (Success)
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      double? risk = double.tryParse(data['risk_percentage']?.toString() ?? '');
      updateDnaModel(risk);
    } else {
      // 2. If it's HTML, this will print the error page so you can read it
      print("❌ Server Error (${response.statusCode}): ${response.body}");
    }
  } catch (e) {
    print("❌ Connection error: $e");
  }
}

  // ✅ DRUG ANALYSIS
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

      print("FULL API RESPONSE: $data");

      if (response.statusCode == 200) {
        setState(() {
          drugName = data['drug']?.toString() ?? drug;
          bestModel = data['best_model']?.toString() ?? "Unknown";
          message = data['message']?.toString() ?? "";
          fileUsed = data['file_used']?.toString() ?? "";

          combinedScore = double.tryParse(data['combined_score']?.toString() ?? '');
          rankScore = double.tryParse(data['rank_score']?.toString() ?? '');
          ic50 = double.tryParse(data['ic50']?.toString() ?? '');
          twinReduction = double.tryParse(data['twin_reduction']?.toString() ?? '');

          markerX = (data['marker_x'] ?? 170).toDouble();
          markerY = (data['marker_y'] ?? 220).toDouble();
        });

        // ✅ AFTER DRUG → FETCH RISK FROM DB
        await fetchUserRisk();

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

  // ✅ COLOR FOR MARKER
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
  @override
void initState() {
  super.initState();
  // Fetch the risk as soon as the screen opens
  fetchUserRisk();
}
  @override
  Widget build(BuildContext context) {
    final scoreColor = getScoreColor();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Genetic Twin Simulation'),
      ),
      body: Stack(
        children: [
          // ✅ FORCE MODEL REBUILD
       Positioned.fill(
      child: SizedBox.expand(
      child: ModelViewer(
      key: UniqueKey(),
      src: dnaModelPath,
      alt: "DNA Model",
      autoRotate: true,
      cameraControls: true,
      ar: false,
      backgroundColor: Colors.white,
      shadowIntensity: 1.0,
      exposure: 1.2,
      cameraOrbit: "0deg 75deg 10m",
      fieldOfView: "45deg",
    ),
  ),
),

          // 📍 MARKER
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

          // 🔍 SEARCH BAR
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

          // ❌ ERROR
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

          // 📊 DATA CARD
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
      ),
    );
  }
}