//File upload screen to upload medical documents
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:convert'; // For jsonDecode
import 'package:http/http.dart' as http; // For http.MultipartRequest
import '../../core/secure_storage.dart'; // Ensure this path matches your project structure
import '../../core/constants.dart'; // Ensure this path matches your project structure

class UploadScreen extends StatefulWidget {
  const UploadScreen({super.key});

  @override
  State<UploadScreen> createState() => _UploadScreenState();
}

class _UploadScreenState extends State<UploadScreen> {
  String? selectedFileName;

<<<<<<< Updated upstream
=======
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

  PlatformFile? _pickedFile;
>>>>>>> Stashed changes
  Future<void> pickFile() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.custom,
     allowedExtensions: ['vcf', 'txt', 'csv'],
     withData: true,
     );

    if (result != null) {
      setState(() => selectedFileName = result.files.single.name);
      
      if (_selectedType == UploadType.geneExpression) {
        _uploadAndAnalyze(result.files.single);      }
    }
  }

<<<<<<< Updated upstream
=======
 Future<void> _uploadAndAnalyze(PlatformFile file) async {
    // 1. Show Loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );
  
    try {
      var request = http.MultipartRequest('POST', Uri.parse("${baseUrl}gene-upload/"));
      
      final token = await SecureStorage.readToken();
      if (token != null) {
        request.headers['Authorization'] = 'Bearer $token';
      }

      // WEB FIX: Check if bytes are available (Standard for Web)
      if (file.bytes != null) {
        request.files.add(http.MultipartFile.fromBytes(
          'file',
          file.bytes!,
          filename: file.name,
        ));
      } else if (file.path != null) {
        // Fallback for Mobile/Desktop
        request.files.add(await http.MultipartFile.fromPath('file', file.path!));
      } else {
        throw Exception("File data is inaccessible.");
      }

      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      Navigator.pop(context); // remove loading dialog FIRST

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        _showResultDialog(
          (data['percentage'] as num).toDouble(),
          data['label'],
        );
      } else {
        // DO NOT jsonDecode blindly
        String errorMessage = "Upload failed";

        try {
          final errorData = jsonDecode(response.body);
          errorMessage = errorData['error'] ?? errorMessage;
        } catch (_) {
          errorMessage = response.body; // fallback
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMessage)),
        );
      }


    } catch (e) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Upload Failed: $e")));
    }
  }

  void _showResultDialog(double percentage, String label) {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text("Analysis Results"),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text("Rheumatoid Arthritis Probability:"),
          const SizedBox(height: 10),
          Text("$percentage%", 
            style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, 
            color: percentage > 50 ? Colors.red : Colors.green)),
          Text("Classification: $label"),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text("OK")),
      ],
    ),
  );
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

>>>>>>> Stashed changes
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Upload')),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ElevatedButton.icon(
              onPressed: pickFile,
              icon: const Icon(Icons.upload_file),
              label: const Text('Upload File'),
            ),
            if (selectedFileName != null) ...[
              const SizedBox(height: 12),
              Text('Uploaded: $selectedFileName'),
            ],
          ],
        ),
      ),
    );
  }
}
