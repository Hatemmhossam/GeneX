import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../viewmodels/providers.dart';

class PendingPatientsView extends ConsumerStatefulWidget {
  const PendingPatientsView({super.key});

  @override
  ConsumerState<PendingPatientsView> createState() => _PendingPatientsViewState();
}

class _PendingPatientsViewState extends ConsumerState<PendingPatientsView> {
  static const Color mainBlue = Color(0xFF1A5699);

  bool isLoading = true;
  List<dynamic> pendingPatients = [];

  @override
  void initState() {
    super.initState();
    fetchPendingPatients();
  }

  Future<void> fetchPendingPatients() async {
    try {
      final api = ref.read(apiServiceProvider);
      final response = await api.get('/doctor/pending-patients/');

      if (response.statusCode == 200) {
        setState(() {
          pendingPatients = response.data['patients'] ?? [];
          isLoading = false;
        });
      } else {
        setState(() {
          isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('❌ Error fetching pending patients: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> refreshData() async {
    setState(() {
      isLoading = true;
    });
    await fetchPendingPatients();
  }

  String getDisplayName(Map<String, dynamic> patient) {
    final firstName = (patient['first_name'] ?? '').toString().trim();
    final lastName = (patient['last_name'] ?? '').toString().trim();

    if (firstName.isNotEmpty || lastName.isNotEmpty) {
      return '$firstName $lastName'.trim();
    }

    return (patient['username'] ?? 'Unknown Patient').toString();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F8),
      appBar: AppBar(
        title: const Text('Pending Patients'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: RefreshIndicator(
        onRefresh: refreshData,
        child: isLoading
            ? const Center(child: CircularProgressIndicator())
            : pendingPatients.isEmpty
                ? ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    children: const [
                      SizedBox(height: 180),
                      Center(
                        child: Text(
                          'No pending patients found',
                          style: TextStyle(fontSize: 16),
                        ),
                      ),
                    ],
                  )
                : ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: pendingPatients.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final patient = Map<String, dynamic>.from(pendingPatients[index]);

                      return Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 24,
                              backgroundColor: mainBlue.withOpacity(0.1),
                              child: const Icon(Icons.person_outline, color: mainBlue),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    getDisplayName(patient),
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    (patient['email'] ?? '').toString(),
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: Colors.grey[700],
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Status: ${(patient['status'] ?? 'pending').toString()}',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: Colors.orange[800],
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  if ((patient['appointment_date'] ?? '').toString().trim().isNotEmpty) ...[
                                    const SizedBox(height: 4),
                                    Text(
                                      'Appointment: ${patient['appointment_date']}',
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: Colors.grey[700],
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
      ),
    );
  }
}