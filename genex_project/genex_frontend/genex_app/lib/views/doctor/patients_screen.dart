// lib/views/doctor/patients_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/user_model.dart'; 
import '../../services/api_service.dart';

// Provider to fetch patients
final patientListProvider = FutureProvider.autoDispose.family<List<UserModel>, String?>((ref, query) async {
  final api = ApiService(); 
  // Make sure your ApiService has the getPatients method we added earlier
  return await api.getPatients(query: query);
});

class PatientsScreen extends ConsumerStatefulWidget {
  const PatientsScreen({super.key});

  @override
  ConsumerState<PatientsScreen> createState() => _PatientsScreenState();
}

class _PatientsScreenState extends ConsumerState<PatientsScreen> {
  String? searchQuery;
  final TextEditingController _searchController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final patientsAsync = ref.watch(patientListProvider(searchQuery));

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Patients'),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Add Patient functionality coming soon')),
          );
        },
        child: const Icon(Icons.add),
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search all patients...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                    setState(() {
                      searchQuery = null;
                    });
                  },
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onSubmitted: (value) {
                setState(() {
                  searchQuery = value.isEmpty ? null : value;
                });
              },
            ),
          ),
          // Patient List
          Expanded(
            child: patientsAsync.when(
              data: (patients) {
                if (patients.isEmpty) {
                  return const Center(child: Text('No patients found.'));
                }
                return ListView.builder(
                  itemCount: patients.length,
                  itemBuilder: (context, index) {
                    final patient = patients[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: ListTile(
                        leading: CircleAvatar(
                          child: Text(patient.username.isNotEmpty 
                              ? patient.username[0].toUpperCase() 
                              : '?'),
                        ),
                        title: Text(patient.username), 
                        subtitle: Text(patient.email ?? 'No email'),
                        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                        onTap: () {
                           // Navigate to detail screen later
                        },
                      ),
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, stack) => Center(child: Text('Error: $err')),
            ),
          ),
        ],
      ),
    );
  }
}