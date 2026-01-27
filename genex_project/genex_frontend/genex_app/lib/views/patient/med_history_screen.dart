import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'package:dio/dio.dart';
import '../../models/medicine_model.dart';
import '../../core/secure_storage.dart'; // Import your secure storage class

class MedHistoryScreen extends StatefulWidget {
  const MedHistoryScreen({super.key});

  @override
  State<MedHistoryScreen> createState() => _MedHistoryScreenState();
}

class _MedHistoryScreenState extends State<MedHistoryScreen> {
  bool _isAdding = false; // Tracks API loading state
  final List<MedicineHistory> medicines = [];
  final GlobalKey<AnimatedListState> _listKey = GlobalKey<AnimatedListState>();
  
  // Base configuration for Dio
  final Dio _dio = Dio(BaseOptions(baseUrl: "http://127.0.0.1:8000/api/"));

  @override
  void initState() {
    super.initState();
    _loadMedicinesFromDB();
  }

  Future<String?> _getToken() async {
    final token = await SecureStorage.readToken();
    debugPrint("DEBUG: Token from SecureStorage -> $token"); 
    return token;     
  }

  Future<List<String>> _getDrugSuggestions(String query) async {
    if (query.length < 3) return [];
    final url = Uri.parse('https://clinicaltables.nlm.nih.gov/api/rxterms/v3/search?terms=$query');
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return List<String>.from(data[1]);
      }
    } catch (e) {
      debugPrint("External API Error: $e");
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

  // 1. Updated Add Medicine Function
  Future<void> _addMedicineToDB(String medName) async {
    final trimmedName = medName.trim();
    if (trimmedName.isEmpty) return;

    // CHECK 1: Local existence check (Case-insensitive)
    bool exists = medicines.any((m) => m.name.toLowerCase() == trimmedName.toLowerCase());
    
    if (exists) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("This medicine is already in your list.")),
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
        data: {"name": trimmedName,
        "added_at": DateTime.now().toIso8601String()
        },
        options: Options(headers: {"Authorization": "Bearer $token"}),
      );

      if (response.statusCode == 201) {
        final newMed = MedicineHistory.fromJson(response.data);
        
        // 2. UI Update: Add to the top of the list immediately
        setState(() {
          medicines.insert(0, newMed); 
        });
        _listKey.currentState?.insertItem(0);
        
        debugPrint("Medicine added successfully");
      }
    } catch (e) {
      debugPrint("Add Error: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Failed to add medicine. Please try again.")),
      );
    } finally {
    // 4. Stop Loading
      setState(() => _isAdding = false);
    }
  }
  Future<void> _removeMedicineFromDB(int index) async {
    final token = await _getToken();
    final medId = medicines[index].id;
    try {
      final response = await _dio.delete(
        'medicines/$medId/',
        options: Options(headers: {"Authorization": "Bearer $token"}),
      );
      if (response.statusCode == 204) {
        final removed = medicines.removeAt(index);
        _listKey.currentState?.removeItem(
          index,
          (context, animation) => _buildItem(removed, animation),
        );
      }
    } catch (e) {
      debugPrint("Delete Error: $e");
    }
  }

  void _confirmDelete(int index) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Delete Medicine"),
        content: const Text("Are you sure you want to remove this medicine?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              _removeMedicineFromDB(index);
            },
            child: const Text("Delete"),
          ),
        ],
      ),
    );
  }

  Widget _buildItem(MedicineHistory med, Animation<double> animation) {
    String formattedDate = "Just now";
    if (med.date != null) {
      DateTime dt = DateTime.parse(med.date!).toLocal();
      formattedDate = DateFormat('yyyy-MM-dd – kk:mm').format(dt);
    }
    return SizeTransition(
      sizeFactor: animation,
      child: Card(
        margin: const EdgeInsets.symmetric(vertical: 5),
        child: ListTile(
          title: Text(med.name, style: const TextStyle(fontWeight: FontWeight.w500)),
          subtitle: Text("Added on: $formattedDate"),
          trailing: IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
            onPressed: () {
              int currentIndex = medicines.indexOf(med);
              if (currentIndex != -1) _confirmDelete(currentIndex);
            },
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Medicine History')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Search & Add Medicine",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            
            Autocomplete<String>(
              optionsBuilder: (TextEditingValue textEditingValue) async {
                return await _getDrugSuggestions(textEditingValue.text);
              },
              onSelected: (String selection) {
                // Logic removed here so it only adds on Enter or Plus click
                debugPrint("Selected suggestion: $selection");
              },
              fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
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
                    hintText: "Search (e.g., Ibuprofen...)",
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () => controller.clear(),
                        ),
                        // Dynamic Plus Button / Loading Spinner
                        Padding(
                          padding: const EdgeInsets.only(right: 8.0),
                          child: _isAdding 
                            ? const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : IconButton(
                                icon: const Icon(Icons.add_circle, color: Colors.blue, size: 28),
                                onPressed: () {
                                  _addMedicineToDB(controller.text);
                                  controller.clear();
                                  focusNode.unfocus();
                                },
                              ),
                        ),
                      ],
                    ),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                );
              },
            ),

            const SizedBox(height: 24),
            const Text("Patient Medicines:",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            
            Expanded(
              child: medicines.isEmpty 
                ? const Center(child: Text("No medicines added yet."))
                : AnimatedList(
                    key: _listKey,
                    initialItemCount: medicines.length,
                    itemBuilder: (context, index, animation) {
                      return _buildItem(medicines[index], animation);
                    },
                  ),
            ),
          ],
        ),
      ),
    );
  }
}