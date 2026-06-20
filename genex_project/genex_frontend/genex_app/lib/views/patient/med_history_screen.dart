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

class MedHistoryScreen extends ConsumerStatefulWidget {
  const MedHistoryScreen({super.key});

  @override
  ConsumerState<MedHistoryScreen> createState() => _MedHistoryScreenState();
}

class _MedHistoryScreenState extends ConsumerState<MedHistoryScreen> {
  bool _isAdding = false;
  String _sortOption = 'newest';

  final List<MedicineHistory> medicines = [];

  final Dio _dio = Dio(BaseOptions(baseUrl: "http://127.0.0.1:8000/api/"));

  List<MedicineHistory> get _sortedMedicines {
    final sorted = [...medicines];

    switch (_sortOption) {
      case 'oldest':
        sorted.sort((a, b) => (a.date ?? '').compareTo(b.date ?? ''));
        break;

      case 'az':
        sorted.sort(
          (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
        );
        break;

      case 'za':
        sorted.sort(
          (a, b) => b.name.toLowerCase().compareTo(a.name.toLowerCase()),
        );
        break;

      case 'newest':
      default:
        sorted.sort((a, b) => (b.date ?? '').compareTo(a.date ?? ''));
        break;
    }

    return sorted;
  }

  @override
  void initState() {
    super.initState();
    _loadMedicinesFromDB();
  }

  Future<String?> _getToken() async {
    return await SecureStorage.readToken();
  }

  Future<List<String>> _getDrugSuggestions(String query) async {
    if (query.length < 3) return [];

    final url = Uri.parse(
      'https://clinicaltables.nlm.nih.gov/api/rxterms/v3/search?terms=$query',
    );

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return List<String>.from(data[1]);
      }
    } catch (e) {
      debugPrint("Suggestion API Error: $e");
    }

