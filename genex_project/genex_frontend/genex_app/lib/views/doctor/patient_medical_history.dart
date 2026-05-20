import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:genex_app/l10n/app_localizations.dart';
import '../../viewmodels/providers.dart';
import '../shared/chat_screen.dart';

class PatientMedicalHistoryScreen extends ConsumerStatefulWidget {
  final int patientId;
  final String patientName;

  const PatientMedicalHistoryScreen({
    super.key,
    required this.patientId,
    required this.patientName,
  });

  @override
  ConsumerState<PatientMedicalHistoryScreen> createState() =>
      _PatientMedicalHistoryScreenState();
}

class _PatientMedicalHistoryScreenState
    extends ConsumerState<PatientMedicalHistoryScreen> {
  List<dynamic> medicines = [];
  List<dynamic> symptoms = [];
  List<dynamic> testResults = [];
  List<dynamic> geneReports = [];

  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchPatientData();
  }

  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  Future<void> _openPatientChat() async {
    try {
      final token = await _getToken();

      if (token == null || token.isEmpty) {
        throw Exception('No authentication token found');
      }

      final authState = ref.read(authViewModelProvider);
      final rawDoctorId = authState.user?.id;
      final doctorId = int.tryParse(rawDoctorId?.toString() ?? '');

      if (doctorId == null) {
        throw Exception('Doctor ID not found in auth state');
      }

      final response = await http.post(
        Uri.parse('http://127.0.0.1:8000/api/chat/open/'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'doctor_id': doctorId,
          'patient_id': widget.patientId,
        }),
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to open chat: ${response.body}');
      }

      final data = jsonDecode(response.body);
      final conversationId = data['id'];

      if (!mounted) return;

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ChatScreen(
            conversationId: conversationId,
            receiverName: widget.patientName,
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Unable to open chat: $e'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _fetchPatientData() async {
    final token = await _getToken();

    final url = Uri.parse(
      'http://127.0.0.1:8000/api/doctor/patient-records/${widget.patientId}/',
    );

    try {
      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          medicines = data['medicines'] ?? [];
          symptoms = data['symptoms'] ?? [];
          testResults = data['test_results'] ?? [];
          geneReports = data['gene_prediction_reports'] ?? [];
          _errorMessage = null;
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = "Access Denied or Error: ${response.statusCode}";
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = "Connection Error: $e";
        _isLoading = false;
      });
    }
  }

Future<void> _showNoteDialog(
  int symptomId,
  String currentNotes,
) async {
  final theme = Theme.of(context);

  final TextEditingController noteController =
      TextEditingController(
    text: currentNotes,
  );

  showDialog(
    context: context,
    builder: (context) {
      return AlertDialog(
        backgroundColor: theme.colorScheme.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
        ),

        title: Text(
          "Add Doctor Note",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.onSurface,
          ),
        ),

        content: TextField(
          controller: noteController,
          style: TextStyle(
            color: theme.colorScheme.onSurface,
          ),
          decoration: InputDecoration(
            hintText: "Enter instructions or observations...",
            hintStyle: TextStyle(
              color: theme.colorScheme.onSurface.withOpacity(0.5),
            ),

            filled: true,
            fillColor: theme.inputDecorationTheme.fillColor,

            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(
                color: theme.dividerColor.withOpacity(0.2),
              ),
            ),

            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(
                color: theme.dividerColor.withOpacity(0.2),
              ),
            ),

            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(
                color: theme.colorScheme.primary,
              ),
            ),
          ),
          maxLines: 4,
        ),

        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              "Cancel",
              style: TextStyle(
                color: theme.colorScheme.primary,
              ),
            ),
          ),

          ElevatedButton.icon(
            onPressed: () async {
              if (noteController.text.trim().isNotEmpty) {
                Navigator.pop(context);

                await _saveDoctorNote(
                  symptomId,
                  noteController.text.trim(),
                );
              }
            },

            icon: const Icon(
              Icons.save_outlined,
              size: 18,
            ),

            label: const Text("Save"),

            style: ElevatedButton.styleFrom(
              backgroundColor: theme.colorScheme.primary,
              foregroundColor: Colors.white,

              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 10,
              ),

              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      );
    },
  );
}

 Future<void> _saveDoctorNote(int symptomId, String note) async {
  final theme = Theme.of(context);
  final token = await _getToken();

  final url = Uri.parse(
    'http://127.0.0.1:8000/api/doctor/add-note/$symptomId/',
  );

  try {
    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({'note': note}),
    );

    if (!mounted) return;

    if (response.statusCode == 200) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text("Note Saved!"),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );

      _fetchPatientData();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error: ${response.statusCode}"),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    }
  } catch (e) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("Connection Error: $e"),
        backgroundColor: Colors.redAccent,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }
}

 String _boolText(dynamic value) {
  return value == true ? "Positive" : "Negative";
}

