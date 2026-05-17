// lib/views/doctor/doctor_dashboard.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../viewmodels/providers.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../doctor/user_search_view.dart';
import '../doctor/see_accessed_patients.dart';
import '../doctor/pending_patients_view.dart';
import '../doctor/twin_preview_screen.dart'; // adjust path if needed

class DoctorDashboard extends ConsumerStatefulWidget {
  const DoctorDashboard({super.key});

  @override
  ConsumerState<DoctorDashboard> createState() => _DoctorDashboardState();
}

class _DoctorDashboardState extends ConsumerState<DoctorDashboard> {
  bool _isLoading = true;
  bool _isAuthorized = false;
  bool _isStatsLoading = true;

  static const Color mainBlue = Color(0xFF1A5699);

  int totalPatients = 0;
  int pendingPatients = 0;

  @override
  void initState() {
    super.initState();
    _initializeDashboard();
  }

  Future<void> _initializeDashboard() async {
    await _checkAccess();
    if (_isAuthorized) {
      await _fetchDashboardStats();
    }
  }

  Future<void> _checkAccess() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    final role = prefs.getString('role');

    if (token == null || role != 'doctor') {
      if (mounted) {
        Navigator.of(context).pushNamedAndRemoveUntil('/signin', (r) => false);
      }
      return;
    }

    if (mounted) {
      setState(() {
        _isAuthorized = true;
        _isLoading = false;
      });
    }
  }

  Future<void> _fetchDashboardStats() async {
    try {
      final api = ref.read(apiServiceProvider);
      final response = await api.get('/doctor/dashboard-stats/');

      if (response.statusCode == 200) {
        if (mounted) {
          setState(() {
            totalPatients = response.data['assigned_patients'] ?? 0;
            pendingPatients = response.data['pending_patients'] ?? 0;
            _isStatsLoading = false;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _isStatsLoading = false;
          });
        }
      }
    } catch (e) {
      debugPrint('❌ Error fetching dashboard stats: $e');
      if (mounted) {
        setState(() {
          _isStatsLoading = false;
        });
      }
    }
  }

  Future<void> _refreshDashboard() async {
    setState(() {
      _isStatsLoading = true;
    });
    await _fetchDashboardStats();
  }

  Future<void> _showLogoutConfirmation(
    BuildContext context,
    AuthViewModel authVM,
  ) async {
    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          title: const Text('Confirm Logout'),
          content: const Text(
            'Are you sure you want to log out of the GeneX portal?',
          ),
          actions: [
            TextButton(
              child: const Text('Cancel'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                foregroundColor: Colors.white,
              ),
              onPressed: () async {
                final prefs = await SharedPreferences.getInstance();
                await prefs.clear();
                await authVM.logout();
                if (context.mounted) {
                  Navigator.of(
                    context,
                  ).pushNamedAndRemoveUntil('/signin', (r) => false);
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

    if (!_isAuthorized) return const SizedBox.shrink();

    final authVM = ref.read(authViewModelProvider.notifier);

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F8),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _refreshDashboard,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Doctor Dashboard',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.refresh, color: mainBlue),
                          onPressed: _refreshDashboard,
                        ),
                        IconButton(
                          icon: const Icon(
                            Icons.logout,
                            color: Colors.redAccent,
                          ),
                          onPressed: () =>
                              _showLogoutConfirmation(context, authVM),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 32),

                // Summary Stats Section
                Row(
                  children: [
                    _buildStatCard(
                      title: 'Assigned Patients',
                      value: _isStatsLoading ? '...' : totalPatients.toString(),
                      icon: Icons.people_alt_outlined,
                    ),
                    const SizedBox(width: 16),
                    _buildStatCard(
                      title: 'Pending Patients',
                      value: _isStatsLoading
                          ? '...'
                          : pendingPatients.toString(),
                      icon: Icons.hourglass_top_outlined,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const PendingPatientsView(),
                          ),
                        );
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 32),

                // Navigation Tiles
                const Text(
                  'Quick Actions',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),

                _buildDashboardTile(
                  icon: Icons.people_outline,
                  title: 'Manage Patients',
                  subtitle: 'View full patient directory',
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const UserSearchView()),
                  ),
                ),
                const SizedBox(height: 16),

                _buildDashboardTile(
                  icon: Icons.medical_services_outlined,
                  title: 'My Patients',
                  subtitle: 'View patient medical logs',
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const DoctorDashboardScreen(),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                _buildDashboardTile(
                  icon: Icons.science_outlined,
                  title: 'Twin Simulation Review',
                  subtitle: 'Review patient simulations',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const TwinPreviewScreen(),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    VoidCallback? onTap,
  }) {
    final card = Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: mainBlue),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
          ),
          Text(title, style: TextStyle(color: Colors.grey[600], fontSize: 13)),
        ],
      ),
    );

    return Expanded(
      child: onTap == null
          ? card
          : InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(12),
              child: card,
            ),
    );
  }

  Widget _buildDashboardTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(icon, color: mainBlue, size: 28),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(color: Colors.grey[600], fontSize: 13),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
          ],
        ),
      ),
    );
  }
}
