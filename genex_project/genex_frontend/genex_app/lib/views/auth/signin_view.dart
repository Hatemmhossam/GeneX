// lib/views/auth/signin_view.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../viewmodels/providers.dart';
import '../../viewmodels/auth_state.dart';
import '../../widgets/loading_button.dart';
import 'package:genex_app/l10n/app_localizations.dart';

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

  static const Color mainBlue = Color(0xFF1A5699);

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
          SnackBar(content: Text(next.errorMessage!)),
        );
      }
    });

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Material(
            elevation: isDark ? 0 : 4,
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(16),
            clipBehavior: Clip.antiAlias,
            child: Container(
              width: 800,
              height: 550,
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                border: Border.all(
                  color: theme.dividerColor.withOpacity(0.15),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    flex: 6,
                    child: Padding(
                      padding: const EdgeInsets.all(40.0),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              loc.signIn,
                              style: theme.textTheme.headlineMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: theme.colorScheme.onSurface,
                              ),
                            ),
                            const SizedBox(height: 32),
                            _buildTextField(
                              context: context,
                              controller: _usernameCtr,
                              hintText: loc.username,
                              icon: Icons.person_outline,
                              validator: (v) => v != null && v.isNotEmpty
                                  ? null
                                  : loc.enterValidUsername,
                            ),
                            const SizedBox(height: 16),
                            _buildTextField(
                              context: context,
                              controller: _passwordCtr,
                              hintText: loc.password,
                              icon: Icons.lock_outline,
                              isPassword: true,
                              validator: (v) => v != null && v.length >= 6
                                  ? null
                                  : loc.minSixChars,
                            ),
                            const SizedBox(height: 24),
                            SizedBox(
                              width: double.infinity,
                              height: 50,
                              child: LoadingButton(
                                loading: authState.status ==
                                    AuthStatus.authenticating,
                                color: theme.colorScheme.primary,
                                textColor: Colors.white,
                                onPressed: () {
                                  if (_formKey.currentState!.validate()) {
                                    authVM.login(
                                      username: _usernameCtr.text.trim(),
                                      password: _passwordCtr.text,
                                    );
                                  }
                                },
                                label: loc.signIn,
                              ),
                            ),
                            const SizedBox(height: 24),
                            Align(
                              alignment: Alignment.center,
                              child: Text(
                                loc.orSignInWith,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: theme.colorScheme.onSurface
                                      .withOpacity(0.6),
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                _buildSocialButton(Icons.facebook, Colors.blue),
                                const SizedBox(width: 16),
                                _buildSocialButton(
                                  Icons.g_mobiledata,
                                  Colors.redAccent,
                                ),
                                const SizedBox(width: 16),
                                _buildSocialButton(
                                  Icons.chat_bubble_outline,
                                  Colors.cyan,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 4,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: isDark
                              ? const [
                                  Color(0xFF0F172A),
                                  Color(0xFF1E3A8A),
                                ]
                              : const [
                                  Color(0xFF1A5699),
                                  Color(0xFF2967A6),
                                ],
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(32.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              loc.welcomeBack,
                              style: const TextStyle(
                                fontSize: 26,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              loc.welcomeBackMessage,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 16,
                                color: Colors.white70,
                                height: 1.5,
                              ),
                            ),
                            const SizedBox(height: 32),
                            OutlinedButton(
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.white,
                                side: const BorderSide(
                                  color: Colors.white,
                                  width: 1,
                                ),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 24,
                                  vertical: 12,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(30),
                                ),
                              ),
                              onPressed: () => Navigator.of(context)
                                  .pushReplacementNamed('/signup'),
                              child: Text(
                                loc.noAccountYet,
                                style: const TextStyle(fontSize: 16),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
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
      style: TextStyle(color: theme.colorScheme.onSurface),
      decoration: InputDecoration(
        hintText: hintText,
        prefixIcon: Icon(icon, color: theme.colorScheme.primary),
        hintStyle: TextStyle(
          color: theme.colorScheme.onSurface.withOpacity(0.5),
        ),
        filled: true,
        fillColor: theme.inputDecorationTheme.fillColor,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(
          vertical: 16,
          horizontal: 20,
        ),
        suffixIcon: isPassword
            ? IconButton(
                icon: Icon(
                  _obscurePassword ? Icons.visibility_off : Icons.visibility,
                  color: theme.colorScheme.primary,
                ),
                onPressed: () {
                  setState(() {
                    _obscurePassword = !_obscurePassword;
                  });
                },
              )
            : null,
      ),
    );
  }

  Widget _buildSocialButton(IconData icon, Color color) {
    return CircleAvatar(
      backgroundColor: color.withOpacity(0.12),
      child: Icon(icon, color: color),
    );
  }
}