String _formatDate(dynamic dateValue) {
  if (dateValue == null) return '-';

  final text = dateValue.toString();

  return text.contains('T')
      ? text.split('T')[0]
      : text;
}

String _formatConfidence(dynamic confidence) {
  if (confidence == null) return '-';

  final double val = (confidence as num).toDouble();

  if (val <= 1) {
    return "${(val * 100).toStringAsFixed(1)}%";
  }

  return "${val.toStringAsFixed(1)}%";
}

String _formatRiskPercentage(dynamic value) {
  if (value == null) return '-';

  final double val = (value as num).toDouble();

  return "${val.toStringAsFixed(1)}%";
}

String _formatMetric(dynamic value) {
  if (value == null) return '-';

  final double val = (value as num).toDouble();

  if (val <= 1) {
    return "${(val * 100).toStringAsFixed(1)}%";
  }

  return "${val.toStringAsFixed(1)}%";
}

Widget _sectionTitle(
  String title,
  IconData icon,
  Color color,
) {
  final theme = Theme.of(context);

  return Row(
    children: [
      Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: color.withOpacity(0.12),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Icon(
          icon,
          color: color,
          size: 22,
        ),
      ),

      const SizedBox(width: 12),

      Text(
        title,
        style: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w800,
          color: theme.colorScheme.onSurface,
        ),
      ),
    ],
  );
}

Widget _infoChip(
  String label,
  String value, {
  Color? color,
}) {
  final theme = Theme.of(context);

  final chipColor = color ?? theme.colorScheme.primary;

  return Container(
    padding: const EdgeInsets.symmetric(
      horizontal: 12,
      vertical: 10,
    ),
    decoration: BoxDecoration(
      color: chipColor.withOpacity(0.08),
      borderRadius: BorderRadius.circular(14),
      border: Border.all(
        color: chipColor.withOpacity(0.18),
      ),
    ),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 13,
            color: theme.colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: theme.colorScheme.onSurface.withOpacity(0.65),
          ),
        ),
      ],
    ),
  );
}

