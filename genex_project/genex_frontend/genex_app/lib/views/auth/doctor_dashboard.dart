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
import 'dart:ui';

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

  static const Color mainBlue = Color(0xFF2563EB);
  static const Color deepBlue = Color(0xFF1E3A8A);
  static const Color cyanBlue = Color(0xFF3B82F6);
  static const Color purpleGlow = Color(0xFF7C3AED);
  static const Color darkBg = Color(0xFF020617);
  static const Color darkCard = Color(0xFF0F172A);
  static const Color lightBg = Color(0xFFF8FAFC);

  @override
  void initState() {
    super.initState();
    _initializeDashboard();
  }

  Future<void> _initializeDashboard() async {
    await _checkAccess();
    if (_isAuthorized) await _fetchDashboardStats();
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

      if (response.statusCode == 200 && mounted) {
        setState(() {
          totalPatients = response.data['assigned_patients'] ?? 0;
          pendingPatients = response.data['pending_patients'] ?? 0;
          _isStatsLoading = false;
        });
      } else if (mounted) {
        setState(() => _isStatsLoading = false);
      }
    } catch (e) {
      debugPrint('❌ Error fetching dashboard stats: $e');
      if (mounted) setState(() => _isStatsLoading = false);
    }
  }

  Future<void> _refreshDashboard() async {
    setState(() => _isStatsLoading = true);
    await _fetchDashboardStats();
  }

  Future<void> _showLogoutConfirmation(
    BuildContext context,
    AuthViewModel authVM,
  ) async {
    final loc = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: theme.colorScheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text(
          loc.confirmLogout,
          style: const TextStyle(fontWeight: FontWeight.w900),
        ),
        content: Text(loc.logoutMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(loc.cancel),
          ),
          ElevatedButton.icon(
            icon: const Icon(Icons.logout_rounded, size: 18),
            label: Text(loc.logout),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
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
          ),
        ],
      ),
    );
  }


