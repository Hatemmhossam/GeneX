// lib/views/patient/responsive_dashboard.dart

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../viewmodels/providers.dart';
import '../../widgets/premium_card.dart';
import 'profile_view.dart';
import 'upload_screen.dart';
import 'med_history_screen.dart';
import 'twin_simulation_screen.dart';
import 'doctor_requests_screen.dart';
import 'reports_screen.dart';
import 'symptoms_screen.dart';
import 'about_system_screen.dart';
import 'dna_model_visualization.dart';
import 'my_doctors_screen.dart';
import 'package:genex_app/l10n/app_localizations.dart';

class ResponsiveDashboard extends ConsumerStatefulWidget {
  const ResponsiveDashboard({super.key});

  @override
  ConsumerState<ResponsiveDashboard> createState() =>
      _ResponsiveDashboardState();
}

class _ResponsiveDashboardState extends ConsumerState<ResponsiveDashboard> {
  int _selectedIndex = 0;

  final List<Widget> _pages = const [
    DashboardOverview(),
    ProfileScreen(),
    MedHistoryScreen(),
    SymptomReportScreen(),
    UploadScreen(),
    TwinSimulationScreen(),
    DoctorRequestsScreen(),
    MyDoctorsScreen(),
    ReportsScreen(),
    AboutSystemScreen(),
  ];

  Future<void> _handleLogout() async {
    final theme = Theme.of(context);
    final loc = AppLocalizations.of(context)!;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: theme.colorScheme.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        title: Text(loc.confirmLogout),
        content: Text(loc.logoutConfirmationMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(loc.cancel),
          ),
          ElevatedButton.icon(
            icon: const Icon(Icons.logout_rounded),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            onPressed: () => Navigator.pop(context, true),
            label: Text(loc.logout),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await ref.read(authViewModelProvider.notifier).logout();

      if (mounted) {
        Navigator.of(context).pushNamedAndRemoveUntil(
          '/signin',
          (route) => false,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final width = MediaQuery.of(context).size.width;
    final isDesktop = width > 900;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Row(
        children: [
          if (isDesktop)
            _DesktopRail(
              selectedIndex: _selectedIndex,
              onSelected: (index) {
                setState(() => _selectedIndex = index);
              },
            ),
          Expanded(
            child: Column(
              children: [
                _DashboardHeader(onLogout: _handleLogout),
                Expanded(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 280),
                    child: _pages[_selectedIndex.clamp(0, _pages.length - 1)],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: isDesktop
          ? null
          : _MobileBottomBar(
              selectedIndex: _selectedIndex > 4 ? 0 : _selectedIndex,
              onSelected: (index) {
                setState(() => _selectedIndex = index);
              },
            ),
    );
  }
}

class _DesktopRail extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  const _DesktopRail({
    required this.selectedIndex,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final loc = AppLocalizations.of(context)!;
    final width = MediaQuery.of(context).size.width;

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          right: BorderSide(
            color: theme.dividerColor.withOpacity(0.12),
          ),
        ),
      ),
      child: NavigationRail(
        extended: width > 1200,
        backgroundColor: Colors.transparent,
        selectedIndex: selectedIndex,
        onDestinationSelected: onSelected,
        selectedIconTheme: IconThemeData(
          color: theme.colorScheme.primary,
          size: 26,
        ),
        unselectedIconTheme: IconThemeData(
          color: theme.colorScheme.onSurface.withOpacity(0.50),
        ),
        selectedLabelTextStyle: TextStyle(
          color: theme.colorScheme.primary,
          fontWeight: FontWeight.w800,
        ),
        unselectedLabelTextStyle: TextStyle(
          color: theme.colorScheme.onSurface.withOpacity(0.60),
          fontWeight: FontWeight.w600,
        ),
        leading: Padding(
          padding: const EdgeInsets.only(top: 18, bottom: 24),
          child: CircleAvatar(
            radius: 26,
            backgroundColor: theme.colorScheme.primary.withOpacity(0.12),
            child: Icon(
              Icons.biotech_rounded,
              color: theme.colorScheme.primary,
            ),
          ),
        ),
        destinations: [
          _railItem(Icons.dashboard_rounded, loc.overview),
          _railItem(Icons.person_rounded, loc.profile),
          _railItem(Icons.medication_rounded, loc.history),
          _railItem(Icons.sick_rounded, loc.symptoms),
          _railItem(Icons.upload_file_rounded, loc.upload),
          _railItem(Icons.biotech_rounded, loc.simulation),
          _railItem(Icons.person_search_rounded, loc.doctorRequests),
          _railItem(Icons.medical_services_outlined, loc.myDoctors),
          _railItem(Icons.folder_shared_rounded, loc.reports),
          _railItem(Icons.info_outline_rounded, loc.about),
        ],
      ),
    );
  }

  NavigationRailDestination _railItem(IconData icon, String label) {
    return NavigationRailDestination(
      icon: Icon(icon),
      selectedIcon: Icon(icon),
      label: Text(label),
    );
  }
}

class _MobileBottomBar extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  const _MobileBottomBar({
    required this.selectedIndex,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final loc = AppLocalizations.of(context)!;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: theme.dividerColor.withOpacity(0.12),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(
              theme.brightness == Brightness.dark ? 0.28 : 0.08,
            ),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: BottomNavigationBar(
          currentIndex: selectedIndex,
          type: BottomNavigationBarType.fixed,
          elevation: 0,
          backgroundColor: Colors.transparent,
          selectedItemColor: theme.colorScheme.primary,
          unselectedItemColor: theme.colorScheme.onSurface.withOpacity(0.50),
          selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w800),
          unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600),
          onTap: onSelected,
          items: [
            BottomNavigationBarItem(
              icon: const Icon(Icons.dashboard_rounded),
              label: loc.home,
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.person_rounded),
              label: loc.profile,
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.medication_rounded),
              label: loc.meds,
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.sick_rounded),
              label: loc.symptoms,
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.medical_services_outlined),
              label: loc.doctors,
            ),
          ],
        ),
      ),
    );
  }
}

