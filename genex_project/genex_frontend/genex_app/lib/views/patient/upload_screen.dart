// lib/views/patient/upload_screen.dart

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:http/http.dart' as http;

import '../../core/secure_storage.dart';
import '../../widgets/loading_button.dart';
import '../../widgets/premium_card.dart';
import 'package:genex_app/l10n/app_localizations.dart';

enum UploadType { geneExpression, tests, mri }

class UploadScreen extends StatefulWidget {
  const UploadScreen({super.key});

  @override
  State<UploadScreen> createState() => _UploadScreenState();
}

class _UploadScreenState extends State<UploadScreen> {
  UploadType _selectedType = UploadType.geneExpression;
  String? selectedFileName;
  PlatformFile? _pickedFile;
  bool _isLoading = false;

  static const String baseUrl = 'http://127.0.0.1:8000/api/';

  final _formKey = GlobalKey<FormState>();

  // --- Controllers ---

  final _esrController = TextEditingController();
  final _crpController = TextEditingController();
  final _antiCcpController = TextEditingController();
  final _rfController = TextEditingController();
  final _c3Controller = TextEditingController();
  final _c4Controller = TextEditingController();

  String _selectedGender = "Female";

  final Map<String, bool> _pnValues = {
    "ANA": false,
    "Anti-Sm": false,
    "Anti-Ro": false,
    "HLA-B27": false,
    "Anti-La": false,
    "Anti-dsDNA": false,
  };

  @override
  void dispose() {
    _esrController.dispose();
    _crpController.dispose();
    _antiCcpController.dispose();
    _rfController.dispose();
    _c3Controller.dispose();
    _c4Controller.dispose();
    super.dispose();
  }

  Future<void> pickFile() async {
    //choose file format based on type of file

    List<String> allowedExtensions;

    switch (_selectedType) {
      case UploadType.geneExpression:
        allowedExtensions = ['csv', 'txt'];
        break;

      case UploadType.mri:
        // change these if your backend expects other MRI formats
        allowedExtensions = ['nii', 'nii.gz', 'dcm', 'zip'];
        break;

      case UploadType.tests:
        return; // no file picker needed for tests
    }

    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: allowedExtensions,
      withData: true,
    );

