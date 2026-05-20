// lib/views/doctor/doctor_dashboard.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:genex_app/l10n/app_localizations.dart';

import '../../viewmodels/providers.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../doctor/user_search_view.dart';
import '../doctor/see_accessed_patients.dart';
import '../doctor/pending_patients_view.dart';
import '../doctor/twin_preview_screen.dart';

class DoctorDashboard extends ConsumerStatefulWidget {
  const DoctorDashboard({super.key});

  @override
  ConsumerState<DoctorDashboard> createState() => _DoctorDashboardState();
}

class _DoctorDashboardState extends ConsumerState<DoctorDashboard> {
  bool _isLoading = true;
  bool _isAuthorized = false;
  bool _isStatsLoading = true;

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
    final loc = AppLocalizations.of(context)!;

    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          title: Text(loc.confirmLogout),
          content: Text(loc.logoutMessage),
          actions: [
            TextButton(
              child: Text(loc.cancel),
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
                  Navigator.of(context).pushNamedAndRemoveUntil(
                    '/signin',
                    (r) => false,
                  );
                }
              },
              child: Text(loc.logout),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    if (_isLoading) {
      return Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (!_isAuthorized) {
      return const SizedBox.shrink();
    }

    final authVM = ref.read(authViewModelProvider.notifier);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _refreshDashboard,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      loc.doctorDashboard,
                      style: theme.textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    Row(
                      children: [
                        IconButton(
                          icon: Icon(
                            Icons.settings,
                            color: theme.colorScheme.primary,
                          ),
                          onPressed: () {
                            Navigator.pushNamed(context, '/settings');
                          },
                        ),
                        IconButton(
                          icon: Icon(
                            Icons.refresh,
                            color: theme.colorScheme.primary,
                          ),
                          onPressed: _refreshDashboard,
                        ),
                        IconButton(
                          icon: const Icon(
                            Icons.logout,
                            color: Colors.redAccent,
                          ),
                          onPressed: () => _showLogoutConfirmation(
                            context,
                            authVM,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),

                const SizedBox(height: 32),

                Row(
                  children: [
                    _buildStatCard(
                      context: context,
                      title: loc.assignedPatients,
                      value: _isStatsLoading ? '...' : totalPatients.toString(),
                      icon: Icons.people_alt_outlined,
                    ),
                    const SizedBox(width: 16),
                    _buildStatCard(
                      context: context,
                      title: loc.pendingPatients,
                      value: _isStatsLoading ? '...' : pendingPatients.toString(),
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

                Text(
                  loc.quickActions,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onSurface,
                  ),
                ),

                const SizedBox(height: 16),

                _buildDashboardTile(
                  context: context,
                  icon: Icons.people_outline,
                  title: loc.managePatients,
                  subtitle: loc.viewPatientDirectory,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const UserSearchView(),
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                _buildDashboardTile(
                  context: context,
                  icon: Icons.medical_services_outlined,
                  title: loc.myPatients,
                  subtitle: loc.viewMedicalLogs,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const DoctorDashboardScreen(),
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                _buildDashboardTile(
                  context: context,
                  icon: Icons.science_outlined,
                  title: loc.twinSimulationReview,
                  subtitle: loc.reviewPatientSimulations,
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
    required BuildContext context,
    required String title,
    required String value,
    required IconData icon,
    VoidCallback? onTap,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final card = Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark
              ? Colors.white.withOpacity(0.08)
              : Colors.black.withOpacity(0.04),
        ),
        boxShadow: [
          if (!isDark)
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
          Icon(icon, color: theme.colorScheme.primary),
          const SizedBox(height: 12),
          Text(
            value,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onSurface,
            ),
          ),
          Text(
            title,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.65),
            ),
          ),
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
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isDark
                ? Colors.white.withOpacity(0.08)
                : Colors.black.withOpacity(0.04),
          ),
          boxShadow: [
            if (!isDark)
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
          ],
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: theme.colorScheme.primary,
              size: 28,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withOpacity(0.65),
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              size: 14,
              color: theme.colorScheme.onSurface.withOpacity(0.45),
            ),
          ],
        ),
      ),
    );
  }
}