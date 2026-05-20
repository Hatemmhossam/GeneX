import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'package:dio/dio.dart';
import 'package:genex_app/l10n/app_localizations.dart';
import '../../models/medicine_model.dart';
import '../../core/secure_storage.dart';
import '../../viewmodels/providers.dart';
//done
class MedHistoryScreen
    extends ConsumerStatefulWidget {
  const MedHistoryScreen({
    super.key,
  });

  @override
  ConsumerState<MedHistoryScreen>
      createState() =>
          _MedHistoryScreenState();
}

class _MedHistoryScreenState
    extends ConsumerState<
        MedHistoryScreen> {
  bool _isAdding = false;

  final List<MedicineHistory>
      medicines = [];

  final GlobalKey<AnimatedListState>
      _listKey =
      GlobalKey<AnimatedListState>();

  final Dio _dio = Dio(
    BaseOptions(
      baseUrl:
          "http://127.0.0.1:8000/api/",
    ),
  );

  @override
  void initState() {
    super.initState();
    _loadMedicinesFromDB();
  }

  Future<String?> _getToken() async {
    final token =
        await SecureStorage
            .readToken();

    debugPrint(
      "DEBUG: Token from SecureStorage -> $token",
    );

    return token;
  }

  Future<List<String>>
      _getDrugSuggestions(
    String query,
  ) async {
    if (query.length < 3) {
      return [];
    }

    final url = Uri.parse(
      'https://clinicaltables.nlm.nih.gov/api/rxterms/v3/search?terms=$query',
    );

    try {
      final response =
          await http.get(url);

      if (response.statusCode ==
          200) {
        final List<dynamic> data =
            json.decode(response.body);

        return List<String>.from(
          data[1],
        );
      }
    } catch (e) {
      debugPrint(
        "External API Error: $e",
      );
    }

    return [];
  }

  Future<void>
      _loadMedicinesFromDB() async {
    final token =
        await _getToken();

    try {
      final response =
          await _dio.get(
        'medicines/',
        options: Options(
          headers: {
            "Authorization":
                "Bearer $token",
          },
        ),
      );

      if (response.statusCode ==
          200) {
        final List data =
            response.data;

        if (!mounted) return;

        setState(() {
          medicines.clear();

          for (var item in data) {
            medicines.add(
              MedicineHistory
                  .fromJson(item),
            );
          }
        });
      }
    } catch (e) {
      debugPrint(
        "Load Error: $e",
      );
    }
  }

  Future<void> _addMedicineToDB(
    String medName,
  ) async {
    final loc =
        AppLocalizations.of(context)!;

    final trimmedName =
        medName.trim();

    if (trimmedName.isEmpty) {
      return;
    }

    final exists = medicines.any(
      (m) =>
          m.name.toLowerCase() ==
          trimmedName.toLowerCase(),
    );

    if (exists) {
      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          content: Text(
            loc
                .medicineAlreadyExists,
          ),
          behavior:
              SnackBarBehavior
                  .floating,
        ),
      );

      return;
    }

    setState(
      () => _isAdding = true,
    );

    final token =
        await _getToken();

    if (token == null) {
      if (mounted) {
        setState(
          () => _isAdding = false,
        );
      }

      return;
    }

    try {
      final response =
          await _dio.post(
        'medicines/',
        data: {
          "name": trimmedName,
          "added_at": DateTime.now()
              .toIso8601String(),
        },
        options: Options(
          headers: {
            "Authorization":
                "Bearer $token",
          },
        ),
      );

      if (response.statusCode ==
          201) {
        ref.invalidate(
          medicinesProvider,
        );

        final newMed =
            MedicineHistory.fromJson(
          response.data,
        );

        if (!mounted) return;

        setState(() {
          medicines.insert(
            0,
            newMed,
          );
        });

        _listKey.currentState
            ?.insertItem(0);

        debugPrint(
          "Medicine added successfully",
        );
      }
    } catch (e) {
      debugPrint(
        "Add Error: $e",
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          content: Text(
            loc
                .failedToAddMedicine,
          ),
          behavior:
              SnackBarBehavior
                  .floating,
          backgroundColor:
              Colors.redAccent,
        ),
      );
    } finally {
      if (mounted) {
        setState(
          () => _isAdding = false,
        );
      }
    }
  }

  Future<void>
      _removeMedicineFromDB(
    int index,
  ) async {
    final token =
        await _getToken();

    final medId =
        medicines[index].id;

    try {
      final response =
          await _dio.delete(
        'medicines/$medId/',
        options: Options(
          headers: {
            "Authorization":
                "Bearer $token",
          },
        ),
      );

      if (response.statusCode ==
          204) {
        ref.invalidate(
          medicinesProvider,
        );

        if (!mounted) return;

        final removed =
            medicines.removeAt(
          index,
        );

        _listKey.currentState
            ?.removeItem(
          index,
          (
            context,
            animation,
          ) =>
              _buildItem(
            removed,
            animation,
          ),
        );
      }
    } catch (e) {
      debugPrint(
        "Delete Error: $e",
      );
    }
  }

  void _confirmDelete(
    int index,
  ) {
    final theme =
        Theme.of(context);

    final loc =
        AppLocalizations.of(context)!;

    showDialog(
      context: context,
      builder: (ctx) =>
          AlertDialog(
        backgroundColor:
            theme.colorScheme.surface,
        title: Text(
          loc.deleteMedicine,
          style: TextStyle(
            color: theme
                .colorScheme
                .onSurface,
            fontWeight:
                FontWeight.bold,
          ),
        ),
        content: Text(
          loc
              .removeMedicineQuestion,
          style: TextStyle(
            color: theme
                .colorScheme
                .onSurface
                .withOpacity(0.75),
          ),
        ),
        actions: [
          TextButton(
            onPressed:
                () => Navigator.pop(
              ctx,
            ),
            child: Text(
              loc.cancel,
              style: TextStyle(
                color: theme
                    .colorScheme
                    .primary,
              ),
            ),
          ),
          ElevatedButton(
            style:
                ElevatedButton.styleFrom(
              backgroundColor:
                  Colors.redAccent,
              foregroundColor:
                  Colors.white,
            ),
            onPressed: () {
              Navigator.pop(ctx);

              _removeMedicineFromDB(
                index,
              );
            },
            child: Text(
              loc.delete,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildItem(
    MedicineHistory med,
    Animation<double> animation,
  ) {
    final theme =
        Theme.of(context);

    final isDark =
        theme.brightness ==
            Brightness.dark;

    final loc =
        AppLocalizations.of(context)!;

    String formattedDate =
        loc.justNow;

    if (med.date != null) {
      DateTime dt = DateTime.parse(
        med.date!,
      ).toLocal();

      formattedDate =
          DateFormat(
        'yyyy-MM-dd – kk:mm',
      ).format(dt);
    }

    return SizeTransition(
      sizeFactor: animation,
      child: Card(
        color:
            theme.colorScheme.surface,
        elevation:
            isDark ? 0 : 1,
        margin:
            const EdgeInsets.symmetric(
          vertical: 5,
        ),
        shape:
            RoundedRectangleBorder(
          borderRadius:
              BorderRadius.circular(
                  12),
          side: BorderSide(
            color: theme
                .dividerColor
                .withOpacity(0.15),
          ),
        ),
        child: ListTile(
          title: Text(
            med.name,
            style: TextStyle(
              fontWeight:
                  FontWeight.w500,
              color: theme
                  .colorScheme
                  .onSurface,
            ),
          ),
          subtitle: Text(
            "${loc.addedOn}: $formattedDate",
            style: TextStyle(
              color: theme
                  .colorScheme
                  .onSurface
                  .withOpacity(0.65),
            ),
          ),
          trailing: IconButton(
            icon: const Icon(
              Icons.delete_outline,
              color: Colors.redAccent,
            ),
            onPressed: () {
              int currentIndex =
                  medicines.indexOf(
                med,
              );

              if (currentIndex !=
                  -1) {
                _confirmDelete(
                  currentIndex,
                );
              }
            },
          ),
        ),
      ),
    );
  }

  @override
  Widget build(
    BuildContext context,
  ) {
    final theme =
        Theme.of(context);

    final loc =
        AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor:
          theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          loc.medicineHistory,
          style: TextStyle(
            color:
                theme.colorScheme.onSurface,
            fontWeight:
                FontWeight.bold,
          ),
        ),
        backgroundColor:
            theme.appBarTheme
                .backgroundColor,
        foregroundColor:
            theme.colorScheme
                .onSurface,
        elevation: 0,
      ),
      body: Padding(
        padding:
            const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment
                  .start,
          children: [
            Text(
              loc.searchAddMedicine,
              style: TextStyle(
                fontSize: 18,
                fontWeight:
                    FontWeight.bold,
                color: theme
                    .colorScheme
                    .onSurface,
              ),
            ),

            const SizedBox(
                height: 12),

            Autocomplete<String>(
              optionsBuilder:
                  (
                    TextEditingValue
                        textEditingValue,
                  ) async {
                return await _getDrugSuggestions(
                  textEditingValue
                      .text,
                );
              },
              onSelected:
                  (
                    String selection,
                  ) {
                debugPrint(
                  "Selected suggestion: $selection",
                );
              },
              fieldViewBuilder: (
                context,
                controller,
                focusNode,
                onFieldSubmitted,
              ) {
                return TextField(
                  controller:
                      controller,
                  focusNode:
                      focusNode,
                  style: TextStyle(
                    color: theme
                        .colorScheme
                        .onSurface,
                  ),
                  onSubmitted:
                      (value) {
                    if (!_isAdding) {
                      _addMedicineToDB(
                        value,
                      );

                      controller
                          .clear();
                    }
                  },
                  decoration:
                      InputDecoration(
                    hintText: loc
                        .searchMedicineHint,
                    hintStyle:
                        TextStyle(
                      color: theme
                          .colorScheme
                          .onSurface
                          .withOpacity(
                              0.5),
                    ),
                    prefixIcon: Icon(
                      Icons.search,
                      color: theme
                          .colorScheme
                          .primary,
                    ),
                    suffixIcon:
                        Row(
                      mainAxisSize:
                          MainAxisSize
                              .min,
                      children: [
                        IconButton(
                          icon: Icon(
                            Icons.clear,
                            color: theme
                                .colorScheme
                                .onSurface
                                .withOpacity(
                                    0.6),
                          ),
                          onPressed:
                              () =>
                                  controller
                                      .clear(),
                        ),
                        Padding(
                          padding:
                              const EdgeInsets.only(
                            right:
                                8.0,
                          ),
                          child: _isAdding
                              ? SizedBox(
                                  width:
                                      24,
                                  height:
                                      24,
                                  child:
                                      CircularProgressIndicator(
                                    strokeWidth:
                                        2,
                                    color: theme
                                        .colorScheme
                                        .primary,
                                  ),
                                )
                              : IconButton(
                                  icon:
                                      Icon(
                                    Icons
                                        .add_circle,
                                    color: theme
                                        .colorScheme
                                        .primary,
                                    size:
                                        28,
                                  ),
                                  onPressed:
                                      () {
                                    _addMedicineToDB(
                                      controller
                                          .text,
                                    );

                                    controller
                                        .clear();

                                    focusNode
                                        .unfocus();
                                  },
                                ),
                        ),
                      ],
                    ),
                    filled: true,
                    fillColor: theme
                        .inputDecorationTheme
                        .fillColor,
                    border:
                        OutlineInputBorder(
                      borderRadius:
                          BorderRadius.circular(
                              10),
                    ),
                    enabledBorder:
                        OutlineInputBorder(
                      borderRadius:
                          BorderRadius.circular(
                              10),
                      borderSide:
                          BorderSide(
                        color: theme
                            .dividerColor
                            .withOpacity(
                                0.2),
                      ),
                    ),
                    focusedBorder:
                        OutlineInputBorder(
                      borderRadius:
                          BorderRadius.circular(
                              10),
                      borderSide:
                          BorderSide(
                        color: theme
                            .colorScheme
                            .primary,
                      ),
                    ),
                  ),
                );
              },
            ),

            const SizedBox(
                height: 24),

            Text(
              loc.patientMedicines,
              style: TextStyle(
                fontSize: 18,
                fontWeight:
                    FontWeight.bold,
                color: theme
                    .colorScheme
                    .onSurface,
              ),
            ),

            const SizedBox(
                height: 8),

            Expanded(
              child: medicines.isEmpty
                  ? Center(
                      child: Text(
                        loc
                            .noMedicinesAdded,
                        style:
                            TextStyle(
                          color: theme
                              .colorScheme
                              .onSurface
                              .withOpacity(
                                  0.65),
                        ),
                      ),
                    )
                  : AnimatedList(
                      key: _listKey,
                      initialItemCount:
                          medicines
                              .length,
                      itemBuilder: (
                        context,
                        index,
                        animation,
                      ) {
                        return _buildItem(
                          medicines[index],
                          animation,
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}