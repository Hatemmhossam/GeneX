import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Required for FilteringTextInputFormatter
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;

enum UploadType { vcf, geneExpression, tests }

class UploadScreen extends StatefulWidget {
  const UploadScreen({super.key});

  @override
  State<UploadScreen> createState() => _UploadScreenState();
}

class _UploadScreenState extends State<UploadScreen> {
  UploadType _selectedType = UploadType.vcf;
  String? selectedFileName;
  
  // Key for Form Validation
  final _formKey = GlobalKey<FormState>();

  // --- Controllers ---
  final _ageController = TextEditingController();
  String _selectedGender = "Female"; 

  final _esrController = TextEditingController();
  final _crpController = TextEditingController();
  final _antiCcpController = TextEditingController();
  final _rfController = TextEditingController();
  final _c3Controller = TextEditingController();
  final _c4Controller = TextEditingController();

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
    _ageController.dispose();
    _esrController.dispose();
    _crpController.dispose();
    _antiCcpController.dispose();
    _rfController.dispose();
    _c3Controller.dispose();
    _c4Controller.dispose();
    super.dispose();
  }

  Future<void> pickFile() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.any);
    if (result != null) {
      setState(() => selectedFileName = result.files.single.name);
    }
  }

  Future<void> sendTestsToBackend() async {
    // TRIGGER VALIDATION: If the form is not valid, stop here.
    if (!_formKey.currentState!.validate()) {
      _showErrorSnackBar("Please fix the errors in the form.");
      return;
    }

    final url = Uri.parse('http://127.0.0.1:8000/predict_xai/');
    final Map<String, dynamic> requestBody = {
      "Age": int.tryParse(_ageController.text) ?? 0,
      "Gender": _selectedGender,
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
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => const Center(child: CircularProgressIndicator()),
      );

      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(requestBody),
      );

      if (mounted) Navigator.of(context).pop();

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _showResultDialog(
          prediction: data['disease_prediction'],
          confidence: data['confidence'],
          explanation: data['xai_explanation'],
        );
      } else {
        _showErrorSnackBar("Server Error: ${response.statusCode}");
      }
    } catch (e) {
      if (mounted && Navigator.canPop(context)) Navigator.of(context).pop();
      _showErrorSnackBar("Connection Failed: Check if Python server is running.");
    }
  }

  void _showResultDialog({required String prediction, required double confidence, required String explanation}) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text("Result: $prediction"),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text("Confidence: ${(confidence * 100).toStringAsFixed(1)}%", 
                  style: const TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              const Text("AI Explanation:", style: TextStyle(fontWeight: FontWeight.bold)),
              Text(explanation),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Close")),
        ],
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  String _titleForType(UploadType type) {
    switch (type) {
      case UploadType.vcf: return "Upload VCF File";
      case UploadType.geneExpression: return "Upload Gene Expression File";
      case UploadType.tests: return "Enter Medical Tests";
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = _titleForType(_selectedType);

    return Scaffold(
      appBar: AppBar(title: const Text('Medical Analysis Upload')),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form( // WRAP EVERYTHING IN A FORM
            key: _formKey,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  DropdownButtonFormField<UploadType>(
                    value: _selectedType,
                    decoration: const InputDecoration(
                      labelText: "Choose upload type",
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(value: UploadType.vcf, child: Text("VCF")),
                      DropdownMenuItem(value: UploadType.geneExpression, child: Text("Gene Expression")),
                      DropdownMenuItem(value: UploadType.tests, child: Text("Tests (ML Prediction)")),
                    ],
                    onChanged: (val) {
                      if (val == null) return;
                      setState(() {
                        _selectedType = val;
                        selectedFileName = null;
                      });
                    },
                  ),

                  const SizedBox(height: 18),
                  Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),

                  if (_selectedType == UploadType.vcf) ...[
                    const Text("Please upload your VCF file."),
                    const SizedBox(height: 12),
                    ElevatedButton.icon(
                      onPressed: pickFile,
                      icon: const Icon(Icons.upload_file),
                      label: const Text('Upload VCF'),
                    ),
                    if (selectedFileName != null) ...[
                      const SizedBox(height: 12),
                      Text('Uploaded: $selectedFileName'),
                    ],
                  ] else if (_selectedType == UploadType.geneExpression) ...[
                    const Text("Please upload your Gene Expression file."),
                    const SizedBox(height: 12),
                    ElevatedButton.icon(
                      onPressed: pickFile,
                      icon: const Icon(Icons.upload_file),
                      label: const Text('Upload Gene Expression'),
                    ),
                    if (selectedFileName != null) ...[
                      const SizedBox(height: 12),
                      Text('Uploaded: $selectedFileName'),
                    ],
                  ] else ...[
                    const Text("Enter patient details and test results."),
                    const SizedBox(height: 12),

                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start, // Align for error labels
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: _selectedGender,
                            decoration: const InputDecoration(labelText: "Gender", border: OutlineInputBorder()),
                            items: ["Male", "Female"]
                                .map((g) => DropdownMenuItem(value: g, child: Text(g)))
                                .toList(),
                            onChanged: (v) => setState(() => _selectedGender = v!),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _numberField("Age", _ageController, isInt: true),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),

                    _numberField("ESR", _esrController),
                    const SizedBox(height: 10),
                    _numberField("CRP", _crpController),
                    const SizedBox(height: 10),
                    _numberField("ANTI-CCP", _antiCcpController),
                    const SizedBox(height: 10),
                    _numberField("RF", _rfController),
                    const SizedBox(height: 10),
                    _numberField("C3", _c3Controller),
                    const SizedBox(height: 10),
                    _numberField("C4", _c4Controller),

                    const SizedBox(height: 18),
                    const Divider(),
                    const Text("Serology (Positive/Negative)", style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 10),

                    ..._pnValues.keys.map((label) => _positiveNegativeRow(label)).toList(),

                    const SizedBox(height: 18),
                    
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: Colors.blueAccent,
                        foregroundColor: Colors.white,
                      ),
                      onPressed: sendTestsToBackend, 
                      child: const Text("Save Tests & Get Analysis", style: TextStyle(fontSize: 16)),
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

  // UPDATED NUMBER FIELD WITH VALIDATION
  Widget _numberField(String label, TextEditingController controller, {bool isInt = false}) {
    return TextFormField(
      controller: controller,
      // Only allows digits and one decimal point
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(isInt ? r'^\d*' : r'^\d*\.?\d*')),
      ],
      keyboardType: TextInputType.numberWithOptions(decimal: !isInt),
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        isDense: true,
        errorStyle: const TextStyle(fontSize: 11),
      ),
      // THE ERROR GENERATOR
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return "$label is required";
        }
        final n = num.tryParse(value);
        if (n == null) {
          return "Invalid number";
        }
        return null;
      },
    );
  }

  Widget _positiveNegativeRow(String label) {
    final value = _pnValues[label] ?? false;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Expanded(child: Text(label, style: const TextStyle(fontSize: 16))),
          const SizedBox(width: 10),
          SegmentedButton<bool>(
            segments: const [
              ButtonSegment(value: true, label: Text("Pos")),
              ButtonSegment(value: false, label: Text("Neg")),
            ],
            selected: {value},
            onSelectionChanged: (set) => setState(() => _pnValues[label] = set.first),
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
}