Widget _emptyState(
  String text,
  IconData icon,
  Color color,
) {
  final theme = Theme.of(context);

  return Container(
    width: double.infinity,

    padding: const EdgeInsets.symmetric(
      vertical: 24,
      horizontal: 16,
    ),

    decoration: BoxDecoration(
      color: color.withOpacity(0.06),
      borderRadius: BorderRadius.circular(18),

      border: Border.all(
        color: color.withOpacity(0.14),
      ),
    ),

    child: Column(
      children: [
        Icon(
          icon,
          size: 38,
          color: color,
        ),

        const SizedBox(height: 10),

        Text(
          text,
          textAlign: TextAlign.center,

          style: TextStyle(
            color: theme.colorScheme.onSurface.withOpacity(0.7),
            fontSize: 15,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    ),
  );
}

 Widget _buildHeaderCard() {
  final theme = Theme.of(context);
  final isDark = theme.brightness == Brightness.dark;

  return Container(
    width: double.infinity,
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      gradient: LinearGradient(
  colors: [
    const Color(0xFF0F172A),
    theme.colorScheme.primary,
    const Color(0xFF1D4ED8),
  ],
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
),
      borderRadius: BorderRadius.circular(24),
      boxShadow: [
        if (!isDark)
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
      ],
    ),
    child: Column(
      children: [
        Row(
          children: [
            CircleAvatar(
              radius: 30,
              backgroundColor: Colors.white.withOpacity(0.18),
              child: const Icon(
                Icons.person,
                color: Colors.white,
                size: 32,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Patient Medical History",
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    widget.patientName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Review medicines, symptoms, test results, gene reports, and doctor notes.",
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.92),
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),
        Align(
          alignment: Alignment.centerLeft,
          child: ElevatedButton.icon(
            onPressed: _openPatientChat,
            icon: const Icon(Icons.chat_bubble_outline),
            label: const Text("Chat with Patient"),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: theme.colorScheme.primary,
              padding: const EdgeInsets.symmetric(
                horizontal: 18,
                vertical: 12,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
        ),
      ],
    ),
  );
}

Widget _buildMedicinesSection() {
  final theme = Theme.of(context);
  final isDark = theme.brightness == Brightness.dark;

  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      _sectionTitle(
        "Medicines",
        Icons.medication_outlined,
        Colors.blue,
      ),

      const SizedBox(height: 14),

      medicines.isEmpty
          ? _emptyState(
              "No medicines recorded.",
              Icons.medication_liquid_outlined,
              Colors.blue,
            )
          : ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: medicines.length,
              itemBuilder: (context, index) {
                final med = medicines[index];

                return Container(
                  margin: const EdgeInsets.only(bottom: 12),

                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface,
                    borderRadius: BorderRadius.circular(18),

                    boxShadow: [
                      if (!isDark)
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 12,
                          offset: const Offset(0, 6),
                        ),
                    ],
                  ),

                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),

                    leading: Container(
                      padding: const EdgeInsets.all(10),

                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),

                      child: Icon(
                        Icons.medication,
                        color: theme.colorScheme.primary,
                      ),
                    ),

                    title: Text(
                      med['name'] ?? 'Unknown Drug',

                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),

                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 6),

                      child: Text(
                        "Added: ${_formatDate(med['added_at'])}",

                        style: TextStyle(
                          color: theme.colorScheme.onSurface
                              .withOpacity(0.65),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
    ],
  );
}

 Widget _buildSymptomsSection() {
  final theme = Theme.of(context);
  final isDark = theme.brightness == Brightness.dark;

  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      _sectionTitle(
        "Symptoms",
        Icons.warning_amber_rounded,
        Colors.orange,
      ),

      const SizedBox(height: 14),

      symptoms.isEmpty
          ? _emptyState(
              "No symptoms reported.",
              Icons.health_and_safety_outlined,
              Colors.orange,
            )
          : ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: symptoms.length,
              itemBuilder: (context, index) {
                final sym = symptoms[index];

                return Container(
                  margin: const EdgeInsets.only(bottom: 14),

                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface,
                    borderRadius: BorderRadius.circular(18),

                    border: Border.all(
                      color: theme.dividerColor.withOpacity(0.2),
                    ),
                  ),

                  child: Padding(
                    padding: const EdgeInsets.all(14),

                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,

                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),

                              decoration: BoxDecoration(
                                color: Colors.orange.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(12),
                              ),

                              child: Icon(
                                Icons.warning_amber_rounded,
                                color: theme.colorScheme.primary,
                              ),
                            ),

                            const SizedBox(width: 12),

                            Expanded(
                              child: Text(
                                sym['symptom_name'] ??
                                    sym['symptom'] ??
                                    'Unknown',

                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: theme.colorScheme.onSurface,
                                ),
                              ),
                            ),

                            IconButton(
                              icon: const Icon(
                                Icons.edit_note_rounded,
                                color: Colors.blue,
                                size: 28,
                              ),

                              onPressed: () {
                                _showNoteDialog(
                                  sym['id'],
                                  sym['notes'] ?? "",
                                );
                              },
                            ),
                          ],
                        ),

                        const SizedBox(height: 10),

                        Wrap(
                          spacing: 10,
                          runSpacing: 10,

                          children: [
                            _infoChip(
                              "Severity",
                              "${sym['severity'] ?? '-'} / 10",
                              color: Colors.orange,
                            ),

                            if (sym['frequency'] != null)
                              _infoChip(
                                "Frequency",
                                "${sym['frequency']}",
                                color: Colors.deepOrange,
                              ),
                          ],
                        ),

                        if (sym['notes'] != null &&
                            sym['notes'].toString().isNotEmpty) ...[
                          const SizedBox(height: 12),

                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(12),

                            decoration: BoxDecoration(
                              color: theme.scaffoldBackgroundColor,
                              borderRadius: BorderRadius.circular(14),

                              border: Border.all(
                                color: theme.dividerColor
                                    .withOpacity(0.2),
                              ),
                            ),

                            child: Text(
                              "Doctor Notes:\n${sym['notes']}",

                              style: TextStyle(
                                color: theme.colorScheme.onSurface
                                    .withOpacity(0.75),
                                height: 1.45,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              },
            ),
    ],
  );
}
 Widget _buildTestsSection() {
  final theme = Theme.of(context);
  final isDark = theme.brightness == Brightness.dark;

  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      _sectionTitle(
        "Test Results",
        Icons.science_outlined,
        theme.colorScheme.primary,
      ),

      const SizedBox(height: 14),

      testResults.isEmpty
          ? _emptyState(
              "No test results recorded.",
              Icons.biotech_outlined,
              theme.colorScheme.primary,
            )
          : ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: testResults.length,

              itemBuilder: (context, index) {
                final test = testResults[index];

                return Container(
                  margin: const EdgeInsets.only(bottom: 14),

                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface,
                    borderRadius: BorderRadius.circular(20),

                    boxShadow: [
                      if (!isDark)
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 14,
                          offset: const Offset(0, 8),
                        ),
                    ],
                  ),

                  child: Theme(
                    data: Theme.of(context).copyWith(
                      dividerColor: Colors.transparent,
                    ),

                    child: ExpansionTile(
                      tilePadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),

                      childrenPadding: const EdgeInsets.fromLTRB(
                        16,
                        0,
                        16,
                        16,
                      ),

                      leading: CircleAvatar(
                        radius: 24,
                        backgroundColor: theme.colorScheme.primary.withOpacity(0.12),

                        child: Icon(
                          Icons.science,
                          color: theme.colorScheme.primary,
                        ),
                      ),

                      title: Text(
                        test['disease_prediction'] ??
                            'Unknown Prediction',

                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),

                      subtitle: Padding(
                        padding: const EdgeInsets.only(top: 6),

                        child: Text(
                          "Confidence: ${_formatConfidence(test['confidence'])}",

                          style: TextStyle(
                            color: theme.colorScheme.onSurface
                                .withOpacity(0.65),
                          ),
                        ),
                      ),

                      children: [
                        Wrap(
                          spacing: 10,
                          runSpacing: 10,

                          children: [
                            _infoChip(
                              "Age",
                              "${test['age'] ?? '-'}",
                            ),

                            _infoChip(
                              "Gender",
                              "${test['gender'] ?? '-'}",
                            ),

                            _infoChip(
                              "ESR",
                              "${test['esr'] ?? '-'}",
                            ),

                            _infoChip(
                              "CRP",
                              "${test['crp'] ?? '-'}",
                            ),

                            _infoChip(
                              "RF",
                              "${test['rf'] ?? '-'}",
                            ),

                            _infoChip(
                              "Anti-CCP",
                              "${test['anti_ccp'] ?? '-'}",
                            ),

                            _infoChip(
                              "C3",
                              "${test['c3'] ?? '-'}",
                            ),

                            _infoChip(
                              "C4",
                              "${test['c4'] ?? '-'}",
                            ),

                            _infoChip(
                              "ANA",
                              _boolText(test['ana']),
                            ),

                            _infoChip(
                              "Anti-Sm",
                              _boolText(test['anti_sm']),
                            ),

                            _infoChip(
                              "Anti-Ro",
                              _boolText(test['anti_ro']),
                            ),

                            _infoChip(
                              "HLA-B27",
                              _boolText(test['hla_b27']),
                            ),

                            _infoChip(
                              "Anti-La",
                              _boolText(test['anti_la']),
                            ),

                            _infoChip(
                              "Anti-dsDNA",
                              _boolText(test['anti_dsdna']),
                            ),
                          ],
                        ),

                        const SizedBox(height: 16),

                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(14),

                          decoration: BoxDecoration(
                            color: theme.scaffoldBackgroundColor,
                            borderRadius: BorderRadius.circular(16),

                            border: Border.all(
                              color: theme.dividerColor
                                  .withOpacity(0.2),
                            ),
                          ),

                          child: Text(
                            "XAI Explanation:\n${test['xai_explanation'] ?? 'No explanation available'}",

                            style: TextStyle(
                              color: theme.colorScheme.onSurface
                                  .withOpacity(0.75),
                              height: 1.45,
                            ),
                          ),
                        ),

                        const SizedBox(height: 12),

                        Row(
                          children: [
                            Icon(
                              Icons.calendar_today_outlined,
                              size: 15,
                              color: theme.colorScheme.onSurface
                                  .withOpacity(0.55),
                            ),

                            const SizedBox(width: 6),

                            Text(
                              "Date: ${_formatDate(test['created_at'])}",

                              style: TextStyle(
                                fontSize: 12.5,
                                color: theme.colorScheme.onSurface
                                    .withOpacity(0.55),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    ],
  );
}

  Widget _buildGeneReportsSection() {
  final theme = Theme.of(context);
  final isDark = theme.brightness == Brightness.dark;

  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      _sectionTitle(
        "Gene Expression Reports",
        Icons.analytics_outlined,
        Colors.purple,
      ),

      const SizedBox(height: 14),

      geneReports.isEmpty
          ? _emptyState(
              "No gene expression reports recorded.",
              Icons.insert_chart_outlined_rounded,
              Colors.purple,
            )
          : ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: geneReports.length,

              itemBuilder: (context, index) {
                final report = geneReports[index];
                final topGenes = report['top_affecting_genes'];

                return Container(
                  margin: const EdgeInsets.only(bottom: 14),

                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface,
                    borderRadius: BorderRadius.circular(20),

                    boxShadow: [
                      if (!isDark)
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 14,
                          offset: const Offset(0, 8),
                        ),
                    ],
                  ),

                  child: Theme(
                    data: Theme.of(context).copyWith(
                      dividerColor: Colors.transparent,
                    ),

                    child: ExpansionTile(
                      tilePadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),

                      childrenPadding: const EdgeInsets.fromLTRB(
                        16,
                        0,
                        16,
                        16,
                      ),

                      leading: CircleAvatar(
                        radius: 24,
                        backgroundColor:
                            Colors.purple.withOpacity(0.12),

                        child: Icon(
                          Icons.analytics_outlined,
                          color: theme.colorScheme.primary,
                        ),
                      ),

                      title: Text(
                        report['result_label'] ??
                            'Unknown Result',

                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),

                      subtitle: Padding(
                        padding: const EdgeInsets.only(top: 6),

                        child: Text(
                          "Risk: ${_formatRiskPercentage(report['risk_percentage'])}",

                          style: TextStyle(
                            color: theme.colorScheme.onSurface
                                .withOpacity(0.65),
                          ),
                        ),
                      ),

                      children: [
                        Wrap(
                          spacing: 10,
                          runSpacing: 10,

                          children: [
                            _infoChip(
                              "Risk",
                              _formatRiskPercentage(
                                report['risk_percentage'],
                              ),
                              color: Colors.purple,
                            ),

                            _infoChip(
                              "Precision",
                              _formatMetric(report['precision']),
                              color: Colors.indigo,
                            ),

                            _infoChip(
                              "Recall",
                              _formatMetric(report['recall']),
                              color: Colors.deepPurple,
                            ),

                            _infoChip(
                              "F1 Score",
                              _formatMetric(report['f1_score']),
                              color: Colors.pink,
                            ),
                          ],
                        ),

                        const SizedBox(height: 14),

                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(14),

                          decoration: BoxDecoration(
                            color: theme.scaffoldBackgroundColor,
                            borderRadius: BorderRadius.circular(16),

                            border: Border.all(
                              color: theme.dividerColor
                                  .withOpacity(0.2),
                            ),
                          ),

                          child: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,

                            children: [
                              Text(
                                "File Name: ${report['file_name'] ?? '-'}",

                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: theme.colorScheme.onSurface,
                                ),
                              ),

                              const SizedBox(height: 8),

                              Text(
                                "Confidence Interval: ${report['risk_percentage'] ?? '-'}",

                                style: TextStyle(
                                  color: theme.colorScheme.onSurface
                                      .withOpacity(0.75),
                                ),
                              ),

                              const SizedBox(height: 8),

                              Text(
                                "Created At: ${_formatDate(report['created_at'])}",

                                style: TextStyle(
                                  color: theme.colorScheme.onSurface
                                      .withOpacity(0.75),
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 14),

                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(14),

                          decoration: BoxDecoration(
                            color: theme.scaffoldBackgroundColor,
                            borderRadius: BorderRadius.circular(16),

                            border: Border.all(
                              color: theme.dividerColor
                                  .withOpacity(0.2),
                            ),
                          ),

                          child: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,

                            children: [
                              Text(
                                "Top Affecting Genes",

                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                  color: theme.colorScheme.onSurface,
                                ),
                              ),

                              const SizedBox(height: 8),

                              Text(
                                topGenes == null
                                    ? "No genes available"
                                    : const JsonEncoder.withIndent(
                                        '  ',
                                      ).convert(topGenes),

                                style: TextStyle(
                                  color: theme.colorScheme.onSurface
                                      .withOpacity(0.75),
                                  height: 1.45,
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 12),
                      ],
                    ),
                  ),
                );
              },
            ),
    ],
  );
}

 Widget _buildErrorState() {
  final theme = Theme.of(context);
  final isDark = theme.brightness == Brightness.dark;

  return Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: isDark
              ? Colors.red.withOpacity(0.12)
              : Colors.red.shade50,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: isDark
                ? Colors.red.withOpacity(0.35)
                : Colors.red.shade100,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline,
              color: isDark ? Colors.red.shade300 : Colors.red.shade400,
              size: 46,
            ),
            const SizedBox(height: 12),
            Text(
              "Something went wrong",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
                color: theme.colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage ?? "Unknown error",
              textAlign: TextAlign.center,
              style: TextStyle(
                color: theme.colorScheme.onSurface.withOpacity(0.65),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () {
                setState(() => _isLoading = true);
                _fetchPatientData();
              },
              icon: const Icon(Icons.refresh),
              label: const Text("Try Again"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.shade400,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

Widget _buildLoadingState() {
  final theme = Theme.of(context);

  return Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        CircularProgressIndicator(
          color: theme.colorScheme.primary,
          strokeWidth: 3,
        ),
        const SizedBox(height: 14),
        Text(
          "Loading patient records...",
          style: TextStyle(
            color: theme.colorScheme.onSurface.withOpacity(0.65),
            fontSize: 15,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    ),
  );
}

@override
Widget build(BuildContext context) {
  final theme = Theme.of(context);
  final loc = AppLocalizations.of(context)!;

  return Scaffold(
    backgroundColor: theme.scaffoldBackgroundColor,
    appBar: AppBar(
      elevation: 0,
      backgroundColor: theme.appBarTheme.backgroundColor,
      foregroundColor: theme.colorScheme.onSurface,
      centerTitle: true,
      title: Text(
        loc.patientRecords,
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: theme.colorScheme.onSurface,
        ),
      ),
    ),
    body: _isLoading
        ? _buildLoadingState()
        : _errorMessage != null
            ? _buildErrorState()
            : RefreshIndicator(
                onRefresh: _fetchPatientData,
                color: theme.colorScheme.primary,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHeaderCard(),
                      const SizedBox(height: 22),
                      _buildMedicinesSection(),
                      const SizedBox(height: 28),
                      _buildSymptomsSection(),
                      const SizedBox(height: 28),
                      _buildTestsSection(),
                      const SizedBox(height: 28),
                      _buildGeneReportsSection(),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
  );
}
    }