class _DashboardHeader extends StatelessWidget {
  final VoidCallback onLogout;

  const _DashboardHeader({
    required this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final loc = AppLocalizations.of(context)!;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          bottom: BorderSide(
            color: theme.dividerColor.withOpacity(0.12),
          ),
        ),
      ),
      child: Row(
        children: [
          Text(
            loc.geneXMedicalPortal,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w900,
            ),
          ),
          const Spacer(),
          IconButton(
            tooltip: loc.logout,
            onPressed: onLogout,
            icon: const Icon(Icons.logout_rounded),
            color: Colors.redAccent,
          ),
          const SizedBox(width: 12),
          CircleAvatar(
            backgroundColor: theme.colorScheme.primary.withOpacity(0.12),
            child: Icon(
              Icons.person_rounded,
              color: theme.colorScheme.primary,
            ),
          ),
        ],
      ),
    );
  }
}

class DashboardOverview extends ConsumerWidget {
  const DashboardOverview({super.key});

@override
Widget build(BuildContext context, WidgetRef ref) {
  final theme = Theme.of(context);
  final loc = AppLocalizations.of(context)!;

  final medsAsync = ref.watch(medicinesProvider);
  final reportsAsync = ref.watch(geneReportsProvider);

  return Stack(
    children: [
      Positioned(
        right: -180,
        top: 120,
        child: Transform.rotate(
          angle: 0.18,
          child: _softDnaImage(
            width: 480,
            opacity: 0.12,
          ),
        ),
      ),

      Positioned(
        left: -180,
        bottom: 0,
        child: Transform.rotate(
          angle: -0.15,
          child: _softDnaImage(
            width: 420,
            opacity: 0.10,
          ),
        ),
      ),

      SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _HeroDashboardCard(loc: loc),
            const SizedBox(height: 24),
            Text(
              loc.systemOverview,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 18),
            LayoutBuilder(
              builder: (context, constraints) {
                final crossAxisCount = constraints.maxWidth > 1200
                    ? 4
                    : constraints.maxWidth > 760
                        ? 2
                        : 1;

                return GridView.count(
                  crossAxisCount: crossAxisCount,
                  shrinkWrap: true,
                  crossAxisSpacing: 18,
                  mainAxisSpacing: 18,
                  childAspectRatio: crossAxisCount == 1 ? 2.4 : 1.55,
                  physics: const NeverScrollableScrollPhysics(),
                  children: [
                    reportsAsync.when(
                      data: (reports) {
                        final latestReport =
                            reports.isNotEmpty ? reports.first : null;

                        final status = latestReport != null
                            ? latestReport['label'].toString()
                            : loc.noData;

                        final color = status.toLowerCase().contains('high')
                            ? Colors.redAccent
                            : Colors.green;

                        return _DashboardMetricCard(
                          title: loc.vitalsStatus,
                          value: status,
                          icon: latestReport != null
                              ? Icons.favorite_rounded
                              : Icons.favorite_border_rounded,
                          color: color,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    const DnaModelVisualizationScreen(),
                              ),
                            );
                          },
                        );
                      },
                      loading: () => _DashboardMetricCard(
                        title: loc.vitalsStatus,
                        value: loc.loading,
                        icon: Icons.favorite_rounded,
                        color: Colors.grey,
                      ),
                      error: (err, stack) => _DashboardMetricCard(
                        title: loc.vitalsStatus,
                        value: loc.error,
                        icon: Icons.error_rounded,
                        color: Colors.orange,
                      ),
                    ),

                    medsAsync.when(
                      data: (meds) => _DashboardMetricCard(
                        title: loc.meds,
                        value: '${meds.length} Prescribed',
                        icon: Icons.medication_rounded,
                        color: theme.colorScheme.primary,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const MedHistoryScreen(),
                            ),
                          );
                        },
                      ),
                      loading: () => _DashboardMetricCard(
                        title: loc.meds,
                        value: loc.loading,
                        icon: Icons.medication_rounded,
                        color: Colors.grey,
                      ),
                      error: (err, stack) => _DashboardMetricCard(
                        title: loc.meds,
                        value: loc.error,
                        icon: Icons.error_rounded,
                        color: Colors.orange,
                      ),
                    ),

                    _DashboardMetricCard(
                      title: loc.reports,
                      value: 'View History',
                      icon: Icons.folder_shared_rounded,
                      color: Colors.purpleAccent,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const ReportsScreen(),
                          ),
                        );
                      },
                    ),

                    _DashboardMetricCard(
                      title: loc.myDoctors,
                      value: 'View & Chat',
                      icon: Icons.medical_services_rounded,
                      color: Colors.teal,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const MyDoctorsScreen(),
                          ),
                        );
                      },
                    ),

                    _DashboardMetricCard(
                      title: 'Next Simulation',
                      value: 'Scheduled: Feb 25',
                      icon: Icons.science_rounded,
                      color: Colors.deepPurpleAccent,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const TwinSimulationScreen(),
                          ),
                        );
                      },
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    ],
  );
}
}
class _HeroDashboardCard extends StatelessWidget {
  final AppLocalizations loc;

