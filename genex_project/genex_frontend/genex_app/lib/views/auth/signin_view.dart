// lib/views/auth/signin_view.dart

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../viewmodels/providers.dart';
import '../../viewmodels/auth_state.dart';
import '../../widgets/loading_button.dart';
import 'package:genex_app/l10n/app_localizations.dart';
import '../../services/fcm_service.dart';

class SigninView extends ConsumerStatefulWidget {
  const SigninView({super.key});

  @override
  ConsumerState<SigninView> createState() => _SigninViewState();
}

class _SigninViewState extends ConsumerState<SigninView> {
  final _formKey = GlobalKey<FormState>();
  final _usernameCtr = TextEditingController();
  final _passwordCtr = TextEditingController();

  bool _obscurePassword = true;

  static const Color mainBlue = Color(0xFF2563EB);
  static const Color cyanBlue = Color(0xFF22D3EE);

  @override
  void dispose() {
    _usernameCtr.dispose();
    _passwordCtr.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isMobile = MediaQuery.of(context).size.width < 760;

    final authState = ref.watch(authViewModelProvider);
    final authVM = ref.read(authViewModelProvider.notifier);

    ref.listen<AuthState>(authViewModelProvider, (previous, next) async {
      if (next.status == AuthStatus.authenticated) {
        final role = next.role;
        final prefs = await SharedPreferences.getInstance();

        await prefs.setString('role', role ?? '');

        if (next.token != null) {
          await prefs.setString('token', next.token!);
        }
      try {
        final fcmToken = await FcmService.getToken();

        if (fcmToken != null && fcmToken.isNotEmpty) {
          final apiService = ref.read(apiServiceProvider);
          await apiService.saveFcmToken(fcmToken);
        }
      } catch (e) {
        debugPrint("FCM token save failed: $e");
      }
      
        if (!context.mounted) return;

        if (role == 'patient') {
          Navigator.of(context).pushReplacementNamed('/home');
        } else if (role == 'doctor') {
          Navigator.of(context).pushReplacementNamed('/doctor');
        } else {
          showDialog(
            context: context,
            builder: (_) => AlertDialog(
              title: Text(loc.accessDenied),
              content: Text(
                role == null || role.isEmpty
                    ? loc.accountNoRole
                    : loc.roleNotAllowed,
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                    prefs.clear();
                  },
                  child: Text(loc.ok),
                ),
              ],
            ),
          );
        }
      } else if (next.status == AuthStatus.error && next.errorMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.errorMessage!),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    });

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Stack(
        children: [
          _background(isDark),
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1040),
                child: Container(
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface,
                    borderRadius: BorderRadius.circular(34),
                    border: Border.all(
                      color: theme.dividerColor.withOpacity(0.12),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: theme.colorScheme.primary.withOpacity(0.18),
                        blurRadius: 45,
                        offset: const Offset(0, 24),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(34),
                    child: isMobile
                        ? Column(
                            children: [
                              _heroPanel(context)
                                  .animate()
                                  .fadeIn(duration: 500.ms)
                                  .slideY(begin: -0.08),
                              _formPanel(context, authState, authVM)
                                  .animate()
                                  .fadeIn(duration: 500.ms)
                                  .slideY(begin: 0.08),
                            ],
                          )
                        : Row(
                            children: [
                              Expanded(
                                flex: 6,
                                child: _formPanel(
                                  context,
                                  authState,
                                  authVM,
                                )
                                    .animate()
                                    .fadeIn(duration: 500.ms)
                                    .slideX(begin: -0.08),
                              ),
                              Expanded(
                                flex: 5,
                                child: _heroPanel(context)
                                    .animate()
                                    .fadeIn(duration: 600.ms)
                                    .slideX(begin: 0.08),
                              ),
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
    );
  }

  Widget _formPanel(
    BuildContext context,
    AuthState authState,
    dynamic authVM,
  ) {
    final loc = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      constraints: const BoxConstraints(minHeight: 620),
      padding: const EdgeInsets.symmetric(horizontal: 46, vertical: 44),
      color: isDark ? const Color(0xFF020617) : Colors.white,
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _logoTitle(context),
            const SizedBox(height: 42),
            Text(
              loc.signIn,
              style: theme.textTheme.displayMedium?.copyWith(
                fontWeight: FontWeight.w900,
                letterSpacing: -0.7,
              ),
            ),
            const SizedBox(height: 34),
            _textField(
              context: context,
              controller: _usernameCtr,
              hintText: loc.username,
              icon: Icons.person_outline_rounded,
              validator: (v) =>
                  v != null && v.isNotEmpty ? null : loc.enterValidUsername,
            ),
            const SizedBox(height: 16),
            _textField(
              context: context,
              controller: _passwordCtr,
              hintText: loc.password,
              icon: Icons.lock_outline_rounded,
              isPassword: true,
              validator: (v) =>
                  v != null && v.length >= 6 ? null : loc.minSixChars,
            ),
            const SizedBox(height: 12),
            Align(
              alignment: AlignmentDirectional.centerEnd,
              child: TextButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Password reset screen is not added yet.'),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
                child: Text(
                  'Forgot password?',
                  style: TextStyle(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 14),
            LoadingButton(
              loading: authState.status == AuthStatus.authenticating,
              icon: Icons.login_rounded,
              label: loc.signIn,
              onPressed: () {
                if (_formKey.currentState!.validate()) {
                  authVM.login(
                    username: _usernameCtr.text.trim(),
                    password: _passwordCtr.text,
                  );
                }
              },
            ).animate().fadeIn(duration: 500.ms).slideY(begin: 0.08),
            const SizedBox(height: 28),
            Row(
              children: [
                Expanded(child: Divider(color: theme.dividerColor.withOpacity(0.25))),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  child: Text(
                    loc.orSignInWith,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withOpacity(0.55),
                    ),
                  ),
                ),
                Expanded(child: Divider(color: theme.dividerColor.withOpacity(0.25))),
              ],
            ),
            const SizedBox(height: 18),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _socialButton(Icons.facebook_rounded, mainBlue),
                const SizedBox(width: 14),
                _socialButton(Icons.g_mobiledata_rounded, Colors.redAccent),
                const SizedBox(width: 14),
                _socialButton(Icons.chat_bubble_outline_rounded, cyanBlue),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _heroPanel(BuildContext context) {
    final loc = AppLocalizations.of(context)!;

    return Container(
      constraints: const BoxConstraints(minHeight: 620),
      padding: const EdgeInsets.all(42),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Color(0xFF0F172A),
            Color(0xFF1E3A8A),
            mainBlue,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Stack(
        children: [
          Positioned(top: -30, right: -30, child: _ring(180)),
          Positioned(bottom: -60, left: -50, child: _ring(240)),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _largeLogo(),
              const SizedBox(height: 30),
              Text(
                loc.welcomeBack,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 30,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.6,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                loc.welcomeBackMessage,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.78),
                  fontSize: 16,
                  height: 1.6,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 34),
              _pill(Icons.verified_user_outlined, 'Secure AI Healthcare'),
              const SizedBox(height: 12),
              _pill(Icons.auto_graph_rounded, 'Smart Medical Insights'),
              const SizedBox(height: 34),
              OutlinedButton(
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  side: BorderSide(color: Colors.white.withOpacity(0.8)),
                  padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                ),
                onPressed: () {
                  Navigator.of(context).pushReplacementNamed('/signup');
                },
                child: Text(
                  loc.noAccountYet,
                  style: const TextStyle(
                    fontSize: 15.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _logoTitle(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'GeneX',
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'AI-Powered Healthcare',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.primary,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }

  Widget _largeLogo() {
    return Container(
      width: 118,
      height: 118,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: cyanBlue.withOpacity(0.65), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: cyanBlue.withOpacity(0.35),
            blurRadius: 35,
            spreadRadius: 4,
          ),
        ],
      ),
      child: ClipOval(
        child: Image.asset(
          'images/genex_logo.jpeg',
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return Container(
              color: mainBlue,
              child: const Icon(
                Icons.biotech_rounded,
                color: Colors.white,
                size: 56,
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _textField({
    required BuildContext context,
    required TextEditingController controller,
    required String hintText,
    required IconData icon,
    bool isPassword = false,
    String? Function(String?)? validator,
  }) {
    final theme = Theme.of(context);

    return TextFormField(
      controller: controller,
      obscureText: isPassword ? _obscurePassword : false,
      validator: validator,
      style: TextStyle(
        color: theme.colorScheme.onSurface,
        fontWeight: FontWeight.w600,
      ),
      decoration: InputDecoration(
        hintText: hintText,
        prefixIcon: Icon(icon, color: theme.colorScheme.primary),
        suffixIcon: isPassword
            ? IconButton(
                icon: Icon(
                  _obscurePassword
                      ? Icons.visibility_off_rounded
                      : Icons.visibility_rounded,
                  color: theme.colorScheme.primary,
                ),
                onPressed: () {
                  setState(() => _obscurePassword = !_obscurePassword);
                },
              )
            : null,
      ),
    );
  }

  Widget _socialButton(IconData icon, Color color) {
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: () {},
      child: Container(
        width: 50,
        height: 50,
        decoration: BoxDecoration(
          color: color.withOpacity(0.12),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: color.withOpacity(0.22)),
        ),
        child: Icon(icon, color: color, size: 25),
      ),
    );
  }

  Widget _pill(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.12),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: Colors.white.withOpacity(0.16)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 18),
          const SizedBox(width: 8),
          Text(
            text,
            style: TextStyle(
              color: Colors.white.withOpacity(0.9),
              fontWeight: FontWeight.w700,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  Widget _ring(double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: Colors.white.withOpacity(0.07),
          width: 18,
        ),
      ),
    );
  }
}