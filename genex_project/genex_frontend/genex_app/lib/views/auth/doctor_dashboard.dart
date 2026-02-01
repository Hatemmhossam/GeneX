import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../viewmodels/providers.dart';
import '../doctor/user_search_view.dart';

class DoctorDashboard extends ConsumerWidget {
  const DoctorDashboard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authVM = ref.read(authViewModelProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Doctor Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await authVM.logout(); // make sure you have this
              if (context.mounted) {
                Navigator.of(context).pushNamedAndRemoveUntil('/signin', (r) => false);
              }
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            Card(
              child: ListTile(
                leading: const Icon(Icons.people),
                title: const Text('Patients'),
                subtitle: const Text('View assigned patients'),
                onTap: () {
                 Navigator.push(
                    context,
                     MaterialPageRoute(builder: (context) => const UserSearchView()),
                 );
                },
              ),
            ),
            Card(
              child: ListTile(
                leading: const Icon(Icons.medical_services),
                title: const Text('Prescriptions / Notes'),
                subtitle: const Text('Add clinical notes (coming soon)'),
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Notes screen not implemented yet')),
                  );
                },
              ),
            ),
            Card(
              child: ListTile(
                leading: const Icon(Icons.analytics),
                title: const Text('Twin Simulation Review'),
                subtitle: const Text('Review patient simulations (coming soon)'),
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Simulation review not implemented yet')),
                  );
                },
              ),
            ),
            // inside DoctorDashboard.dart

          ],
        ),
      ),
    );
  }
}