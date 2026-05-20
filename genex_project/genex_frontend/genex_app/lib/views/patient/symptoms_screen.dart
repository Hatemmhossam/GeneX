import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import '../../core/secure_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../viewmodels/providers.dart';
import 'package:genex_app/l10n/app_localizations.dart';
//done
class SymptomReportScreen extends ConsumerStatefulWidget {
  const SymptomReportScreen({super.key});

  @override
  ConsumerState<SymptomReportScreen> createState() =>
      _SymptomReportScreenState();
}

class _SymptomReportScreenState
    extends ConsumerState<SymptomReportScreen> {
  final Dio _dio = Dio(
    BaseOptions(
      baseUrl: "http://localhost:8000/api/",
    ),
  );

  final _formKey = GlobalKey<FormState>();

  final _notesController =
      TextEditingController();

  bool _isAdding = false;

  String? _selectedSymptom;

  String _selectedFrequency =
      'Occasionally';

  double _severity = 5.0;

  final List<String> _autoimmuneSymptoms = [
    'Joint Pain / Stiffness',
    'Chronic Fatigue',
    'Muscle Weakness',
    'Skin Rash / Inflammation',
    'Digestive Issues (IBD)',
    'Brain Fog / Memory Loss',
    'Numbness / Tingling',
    'Sensitivity to Light',
    'Hair Loss',
  ];

  final List<String> _frequencies = [
    'Constantly',
    'Daily',
    'Occasionally',
    'Rarely',
  ];

  Future<void> _submitReport() async {
    final loc =
        AppLocalizations.of(context)!;

    if (!_formKey.currentState!
            .validate() ||
        _selectedSymptom == null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          content: Text(
            loc.pleaseSelectSymptom,
          ),
        ),
      );
      return;
    }

    setState(() => _isAdding = true);

    final token =
        await SecureStorage.readToken();

    try {
      final response = await _dio.post(
        'symptoms/',
        data: {
          "symptom_name":
              _selectedSymptom,
          "severity":
              _severity.toInt(),
          "frequency":
              _selectedFrequency,
          "notes":
              _notesController.text
                  .trim(),
        },
        options: Options(
          headers: {
            "Authorization":
                "Bearer $token",
          },
        ),
      );

      if (response.statusCode == 201) {
        ref.invalidate(
          symptomsProvider,
        );

        ScaffoldMessenger.of(context)
            .showSnackBar(
          SnackBar(
            content: Text(
              loc
                  .symptomReportedSuccessfully,
            ),
          ),
        );

        _notesController.clear();

        setState(() {
          _selectedSymptom = null;
          _severity = 5.0;
        });
      }
    } catch (e) {
      debugPrint(
        "Symptom Add Error: $e",
      );

      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          content: Text(
            loc.failedToSaveReport,
          ),
        ),
      );
    } finally {
      setState(
        () => _isAdding = false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc =
        AppLocalizations.of(context)!;

    return SingleChildScrollView(
      padding:
          const EdgeInsets.all(24),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            Text(
              loc.dailySymptomTracker,
              style: const TextStyle(
                fontSize: 24,
                fontWeight:
                    FontWeight.bold,
              ),
            ),
            Text(
              loc
                  .dailySymptomTrackerDescription,
              style: const TextStyle(
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 30),

            DropdownButtonFormField<
                String>(
              value: _selectedSymptom,
              decoration: InputDecoration(
                labelText:
                    loc.whatAreYouExperiencing,
                border:
                    OutlineInputBorder(
                  borderRadius:
                      BorderRadius
                          .circular(
                              10),
                ),
                prefixIcon:
                    const Icon(
                  Icons.sick,
                ),
              ),
              items:
                  _autoimmuneSymptoms
                      .map((s) {
                return DropdownMenuItem(
                  value: s,
                  child: Text(s),
                );
              }).toList(),
              onChanged: (val) =>
                  setState(
                () => _selectedSymptom =
                    val,
              ),
            ),

            const SizedBox(height: 25),

            Text(
              "${loc.severityLevel}: ${_severity.toInt()}/10",
              style:
                  const TextStyle(
                fontSize: 16,
                fontWeight:
                    FontWeight.w600,
              ),
            ),

            Slider(
              value: _severity,
              min: 0,
              max: 10,
              divisions: 10,
              label: _severity
                  .round()
                  .toString(),
              activeColor:
                  _severity > 7
                      ? Colors.red
                      : Colors.teal,
              onChanged: (val) =>
                  setState(
                () => _severity = val,
              ),
            ),

            Row(
              mainAxisAlignment:
                  MainAxisAlignment
                      .spaceBetween,
              children: [
                Text(
                  loc.mild,
                  style:
                      const TextStyle(
                    color: Colors.grey,
                  ),
                ),
                Text(
                  loc.unbearable,
                  style:
                      const TextStyle(
                    color: Colors.grey,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 25),

            DropdownButtonFormField<
                String>(
              value: _selectedFrequency,
              decoration: InputDecoration(
                labelText:
                    loc.howOften,
                border:
                    OutlineInputBorder(
                  borderRadius:
                      BorderRadius
                          .circular(
                              10),
                ),
                prefixIcon:
                    const Icon(
                  Icons.timer,
                ),
              ),
              items:
                  _frequencies.map(
                (f) {
                  return DropdownMenuItem(
                    value: f,
                    child: Text(f),
                  );
                },
              ).toList(),
              onChanged: (val) =>
                  setState(
                () =>
                    _selectedFrequency =
                        val!,
              ),
            ),

            const SizedBox(height: 25),

            TextFormField(
              controller:
                  _notesController,
              maxLines: 3,
              decoration: InputDecoration(
                labelText: loc
                    .additionalNotes,
                hintText:
                    loc.notesHint,
                border:
                    OutlineInputBorder(
                  borderRadius:
                      BorderRadius
                          .circular(
                              10),
                ),
              ),
            ),

            const SizedBox(height: 30),

            SizedBox(
              width: double.infinity,
              height: 50,
              child:
                  ElevatedButton(
                style:
                    ElevatedButton
                        .styleFrom(
                  backgroundColor:
                      Colors.teal,
                  shape:
                      RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius
                            .circular(
                                10),
                  ),
                ),
                onPressed:
                    _isAdding
                        ? null
                        : _submitReport,
                child: _isAdding
                    ? const CircularProgressIndicator(
                        color:
                            Colors
                                .white,
                      )
                    : Text(
                        loc
                            .logSymptom,
                        style:
                            const TextStyle(
                          color: Colors
                              .white,
                          fontSize: 16,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}