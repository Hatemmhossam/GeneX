import 'dart:convert';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../services/api_service.dart';

class TwinPreviewScreen extends StatefulWidget {
  const TwinPreviewScreen({super.key});

  @override
  State<TwinPreviewScreen> createState() => _TwinPreviewScreenState();
}

class _TwinPreviewScreenState extends State<TwinPreviewScreen> {
  String selectedMode = "drug_gene"; // drug_gene / drug_drug

  // =========================
  // DRUG TO GENE
  // =========================
  PlatformFile? selectedFile;

  final TextEditingController geneDrug1Controller = TextEditingController();
  final TextEditingController geneDrug2Controller = TextEditingController();

  Map<String, dynamic>? result;
  bool loading = false;

  final ApiService apiService = ApiService();

  // =========================
  // DRUG TO DRUG
  // =========================
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

  // =========================
  // DRUG TO GENE LOGIC
  // =========================
  Future<void> pickFile() async {
    try {
      final picked = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['csv', 'txt'],
        withData: kIsWeb,
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
      ).showSnackBar(SnackBar(content: Text("File selection failed: $e")));
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
      final res = await apiService
          .evaluateTwinSimulation(
            file: selectedFile!,
            drug1: geneDrug1Controller.text.trim(),
            drug2: geneDrug2Controller.text.trim(),
          )
          .timeout(const Duration(seconds: 30));

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

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Report saved successfully")),
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Save failed: $e")));
    }
  }

  // =========================
  // DRUG TO DRUG LOGIC
  // =========================
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
                'Interaction found:\n\n${data['drug1']} + ${data['drug2']}\n\n${data['description']}';
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

  // =========================
  // HELPERS
  // =========================
  String formatKey(String key) {
    return key
        .replaceAll('_', ' ')
        .replaceAll('-', ' ')
        .split(' ')
        .where((e) => e.trim().isNotEmpty)
        .map((word) => word[0].toUpperCase() + word.substring(1))
        .join(' ');
  }

  bool isPrimitive(dynamic value) {
    return value == null || value is String || value is num || value is bool;
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

  // =========================
  // DRUG TO GENE UI
  // =========================
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
              "Upload a patient file, enter the selected drug(s), and review the result in a cleaner structured layout.",
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
            "Run the simulation and the results will appear here in a more readable format.",
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

    if (best == null) {
      return const Center(child: Text("No best recommendation found"));
    }

    return ListView(
      children: [
        buildSummaryCard(
          title: "Best Drug",
          value: best["drug"]?.toString() ?? "-",
          icon: Icons.star_rounded,
        ),
        const SizedBox(height: 12),
        buildSummaryCard(
          title: "Risk Reduction (%)",
          value: best["risk_reduction"]?.toStringAsFixed(2) ?? "-",
          icon: Icons.trending_down_rounded,
        ),
      ],
    );
  }

  Widget buildPrimitiveValue(dynamic value) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Text(
        value?.toString() ?? "-",
        style: const TextStyle(fontSize: 14, height: 1.45),
      ),
    );
  }

  Widget buildListValue(List list) {
    if (list.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: const Text("No data available"),
      );
    }

    final primitiveOnly = list.every((item) => isPrimitive(item));

    if (primitiveOnly) {
      return Wrap(
        spacing: 8,
        runSpacing: 8,
        children: list.map((item) {
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.indigo.shade50,
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: Colors.indigo.shade100),
            ),
            child: Text(
              item.toString(),
              style: TextStyle(
                color: Colors.indigo.shade900,
                fontWeight: FontWeight.w500,
              ),
            ),
          );
        }).toList(),
      );
    }

    return Column(
      children: List.generate(list.length, (index) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: buildStructuredBlock(
            title: "Item ${index + 1}",
            value: list[index],
            nested: true,
          ),
        );
      }),
    );
  }

  Widget buildMapValue(Map map, {bool nested = false}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: nested ? Colors.white : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: map.entries.map<Widget>((entry) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  formatKey(entry.key.toString()),
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                buildStructuredValue(entry.value, nested: true),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget buildStructuredValue(dynamic value, {bool nested = false}) {
    if (value is Map) {
      return buildMapValue(value, nested: nested);
    } else if (value is List) {
      return buildListValue(value);
    } else {
      return buildPrimitiveValue(value);
    }
  }

  Widget buildStructuredBlock({
    required String title,
    required dynamic value,
    bool nested = false,
  }) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              formatKey(title),
              style: TextStyle(
                fontSize: nested ? 14 : 15,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            buildStructuredValue(value, nested: true),
          ],
        ),
      ),
    );
  }

  Widget buildDetailsTab() {
    if (result == null) return const SizedBox.shrink();

    return ListView.separated(
      physics: const BouncingScrollPhysics(),
      itemCount: result!.entries.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (_, index) {
        final entry = result!.entries.elementAt(index);
        return buildStructuredBlock(title: entry.key, value: entry.value);
      },
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

  // =========================
  // DRUG TO DRUG UI
  // =========================
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

  // =========================
  // MAIN BUILD
  // =========================
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
