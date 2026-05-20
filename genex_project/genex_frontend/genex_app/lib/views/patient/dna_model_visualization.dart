import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:model_viewer_plus/model_viewer_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:genex_app/l10n/app_localizations.dart';
//done
class DnaModelVisualizationScreen extends StatefulWidget {
  const DnaModelVisualizationScreen({super.key});

  @override
  State<DnaModelVisualizationScreen> createState() =>
      _DnaModelVisualizationScreenState();
}

class _DnaModelVisualizationScreenState
    extends State<DnaModelVisualizationScreen> {
  String dnaModelPath =
      'assets/models/dna.glb';

  double? riskPercentage;

  void updateDnaModel(double? risk) {
    String newPath;

    if (risk == null) return;

    if (risk < 30) {
      newPath =
          'assets/models/dnagreen.glb';
    } else if (risk <= 70) {
      newPath =
          'assets/models/dnaorange.glb';
    } else {
      newPath =
          'assets/models/dnared.glb';
    }

    if (mounted &&
        dnaModelPath != newPath) {
      setState(() {
        dnaModelPath = newPath;
        riskPercentage = risk;
      });
    }
  }

  Future<void> fetchUserRisk() async {
    try {
      final prefs =
          await SharedPreferences
              .getInstance();

      final token =
          prefs.getString('access');

      if (token == null ||
          token.isEmpty) {
        debugPrint(
          "❌ No access token found",
        );
        return;
      }

      final response = await http.get(
        Uri.parse(
          'http://127.0.0.1:8000/api/get-user-risk/2/',
        ),
        headers: {
          'Authorization':
              'Bearer $token',
          'Content-Type':
              'application/json',
        },
      );

      debugPrint(
        "GET USER RISK STATUS: ${response.statusCode}",
      );

      debugPrint(
        "GET USER RISK BODY: ${response.body}",
      );

      if (response.statusCode == 200) {
        final data =
            jsonDecode(response.body);

        final rawRisk =
            data['risk_percentage'];

        double? risk;

        if (rawRisk is num) {
          risk = rawRisk.toDouble();
        } else if (rawRisk is String) {
          risk = double.tryParse(
            rawRisk,
          );
        }

        debugPrint(
          "🎯 SUCCESS! Risk is: $risk",
        );

        updateDnaModel(risk);
      } else {
        debugPrint(
          "❌ Server error: ${response.statusCode}",
        );
      }
    } catch (e) {
      debugPrint(
        "❌ Error fetching risk: $e",
      );
    }
  }

  String getRiskLevelText(
    BuildContext context,
  ) {
    final loc =
        AppLocalizations.of(context)!;

    if (riskPercentage == null) {
      return loc.loading;
    }

    if (riskPercentage! < 30) {
      return loc.lowRisk;
    } else if (riskPercentage! <= 70) {
      return loc.mediumRisk;
    } else {
      return loc.highRisk;
    }
  }

  Color getRiskColor() {
    if (riskPercentage == null) {
      return Colors.grey;
    }

    if (riskPercentage! < 30) {
      return Colors.green;
    } else if (riskPercentage! <= 70) {
      return Colors.orange;
    } else {
      return Colors.red;
    }
  }

  @override
  void initState() {
    super.initState();
    fetchUserRisk();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final loc =
        AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor:
          theme.scaffoldBackgroundColor,
      appBar: AppBar(
        elevation: 0,
        title: Text(
          loc.dnaModelVisualization,
          style: TextStyle(
            fontWeight:
                FontWeight.bold,
            color:
                theme.colorScheme.onSurface,
          ),
        ),
        backgroundColor:
            theme.appBarTheme
                .backgroundColor,
        foregroundColor:
            theme.colorScheme.onSurface,
      ),
      body: Column(
        children: [
          Container(
            margin:
                const EdgeInsets.all(
                    16),
            padding:
                const EdgeInsets.all(
                    18),
            decoration: BoxDecoration(
              color:
                  theme.colorScheme.surface,
              borderRadius:
                  BorderRadius.circular(
                      18),
              border: Border.all(
                color: theme
                    .dividerColor
                    .withOpacity(0.15),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black
                      .withOpacity(0.04),
                  blurRadius: 8,
                  offset:
                      const Offset(0, 3),
                ),
              ],
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor:
                      getRiskColor()
                          .withOpacity(
                              0.15),
                  child: Icon(
                    Icons.biotech,
                    color:
                        getRiskColor(),
                    size: 30,
                  ),
                ),
                const SizedBox(
                    width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment
                            .start,
                    children: [
                      Text(
                        loc.currentRiskLevel,
                        style: TextStyle(
                          fontSize: 14,
                          color: theme
                              .colorScheme
                              .onSurface
                              .withOpacity(
                                  0.65),
                        ),
                      ),
                      const SizedBox(
                          height: 4),
                      Text(
                        getRiskLevelText(
                            context),
                        style:
                            TextStyle(
                          fontSize: 20,
                          fontWeight:
                              FontWeight
                                  .bold,
                          color:
                              getRiskColor(),
                        ),
                      ),
                      if (riskPercentage !=
                          null)
                        Padding(
                          padding:
                              const EdgeInsets.only(
                            top: 4,
                          ),
                          child: Text(
                            "${riskPercentage!.toStringAsFixed(1)}%",
                            style:
                                TextStyle(
                              fontSize:
                                  15,
                              color: theme
                                  .colorScheme
                                  .onSurface,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          Expanded(
            child: Padding(
              padding:
                  const EdgeInsets.only(
                left: 16,
                right: 16,
                bottom: 16,
              ),
              child: ClipRRect(
                borderRadius:
                    BorderRadius.circular(
                        20),
                child: ModelViewer(
                  key: ValueKey(
                    dnaModelPath,
                  ),
                  src: dnaModelPath,
                  alt: loc.dnaModel,
                  backgroundColor:
                      Colors.white,
                  autoRotate: true,
                  cameraControls: true,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}