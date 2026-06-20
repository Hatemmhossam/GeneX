import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../../services/api_service.dart';

class TwinPreviewScreen extends StatefulWidget {
  const TwinPreviewScreen({super.key});

  @override
  State<TwinPreviewScreen> createState() => _TwinPreviewScreenState();
}

class _TwinPreviewScreenState extends State<TwinPreviewScreen> {
  String selectedMode = "drug_gene";

  PlatformFile? selectedFile;

  final TextEditingController geneDrug1Controller = TextEditingController();
  final TextEditingController geneDrug2Controller = TextEditingController();

  Map<String, dynamic>? result;
  bool loading = false;

  final ApiService apiService = ApiService();

  final TextEditingController interactionDrug1Controller =
      TextEditingController();
  final TextEditingController interactionDrug2Controller =
      TextEditingController();

  String interactionResult = '';
  bool isInteractionLoading = false;

  @override
  void dispose() {
    geneDrug1Controller.dispose();
    geneDrug2Controller.dispose();
    interactionDrug1Controller.dispose();
    interactionDrug2Controller.dispose();
    super.dispose();
  }

  Future<void> pickFile() async {
    try {
      final picked = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['csv', 'txt'],
        withData: true,
      );

      if (picked != null && picked.files.isNotEmpty) {
        if (!mounted) return;

        setState(() {
          selectedFile = picked.files.single;
        });

        debugPrint("Picked file: ${selectedFile?.name}");
        debugPrint("Picked path: ${selectedFile?.path}");
        debugPrint("Picked bytes length: ${selectedFile?.bytes?.length}");
        debugPrint("Picked size: ${selectedFile?.size}");
      }
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("success")));
    }
  }

  Future<void> evaluate() async {
    if (selectedFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please upload the patient CSV first.")),
      );
      return;
    }

    if (geneDrug1Controller.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter at least Drug 1.")),
      );
      return;
    }

    setState(() => loading = true);

    try {
      await apiService.uploadGeneFile(file: selectedFile!);

      final drugs = [
        geneDrug1Controller.text.trim(),
        if (geneDrug2Controller.text.trim().isNotEmpty)
          geneDrug2Controller.text.trim(),
      ];

      final res = await apiService
          .runTwinSimulation(drugs: drugs)
          .timeout(const Duration(seconds: 120));

      if (!mounted) return;

      setState(() {
        result = res;
        loading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() => loading = false);

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error: $e")));
    }
  }

  Future<void> saveReport() async {
    if (result == null) return;

    try {
      await apiService.saveTwinReport(
        result: result!,
        drug1: geneDrug1Controller.text.trim(),
        drug2: geneDrug2Controller.text.trim(),
        fileName: selectedFile?.name ?? "",
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Report saved successfully")),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Save failed: $e")));
    }
  }

  Future<void> checkInteraction() async {
    final drug1 = interactionDrug1Controller.text.trim();
    final drug2 = interactionDrug2Controller.text.trim();

    if (drug1.isEmpty || drug2.isEmpty) {
      setState(() {
        interactionResult = 'Please enter both drug names.';
      });
      return;
    }

    setState(() {
      isInteractionLoading = true;
      interactionResult = '';
    });

    try {
      final response = await http.post(
        Uri.parse('http://127.0.0.1:8000/api/check-interaction/'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'drug1': drug1, 'drug2': drug2}),
      );

      final data = jsonDecode(response.body);

      setState(() {
        if (response.statusCode == 200) {
          if (data['found'] == true) {
            interactionResult =
                'Interaction found:\n\n$drug1 + $drug2\n\n${data['description'] ?? "-"}';
          } else {
            interactionResult = data['message'] ?? 'No interaction found.';
          }
        } else {
          interactionResult = data['error'] ?? 'Something went wrong.';
        }
      });
    } catch (e) {
      setState(() {
        interactionResult = 'Error: $e';
      });
    } finally {
      setState(() {
        isInteractionLoading = false;
      });
    }
  }

  String formatKey(String key) {
    return key
        .replaceAll('_', ' ')
        .replaceAll('-', ' ')
        .split(' ')
        .where((e) => e.trim().isNotEmpty)
        .map((word) => word[0].toUpperCase() + word.substring(1))
        .join(' ');
  }

  double getResultSectionHeight(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

    if (screenHeight < 700) return 500;
    if (screenHeight < 850) return 580;

    return 650;
  }

  Widget buildModeSelector() {
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () {
                setState(() {
                  selectedMode = "drug_gene";
                });
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  color: selectedMode == "drug_gene"
                      ? Colors.blue.shade600
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Text(
                  "Drug to Gene Interaction",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: selectedMode == "drug_gene"
                        ? Colors.white
                        : Colors.black87,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: GestureDetector(
              onTap: () {
                setState(() {
                  selectedMode = "drug_drug";
                });
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  color: selectedMode == "drug_drug"
                      ? Colors.blue.shade600
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Text(
                  "Drug to Drug Interaction",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: selectedMode == "drug_drug"
                        ? Colors.white
                        : Colors.black87,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget buildInputField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool optional = false,
  }) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: optional ? "$label (Optional)" : label,
        prefixIcon: Icon(icon),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 16,
        ),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
      ),
    );
  }

  Widget buildDrugGeneSection() {
    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(22),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Drug to Gene Interaction",
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            Text(
              "Upload a patient file, enter the selected drug(s), and review the TwinSimulation result.",
              style: TextStyle(
                fontSize: 13.5,
                color: Colors.grey.shade700,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: pickFile,
                icon: const Icon(Icons.upload_file_rounded),
                label: Text(
                  selectedFile == null ? "Upload Patient CSV" : "Change File",
                ),
                style: ElevatedButton.styleFrom(
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ),
            if (selectedFile != null) ...[
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.green.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.check_circle, color: Colors.green.shade700),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        "Selected file: ${selectedFile!.name}",
                        style: TextStyle(
                          color: Colors.green.shade800,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 16),
            buildInputField(
              controller: geneDrug1Controller,
              label: "Drug 1",
              icon: Icons.medication_rounded,
            ),
            const SizedBox(height: 12),
            buildInputField(
              controller: geneDrug2Controller,
              label: "Drug 2",
              icon: Icons.medication_outlined,
              optional: true,
            ),
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: loading ? null : evaluate,
                style: ElevatedButton.styleFrom(
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: loading
                    ? const SizedBox(
                        height: 22,
                        width: 22,
                        child: CircularProgressIndicator(strokeWidth: 2.4),
                      )
                    : const Text(
                        "Evaluate",
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildEmptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.analytics_outlined, size: 48, color: Colors.grey.shade500),
          const SizedBox(height: 12),
          const Text(
            "No evaluation yet",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          Text(
            "Run the simulation and the results will appear here.",
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey.shade700, fontSize: 13.5),
          ),
        ],
      ),
    );
  }

  Widget buildSummaryCard({
    required String title,
    required String value,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: Colors.blue.shade700),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(fontSize: 12.5, color: Colors.grey.shade700),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.bold,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget buildSummaryTab() {
    if (result == null) return const SizedBox.shrink();

    final best = result!["best_recommendation"];
    final xaiSummary = result!["xai_summary"];

    final fusionResults = result!["fusion_results"] is List
        ? result!["fusion_results"] as List
        : [];

    if (best == null) {
      return const Center(child: Text("No best recommendation found"));
    }

    String bestDrug = "-";

    if (best["drug_pair"] is List) {
      bestDrug = (best["drug_pair"] as List).join(" + ");
    } else if (best["drug"] != null) {
      bestDrug = best["drug"].toString();
    } else if (best["drug_name"] != null) {
      bestDrug = best["drug_name"].toString();
    }

    double? fusionScoreValue;

    if (fusionResults.isNotEmpty && fusionResults.first is Map) {
      final score = fusionResults.first["fusion_score"];

      if (score is num) {
        fusionScoreValue = score.toDouble();
      } else if (score != null) {
        fusionScoreValue = double.tryParse(score.toString());
      }
    } else if (best["fusion_score"] is num) {
      fusionScoreValue = (best["fusion_score"] as num).toDouble();
    } else if (best["fusion_score"] != null) {
      fusionScoreValue = double.tryParse(best["fusion_score"].toString());
    }

    final String fusionScore = fusionScoreValue != null
        ? fusionScoreValue.toStringAsFixed(4)
        : "-";

    final bool isNotRecommended =
        fusionScoreValue != null && fusionScoreValue < 0.6;

    return ListView(
      children: [
        buildSummaryCard(
          title: "Recommendation Status",
          value: isNotRecommended ? "Not Recommended" : "Recommended",
          icon: isNotRecommended
              ? Icons.warning_rounded
              : Icons.check_circle_rounded,
        ),
        const SizedBox(height: 12),
        buildSummaryCard(
          title: isNotRecommended ? "Drug Evaluated" : "Best Drug",
          value: bestDrug,
          icon: Icons.star_rounded,
        ),
        const SizedBox(height: 12),
        buildSummaryCard(
          title: "Fusion Score",
          value: fusionScore,
          icon: Icons.auto_graph_rounded,
        ),
        if (isNotRecommended) ...[
          const SizedBox(height: 12),
          buildSummaryCard(
            title: "Reason",
            value:
                "The fusion score is below 0.6, so this drug is not recommended based on the current TwinSimulation analysis.",
            icon: Icons.info_outline_rounded,
          ),
        ],
        if (!isNotRecommended &&
            xaiSummary is Map &&
            xaiSummary["available"] == true) ...[
          const SizedBox(height: 12),
          buildSummaryCard(
            title: "XAI Explanation",
            value: xaiSummary["final_explanation"]?.toString() ?? "-",
            icon: Icons.psychology_rounded,
          ),
          const SizedBox(height: 12),
          buildSummaryCard(
            title: "Top Genes",
            value: formatXaiGenes(xaiSummary["top_genes"]),
            icon: Icons.biotech_rounded,
          ),
          const SizedBox(height: 12),
          buildSummaryCard(
            title: "Top Pathways",
            value: formatXaiPathways(xaiSummary["top_pathways"]),
            icon: Icons.account_tree_rounded,
          ),
        ] else if (!isNotRecommended && xaiSummary is Map) ...[
          const SizedBox(height: 12),
          buildSummaryCard(
            title: "XAI Explanation",
            value:
                xaiSummary["message"]?.toString() ??
                "XAI explanation is not available.",
            icon: Icons.info_outline_rounded,
          ),
        ],
      ],
    );
  }

  String formatXaiGenes(dynamic genes) {
    if (genes == null || genes is! List || genes.isEmpty) {
      return "-";
    }

    return genes
        .map((gene) {
          if (gene is Map) {
            final name = gene["gene"]?.toString() ?? "-";
            final importance = gene["importance"];

            if (importance is num) {
              return "$name (${importance.toStringAsFixed(4)})";
            }

            return name;
          }

          return gene.toString();
        })
        .join(", ");
  }

  String formatXaiPathways(dynamic pathways) {
    if (pathways == null || pathways is! List || pathways.isEmpty) {
      return "-";
    }

    return pathways
        .map((pathway) {
          if (pathway is Map) {
            final name = pathway["pathway"]?.toString() ?? "-";
            final score = pathway["score"];

            if (score is num) {
              return "$name (${score.toStringAsFixed(4)})";
            }

            return name;
          }

          return pathway.toString();
        })
        .join(", ");
  }

  Widget buildDetailsTab() {
    if (result == null) {
      return const Center(child: Text("No results available"));
    }

    final fusionResults = result!["fusion_results"] is List
        ? result!["fusion_results"] as List
        : [];

    final singleResults = result!["single_results"] is List
        ? result!["single_results"] as List
        : [];

    final pairResults = result!["pair_results"] is List
        ? result!["pair_results"] as List
        : [];

    final bestRecommendation = result!["best_recommendation"];

    double? bestFusionScore;

    if (fusionResults.isNotEmpty && fusionResults.first is Map) {
      final score = fusionResults.first["fusion_score"];

      if (score is num) {
        bestFusionScore = score.toDouble();
      } else if (score != null) {
        bestFusionScore = double.tryParse(score.toString());
      }
    }

    final bool isNotRecommended =
        bestFusionScore != null && bestFusionScore < 0.6;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        buildBestRecommendationCard(
          bestRecommendation: bestRecommendation,
          bestFusionScore: bestFusionScore,
          isNotRecommended: isNotRecommended,
        ),
        const SizedBox(height: 16),
        if (fusionResults.isNotEmpty) ...[
          const Text(
            "Drug Details",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          ...fusionResults.map((item) {
            if (item is! Map) return const SizedBox.shrink();

            final drugName = item["drug_name"]?.toString() ?? "-";

            dynamic matchingSingle;

            for (final single in singleResults) {
              if (single is Map &&
                  single["drug_name"]?.toString().toLowerCase() ==
                      drugName.toLowerCase()) {
                matchingSingle = single;
                break;
              }
            }

            final fusionScore = item["fusion_score"] is num
                ? (item["fusion_score"] as num).toStringAsFixed(4)
                : item["fusion_score"]?.toString() ?? "-";

            final topPathway = item["top_pathway"]?.toString() ?? "-";

            final pathwayHits =
                item["pathway_hits"] ?? matchingSingle?["pathway_hits"];

            final targets =
                item["valid_targets"] ?? matchingSingle?["valid_targets"];

            return buildDrugResultCard(
              drugName: drugName,
              fusionScore: fusionScore,
              topPathway: topPathway,
              pathwayHits: pathwayHits,
              targets: targets,
            );
          }).toList(),
        ],
        if (pairResults.isNotEmpty) ...[
          const SizedBox(height: 20),
          const Text(
            "Combination Details",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          ...pairResults.map((pair) {
            if (pair is! Map) return const SizedBox.shrink();

            return buildCombinationCard(pair);
          }).toList(),
        ],
      ],
    );
  }

  Widget buildResultSection() {
    return SizedBox(
      height: getResultSectionHeight(context),
      child: DefaultTabController(
        length: 2,
        child: Column(
          children: [
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: const TabBar(
                labelColor: Colors.black,
                unselectedLabelColor: Colors.grey,
                indicatorSize: TabBarIndicatorSize.tab,
                tabs: [
                  Tab(text: "Summary"),
                  Tab(text: "Details"),
                ],
              ),
            ),
            const SizedBox(height: 14),
            Expanded(
              child: TabBarView(
                children: [buildSummaryTab(), buildDetailsTab()],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildBestRecommendationCard({
    required dynamic bestRecommendation,
    required double? bestFusionScore,
    required bool isNotRecommended,
  }) {
    String bestDrug = "-";
    String scoreText = bestFusionScore != null
        ? bestFusionScore.toStringAsFixed(4)
        : "-";

    if (bestRecommendation is Map) {
      if (bestRecommendation["drug_pair"] is List) {
        bestDrug = (bestRecommendation["drug_pair"] as List).join(" + ");
      } else if (bestRecommendation["drug"] != null) {
        bestDrug = bestRecommendation["drug"].toString();
      } else if (bestRecommendation["drug_name"] != null) {
        bestDrug = bestRecommendation["drug_name"].toString();
      }
    }

    return Card(
      elevation: 0,
      color: isNotRecommended ? Colors.red.shade50 : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(
          color: isNotRecommended ? Colors.red.shade200 : Colors.grey.shade200,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Best Recommendation",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            if (isNotRecommended) ...[
              Text(
                "Not Recommended",
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: Colors.red.shade700,
                ),
              ),
              const SizedBox(height: 8),
            ],
            buildDetailRow("Drug", bestDrug),
            buildDetailRow("Fusion Score", scoreText),
          ],
        ),
      ),
    );
  }

  Widget buildDrugResultCard({
    required String drugName,
    required String fusionScore,
    required String topPathway,
    required dynamic pathwayHits,
    required dynamic targets,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              drugName,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 14),
            buildDetailRow("Fusion Score", fusionScore),
            buildDetailRow("Top Pathway", topPathway),
            buildDetailRow("Pathway Hits", formatCleanValue(pathwayHits)),
            const SizedBox(height: 12),
            const Text(
              "Targets",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
            ),
            const SizedBox(height: 8),
            Text(
              formatCleanValue(targets),
              style: const TextStyle(fontSize: 14, height: 1.4),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildCombinationCard(dynamic pair) {
    final drugPair = pair["drug_pair"] is List
        ? (pair["drug_pair"] as List).join(" + ")
        : "-";

    final riskReduction = pair["risk_reduction_pct"] is num
        ? "${(pair["risk_reduction_pct"] as num).toStringAsFixed(2)}%"
        : pair["risk_reduction_pct"]?.toString() ?? "-";

    final pathwayHits = pair["pathway_hits"];
    final targets = pair["valid_targets"];

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Combination",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            buildDetailRow("Drug Pair", drugPair),
            buildDetailRow("Risk Reduction", riskReduction),
            buildDetailRow("Pathway Hits", formatCleanValue(pathwayHits)),
            const SizedBox(height: 12),
            const Text(
              "Combined Targets",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
            ),
            const SizedBox(height: 8),
            Text(
              formatCleanValue(targets),
              style: const TextStyle(fontSize: 14, height: 1.4),
            ),
          ],
        ),
      ),
    );
  }

  String formatCleanValue(dynamic value) {
    if (value == null) return "-";

    if (value is List) {
      if (value.isEmpty) return "-";
      return value.map((e) => e.toString()).join(", ");
    }

    if (value is Map) {
      if (value.isEmpty) return "-";
      return value.entries
          .map((entry) => "${entry.key}: ${entry.value}")
          .join(", ");
    }

    return value.toString();
  }

  Widget buildDetailRow(String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              "$title:",
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(child: Text(value, style: const TextStyle(height: 1.4))),
        ],
      ),
    );
  }

  Widget buildDrugDrugSection() {
    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(22),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Drug to Drug Interaction",
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            Text(
              "Enter two drug names to check whether there is an interaction between them.",
              style: TextStyle(
                fontSize: 13.5,
                color: Colors.grey.shade700,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 18),
            buildInputField(
              controller: interactionDrug1Controller,
              label: "Enter first drug",
              icon: Icons.medication_rounded,
            ),
            const SizedBox(height: 12),
            buildInputField(
              controller: interactionDrug2Controller,
              label: "Enter second drug",
              icon: Icons.medication_outlined,
            ),
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: isInteractionLoading ? null : checkInteraction,
                style: ElevatedButton.styleFrom(
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: isInteractionLoading
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(strokeWidth: 2.4),
                      )
                    : const Text(
                        "Check Interaction",
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 20),
            Container(
              width: double.infinity,
              constraints: const BoxConstraints(minHeight: 180),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: SingleChildScrollView(
                child: Text(
                  interactionResult.isEmpty
                      ? "The interaction result will appear here."
                      : interactionResult,
                  style: TextStyle(
                    fontSize: 15,
                    height: 1.5,
                    color: interactionResult.isEmpty
                        ? Colors.grey.shade600
                        : Colors.black87,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isDrugGeneMode = selectedMode == "drug_gene";

    return Scaffold(
      backgroundColor: const Color(0xffF6F8FB),
      appBar: AppBar(elevation: 0, title: const Text("Twin Simulation")),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              buildModeSelector(),
              const SizedBox(height: 16),
              if (isDrugGeneMode)
                buildDrugGeneSection()
              else
                buildDrugDrugSection(),
              const SizedBox(height: 16),
              if (isDrugGeneMode) ...[
                if (result != null) ...[
                  buildResultSection(),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: saveReport,
                    icon: const Icon(Icons.save_alt_rounded),
                    label: const Text("Save Report"),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ] else
                  buildEmptyState(),
              ],
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
