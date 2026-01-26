import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class MedHistoryScreen extends StatefulWidget {
  const MedHistoryScreen({super.key});

  @override
  State<MedHistoryScreen> createState() => _MedHistoryScreenState();
}

class _MedHistoryScreenState extends State<MedHistoryScreen> {
  final List<Map<String, String>> medicines = []; // store name + date
  String? selectedMed;
  final TextEditingController _customMedController = TextEditingController();

  final List<String> medicineOptions = const [
    "Vitamin D",
    "Metformin",
    "Prednisone",
    "Thyroxine",
    "Ibuprofen",
  ];

  final GlobalKey<AnimatedListState> _listKey = GlobalKey<AnimatedListState>();

  void _addMedicine(String med) {
    final now = DateFormat('yyyy-MM-dd – kk:mm').format(DateTime.now());
    medicines.add({"name": med, "date": now});
    _listKey.currentState?.insertItem(medicines.length - 1);
  }

  void _removeMedicine(int index) {
    final removed = medicines.removeAt(index);
    _listKey.currentState?.removeItem(
      index,
      (context, animation) => SizeTransition(
        sizeFactor: animation,
        child: Card(
          child: ListTile(
            title: Text(removed["name"]!),
            subtitle: Text("Added on: ${removed["date"]}"),
          ),
        ),
      ),
    );
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
              _removeMedicine(index);
            },
            child: const Text("Delete"),
          ),
        ],
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
            const Text("Add a Medicine",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: DropdownButton<String>(
                    value: selectedMed,
                    hint: const Text("Select Medicine"),
                    items: medicineOptions
                        .map((med) => DropdownMenuItem(value: med, child: Text(med)))
                        .toList(),
                    onChanged: (value) => setState(() => selectedMed = value),
                  ),
                ),
                ElevatedButton(
                  onPressed: selectedMed == null
                      ? null
                      : () {
                          if (!medicines.any((m) => m["name"] == selectedMed)) {
                            _addMedicine(selectedMed!);
                          }
                        },
                  child: const Text("Add"),
                )
              ],
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _customMedController,
              decoration: InputDecoration(
                labelText: "Or enter custom medicine",
                suffixIcon: IconButton(
                  icon: const Icon(Icons.add),
                  onPressed: () {
                    final customMed = _customMedController.text.trim();
                    if (customMed.isNotEmpty &&
                        !medicines.any((m) => m["name"] == customMed)) {
                      _addMedicine(customMed);
                      _customMedController.clear();
                    }
                  },
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text("Patient Medicines:",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Expanded(
              child: AnimatedList(
                key: _listKey,
                initialItemCount: medicines.length,
                itemBuilder: (context, index, animation) {
                  final med = medicines[index];
                  return SizeTransition(
                    sizeFactor: animation,
                    child: Card(
                      child: ListTile(
                        title: Text(med["name"]!),
                        subtitle: Text("Added on: ${med["date"]}"),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete_outline),
                          onPressed: () => _confirmDelete(index),
                        ),
                      ),
                    ),
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
