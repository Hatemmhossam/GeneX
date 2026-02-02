import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../viewmodels/providers.dart';
import '../doctor/user_search_view.dart';
import '../../viewmodels/auth_viewmodel.dart'; // Import to use AuthViewModel type

class DoctorDashboard extends ConsumerStatefulWidget {
  const DoctorDashboard({super.key});

  @override
  ConsumerState<DoctorDashboard> createState() => _DoctorDashboardState();
}

class _DoctorDashboardState extends ConsumerState<DoctorDashboard> {
  bool _isLoading = true;
  bool _isAuthorized = false;

  @override
  void initState() {
    super.initState();
    _checkAccess();
  }

  Future<void> _checkAccess() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    final role = prefs.getString('role');

    if (token == null || role != 'doctor') {
      if (mounted) {
        Navigator.of(context).pushNamedAndRemoveUntil('/signin', (r) => false);
      }
    } else {
      if (mounted) {
        setState(() {
          _isAuthorized = true;
          _isLoading = false;
        });
      }
    }
  }

  // --- 🔴 NEW LOGOUT DIALOG FUNCTION ---
  Future<void> _showLogoutConfirmation(BuildContext context, AuthViewModel authVM) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false, // User must tap a button to close
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20), // Rounded corners like image
          ),
          title: const Text(
            'Confirm Logout',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          content: const Text(
            'Are you sure you want to log out of the GeneX portal?',
            style: TextStyle(fontSize: 16),
          ),
          actions: <Widget>[
            // CANCEL BUTTON
            TextButton(
              child: const Text(
                'Cancel',
                style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold),
              ),
              onPressed: () {
                Navigator.of(context).pop(); // Just close the dialog
              },
            ),
            // LOGOUT BUTTON (Red Style)
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent, // Red background
                foregroundColor: Colors.white, // White text
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              onPressed: () async {
                Navigator.of(context).pop(); // 1. Close Dialog
                
                // 2. Perform Logout Logic
                final prefs = await SharedPreferences.getInstance();
                await prefs.clear();
                await authVM.logout();

                if (context.mounted) {
                  Navigator.of(context).pushNamedAndRemoveUntil('/signin', (r) => false);
                }
              },
              child: const Text('Logout'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (!_isAuthorized) {
      return const SizedBox.shrink();
    }

    final authVM = ref.read(authViewModelProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Doctor Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout), // The exit icon
            color: Colors.redAccent, // Make the icon red to stand out (optional)
            onPressed: () {
              // 🔴 Trigger the custom dialog instead of direct logout
              _showLogoutConfirmation(context, authVM);
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