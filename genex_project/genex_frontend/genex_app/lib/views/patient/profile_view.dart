import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:genex_app/l10n/app_localizations.dart';

import '../../core/secure_storage.dart';
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
  Widget build(
    BuildContext context,
  ) {
    final loc =
        AppLocalizations.of(context)!;

    final theme =
        Theme.of(context);

    if (isFetching) {
      return Scaffold(
        backgroundColor:
            theme.scaffoldBackgroundColor,
        body: Center(
          child:
              CircularProgressIndicator(
            color:
                theme.colorScheme.primary,
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor:
          theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          loc.patientMedicalFile,
          style: TextStyle(
            color:
                theme.colorScheme.onSurface,
            fontWeight:
                FontWeight.bold,
          ),
        ),
        elevation: 0,
        backgroundColor:
            theme.appBarTheme
                .backgroundColor,
        foregroundColor:
            theme.colorScheme
                .onSurface,
        actions: [
          IconButton(
            icon: Icon(
              Icons.settings,
              color: theme
                  .colorScheme
                  .primary,
            ),
            onPressed: () {
              Navigator.pushNamed(
                context,
                '/settings',
              );
            },
          ),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints:
              const BoxConstraints(
            maxWidth: 900,
          ),
          child:
              SingleChildScrollView(
            padding:
                const EdgeInsets.all(
                    32),
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment
                      .start,
              children: [
                Text(
                  loc
                      .coreHealthMetrics,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight:
                        FontWeight
                            .bold,
                    color: theme
                        .colorScheme
                        .primary,
                  ),
                ),

                const SizedBox(
                    height: 24),

                _buildReadOnlyField(
                  nameController,
                  loc.fullName,
                  Icons.lock_outline,
                  loc.contactAdmin,
                ),

                const SizedBox(
                    height: 20),

                LayoutBuilder(
                  builder: (
                    context,
                    constraints,
                  ) {
                    return GridView(
                      shrinkWrap: true,
                      physics:
                          const NeverScrollableScrollPhysics(),
                      gridDelegate:
                          SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount:
                            constraints
                                        .maxWidth >
                                    600
                                ? 2
                                : 1,
                        crossAxisSpacing:
                            20,
                        mainAxisExtent:
                            90,
                      ),
                      children: [
                        _buildDropdown<
                            String>(
                          label: loc
                              .genderIdentity,
                          icon: Icons
                              .wc_outlined,
                          value:
                              selectedGender,
                          items:
                              const [
                            'male',
                            'female',
                          ],
                          onChanged:
                              (val) {
                            setState(
                              () {
                                selectedGender =
                                    val!;
                              },
                            );
                          },
                        ),

                        _buildDropdown<
                            int>(
                          label: loc
                              .currentAge,
                          icon: Icons
                              .calendar_today_outlined,
                          value:
                              selectedAge,
                          items:
                              List.generate(
                            83,
                            (i) =>
                                i +
                                18,
                          ),
                          onChanged:
                              (val) {
                            setState(
                              () {
                                selectedAge =
                                    val!;
                              },
                            );
                          },
                        ),

                        _buildDropdown<
                            int>(
                          label: loc
                              .patientHeight,
                          icon: Icons
                              .height_outlined,
                          value:
                              selectedHeight,
                          items:
                              List.generate(
                            91,
                            (i) =>
                                i +
                                120,
                          ),
                          onChanged:
                              (val) {
                            setState(
                              () {
                                selectedHeight =
                                    val!;
                              },
                            );
                          },
                          suffix:
                              ' cm',
                        ),

                        _buildDropdown<
                            int>(
                          label: loc
                              .bodyWeight,
                          icon: Icons
                              .monitor_weight_outlined,
                          value:
                              selectedWeight,
                          items:
                              List.generate(
                            141,
                            (i) =>
                                i +
                                30,
                          ),
                          onChanged:
                              (val) {
                            setState(
                              () {
                                selectedWeight =
                                    val!;
                              },
                            );
                          },
                          suffix:
                              ' kg',
                        ),
                      ],
                    );
                  },
                ),

                const SizedBox(
                    height: 40),

                Center(
                  child:
                      ElevatedButton.icon(
                    style:
                        ElevatedButton
                            .styleFrom(
                      backgroundColor:
                          theme
                              .colorScheme
                              .primary,
                      foregroundColor:
                          Colors.white,
                      padding:
                          const EdgeInsets.symmetric(
                        horizontal:
                            48,
                        vertical:
                            18,
                      ),
                      shape:
                          RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(
                                10),
                      ),
                    ),
                    onPressed:
                        isSaving
                            ? null
                            : saveProfile,
                    icon: isSaving
                        ? const SizedBox(
                            width:
                                20,
                            height:
                                20,
                            child:
                                CircularProgressIndicator(
                              color: Colors
                                  .white,
                              strokeWidth:
                                  2,
                            ),
                          )
                        : const Icon(
                            Icons
                                .check_circle_outline,
                          ),
                    label: Text(
                      isSaving
                          ? loc
                              .saving
                          : loc
                              .confirmUpdate,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
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