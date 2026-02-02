import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart'; // <--- ADDED IMPORT
import '../../viewmodels/providers.dart';
import '../doctor/user_search_view.dart';

class DoctorDashboard extends ConsumerStatefulWidget {
  const DoctorDashboard({super.key});

  @override
  ConsumerState<DoctorDashboard> createState() => _DoctorDashboardState();
}

class _DoctorDashboardState extends ConsumerState<DoctorDashboard> {
  bool _isLoading = true; // Shows loading spinner initially
  bool _isAuthorized = false;

  @override
  void initState() {
    super.initState();
    _checkAccess();
  }

  // --- SECURITY CHECK ---
  Future<void> _checkAccess() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    final role = prefs.getString('role');

    // If no token or role is not doctor, redirect to Sign In
    if (token == null || role != 'doctor') {
      if (mounted) {
        Navigator.of(context).pushNamedAndRemoveUntil('/signin', (r) => false);
      }
    } else {
      // Access Granted
      if (mounted) {
        setState(() {
          _isAuthorized = true;
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // 1. Show Loader while checking
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    // 2. If not authorized, return empty (redirect happens in _checkAccess)
    if (!_isAuthorized) {
      return const SizedBox.shrink();
    }

    // 3. Main Dashboard UI
    final authVM = ref.read(authViewModelProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Doctor Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              // Clear session locally and in ViewModel
              final prefs = await SharedPreferences.getInstance();
              await prefs.clear(); 
              await authVM.logout();
              
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
          ],
        ),
      ),
    );
  }
}