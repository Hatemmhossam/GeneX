// lib/views/auth/signup_view.dart

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../viewmodels/providers.dart';
import '../../viewmodels/auth_state.dart';
import '../../widgets/loading_button.dart';
import 'package:genex_app/l10n/app_localizations.dart';

class SignupView extends ConsumerStatefulWidget {
  const SignupView({super.key});

  @override
  ConsumerState<SignupView> createState() => _SignupViewState();
}

class _SignupViewState extends ConsumerState<SignupView> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtr = TextEditingController();
  final _emailCtr = TextEditingController();
  final _passwordCtr = TextEditingController();

  bool _obscurePassword = true;

  int age = 18;
  String gender = 'male';
  int height = 160;
  int weight = 60;
  String role = 'patient';

  static const Color mainBlue = Color(0xFF2563EB);
  static const Color cyanBlue = Color(0xFF22D3EE);

  @override
  void dispose() {
    _nameCtr.dispose();
    _emailCtr.dispose();
    _passwordCtr.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isMobile = MediaQuery.of(context).size.width < 850;

    final authState = ref.watch(authViewModelProvider);
    final authVM = ref.read(authViewModelProvider.notifier);

    ref.listen<AuthState>(authViewModelProvider, (previous, next) {
      if (next.status == AuthStatus.authenticated) {
        Navigator.of(context).pushReplacementNamed('/home');
      } else if (next.status == AuthStatus.error && next.errorMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.errorMessage!),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
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
                constraints: const BoxConstraints(maxWidth: 1120),
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
                              _heroPanel(context, isMobile: true)
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
                                child: _formPanel(context, authState, authVM)
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
      constraints: const BoxConstraints(minHeight: 680),
      padding: const EdgeInsets.symmetric(horizontal: 46, vertical: 38),
      color: isDark ? const Color(0xFF020617) : Colors.white,
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _logoTitle(context),
            const SizedBox(height: 34),
            Text(
              loc.createAccount,
              style: theme.textTheme.displayMedium?.copyWith(
                fontWeight: FontWeight.w900,
                letterSpacing: -0.7,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Start your personalized AI healthcare journey.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.58),
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 28),
            _textField(
              context: context,
              controller: _nameCtr,
              hintText: loc.fullName,
              icon: Icons.person_outline_rounded,
              validator: (v) =>
                  v != null && v.trim().isNotEmpty ? null : loc.fullName,
            ),
            const SizedBox(height: 14),
            _textField(
              context: context,
              controller: _emailCtr,
              hintText: loc.email,
              icon: Icons.email_outlined,
              keyboardType: TextInputType.emailAddress,
              validator: (v) {
                final value = v?.trim() ?? '';
                if (value.isEmpty || !value.contains('@')) return loc.email;
                return null;
              },
            ),
            const SizedBox(height: 14),
            _textField(
              context: context,
              controller: _passwordCtr,
              hintText: loc.password,
              icon: Icons.lock_outline_rounded,
              isPassword: true,
              validator: (v) {
                if (v == null || v.length < 6) return loc.minSixChars;
                return null;
              },
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: _dropdown<int>(
                    context,
                    loc.age,
                    age,
                    List.generate(83, (i) => i + 18),
                    (v) => setState(() => age = v!),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: _dropdown<String>(
                    context,
                    loc.gender,
                    gender,
                    const ['male', 'female'],
                    (v) => setState(() => gender = v!),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: _dropdown<int>(
                    context,
                    loc.heightCm,
                    height,
                    List.generate(91, (i) => i + 120),
                    (v) => setState(() => height = v!),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: _dropdown<int>(
                    context,
                    loc.weightKg,
                    weight,
                    List.generate(141, (i) => i + 30),
                    (v) => setState(() => weight = v!),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 28),
            LoadingButton(
              loading: authState.status == AuthStatus.authenticating,
              icon: Icons.person_add_alt_1_rounded,
              label: loc.signUp,
              onPressed: () {
                if (_formKey.currentState!.validate()) {
                  authVM.signup(
                    name: _nameCtr.text.trim(),
                    email: _emailCtr.text.trim(),
                    password: _passwordCtr.text,
                    role: role,
                    age: age,
                    gender: gender,
                    height: height.toDouble(),
                    weight: weight.toDouble(),
                  );
                }
              },
            ).animate().fadeIn(duration: 500.ms).slideY(begin: 0.08),
            const SizedBox(height: 18),
            Center(
              child: TextButton(
                onPressed: () =>
                    Navigator.of(context).pushReplacementNamed('/signin'),
                child: Text(
                  loc.alreadyHaveAccount,
                  style: TextStyle(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _heroPanel(BuildContext context, {bool isMobile = false}) {
    final loc = AppLocalizations.of(context)!;

    return Container(
      constraints: BoxConstraints(minHeight: isMobile ? 390 : 680),
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
          Positioned(bottom: -70, left: -55, child: _ring(250)),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _heroIcon(),
              const SizedBox(height: 28),
              const Text(
                'Join GeneX',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 30,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.6,
                ),
              ),
              const SizedBox(height: 14),
              Text(
                'Create your secure profile and unlock AI-powered medical insights tailored to your health data.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.78),
                  fontSize: 16,
                  height: 1.6,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 30),
              _featureCard(
                Icons.verified_user_outlined,
                'Secure Patient Profile',
                'Your personal data stays protected.',
              ),
              const SizedBox(height: 12),
              _featureCard(
                Icons.monitor_heart_outlined,
                'Personalized Health Data',
                'Age, weight, and height help tailor insights.',
              ),
              const SizedBox(height: 12),
              _featureCard(
                Icons.auto_graph_rounded,
                'AI-Powered Predictions',
                'Smarter support for better decisions.',
              ),
              const SizedBox(height: 28),
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
                  Navigator.of(context).pushReplacementNamed('/signin');
                },
                child: Text(
                  loc.alreadyHaveAccount,
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
            letterSpacing: -0.6,
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

  Widget _textField({
    required BuildContext context,
    required TextEditingController controller,
    required String hintText,
    required IconData icon,
    TextInputType? keyboardType,
    bool isPassword = false,
    String? Function(String?)? validator,
  }) {
    final theme = Theme.of(context);

    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
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

  Widget _dropdown<T>(
    BuildContext context,
    String label,
    T value,
    List<T> items,
    ValueChanged<T?> onChanged,
  ) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return DropdownButtonFormField<T>(
      value: value,
      dropdownColor: isDark ? const Color(0xFF0F172A) : Colors.white,
      style: TextStyle(
        color: theme.colorScheme.onSurface,
        fontWeight: FontWeight.w600,
      ),
      icon: Icon(
        Icons.keyboard_arrow_down_rounded,
        color: theme.colorScheme.primary,
      ),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(
          color: theme.colorScheme.primary,
          fontWeight: FontWeight.w700,
        ),
      ),
      items: items.map((item) {
        return DropdownMenuItem<T>(
          value: item,
          child: Text(item.toString()),
        );
      }).toList(),
      onChanged: onChanged,
    );
  }

  Widget _heroIcon() {
    return Container(
      width: 130,
      height: 130,
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: cyanBlue.withOpacity(0.75), width: 2),
        boxShadow: [
          BoxShadow(
            color: cyanBlue.withOpacity(0.35),
            blurRadius: 40,
            spreadRadius: 6,
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

  Widget _featureCard(IconData icon, String title, String subtitle) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 15),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.11),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.14)),
      ),
      child: Row(
        children: [
          Icon(icon, color: cyanBlue, size: 28),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 14.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.72),
                    fontWeight: FontWeight.w500,
                    fontSize: 12.8,
                    height: 1.35,
                  ),
                ),
              ],
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