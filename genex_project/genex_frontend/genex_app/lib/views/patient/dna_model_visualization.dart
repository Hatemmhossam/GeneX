import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:model_viewer_plus/model_viewer_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DnaModelVisualizationScreen extends StatefulWidget {
  const DnaModelVisualizationScreen({super.key});

  @override
  State<DnaModelVisualizationScreen> createState() =>
      _DnaModelVisualizationScreenState();
}

class _DnaModelVisualizationScreenState
    extends State<DnaModelVisualizationScreen> {
  String dnaModelPath = 'assets/models/dna.glb';

  void updateDnaModel(double? risk) {
    String newPath;
    if (risk == null) return;

    if (risk < 30) {
      newPath = 'assets/models/dnagreen.glb';
    } else if (risk <= 70) {
      newPath = 'assets/models/dnaorange.glb';
    } else {
      newPath = 'assets/models/dnared.glb';
    }

    if (mounted && dnaModelPath != newPath) {
      setState(() {
        dnaModelPath = newPath;
      });
    }
  }

  Future<void> fetchUserRisk() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('access');

      if (token == null || token.isEmpty) {
        debugPrint("❌ No access token found");
        return;
      }

      final response = await http.get(
        Uri.parse('http://127.0.0.1:8000/api/get-user-risk/2/'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      debugPrint("GET USER RISK STATUS: ${response.statusCode}");
      debugPrint("GET USER RISK BODY: ${response.body}");

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        final rawRisk = data['risk_percentage'];
        double? risk;

        if (rawRisk is num) {
          risk = rawRisk.toDouble();
        } else if (rawRisk is String) {
          risk = double.tryParse(rawRisk);
        }

        debugPrint("🎯 SUCCESS! Risk is: $risk");
        updateDnaModel(risk);
      } else {
        debugPrint("❌ Server error: ${response.statusCode}");
      }
    } catch (e) {
      debugPrint("❌ Error fetching risk: $e");
    }
  }

  @override
  void initState() {
    super.initState();
    fetchUserRisk();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('DNA Model Visualization')),
      body: SizedBox.expand(
        child: ModelViewer(
          key: ValueKey(dnaModelPath),
          src: dnaModelPath,
          alt: "DNA Model",
          backgroundColor: Colors.white,
          autoRotate: true,
          cameraControls: true,
        ),
      ),
    );
  }
}
