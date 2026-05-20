import 'dart:convert';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../services/api_service.dart';
import 'package:genex_app/l10n/app_localizations.dart';
//done
class TwinSimulationScreen extends StatefulWidget {
  const TwinSimulationScreen({super.key});

  @override
  State<TwinSimulationScreen> createState() =>
      _TwinSimulationScreenState();
}

class _TwinSimulationScreenState
    extends State<TwinSimulationScreen> {
  String selectedMode = "drug_gene";

  PlatformFile? selectedFile;

  final TextEditingController geneDrug1Controller =
      TextEditingController();

  final TextEditingController geneDrug2Controller =
      TextEditingController();

  Map<String, dynamic>? result;

  bool loading = false;

  final ApiService apiService = ApiService();

  final TextEditingController
      interactionDrug1Controller =
      TextEditingController();

  final TextEditingController
      interactionDrug2Controller =
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
    final loc =
        AppLocalizations.of(context)!;

    try {
      final picked =
          await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['csv', 'txt'],
        withData: kIsWeb,
      );

      if (picked != null &&
          picked.files.isNotEmpty) {
        if (!mounted) return;

        setState(() {
          selectedFile =
              picked.files.single;
        });
      }
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          content: Text(
            loc.fileSelectionFailed(
              e.toString(),
            ),
          ),
        ),
      );
    }
  }

  Future<void> evaluate() async {
    final loc =
        AppLocalizations.of(context)!;

    if (selectedFile == null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          content: Text(
            loc.pleaseUploadPatientCsv,
          ),
        ),
      );
      return;
    }

    if (geneDrug1Controller.text
        .trim()
        .isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          content: Text(
            loc.pleaseEnterDrug1,
          ),
        ),
      );
      return;
    }

    setState(() => loading = true);

    try {
      final res = await apiService
          .evaluateTwinSimulation(
            file: selectedFile!,
            drug1:
                geneDrug1Controller.text
                    .trim(),
            drug2:
                geneDrug2Controller.text
                    .trim(),
          )
          .timeout(
            const Duration(
              seconds: 30,
            ),
          );

      if (!mounted) return;

      setState(() {
        result = res;
        loading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() => loading = false);

      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          content: Text(
            loc.errorMessage(
              e.toString(),
            ),
          ),
        ),
      );
    }
  }

  Future<void> saveReport() async {
    final loc =
        AppLocalizations.of(context)!;

    if (result == null) return;

    try {
      await apiService.saveTwinReport(
        result: result!,
        drug1:
            geneDrug1Controller.text
                .trim(),
        drug2:
            geneDrug2Controller.text
                .trim(),
        fileName:
            selectedFile?.name ?? "",
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          content: Text(
            loc.reportSavedSuccessfully,
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          content: Text(
            loc.saveFailed(
              e.toString(),
            ),
          ),
        ),
      );
    }
  }

  Future<void> checkInteraction() async {
    final loc =
        AppLocalizations.of(context)!;

    final drug1 =
        interactionDrug1Controller.text
            .trim();

    final drug2 =
        interactionDrug2Controller.text
            .trim();

    if (drug1.isEmpty ||
        drug2.isEmpty) {
      setState(() {
        interactionResult =
            loc.pleaseEnterBothDrugNames;
      });
      return;
    }

    setState(() {
      isInteractionLoading = true;
      interactionResult = '';
    });

    try {
      final response = await http.post(
        Uri.parse(
          'http://127.0.0.1:8000/api/check-interaction/',
        ),
        headers: {
          'Content-Type':
              'application/json',
        },
        body: jsonEncode({
          'drug1': drug1,
          'drug2': drug2,
        }),
      );

      final data =
          jsonDecode(response.body);

      if (!mounted) return;

      setState(() {
        if (response.statusCode ==
            200) {
          if (data['found'] ==
              true) {
            interactionResult =
                '${loc.interactionFound}\n\n${data['drug1']} + ${data['drug2']}\n\n${data['description']}';
          } else {
            interactionResult =
                data['message'] ??
                    loc
                        .noInteractionFound;
          }
        } else {
          interactionResult =
              data['error'] ??
                  loc
                      .somethingWentWrong;
        }
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        interactionResult =
            loc.errorMessage(
          e.toString(),
        );
      });
    } finally {
      if (!mounted) return;

      setState(() {
        isInteractionLoading =
            false;
      });
    }
  }

  String formatKey(String key) {
    return key
        .replaceAll('_', ' ')
        .replaceAll('-', ' ')
        .split(' ')
        .where(
          (e) =>
              e.trim().isNotEmpty,
        )
        .map(
          (word) =>
              word[0]
                  .toUpperCase() +
              word.substring(1),
        )
        .join(' ');
  }

  bool isPrimitive(dynamic value) {
    return value == null ||
        value is String ||
        value is num ||
        value is bool;
  }

  double getResultSectionHeight(
    BuildContext context,
  ) {
    final screenHeight =
        MediaQuery.of(context)
            .size
            .height;

    if (screenHeight < 700) {
      return 500;
    }

    if (screenHeight < 850) {
      return 580;
    }

    return 650;
  }

  Widget buildModeSelector() {
    final theme = Theme.of(context);
    final loc =
        AppLocalizations.of(context)!;

    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color:
            theme.colorScheme.surface,
        borderRadius:
            BorderRadius.circular(18),
        border: Border.all(
          color: theme.dividerColor
              .withOpacity(0.2),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () {
                setState(() {
                  selectedMode =
                      "drug_gene";
                });
              },
              child:
                  AnimatedContainer(
                duration:
                    const Duration(
                  milliseconds: 200,
                ),
                padding:
                    const EdgeInsets
                        .symmetric(
                  vertical: 14,
                ),
                decoration:
                    BoxDecoration(
                  color: selectedMode ==
                          "drug_gene"
                      ? theme
                          .colorScheme
                          .primary
                      : Colors
                          .transparent,
                  borderRadius:
                      BorderRadius
                          .circular(
                              14),
                ),
                child: Text(
                  loc
                      .drugToGeneInteraction,
                  textAlign:
                      TextAlign.center,
                  style: TextStyle(
                    fontWeight:
                        FontWeight.w600,
                    color: selectedMode ==
                            "drug_gene"
                        ? Colors.white
                        : theme
                            .colorScheme
                            .onSurface,
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
                  selectedMode =
                      "drug_drug";
                });
              },
              child:
                  AnimatedContainer(
                duration:
                    const Duration(
                  milliseconds: 200,
                ),
                padding:
                    const EdgeInsets
                        .symmetric(
                  vertical: 14,
                ),
                decoration:
                    BoxDecoration(
                  color: selectedMode ==
                          "drug_drug"
                      ? theme
                          .colorScheme
                          .primary
                      : Colors
                          .transparent,
                  borderRadius:
                      BorderRadius
                          .circular(
                              14),
                ),
                child: Text(
                  loc
                      .drugToDrugInteraction,
                  textAlign:
                      TextAlign.center,
                  style: TextStyle(
                    fontWeight:
                        FontWeight.w600,
                    color: selectedMode ==
                            "drug_drug"
                        ? Colors.white
                        : theme
                            .colorScheme
                            .onSurface,
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
    required TextEditingController
        controller,
    required String label,
    required IconData icon,
    bool optional = false,
  }) {
    final theme = Theme.of(context);
    final loc =
        AppLocalizations.of(context)!;

    return TextField(
      controller: controller,
      style: TextStyle(
        color:
            theme.colorScheme.onSurface,
      ),
      decoration: InputDecoration(
        labelText: optional
            ? "$label (${loc.optional})"
            : label,
        labelStyle: TextStyle(
          color: theme
              .colorScheme.onSurface
              .withOpacity(0.65),
        ),
        prefixIcon: Icon(
          icon,
          color:
              theme.colorScheme.primary,
        ),
        filled: true,
        fillColor: theme
            .inputDecorationTheme
            .fillColor,
        contentPadding:
            const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 16,
        ),
        border: OutlineInputBorder(
          borderRadius:
              BorderRadius.circular(14),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final loc =
        AppLocalizations.of(context)!;

    final bool isDrugGeneMode =
        selectedMode == "drug_gene";

    return Scaffold(
      backgroundColor:
          theme.scaffoldBackgroundColor,
      appBar: AppBar(
        elevation: 0,
        title: Text(
          loc.twinSimulation,
          style: TextStyle(
            fontWeight:
                FontWeight.bold,
            color:
                theme.colorScheme.onSurface,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics:
              const BouncingScrollPhysics(),
          padding:
              const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment
                    .stretch,
            children: [
              buildModeSelector(),
              const SizedBox(
                  height: 16),

              if (isDrugGeneMode)
                Card(
                  child: Padding(
                    padding:
                        const EdgeInsets
                            .all(18),
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment
                              .start,
                      children: [
                        Text(
                          loc
                              .drugToGeneInteraction,
                        ),
                        const SizedBox(
                            height: 8),
                        Text(
                          loc
                              .uploadPatientDescription,
                        ),
                        const SizedBox(
                            height: 18),
                        ElevatedButton.icon(
                          onPressed:
                              pickFile,
                          icon: const Icon(
                            Icons
                                .upload_file_rounded,
                          ),
                          label: Text(
                            selectedFile ==
                                    null
                                ? loc
                                    .uploadPatientCsv
                                : loc
                                    .changeFile,
                          ),
                        ),
                        if (selectedFile !=
                            null) ...[
                          const SizedBox(
                              height: 12),
                          Text(
                            loc.selectedFile(
                              selectedFile!
                                  .name,
                            ),
                          ),
                        ],
                        const SizedBox(
                            height: 16),
                        buildInputField(
                          controller:
                              geneDrug1Controller,
                          label:
                              loc.drug1,
                          icon: Icons
                              .medication_rounded,
                        ),
                        const SizedBox(
                            height: 12),
                        buildInputField(
                          controller:
                              geneDrug2Controller,
                          label:
                              loc.drug2,
                          icon: Icons
                              .medication_outlined,
                          optional: true,
                        ),
                        const SizedBox(
                            height: 18),
                        ElevatedButton(
                          onPressed:
                              loading
                                  ? null
                                  : evaluate,
                          child: loading
                              ? const CircularProgressIndicator()
                              : Text(
                                  loc
                                      .evaluate,
                                ),
                        ),
                      ],
                    ),
                  ),
                )
              else
                Card(
                  child: Padding(
                    padding:
                        const EdgeInsets
                            .all(18),
                    child: Column(
                      children: [
                        buildInputField(
                          controller:
                              interactionDrug1Controller,
                          label: loc
                              .enterFirstDrug,
                          icon: Icons
                              .medication_rounded,
                        ),
                        const SizedBox(
                            height: 12),
                        buildInputField(
                          controller:
                              interactionDrug2Controller,
                          label: loc
                              .enterSecondDrug,
                          icon: Icons
                              .medication_outlined,
                        ),
                        const SizedBox(
                            height: 18),
                        ElevatedButton(
                          onPressed:
                              isInteractionLoading
                                  ? null
                                  : checkInteraction,
                          child:
                              isInteractionLoading
                                  ? const CircularProgressIndicator()
                                  : Text(
                                      loc
                                          .checkInteraction,
                                    ),
                        ),
                        const SizedBox(
                            height: 20),
                        Container(
                          width:
                              double.infinity,
                          padding:
                              const EdgeInsets
                                  .all(16),
                          child: Text(
                            interactionResult
                                    .isEmpty
                                ? loc
                                    .interactionResultPlaceholder
                                : interactionResult,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}