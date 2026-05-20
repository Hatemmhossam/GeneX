import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:genex_app/l10n/app_localizations.dart';

import '../../core/secure_storage.dart';
import '../../viewmodels/providers.dart';
import '../../widgets/loading_button.dart';
import '../../widgets/premium_card.dart';

class SymptomReportScreen extends ConsumerStatefulWidget {
  const SymptomReportScreen({super.key});

  @override
  ConsumerState<SymptomReportScreen> createState() =>
      _SymptomReportScreenState();
}

class _SymptomReportScreenState extends ConsumerState<SymptomReportScreen> {
  final Dio _dio = Dio(
    BaseOptions(
      baseUrl: "http://localhost:8000/api/",
    ),
  );

  final _formKey = GlobalKey<FormState>();
  final _notesController = TextEditingController();

  bool _isAdding = false;
  String? _selectedSymptom;
  String _selectedFrequency = 'Occasionally';
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

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _submitReport() async {
    final loc = AppLocalizations.of(context)!;

    if (!_formKey.currentState!.validate() || _selectedSymptom == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(loc.pleaseSelectSymptom),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => _isAdding = true);

    final token = await SecureStorage.readToken();

    try {
      final response = await _dio.post(
        'symptoms/',
        data: {
          "symptom_name": _selectedSymptom,
          "severity": _severity.toInt(),
          "frequency": _selectedFrequency,
          "notes": _notesController.text.trim(),
        },
        options: Options(
          headers: {
            "Authorization": "Bearer $token",
          },
        ),
      );

      if (response.statusCode == 201) {
        ref.invalidate(symptomsProvider);

        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(loc.symptomReportedSuccessfully),
            behavior: SnackBarBehavior.floating,
          ),
        );

        _notesController.clear();

        setState(() {
          _selectedSymptom = null;
          _severity = 5.0;
          _selectedFrequency = 'Occasionally';
        });
      }
    } catch (e) {
      debugPrint("Symptom Add Error: $e");

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(loc.failedToSaveReport),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.redAccent,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isAdding = false);
      }
    }
  }

  Widget _buildHeroCard() {
    final theme = Theme.of(context);
    final loc = AppLocalizations.of(context)!;

    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        gradient: LinearGradient(
          colors: [
            const Color(0xFF0F172A),
            theme.colorScheme.primary,
            const Color(0xFF1D4ED8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.primary.withOpacity(0.26),
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
              color: Colors.white.withOpacity(0.16),
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.white.withOpacity(0.22),
              ),
            ),
            child: const Icon(
              Icons.monitor_heart_rounded,
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
                  loc.dailySymptomTracker,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  loc.dailySymptomTrackerDescription,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: Colors.white.withOpacity(0.82),
                    height: 1.45,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 760),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildHeroCard(),
                const SizedBox(height: 24),
                PremiumCard(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      DropdownButtonFormField<String>(
                        value: _selectedSymptom,
                        decoration: InputDecoration(
                          labelText: loc.whatAreYouExperiencing,
                          prefixIcon: Icon(
                            Icons.sick_rounded,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                        items: _autoimmuneSymptoms.map((s) {
                          return DropdownMenuItem(
                            value: s,
                            child: Text(s),
                          );
                        }).toList(),
                        onChanged: (val) {
                          setState(() => _selectedSymptom = val);
                        },
                      ),
                      const SizedBox(height: 24),
                      Text(
                        "${loc.severityLevel}: ${_severity.toInt()}/10",
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      Slider(
                        value: _severity,
                        min: 0,
                        max: 10,
                        divisions: 10,
                        label: _severity.round().toString(),
                        activeColor: _severity > 7
                            ? Colors.redAccent
                            : theme.colorScheme.primary,
                        inactiveColor:
                            theme.colorScheme.primary.withOpacity(0.18),
                        onChanged: (val) {
                          setState(() => _severity = val);
                        },
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            loc.mild,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color:
                                  theme.colorScheme.onSurface.withOpacity(0.55),
                            ),
                          ),
                          Text(
                            loc.unbearable,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color:
                                  theme.colorScheme.onSurface.withOpacity(0.55),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      DropdownButtonFormField<String>(
                        value: _selectedFrequency,
                        decoration: InputDecoration(
                          labelText: loc.howOften,
                          prefixIcon: Icon(
                            Icons.timer_rounded,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                        items: _frequencies.map((f) {
                          return DropdownMenuItem(
                            value: f,
                            child: Text(f),
                          );
                        }).toList(),
                        onChanged: (val) {
                          setState(() => _selectedFrequency = val!);
                        },
                      ),
                      const SizedBox(height: 24),
                      TextFormField(
                        controller: _notesController,
                        maxLines: 3,
                        decoration: InputDecoration(
                          labelText: loc.additionalNotes,
                          hintText: loc.notesHint,
                          prefixIcon: Icon(
                            Icons.notes_rounded,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                      ),
                      const SizedBox(height: 28),
                      LoadingButton(
                        loading: _isAdding,
                        onPressed: _submitReport,
                        label: loc.logSymptom,
                        icon: Icons.add_chart_rounded,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}