  const _HeroDashboardCard({
    required this.loc,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
    gradient: const LinearGradient(
      colors: [
        Color(0xFF0F172A), // Deep navy
        Color(0xFF1E3A8A), // Medical blue
        Color(0xFF2563EB), // Bright blue
      ],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2563EB).withOpacity(0.35),
            blurRadius: 35,
            spreadRadius: 2,
            offset: const Offset(0, 18),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 68,
            height: 68,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.12),
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.white.withOpacity(0.15),
              ),
            ),
            child: const Icon(
              Icons.monitor_heart_rounded,
              color: Colors.white,
              size: 36,
            ),
          ),
          const SizedBox(width: 22),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  loc.geneXMedicalPortal,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Your AI-powered healthcare assistant for predictions, reports, doctors, and smart health insights.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: Colors.white.withOpacity(0.75),
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 450.ms).slideY(begin: -0.08);
  }
}

class _DashboardMetricCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;

  const _DashboardMetricCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return PremiumCard(
      onTap: onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              shape: BoxShape.circle,
              border: Border.all(
                color: color.withOpacity(0.22),
              ),
            ),
            child: Icon(
              icon,
              color: color,
              size: 28,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            title,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.62),
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 450.ms).slideY(begin: 0.08);
  }
}
  Widget _softDnaImage({
  required double width,
  required double opacity,
}) {
  return IgnorePointer(
    child: Opacity(
      opacity: opacity,
      child: ShaderMask(
        shaderCallback: (Rect bounds) {
          return const RadialGradient(
            center: Alignment.center,
            radius: 1.2,
            colors: [
              Colors.white,
              Colors.white,
              Color(0x99FFFFFF),
              Color(0x33FFFFFF),
              Colors.transparent,
            ],
            stops: [0.0, 0.55, 0.78, 0.92, 1.0],
          ).createShader(bounds);
        },
        blendMode: BlendMode.dstIn,
        child: Image.asset(
          'assets/images/dna_bg.png',
          width: width,
          fit: BoxFit.contain,
        ),
      ),
    ),
  );
}
