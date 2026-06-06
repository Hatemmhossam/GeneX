import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:genex_app/l10n/app_localizations.dart';
import '../../widgets/loading_button.dart';
import '../../widgets/premium_card.dart';
import '../../core/secure_storage.dart';
import 'package:flutter_animate/flutter_animate.dart';
//done 

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() =>
      _ProfileScreenState();
}

class _ProfileScreenState
    extends State<ProfileScreen> {
  final nameController =
      TextEditingController();

  String selectedGender = 'male';

  int selectedAge = 18;

  int selectedHeight = 160;

  int selectedWeight = 60;

  bool isSaving = false;

  bool isFetching = true;

  @override
  void initState() {
    super.initState();
    fetchProfile();
  }

  @override
  void dispose() {
    nameController.dispose();
    super.dispose();
  }

  Future<void> fetchProfile() async {
    final token =
        await SecureStorage.readToken();

    if (token == null) {
      if (mounted) {
        setState(
          () => isFetching = false,
        );
      }

      return;
    }
    //retrieve api from urls.py that takes functions from views.py
    try {
      final url = Uri.parse(
        'http://localhost:8000/api/profile/',
      );

      final response =
          await http.get(
        url,
        headers: {
          'Authorization':
              'Bearer $token',
          'Content-Type':
              'application/json',
        },
      );

      if (response.statusCode ==
          200) {
        final data = json.decode(
          response.body,
        );

        if (mounted) {
          setState(() {
            nameController.text =
                data['first_name']
                        ?.toString() ??
                    data['username'] ??
                    '';

            selectedGender =
                data['gender']
                        ?.toString()
                        .toLowerCase() ??
                    'male';

            selectedAge =
                data['age'] != null
                    ? (data['age']
                        as int)
                    : 18;

            selectedHeight =
                data['height'] != null
                    ? (data['height']
                            as num)
                        .toInt()
                    : 160;

            selectedWeight =
                data['weight'] != null
                    ? (data['weight']
                            as num)
                        .toInt()
                    : 60;
          });
        }
      }
    } catch (e) {
      debugPrint(
        "Fetch error: $e",
      );
    } finally {
      if (mounted) {
        setState(
          () => isFetching = false,
        );
      }
    }
  }

  Future<void> saveProfile() async {
    final loc =
        AppLocalizations.of(context)!;

    final token =
        await SecureStorage.readToken();

    if (token == null) {
      return;
    }

    setState(
      () => isSaving = true,
    );

    try {
      final response =
          await http.patch(
        Uri.parse(
          'http://localhost:8000/api/profile/',
        ),
        headers: {
          'Authorization':
              'Bearer $token',
          'Content-Type':
              'application/json',
        },
        body: json.encode({
          'age': selectedAge,
          'gender':
              selectedGender,
          'weight':
              selectedWeight
                  .toDouble(),
          'height':
              selectedHeight
                  .toDouble(),
        }),
      );

      if (!mounted) return;

      if (response.statusCode ==
          200) {
        ScaffoldMessenger.of(context)
            .showSnackBar(
          SnackBar(
            content: Text(
              loc
                  .medicalRecordUpdated,
            ),
            behavior:
                SnackBarBehavior
                    .floating,
          ),
        );
      }
    } catch (e) {
      debugPrint(
        "Update error: $e",
      );
    } finally {
      if (mounted) {
        setState(
          () => isSaving = false,
        );
      }
    }
  }

@override
Widget build(BuildContext context) {
  final loc = AppLocalizations.of(context)!;
  final theme = Theme.of(context);

  if (isFetching) {
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,

      body: Center(
        child: CircularProgressIndicator(
          color: theme.colorScheme.primary,
        ),
      ),
    );
  }

  return Scaffold(
    backgroundColor: theme.scaffoldBackgroundColor,
    appBar: AppBar(
      title: Text(
        loc.patientMedicalFile,
        style: theme.textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w900,
        ),
      ),
      actions: [
        IconButton(
          icon: Icon(
            Icons.settings_rounded,
            color: theme.colorScheme.primary,
          ),
          onPressed: () {
            Navigator.pushNamed(context, '/settings');
          },
        ),
      ],
    ),
    body: Center(
  child: ConstrainedBox(
    constraints: const BoxConstraints(maxWidth: 950),
    child: SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildProfileHero()
              .animate()
              .slideY(
                begin: -0.05,
                duration: 300.ms,
                curve: Curves.easeOutCubic,
              ),

          const SizedBox(height: 24),

          PremiumCard(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  loc.coreHealthMetrics,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),

                const SizedBox(height: 20),

                _buildReadOnlyField(
                  nameController,
                  loc.fullName,
                  Icons.lock_outline_rounded,
                  loc.contactAdmin,
                ),

                const SizedBox(height: 20),

                LayoutBuilder(
                  builder: (context, constraints) {
                    return GridView(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate:
                          SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount:
                            constraints.maxWidth > 620 ? 2 : 1,
                        crossAxisSpacing: 18,
                        mainAxisSpacing: 18,
                        mainAxisExtent: 90,
                      ),
                      children: [
                        _buildDropdown<String>(
                          label: loc.genderIdentity,
                          icon: Icons.wc_outlined,
                          value: selectedGender,
                          items: const ['male', 'female'],
                          onChanged: (val) {
                            setState(() {
                              selectedGender = val!;
                            });
                          },
                        ),

                        _buildDropdown<int>(
                          label: loc.currentAge,
                          icon: Icons.calendar_today_outlined,
                          value: selectedAge,
                          items: List.generate(83, (i) => i + 18),
                          onChanged: (val) {
                            setState(() {
                              selectedAge = val!;
                            });
                          },
                        ),

                        _buildDropdown<int>(
                          label: loc.patientHeight,
                          icon: Icons.height_outlined,
                          value: selectedHeight,
                          items: List.generate(91, (i) => i + 120),
                          onChanged: (val) {
                            setState(() {
                              selectedHeight = val!;
                            });
                          },
                          suffix: ' cm',
                        ),

                        _buildDropdown<int>(
                          label: loc.bodyWeight,
                          icon: Icons.monitor_weight_outlined,
                          value: selectedWeight,
                          items: List.generate(141, (i) => i + 30),
                          onChanged: (val) {
                            setState(() {
                              selectedWeight = val!;
                            });
                          },
                          suffix: ' kg',
                        ),
                      ],
                    );
                  },
                ),

                const SizedBox(height: 28),

                LoadingButton(
                  loading: isSaving,
                  onPressed: saveProfile,
                  label: isSaving
                      ? loc.saving
                      : loc.confirmUpdate,
                  icon: Icons.check_circle_outline_rounded,
                ),
              ],
            ),
          )
                           .animate()
              .slideY(
                begin: 0.05,
                delay: 80.ms,
                duration: 320.ms,
                curve: Curves.easeOutCubic,
              ),
        ],
      ),
    ),
  ),
),
  );
}
  Widget _buildProfileHero() {
  final theme = Theme.of(context);
  final loc = AppLocalizations.of(context)!;

  final displayName = nameController.text.trim().isEmpty
      ? loc.patientMedicalFile
      : nameController.text.trim();

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
          color: const Color(0xFF2563EB).withOpacity(0.35),
          blurRadius: 35,
          spreadRadius: 2,
          offset: const Offset(0, 18),
        ),
      ],
    ),
    child: Row(
      children: [
        Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.12),
            shape: BoxShape.circle,
            border: Border.all(
              color: Colors.white.withOpacity(0.15),
            ),
          ),
          child: const Icon(
            Icons.person_rounded,
            color: Colors.white,
            size: 40,
          ),
        ),
        const SizedBox(width: 22),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                displayName,
                style: theme.textTheme.headlineSmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                loc.coreHealthMetrics,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: Colors.white.withOpacity(0.75),
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

  Widget _buildReadOnlyField(
    TextEditingController
        controller,
    String label,
    IconData icon,
    String helperText,
  ) {
    final theme =
        Theme.of(context);

    return TextField(
      controller: controller,
      readOnly: true,
      style: TextStyle(
        color:
            theme.colorScheme.onSurface,
      ),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(
          color: theme
              .colorScheme
              .onSurface
              .withOpacity(0.65),
        ),
        helperText: helperText,
        helperStyle: TextStyle(
          color: theme
              .colorScheme
              .onSurface
              .withOpacity(0.55),
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
        border: OutlineInputBorder(
          borderRadius:
              BorderRadius.circular(
                  12),
        ),
        enabledBorder:
            OutlineInputBorder(
          borderRadius:
              BorderRadius.circular(
                  12),
          borderSide: BorderSide(
            color: theme
                .dividerColor
                .withOpacity(0.2),
          ),
        ),
        focusedBorder:
            OutlineInputBorder(
          borderRadius:
              BorderRadius.circular(
                  12),
          borderSide: BorderSide(
            color: theme
                .colorScheme
                .primary,
          ),
        ),
      ),
    );
  }

  Widget _buildDropdown<T>({
    required String label,
    required IconData icon,
    required T value,
    required List<T> items,
    required ValueChanged<T?>
        onChanged,
    String suffix = "",
  }) {
    final theme =
        Theme.of(context);

    return DropdownButtonFormField<T>(
      value: value,
      dropdownColor:
          theme.colorScheme.surface,
      style: TextStyle(
        color:
            theme.colorScheme.onSurface,
      ),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(
          color: theme
              .colorScheme
              .onSurface
              .withOpacity(0.65),
        ),
        prefixIcon: Icon(
          icon,
          color:
              theme.colorScheme.primary,
        ),
        border: OutlineInputBorder(
          borderRadius:
              BorderRadius.circular(
                  12),
        ),
        enabledBorder:
            OutlineInputBorder(
          borderRadius:
              BorderRadius.circular(
                  12),
          borderSide: BorderSide(
            color: theme
                .dividerColor
                .withOpacity(0.2),
          ),
        ),
        focusedBorder:
            OutlineInputBorder(
          borderRadius:
              BorderRadius.circular(
                  12),
          borderSide: BorderSide(
            color: theme
                .colorScheme
                .primary,
          ),
        ),
        filled: true,
        fillColor: theme
            .inputDecorationTheme
            .fillColor,
      ),
      items: items.map(
        (item) {
          String displayText =
              item.toString();

          if (item is String) {
            final loc =
                AppLocalizations.of(
                    context)!;

            if (item == 'male') {
              displayText =
                  loc.male;
            } else if (item ==
                'female') {
              displayText =
                  loc.female;
            }
          }

          return DropdownMenuItem<T>(
            value: item,
            child: Text(
              displayText + suffix,
              style: TextStyle(
                color: theme
                    .colorScheme
                    .onSurface,
              ),
            ),
          );
        },
      ).toList(),
      onChanged: onChanged,
    );
  }
  
}