import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;
import '../../core/secure_storage.dart';
import '../../core/constants.dart';
import 'package:genex_app/l10n/app_localizations.dart';

enum UploadType {
  vcf,
  geneExpression,
  tests,
  mri,
}

class UploadScreen extends StatefulWidget {
  const UploadScreen({super.key});

  @override
  State<UploadScreen> createState() =>
      _UploadScreenState();
}

class _UploadScreenState
    extends State<UploadScreen> {
  UploadType _selectedType =
      UploadType.vcf;

  String? selectedFileName;

  static const String baseUrl =
      'http://127.0.0.1:8000/api/';

  final _formKey =
      GlobalKey<FormState>();

  final _ageController =
      TextEditingController();

  String _selectedGender =
      "Female";

  final _esrController =
      TextEditingController();

  final _crpController =
      TextEditingController();

  final _antiCcpController =
      TextEditingController();

  final _rfController =
      TextEditingController();

  final _c3Controller =
      TextEditingController();

  final _c4Controller =
      TextEditingController();

  final Map<String, bool>
      _pnValues = {
    "ANA": false,
    "Anti-Sm": false,
    "Anti-Ro": false,
    "HLA-B27": false,
    "Anti-La": false,
    "Anti-dsDNA": false,
  };

  @override
  void dispose() {
    _ageController.dispose();
    _esrController.dispose();
    _crpController.dispose();
    _antiCcpController.dispose();
    _rfController.dispose();
    _c3Controller.dispose();
    _c4Controller.dispose();
    super.dispose();
  }

  PlatformFile? _pickedFile;

  Future<void> pickFile() async {
    final loc =
        AppLocalizations.of(context)!;

    final result =
        await FilePicker.platform
            .pickFiles(
      type: FileType.custom,
      allowedExtensions: [
        'vcf',
        'txt',
        'csv',
      ],
      withData: true,
    );

    if (result != null) {
      setState(() {
        selectedFileName =
            result.files.single.name;
      });

      if (_selectedType ==
              UploadType
                  .geneExpression ||
          _selectedType ==
              UploadType.mri) {
        _uploadAndAnalyze(
          result.files.single,
        );
      }
    } else {
      _showErrorSnackBar(
        loc.noFileSelected,
      );
    }
  }

  Future<void>
      _uploadAndAnalyze(
    PlatformFile file,
  ) async {
    final loc =
        AppLocalizations.of(context)!;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (context) => const Center(
        child:
            CircularProgressIndicator(),
      ),
    );

    try {
      var request =
          http.MultipartRequest(
        'POST',
        Uri.parse(
          "${baseUrl}gene-upload/",
        ),
      );

      final token =
          await SecureStorage
              .readToken();

      if (token != null) {
        request.headers[
                'Authorization'] =
            'Bearer $token';
      }

      if (file.bytes != null) {
        request.files.add(
          http.MultipartFile
              .fromBytes(
            'file',
            file.bytes!,
            filename: file.name,
          ),
        );
      } else if (file.path !=
          null) {
        request.files.add(
          await http.MultipartFile
              .fromPath(
            'file',
            file.path!,
          ),
        );
      } else {
        throw Exception(
          loc.fileDataInaccessible,
        );
      }

      var streamedResponse =
          await request.send();

      var response =
          await http.Response
              .fromStream(
        streamedResponse,
      );

      Navigator.pop(context);

      if (response.statusCode ==
          200) {
        final data = jsonDecode(
          response.body,
        );

        _showResultDialogg(
          (data['percentage']
                  as num)
              .toDouble(),
          data['label'],
        );
      } else {
        String errorMessage =
            loc.uploadFailed;

        try {
          final errorData =
              jsonDecode(
            response.body,
          );

          errorMessage =
              errorData['error'] ??
                  errorMessage;
        } catch (_) {
          errorMessage =
              response.body;
        }

        ScaffoldMessenger.of(
          context,
        ).showSnackBar(
          SnackBar(
            content:
                Text(errorMessage),
          ),
        );
      }
    } catch (e) {
      Navigator.pop(context);

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(
        SnackBar(
          content: Text(
            "${loc.uploadFailed}: $e",
          ),
        ),
      );
    }
  }

  void _showResultDialogg(
    double percentage,
    String label,
  ) {
    final loc =
        AppLocalizations.of(context)!;

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
        title: Text(
          loc.analysisResults,
        ),
        content: Column(
          mainAxisSize:
              MainAxisSize.min,
          children: [
            Text(
              loc
                  .rheumatoidProbability,
            ),

            const SizedBox(
                height: 10),

            Text(
              "$percentage%",
              style: TextStyle(
                fontSize: 32,
                fontWeight:
                    FontWeight.bold,
                color: percentage >
                        50
                    ? Colors.red
                    : Colors.green,
              ),
            ),

            Text(
              "${loc.classification}: $label",
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed:
                () => Navigator.pop(
              context,
            ),
            child: Text(loc.ok),
          ),
        ],
      ),
    );
  }

  Future<void>
      sendTestsToBackend() async {
    final loc =
        AppLocalizations.of(context)!;

    if (!_formKey.currentState!
        .validate()) {
      _showErrorSnackBar(
        loc.fixFormErrors,
      );

      return;
    }

    final token =
        await SecureStorage
            .readToken();

    if (token == null ||
        token.isEmpty) {
      _showErrorSnackBar(
        loc.notLoggedIn,
      );

      return;
    }

    final url = Uri.parse(
      "${baseUrl}predict_xai/",
    );

    final Map<String, dynamic>
        requestBody = {
      "Age": int.tryParse(
            _ageController.text,
          ) ??
          0,
      "Gender":
          _selectedGender,
      "ESR": double.tryParse(
        _esrController.text,
      ),
      "CRP": double.tryParse(
        _crpController.text,
      ),
      "RF": double.tryParse(
        _rfController.text,
      ),
      "Anti_CCP":
          double.tryParse(
        _antiCcpController.text,
      ),
      "C3": double.tryParse(
        _c3Controller.text,
      ),
      "C4": double.tryParse(
        _c4Controller.text,
      ),
      "ANA":
          _pnValues["ANA"],
      "Anti_Sm":
          _pnValues["Anti-Sm"],
      "Anti_Ro":
          _pnValues["Anti-Ro"],
      "HLA_B27":
          _pnValues["HLA-B27"],
      "Anti_La":
          _pnValues["Anti-La"],
      "Anti_dsDNA":
          _pnValues[
              "Anti-dsDNA"],
    };

    try {
      showDialog(
        context: context,
        barrierDismissible:
            false,
        builder:
            (ctx) => const Center(
          child:
              CircularProgressIndicator(),
        ),
      );

      final response =
          await http.post(
        url,
        headers: {
          "Content-Type":
              "application/json",
          "Authorization":
              "Bearer $token",
        },
        body: jsonEncode(
          requestBody,
        ),
      );

      if (mounted &&
          Navigator.canPop(
              context)) {
        Navigator.of(context)
            .pop();
      }

      if (response.statusCode ==
          200) {
        final data = jsonDecode(
          response.body,
        );

        _showResultDialog(
          prediction: data[
              'disease_prediction'],
          confidence:
              (data['confidence']
                      as num)
                  .toDouble(),
          explanation: data[
              'xai_explanation'],
        );
      } else {
        String errorMessage =
            "${loc.serverError}: ${response.statusCode}";

        try {
          final errorData =
              jsonDecode(
            response.body,
          );

          errorMessage =
              errorData['error'] ??
                  errorMessage;
        } catch (_) {}

        _showErrorSnackBar(
          errorMessage,
        );
      }
    } catch (e) {
      if (mounted &&
          Navigator.canPop(
              context)) {
        Navigator.of(context)
            .pop();
      }

      _showErrorSnackBar(
        "${loc.connectionFailed}: $e",
      );
    }
  }

  void _showResultDialog({
    required String prediction,
    required double confidence,
    required String explanation,
  }) {
    final loc =
        AppLocalizations.of(context)!;

    showDialog(
      context: context,
      builder:
          (ctx) => AlertDialog(
        title: Text(
          "${loc.result}: $prediction",
        ),
        content:
            SingleChildScrollView(
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment
                    .start,
            mainAxisSize:
                MainAxisSize.min,
            children: [
              Text(
                "${loc.confidence}: ${(confidence * 100).toStringAsFixed(1)}%",
                style:
                    const TextStyle(
                  fontWeight:
                      FontWeight.bold,
                ),
              ),

              const SizedBox(
                  height: 10),

              Text(
                loc.aiExplanation,
                style:
                    const TextStyle(
                  fontWeight:
                      FontWeight.bold,
                ),
              ),

              Text(explanation),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed:
                () => Navigator.pop(
              ctx,
            ),
            child: Text(
              loc.close,
            ),
          ),
        ],
      ),
    );
  }

  void _showErrorSnackBar(
    String message,
  ) {
    ScaffoldMessenger.of(context)
        .showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor:
            Colors.red,
      ),
    );
  }

  String _titleForType(
    UploadType type,
  ) {
    final loc =
        AppLocalizations.of(context)!;

    switch (type) {
      case UploadType.vcf:
        return loc.uploadVCFFile;

      case UploadType
            .geneExpression:
        return loc
            .uploadGeneExpressionFile;

      case UploadType.tests:
        return loc
            .enterMedicalTests;

      case UploadType.mri:
        return loc.enterMRI;
    }
  }

  @override
  Widget build(
    BuildContext context,
  ) {
    final theme =
        Theme.of(context);

    final loc =
        AppLocalizations.of(context)!;

    final title =
        _titleForType(
      _selectedType,
    );

    return Scaffold(
      backgroundColor:
          theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          loc.medicalAnalysisUpload,
        ),
      ),
      body: Center(
        child:
            SingleChildScrollView(
          padding:
              const EdgeInsets.all(
                  20),
          child: Form(
            key: _formKey,
            child: ConstrainedBox(
              constraints:
                  const BoxConstraints(
                maxWidth: 520,
              ),
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment
                        .stretch,
                children: [
                  DropdownButtonFormField<
                      UploadType>(
                    value:
                        _selectedType,
                    decoration:
                        InputDecoration(
                      labelText: loc
                          .chooseUploadType,
                      border:
                          const OutlineInputBorder(),
                    ),
                    items: [
                      DropdownMenuItem(
                        value:
                            UploadType
                                .vcf,
                        child: Text(
                          loc.vcf,
                        ),
                      ),
                      DropdownMenuItem(
                        value:
                            UploadType
                                .geneExpression,
                        child: Text(
                          loc
                              .geneExpression,
                        ),
                      ),
                      DropdownMenuItem(
                        value:
                            UploadType
                                .tests,
                        child: Text(
                          loc.tests,
                        ),
                      ),
                      DropdownMenuItem(
                        value:
                            UploadType
                                .mri,
                        child: Text(
                          loc.mri,
                        ),
                      ),
                    ],
                    onChanged: (
                      val,
                    ) {
                      if (val == null)
                        return;

                      setState(() {
                        _selectedType =
                            val;

                        selectedFileName =
                            null;
                      });
                    },
                  ),

                  const SizedBox(
                      height: 18),

                  Text(
                    title,
                    style:
                        const TextStyle(
                      fontSize: 18,
                      fontWeight:
                          FontWeight
                              .bold,
                    ),
                  ),

                  const SizedBox(
                      height: 12),

                  if (_selectedType ==
                      UploadType.vcf) ...[
                    Text(
                      loc
                          .uploadVCFInstruction,
                    ),

                    const SizedBox(
                        height: 12),

                    ElevatedButton.icon(
                      onPressed:
                          pickFile,
                      icon: const Icon(
                        Icons
                            .upload_file,
                      ),
                      label: Text(
                        loc.uploadVCF,
                      ),
                    ),

                    if (selectedFileName !=
                        null) ...[
                      const SizedBox(
                          height: 12),

                      Text(
                        "${loc.uploaded}: $selectedFileName",
                      ),
                    ],
                  ] else if (_selectedType ==
                      UploadType
                          .geneExpression) ...[
                    Text(
                      loc
                          .uploadGeneExpressionInstruction,
                    ),

                    const SizedBox(
                        height: 12),

                    ElevatedButton.icon(
                      onPressed:
                          pickFile,
                      icon: const Icon(
                        Icons
                            .upload_file,
                      ),
                      label: Text(
                        loc
                            .uploadGeneExpression,
                      ),
                    ),

                    if (selectedFileName !=
                        null) ...[
                      const SizedBox(
                          height: 12),

                      Text(
                        "${loc.uploaded}: $selectedFileName",
                      ),
                    ],
                  ] else if (_selectedType ==
                      UploadType.mri) ...[
                    Text(
                      loc
                          .uploadMRIInstruction,
                    ),

                    const SizedBox(
                        height: 12),

                    ElevatedButton.icon(
                      onPressed:
                          pickFile,
                      icon: const Icon(
                        Icons
                            .upload_file,
                      ),
                      label: Text(
                        loc.uploadMRI,
                      ),
                    ),

                    if (selectedFileName !=
                        null) ...[
                      const SizedBox(
                          height: 12),

                      Text(
                        "${loc.uploaded}: $selectedFileName",
                      ),
                    ],
                  ] else ...[
                    Text(
                      loc
                          .enterPatientDetails,
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _numberField(
    String label,
    TextEditingController
        controller, {
    bool isInt = false,
  }) {
    return TextFormField(
      controller: controller,
      inputFormatters: [
        FilteringTextInputFormatter
            .allow(
          RegExp(
            isInt
                ? r'^\d*'
                : r'^\d*\.?\d*',
          ),
        ),
      ],
      keyboardType:
          TextInputType
              .numberWithOptions(
        decimal: !isInt,
      ),
      decoration:
          InputDecoration(
        labelText: label,
        border:
            const OutlineInputBorder(),
        isDense: true,
        errorStyle:
            const TextStyle(
          fontSize: 11,
        ),
      ),
      validator: (value) {
        final loc =
            AppLocalizations.of(
                context)!;

        if (value == null ||
            value
                .trim()
                .isEmpty) {
          return "$label ${loc.isRequired}";
        }

        final n =
            num.tryParse(value);

        if (n == null) {
          return loc
              .invalidNumber;
        }

        return null;
      },
    );
  }

  Widget _positiveNegativeRow(
    String label,
  ) {
    final loc =
        AppLocalizations.of(context)!;

    final value =
        _pnValues[label] ??
            false;

    return Padding(
      padding:
          const EdgeInsets.only(
              bottom: 10),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style:
                  const TextStyle(
                fontSize: 16,
              ),
            ),
          ),

          const SizedBox(
              width: 10),

          SegmentedButton<bool>(
            segments: [
              ButtonSegment(
                value: true,
                label:
                    Text(loc.pos),
              ),
              ButtonSegment(
                value: false,
                label:
                    Text(loc.neg),
              ),
            ],
            selected: {value},
            onSelectionChanged:
                (set) => setState(
              () => _pnValues[
                      label] =
                  set.first,
            ),
            showSelectedIcon:
                false,
            style:
                const ButtonStyle(
              tapTargetSize:
                  MaterialTapTargetSize
                      .shrinkWrap,
              visualDensity:
                  VisualDensity
                      .compact,
            ),
          ),
        ],
      ),
    );
  }
}