    return [];
  }

  Future<void> _loadMedicinesFromDB() async {
    final token = await _getToken();

    try {
      final response = await _dio.get(
        'medicines/',
        options: Options(headers: {"Authorization": "Bearer $token"}),
      );

      if (response.statusCode == 200) {
        final List data = response.data;

        if (!mounted) return;

        setState(() {
          medicines.clear();

          for (var item in data) {
            medicines.add(MedicineHistory.fromJson(item));
          }
        });
      }
    } catch (e) {
      debugPrint("Load Error: $e");
    }
  }

  Future<void> _addMedicineToDB(String medName) async {
    final loc = AppLocalizations.of(context)!;

    final trimmedName = medName.trim();

    if (trimmedName.isEmpty) return;

    final exists = medicines.any(
      (m) => m.name.toLowerCase() == trimmedName.toLowerCase(),
    );

    if (exists) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(loc.medicineAlreadyExists),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => _isAdding = true);

    final token = await _getToken();

    if (token == null) {
      setState(() => _isAdding = false);
      return;
    }

    try {
      final response = await _dio.post(
        'medicines/',
        data: {
          "name": trimmedName,
          "added_at": DateTime.now().toIso8601String(),
        },
        options: Options(headers: {"Authorization": "Bearer $token"}),
      );

      if (response.statusCode == 201) {
        ref.invalidate(medicinesProvider); //refresh automatically

        final newMed = MedicineHistory.fromJson(response.data);

        setState(() {
          medicines.insert(0, newMed);
        });
      }
    } catch (e) {
      debugPrint("Add Error: $e");

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Failed to add medicine. Please try again."),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isAdding = false);
      }
    }
  }

  Future<void> _deleteMedicineFromDB(MedicineHistory med) async {
    final token = await _getToken();

    try {
      final response = await _dio.delete(
        'medicines/${med.id}/',
        options: Options(headers: {"Authorization": "Bearer $token"}),
      );

      if (response.statusCode == 204) {
        ref.invalidate(medicinesProvider); //refresh automatically
      }
    } catch (e) {
      debugPrint("Delete Error: $e");

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Failed to delete medicine.")),
      );
    }
  }

  void _dismissMedicine(MedicineHistory med) {
    final currentIndex = medicines.indexWhere((m) => m.id == med.id);

    if (currentIndex == -1) return;

    final removedMed = medicines[currentIndex];

    setState(() {
      medicines.removeAt(currentIndex);
    });

    ScaffoldMessenger.of(context)
        .showSnackBar(
          SnackBar(
            content: Text("${removedMed.name} deleted"),
            duration: const Duration(seconds: 4),
            action: SnackBarAction(
              label: "UNDO",
              onPressed: () {
                setState(() {
                  medicines.insert(currentIndex, removedMed);
                });
              },
            ),
          ),
        )
        .closed
        .then((reason) {
          if (reason != SnackBarClosedReason.action) {
            _deleteMedicineFromDB(removedMed);
          }
        });
  }

  void _confirmDelete(MedicineHistory med) {
    final theme = Theme.of(context);
    final loc = AppLocalizations.of(context)!;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: theme.colorScheme.surface,
        title: Text(
          loc.deleteMedicine,
          style: TextStyle(
            color: theme.colorScheme.onSurface,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(loc.removeMedicineQuestion),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(loc.cancel),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () {
              Navigator.pop(ctx);
              _dismissMedicine(med);
            },
            child: Text(loc.delete),
          ),
        ],
      ),
    );
  }

  Widget _buildItem(MedicineHistory med) {
    final theme = Theme.of(context);
    final loc = AppLocalizations.of(context)!;

    String formattedDate = loc.justNow;

    if (med.date != null) {
      final dt = DateTime.parse(med.date!).toLocal();

      formattedDate = DateFormat('yyyy-MM-dd – kk:mm').format(dt);
    }

    return Dismissible(
      key: ValueKey(med.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        color: Colors.redAccent,
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      onDismissed: (_) {
        _dismissMedicine(med);
      },
      child: Card(
        elevation: 1,
        margin: const EdgeInsets.symmetric(vertical: 5),
        child: ListTile(
          title: Text(
            med.name,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onSurface,
            ),
          ),
          subtitle: Text("${loc.addedOn}: $formattedDate"),
          trailing: IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
            onPressed: () {
              _confirmDelete(med);
            },
          ),
        ),
      ),
    );
  }

  Widget _buildSortDropdown() {
    final theme = Theme.of(context);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          "Sort by:",
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: theme.colorScheme.onSurface,
          ),
        ),
        DropdownButton<String>(
          value: _sortOption,
          borderRadius: BorderRadius.circular(12),
          items: const [
            DropdownMenuItem(value: 'newest', child: Text('Newest to Oldest')),
            DropdownMenuItem(value: 'oldest', child: Text('Oldest to Newest')),
            DropdownMenuItem(value: 'az', child: Text('A-Z')),
            DropdownMenuItem(value: 'za', child: Text('Z-A')),
          ],
          onChanged: (value) {
            if (value == null) return;

            setState(() {
              _sortOption = value;
            });
          },
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final loc = AppLocalizations.of(context)!;

    final sortedMedicines = _sortedMedicines;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          loc.medicineHistory,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              loc.searchAddMedicine,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 12),

            Autocomplete<String>(
              optionsBuilder: (TextEditingValue value) async {
                return await _getDrugSuggestions(value.text);
              },
              fieldViewBuilder:
                  (context, controller, focusNode, onFieldSubmitted) {
                    return TextField(
                      controller: controller,
                      focusNode: focusNode,
                      onSubmitted: (value) {
                        if (!_isAdding) {
                          _addMedicineToDB(value);
                          controller.clear();
                        }
                      },
                      decoration: InputDecoration(
                        hintText: "Search medicine...",
                        prefixIcon: const Icon(Icons.search),
                        suffixIcon: _isAdding
                            ? const Padding(
                                padding: EdgeInsets.all(12),
                                child: SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                ),
                              )
                            : IconButton(
                                icon: const Icon(
                                  Icons.add_circle,
                                  color: Colors.blue,
                                ),
                                onPressed: () {
                                  _addMedicineToDB(controller.text);
                                  controller.clear();
                                  focusNode.unfocus();
                                },
                              ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    );
                  },
            ),

            const SizedBox(height: 24),

            const Text(
              "Patient Medicines:",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 10),

            if (medicines.isNotEmpty) _buildSortDropdown(),

            if (medicines.isNotEmpty) const SizedBox(height: 10),

            Expanded(
              child: medicines.isEmpty
                  ? const Center(child: Text("No medicines added yet."))
                  : ListView.builder(
                      itemCount: sortedMedicines.length,
                      itemBuilder: (context, index) {
                        return _buildItem(sortedMedicines[index]);
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
