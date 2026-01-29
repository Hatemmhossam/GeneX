// File upload screen to upload medical documents
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';

enum UploadType { vcf, geneExpression, tests }

class UploadScreen extends StatefulWidget {
  const UploadScreen({super.key});

  @override
  State<UploadScreen> createState() => _UploadScreenState();
}

class _UploadScreenState extends State<UploadScreen> {
  UploadType _selectedType = UploadType.vcf;
  String? selectedFileName;

  // Integer test controllers
  final _esrController = TextEditingController();
  final _crpController = TextEditingController();
  final _antiCcpController = TextEditingController();
  final _rfController = TextEditingController();
  final _c3Controller = TextEditingController();
  final _c4Controller = TextEditingController();

  // Positive/Negative test values (true=Positive, false=Negative)
  final Map<String, bool> _pnValues = {
    "ANA": false,
    "Anti-Sm": false,
    "Anti-Ro": false,
    "HLA-B27": false,
    "Anti-La": false,
    "Anti-dsDNA": false,
  };

  Future<void> pickFile() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.any);
    if (result != null) {
      setState(() => selectedFileName = result.files.single.name);
    }
  }

  String _titleForType(UploadType type) {
    switch (type) {
      case UploadType.vcf:
        return "Upload VCF File";
      case UploadType.geneExpression:
        return "Upload Gene Expression File";
      case UploadType.tests:
        return "Enter Tests";
    }
  }

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

  @override
  Widget build(BuildContext context) {
    final title = _titleForType(_selectedType);

    return Scaffold(
      appBar: AppBar(title: const Text('Upload')),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Choice box (dropdown)
                DropdownButtonFormField<UploadType>(
                  value: _selectedType,
                  decoration: const InputDecoration(
                    labelText: "Choose upload type",
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: UploadType.vcf,
                      child: Text("VCF"),
                    ),
                    DropdownMenuItem(
                      value: UploadType.geneExpression,
                      child: Text("Gene Expression"),
                    ),
                    DropdownMenuItem(
                      value: UploadType.tests,
                      child: Text("Tests"),
                    ),
                  ],
                  onChanged: (val) {
                    if (val == null) return;
                    setState(() {
                      _selectedType = val;
                      selectedFileName = null; // reset file label when switching
                    });
                  },
                ),

                const SizedBox(height: 18),
                Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),

                // Dynamic section
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
                  // TESTS UI
                  const Text("Enter numeric results and select Positive/Negative."),
                  const SizedBox(height: 12),

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
                  const SizedBox(height: 10),

                  ..._pnValues.keys.map((label) => _positiveNegativeRow(label)).toList(),

                  const SizedBox(height: 18),
                  ElevatedButton(
                    onPressed: () {
                      // Example: collect values (you can send to backend)
                      final int? esr = int.tryParse(_esrController.text);
                      final int? crp = int.tryParse(_crpController.text);

                      // You can validate here if you want.
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Tests saved (example).")),
                      );
                    },
                    child: const Text("Save Tests"),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _numberField(String label, TextEditingController controller) {
    return TextFormField(
      controller: controller,
      keyboardType: TextInputType.number,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
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
              ButtonSegment(value: true, label: Text("Positive")),
              ButtonSegment(value: false, label: Text("Negative")),
            ],
            selected: {value},
            onSelectionChanged: (set) {
              setState(() {
                _pnValues[label] = set.first;
              });
            },
          ),
        ],
      ),
    );
  }
}