    if (result != null && result.files.isNotEmpty) {
      final picked = result.files.single;

      setState(() {
        _pickedFile = picked;
        selectedFileName = picked.name;
      });

      if (_selectedType == UploadType.geneExpression) {
        _uploadAndAnalyze(picked);
      } else if (_selectedType == UploadType.mri) {
        _uploadMRIAndAnalyze(picked);
      }
    }
  }

  Future<void> _uploadAndAnalyze(PlatformFile file) async {
    final loc = AppLocalizations.of(context)!;

    //analyze gene expression file and get risk score

    // 1. Show Loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final request = http.MultipartRequest(
        'POST',
        Uri.parse("${baseUrl}gene-upload/"),
      );

      final token = await SecureStorage.readToken();

      if (token != null) {
        request.headers['Authorization'] = 'Bearer $token';
      }

      if (file.bytes != null) {
        request.files.add(
          http.MultipartFile.fromBytes(
            'file',
            file.bytes!,
            filename: file.name,
          ),
        );
      } else if (file.path != null) {
        request.files.add(
          await http.MultipartFile.fromPath('file', file.path!),
        );
      } else {
        throw Exception(loc.fileDataInaccessible);
      }

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (!mounted) return;

      if (Navigator.canPop(context)) {
        Navigator.pop(context);
      }

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        _showGeneResultDialog(
          (data['percentage'] as num).toDouble(),
          data['label'],
        );
      } else {
        String errorMessage = loc.uploadFailed;

        try {
          final errorData = jsonDecode(response.body);
          errorMessage = errorData['error'] ?? errorMessage;
        } catch (_) {
          errorMessage = response.body;
        }

        _showErrorSnackBar(errorMessage);
      }
    } catch (e) {
      if (!mounted) return;

      if (Navigator.canPop(context)) {
        Navigator.pop(context);
      }

      _showErrorSnackBar("${loc.uploadFailed}: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _uploadMRIAndAnalyze(PlatformFile file) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final token = await SecureStorage.readToken();

      if (token == null || token.isEmpty) {
        Navigator.pop(context);
        _showErrorSnackBar("You are not logged in. Please sign in again.");
        return;
      }

      var request = http.MultipartRequest(
        'POST',
        Uri.parse("${baseUrl}mri-predict-gradcam/"),
      );

      request.headers['Authorization'] = 'Bearer $token';

      if (file.bytes != null) {
        request.files.add(
          http.MultipartFile.fromBytes(
            'file',
            file.bytes!,
            filename: file.name,
          ),
        );
      } else if (file.path != null) {
        request.files.add(
          await http.MultipartFile.fromPath('file', file.path!),
        );
      } else {
        throw Exception("File data is inaccessible.");
      }

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (mounted && Navigator.canPop(context)) {
        Navigator.pop(context);
      }

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final gradcamUrls = Map<String, dynamic>.from(data['gradcam_urls']);
        _showMRIResultDialog(
          riskScore: (data['risk_score'] as num).toDouble(),
          prediction: data['prediction'].toString(),
          gradcamUrls: gradcamUrls,
          explanation:
              data['explanation']?.toString() ??
              "Highlighted regions show the areas that influenced the MRI abnormality prediction.",
        );
      } else {
        String errorMessage = "MRI analysis failed: ${response.statusCode}";

        try {
          final errorData = jsonDecode(response.body);
          errorMessage = errorData['error'] ?? errorMessage;
        } catch (_) {
          errorMessage = response.body;
        }

        _showErrorSnackBar(errorMessage);
      }
    } catch (e) {
      if (mounted && Navigator.canPop(context)) {
        Navigator.pop(context);
      }
      _showErrorSnackBar("MRI Upload Failed: $e");
    }
  }

  void _showMRIResultDialog({
    required double riskScore,
    required String prediction,
    required Map<String, dynamic> gradcamUrls,
    required String explanation,
  }) {
    final percentage = riskScore <= 1 ? riskScore * 100 : riskScore;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text("MRI Result: $prediction"),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                "Abnormality Risk Score:",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                "${percentage.toStringAsFixed(1)}%",
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: percentage >= 55 ? Colors.red : Colors.green,
                ),
              ),
              const SizedBox(height: 16),

              const Text(
                "Grad-CAM Interpretation:",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),

              _buildGradcamImage("Axial", gradcamUrls["axial"]),
              const SizedBox(height: 12),

              _buildGradcamImage("Coronal", gradcamUrls["coronal"]),
              const SizedBox(height: 12),

              _buildGradcamImage("Sagittal", gradcamUrls["sagittal"]),

              const SizedBox(height: 12),
              Text(explanation),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Close"),
          ),
        ],
      ),
    );
  }

  //show dialog with risk percentage and label after uploading gene expression file
  void _showResultDialogg(double percentage, String label) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Analysis Results"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("Rheumatoid Arthritis Probability:"),
            const SizedBox(height: 10),
            Text(
              "$percentage%",
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: percentage > 50 ? Colors.red : Colors.green,
              ),
            ),
            Text("Classification: $label"),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("OK"),
          ),
        ],
      ),
    );
  }

  Future<void> sendTestsToBackend() async {
    final loc = AppLocalizations.of(context)!;

    //send medical tests to backend and get analysis

    if (!_formKey.currentState!.validate()) {
      _showErrorSnackBar(loc.fixFormErrors);
      return;
    }

    final token = await SecureStorage.readToken();

    if (token == null || token.isEmpty) {
      _showErrorSnackBar(loc.notLoggedIn);
      return;
    }

    setState(() => _isLoading = true);

    final url = Uri.parse("${baseUrl}predict_xai/");

    final Map<String, dynamic> requestBody = {
      "ESR": double.tryParse(_esrController.text),
      "CRP": double.tryParse(_crpController.text),
      "RF": double.tryParse(_rfController.text),
      "Anti_CCP": double.tryParse(_antiCcpController.text),
      "C3": double.tryParse(_c3Controller.text),
      "C4": double.tryParse(_c4Controller.text),
      "ANA": _pnValues["ANA"],
      "Anti_Sm": _pnValues["Anti-Sm"],
      "Anti_Ro": _pnValues["Anti-Ro"],
      "HLA_B27": _pnValues["HLA-B27"],
      "Anti_La": _pnValues["Anti-La"],
      "Anti_dsDNA": _pnValues["Anti-dsDNA"],
    };

    try {
      final response = await http.post(
        url,
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
        body: jsonEncode(requestBody),
      );

      if (!mounted) return;

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        _showResultDialog(
          prediction: data['disease_prediction'],
          confidence: (data['confidence'] as num).toDouble(),
          explanation: data['xai_explanation'],
        );
      } else {
        String errorMessage = "${loc.serverError}: ${response.statusCode}";

        try {
          final errorData = jsonDecode(response.body);
          errorMessage = errorData['error'] ?? errorMessage;
        } catch (_) {}

        _showErrorSnackBar(errorMessage);
      }
    } catch (e) {
      if (!mounted) return;
      _showErrorSnackBar("${loc.connectionFailed}: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showGeneResultDialog(double percentage, String label) {
    final loc = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final color = percentage > 50 ? Colors.redAccent : Colors.green;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text(loc.analysisResults),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.analytics_rounded, color: color, size: 46),
            const SizedBox(height: 14),
            Text(loc.rheumatoidProbability),
            const SizedBox(height: 10),
            Text(
              "${percentage.toStringAsFixed(1)}%",
              style: theme.textTheme.displayMedium?.copyWith(
                fontWeight: FontWeight.w900,
                color: color,
              ),
            ),
            const SizedBox(height: 8),
            Text("${loc.classification}: $label"),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(loc.ok),
          ),
        ],
      ),
    );
  }

  void _showResultDialog({
    //show results after getting analysis from AI for medical tests
    required String prediction,
    required double confidence,
    required String explanation,
  }) {
    final loc = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text("${loc.result}: $prediction"),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "${loc.confidence}: ${(confidence * 100).toStringAsFixed(1)}%",
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w900,
                  color: theme.colorScheme.primary,
                ),
              ),
              const SizedBox(height: 14),
              Text(
                loc.aiExplanation,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(explanation),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(loc.close),
          ),
        ],
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.redAccent,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  String _titleForType(UploadType type) {
    final loc = AppLocalizations.of(context)!;

    switch (type) {
      case UploadType.geneExpression:
        return loc.uploadGeneExpressionFile;
      case UploadType.tests:
        return loc.enterMedicalTests;
      case UploadType.mri:
        return loc.enterMRI;
    }
  }

  String _instructionForType(UploadType type) {
    final loc = AppLocalizations.of(context)!;

    switch (type) {
      case UploadType.geneExpression:
        return loc.uploadGeneExpressionInstruction;
      case UploadType.tests:
        return loc.enterPatientDetails;
      case UploadType.mri:
        return loc.uploadMRIInstruction;
    }
  }

  IconData _iconForType(UploadType type) {
    switch (type) {
      case UploadType.geneExpression:
        return Icons.biotech_rounded;
      case UploadType.tests:
        return Icons.science_rounded;
      case UploadType.mri:
        return Icons.image_search_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final title = _titleForType(_selectedType);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(title: Text(loc.medicalAnalysisUpload)),
      body: Stack(
        children: [
          Positioned(
            right: -180,
            top: 140,
            child: Transform.rotate(
              angle: 0.18,
              child: _softDnaImage(context, width: 350, opacity: 0.12),
            ),
          ),

          Positioned(
            left: -180,
            bottom: -50,
            child: Transform.rotate(
              angle: -0.15,
              child: _softDnaImage(context, width: 350, opacity: 0.12),
            ),
          ),

          SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 920),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _HeroUploadCard(
                      title: loc.medicalAnalysisUpload,
                      subtitle:
                          'Upload medical files or enter lab tests to generate AI-powered health insights.',
                    ),
                    const SizedBox(height: 24),
                    _typeSelector(),
                    const SizedBox(height: 24),

                    PremiumCard(
                      padding: const EdgeInsets.all(24),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Row(
                              children: [
                                CircleAvatar(
                                  radius: 26,
                                  backgroundColor: theme.colorScheme.primary
                                      .withOpacity(0.12),
                                  child: Icon(
                                    _iconForType(_selectedType),
                                    color: theme.colorScheme.primary,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Text(
                                    title,
                                    style: theme.textTheme.titleLarge?.copyWith(
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),

                            Text(
                              _instructionForType(_selectedType),
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.colorScheme.onSurface.withOpacity(
                                  0.65,
                                ),
                                height: 1.5,
                              ),
                            ),
                            const SizedBox(height: 22),

                            if (_selectedType == UploadType.tests)
                              _testsForm()
                            else
                              _uploadBox(loc),
                          ],
                        ),
                      ),
                    ).animate().fadeIn(duration: 450.ms).slideY(begin: 0.08),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _softDnaImage(
    BuildContext context, {
    required double width,
    required double opacity,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return IgnorePointer(
      child: Opacity(
        opacity: opacity,
        child: Image.asset(
          isDark ? 'assets/images/dna_dark.png' : 'assets/images/dna_light.png',
          width: width,
          fit: BoxFit.contain,
        ),
      ),
    );
  }

  Widget _typeSelector() {
    final loc = AppLocalizations.of(context)!;

    final items = [
      (UploadType.geneExpression, loc.geneExpression, Icons.biotech_rounded),
      (UploadType.tests, loc.tests, Icons.science_rounded),
      (UploadType.mri, loc.mri, Icons.image_search_rounded),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxWidth < 650;

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: items.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: isCompact ? 2 : 4,
            crossAxisSpacing: 14,
            mainAxisSpacing: 14,
            childAspectRatio: isCompact ? 1.5 : 1.25,
          ),
          itemBuilder: (context, index) {
            final item = items[index];
            final selected = item.$1 == _selectedType;
            final theme = Theme.of(context);

            return InkWell(
              borderRadius: BorderRadius.circular(22),
              onTap: () {
                setState(() {
                  _selectedType = item.$1;
                  selectedFileName = null;
                  _pickedFile = null;
                });
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: selected
                      ? theme.colorScheme.primary.withOpacity(0.12)
                      : theme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(
                    color: selected
                        ? theme.colorScheme.primary.withOpacity(0.45)
                        : theme.dividerColor.withOpacity(0.12),
                  ),
                  boxShadow: [
                    if (selected)
                      BoxShadow(
                        color: theme.colorScheme.primary.withOpacity(0.14),
                        blurRadius: 18,
                        offset: const Offset(0, 8),
                      ),
                  ],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      item.$3,
                      color: selected
                          ? theme.colorScheme.primary
                          : theme.colorScheme.onSurface.withOpacity(0.58),
                      size: 28,
                    ),
                    const SizedBox(height: 10),
                    Text(
                      item.$2,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: selected
                            ? theme.colorScheme.primary
                            : theme.colorScheme.onSurface,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    ).animate().fadeIn(duration: 400.ms);
  }

  Widget _uploadBox(AppLocalizations loc) {
    final theme = Theme.of(context);

    String buttonText;

    switch (_selectedType) {
      case UploadType.geneExpression:
        buttonText = loc.uploadGeneExpression;
        break;
      case UploadType.mri:
        buttonText = loc.uploadMRI;
        break;
      case UploadType.tests:
        buttonText = loc.upload;
        break;
    }

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withOpacity(0.06),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: theme.colorScheme.primary.withOpacity(0.18)),
      ),
      child: Column(
        children: [
          Icon(
            Icons.cloud_upload_rounded,
            color: theme.colorScheme.primary,
            size: 52,
          ),
          const SizedBox(height: 14),
          Text(
            selectedFileName ?? 'Choose a file to start AI analysis',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 20),
          LoadingButton(
            loading: _isLoading,
            icon: Icons.upload_file_rounded,
            label: buttonText,
            onPressed: pickFile,
          ),
          if (_pickedFile != null) ...[
            const SizedBox(height: 14),
            Text(
              "${loc.uploaded}: ${_pickedFile!.name}",
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _testsForm() {
    final loc = AppLocalizations.of(context)!;

    return Column(
      children: [
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(child: _numberField('ESR', _esrController)),
            const SizedBox(width: 14),
            Expanded(child: _numberField('CRP', _crpController)),
          ],
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(child: _numberField('RF', _rfController)),
            const SizedBox(width: 14),
            Expanded(child: _numberField('Anti-CCP', _antiCcpController)),
          ],
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(child: _numberField('C3', _c3Controller)),
            const SizedBox(width: 14),
            Expanded(child: _numberField('C4', _c4Controller)),
          ],
        ),
        const SizedBox(height: 22),
        ..._pnValues.keys.map(_positiveNegativeRow),
        const SizedBox(height: 22),
        LoadingButton(
          loading: _isLoading,
          icon: Icons.auto_awesome_rounded,
          label: loc.result,
          onPressed: sendTestsToBackend,
        ),
      ],
    );
  }

  Widget _genderDropdown() {
    final loc = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return DropdownButtonFormField<String>(
      value: _selectedGender,
      decoration: InputDecoration(labelText: loc.gender),
      items: const [
        DropdownMenuItem(value: "Female", child: Text("Female")),
        DropdownMenuItem(value: "Male", child: Text("Male")),
      ],
      onChanged: (value) {
        if (value == null) return;
        setState(() => _selectedGender = value);
      },
      style: TextStyle(
        color: theme.colorScheme.onSurface,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  Widget _numberField(
    String label,
    TextEditingController controller, {
    bool isInt = false,
  }) {
    return TextFormField(
      controller: controller,
      inputFormatters: [
        FilteringTextInputFormatter.allow(
          RegExp(isInt ? r'^\d*' : r'^\d*\.?\d*'),
        ),
      ],
      keyboardType: TextInputType.numberWithOptions(decimal: !isInt),
      decoration: InputDecoration(labelText: label, isDense: true),
      validator: (value) {
        final loc = AppLocalizations.of(context)!;

        if (value == null || value.trim().isEmpty) {
          return "$label ${loc.isRequired}";
        }

        final n = num.tryParse(value);

        if (n == null) {
          return loc.invalidNumber;
        }

        return null;
      },
    );
  }

  Widget _positiveNegativeRow(String label) {
    final loc = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final value = _pnValues[label] ?? false;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withOpacity(0.04),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: theme.dividerColor.withOpacity(0.12)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          SegmentedButton<bool>(
            segments: [
              ButtonSegment(value: true, label: Text(loc.pos)),
              ButtonSegment(value: false, label: Text(loc.neg)),
            ],
            selected: {value},
            onSelectionChanged: (set) {
              setState(() => _pnValues[label] = set.first);
            },
            showSelectedIcon: false,
            style: const ButtonStyle(
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              visualDensity: VisualDensity.compact,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGradcamImage(String title, dynamic url) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),

        const SizedBox(height: 6),

        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.network(
            url.toString(),
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return Text("Could not load $title Grad-CAM image.");
            },
          ),
        ),
      ],
    );
  }
}

class _HeroUploadCard extends StatelessWidget {
  final String title;
  final String subtitle;

  const _HeroUploadCard({required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        gradient: LinearGradient(
          colors: [theme.colorScheme.primary, theme.colorScheme.secondary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.primary.withOpacity(0.28),
            blurRadius: 28,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 68,
            height: 68,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.18),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white.withOpacity(0.22)),
            ),
            child: const Icon(
              Icons.auto_awesome_rounded,
              color: Colors.white,
              size: 36,
            ),
          ),
          const SizedBox(width: 22),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  subtitle,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: Colors.white.withOpacity(0.82),
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 450.ms).slideY(begin: -0.08);
  }
}