@override
Widget build(BuildContext context) {
  final theme = Theme.of(context);
  final isDark = Theme.of(context).brightness == Brightness.dark;
  final isDesktop = MediaQuery.of(context).size.width >= 1000;

  if (_isLoading) {
    return Scaffold(
      backgroundColor: isDark ? darkBg : lightBg,
      body: const Center(child: CircularProgressIndicator()),
    );
  }

  if (!_isAuthorized) return const SizedBox.shrink();

  final authVM = ref.read(authViewModelProvider.notifier);

  return Scaffold(
    backgroundColor: isDark ? darkBg : lightBg,
    body: Stack(
      children: [
        _background(isDark),

      // DNA Floating Background
      
Positioned(
  right: -120,
  top: 180,
  child: Transform.rotate(
    angle: 0.15,
    child: _softDnaImage(
      context,
      width: 380,
      opacity: Theme.of(context).brightness ==
              Brightness.dark
          ? 0.15
          : 0.20,
    ),
  ),
),

Positioned(
  left: -120,
  bottom: -40,
  child: Transform.rotate(
    angle: 3.14,
    child: _softDnaImage(
      context,
      width: 320,
      opacity: Theme.of(context).brightness ==
              Brightness.dark
          ? 0.12
          : 0.16,
    ),
  ),
),
        SafeArea(
          child: RefreshIndicator(
            color: mainBlue,
            onRefresh: _refreshDashboard,
            
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: EdgeInsets.all(isDesktop ? 32 : 20),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1180),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _topBar(context, authVM),
                      const SizedBox(height: 24),
                      _hero(context),
                      const SizedBox(height: 24),
                      _statsSection(context),
                      const SizedBox(height: 30),
                      _quickActions(context),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    ),
  );
}

  Widget _background(bool isDark) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? const [
                  Color(0xFF020617),
                  Color(0xFF0F172A),
                  Color(0xFF111827),
                ]
              : const [
                  Color(0xFFEFF6FF),
                  Color(0xFFF8FAFC),
                  Color(0xFFE0F2FE),
                ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            top: -100,
            left: -80,
            child: _glow(mainBlue.withOpacity(isDark ? 0.22 : 0.16), 280),
          ),
          Positioned(
            bottom: -130,
            right: -90,
            child: _glow(purpleGlow.withOpacity(isDark ? 0.22 : 0.14), 320),
          ),
          Positioned(
            top: 220,
            right: 220,
            child: _glow(mainBlue.withOpacity(isDark ? 0.12 : 0.10), 180),
          ),
        ],
      ),
    );
  }

  Widget _glow(Color color, double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: color,
            blurRadius: 100,
            spreadRadius: 35,
          ),
        ],
      ),
    );
  }

 
  Widget _topBar(BuildContext context, AuthViewModel authVM) {
  final loc = AppLocalizations.of(context)!;
  final theme = Theme.of(context);

  return Row(
    children: [
      Container(
        width: 52,
        height: 52,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          gradient: const LinearGradient(
            colors: [mainBlue, Color(0xFF1D4ED8)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: mainBlue.withOpacity(0.25),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: const Icon(
          Icons.health_and_safety_rounded,
          color: Colors.white,
        ),
      ),

      const SizedBox(width: 14),

      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              loc.doctorDashboard,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w900,
                color: theme.colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Clinical overview and patient management',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.58),
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),

      _circleButton(
        context,
        Icons.settings_rounded,
        () => Navigator.pushNamed(context, '/settings'),
      ),

      const SizedBox(width: 10),

      _circleButton(
        context,
        Icons.refresh_rounded,
        _refreshDashboard,
      ),

      const SizedBox(width: 10),

      _circleButton(
        context,
        Icons.logout_rounded,
        () => _showLogoutConfirmation(context, authVM),
        color: Colors.redAccent,
      ),
    ],
  );
}
Widget _softDnaImage(
  BuildContext context, {
  required double width,
  required double opacity,
}) {
  final isDark =
      Theme.of(context).brightness == Brightness.dark;

  return IgnorePointer(
    child: Opacity(
      opacity: opacity,
      child: Image.asset(
        isDark
            ? 'assets/images/dna_dark.png'
            : 'assets/images/dna_light.png',
        width: width,
        fit: BoxFit.contain,
      ),
    ),
  );
}
Widget _hero(BuildContext context) {
  final theme = Theme.of(context);

  return Container(
    width: double.infinity,
    padding: const EdgeInsets.all(30),
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(34),
      gradient: const LinearGradient(
        colors: [Color(0xFF0F172A), deepBlue, mainBlue],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      boxShadow: [
        BoxShadow(
          color: mainBlue.withOpacity(0.25),
          blurRadius: 35,
          offset: const Offset(0, 18),
        ),
      ],
    ),
   child: Stack(
  children: [
    LayoutBuilder(
          builder: (context, constraints) {
            final compact = constraints.maxWidth < 700;

            final iconWidget = Container(
              width: 84,
              height: 84,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.13),
                border: Border.all(
                  color: Colors.white.withOpacity(0.18),
                ),
                boxShadow: [
                  BoxShadow(
                    color: cyanBlue.withOpacity(0.28),
                    blurRadius: 30,
                  ),
                ],
              ),
              child: const Icon(
                Icons.monitor_heart_rounded,
                color: Colors.white,
                size: 44,
              ),
            );

            final textWidget = Column(
              crossAxisAlignment: compact
                  ? CrossAxisAlignment.center
                  : CrossAxisAlignment.start,
              children: [
                Text(
                  "Welcome back, Doctor",
                  textAlign: compact ? TextAlign.center : TextAlign.start,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  "Review patient access, manage records, and monitor AI-powered medical insights from one secure workspace.",
                  textAlign: compact ? TextAlign.center : TextAlign.start,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.78),
                    height: 1.5,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            );

            if (compact) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  iconWidget,
                  const SizedBox(height: 22),
                  textWidget,
                ],
              );
            }

            return Row(
              children: [
                iconWidget,
                const SizedBox(width: 22),
                Expanded(child: textWidget),
              ],
            );
          },
        ),
      ],
    ),
  );
}
  Widget _heroRing(double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: Colors.white.withOpacity(0.08),
          width: 18,
        ),
      ),
    );
  }

  Widget _statsSection(BuildContext context) {
  final loc = AppLocalizations.of(context)!;

  return LayoutBuilder(
    builder: (context, constraints) {
      final isWide = constraints.maxWidth >= 720;

      final assignedCard = _statCard(
        context,
        title: loc.assignedPatients,
        value: _isStatsLoading ? '...' : totalPatients.toString(),
        icon: Icons.people_alt_rounded,
        subtitle: 'Active patient records',
      );

      final pendingCard = _statCard(
        context,
        title: loc.pendingPatients,
        value: _isStatsLoading ? '...' : pendingPatients.toString(),
        icon: Icons.pending_actions_rounded,
        subtitle: 'Requests waiting for approval',
        highlight: true,
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const PendingPatientsView()),
          );
        },
      );

      if (!isWide) {
        return Column(
          children: [
            assignedCard,
            const SizedBox(height: 16),
            pendingCard,
          ],
        );
      }

      return Row(
        children: [
          Expanded(child: assignedCard),
          const SizedBox(width: 18),
          Expanded(child: pendingCard),
        ],
      );
    },
  );
}

  Widget _quickActions(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final isWide = MediaQuery.of(context).size.width >= 900;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          loc.quickActions,
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w900,
            color: theme.colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 16),
        GridView.count(
          crossAxisCount: isWide ? 3 : 1,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 18,
          mainAxisSpacing: 18,
          childAspectRatio: isWide ? 1.08 : 3.4,
          children: [
            _actionCard(
              context,
              icon: Icons.manage_accounts_rounded,
              title: loc.managePatients,
              subtitle: loc.viewPatientDirectory,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const UserSearchView()),
              ),
            ),
            _actionCard(
              context,
              icon: Icons.medical_services_rounded,
              title: loc.myPatients,
              subtitle: loc.viewMedicalLogs,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const DoctorDashboardScreen()),
              ),
            ),
            _actionCard(
              context,
              icon: Icons.view_in_ar_rounded,
              title: loc.twinSimulationReview,
              subtitle: loc.reviewPatientSimulations,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const TwinPreviewScreen()),
              ),
            ),
          ],
        ),
      ],
    );
  }

 Widget _statCard(
  BuildContext context, {
  required String title,
  required String value,
  required IconData icon,
  required String subtitle,
  bool highlight = false,
  VoidCallback? onTap,
}) {
  final theme = Theme.of(context);
  final isDark = theme.brightness == Brightness.dark;

  final child = Container(
    width: double.infinity,
    padding: const EdgeInsets.all(24),
    decoration: BoxDecoration(
      color: isDark ? darkCard.withOpacity(0.92) : Colors.white,
      borderRadius: BorderRadius.circular(28),
      border: Border.all(
        color: highlight
            ? mainBlue.withOpacity(0.18)
            : theme.dividerColor.withOpacity(0.12),
      ),
      boxShadow: [
        BoxShadow(
          color: highlight
              ? mainBlue.withOpacity(0.16)
              : Colors.black.withOpacity(isDark ? 0.18 : 0.06),
          blurRadius: 24,
          offset: const Offset(0, 14),
        ),
      ],
    ),
    child: LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 330;

        final iconBox = Container(
          width: 62,
          height: 62,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            gradient:
                highlight ? const LinearGradient(colors: [mainBlue, cyanBlue]) : null,
            color: highlight ? null : mainBlue.withOpacity(0.12),
          ),
          child: Icon(
            icon,
            color: highlight ? Colors.white : mainBlue,
            size: 32,
          ),
        );

        final textContent = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.w900,
                color: theme.colorScheme.onSurface,
              ),
            ),
            Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w900,
                color: theme.colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.55),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        );

        final arrow = onTap == null
            ? const SizedBox.shrink()
            : Icon(
                Directionality.of(context) == TextDirection.rtl
                    ? Icons.arrow_back_ios_rounded
                    : Icons.arrow_forward_ios_rounded,
                color: theme.colorScheme.onSurface.withOpacity(0.32),
                size: 16,
              );

        if (compact) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              iconBox,
              const SizedBox(height: 16),
              textContent,
              if (onTap != null) ...[
                const SizedBox(height: 12),
                Align(
                  alignment: AlignmentDirectional.centerEnd,
                  child: arrow,
                ),
              ],
            ],
          );
        }

        return Row(
          children: [
            iconBox,
            const SizedBox(width: 18),
            Expanded(child: textContent),
            const SizedBox(width: 8),
            arrow,
          ],
        );
      },
    ),
  );

  return onTap == null
      ? child
      : InkWell(
          borderRadius: BorderRadius.circular(28),
          onTap: onTap,
          child: child,
        );
}

  Widget _actionCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return InkWell(
      borderRadius: BorderRadius.circular(28),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: isDark ? darkCard.withOpacity(0.92) : Colors.white,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: theme.dividerColor.withOpacity(0.12)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.18 : 0.06),
              blurRadius: 24,
              offset: const Offset(0, 14),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 58,
              height: 58,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                gradient: const LinearGradient(
  colors: [
    mainBlue,
    Color(0xFF1D4ED8),
  ],
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
),
                boxShadow: [
                  BoxShadow(
                    color: mainBlue.withOpacity(0.22),
                    blurRadius: 18,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Icon(icon, color: Colors.white, size: 30),
            ),
            const SizedBox(height: 18),
            Text(
              title,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w900,
                color: theme.colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 6),
            Expanded(
              child: Text(
                subtitle,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(0.58),
                  height: 1.4,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            Align(
              alignment: AlignmentDirectional.centerEnd,
              child: Icon(
                Directionality.of(context) == TextDirection.rtl
                    ? Icons.arrow_back_rounded
                    : Icons.arrow_forward_rounded,
                color: mainBlue,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _circleButton(
    BuildContext context,
    IconData icon,
    VoidCallback onTap, {
    Color? color,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return InkWell(
      borderRadius: BorderRadius.circular(17),
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: isDark ? Colors.white.withOpacity(0.06) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: theme.dividerColor.withOpacity(0.12)),
        ),
        child: Icon(icon, color: color ?? mainBlue, size: 22),
      ),
    );
  }
}