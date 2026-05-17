// lib/views/auth/signin_view.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../viewmodels/providers.dart';
import '../../viewmodels/auth_state.dart';
import '../../widgets/loading_button.dart';

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

  // Blue Theme Constants
  static const Color mainBlue = Color(0xFF1A5699);
  static const Color backgroundLightGray = Color(0xFFE5E5E5);
  static const Color inputFieldGray = Color(0xFFF3F3F3);

  @override
  void dispose() {
    _usernameCtr.dispose();
    _passwordCtr.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
              title: const Text('Access denied'),
              content: Text(
                role == null || role.isEmpty
                    ? 'Your account has no role assigned.'
                    : 'Your role "$role" is not allowed to access this app.',
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                    prefs.clear();
                  },
                  child: const Text('OK'),
                ),
              ],
            ),
          );
        }
      } else if (next.status == AuthStatus.error && next.errorMessage != null) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(next.errorMessage!)));
      }
    });

    return Scaffold(
      backgroundColor: backgroundLightGray,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Material(
            elevation: 4,
            borderRadius: BorderRadius.circular(12),
            clipBehavior: Clip.antiAlias,
            child: Container(
              color: Colors.white,
              width: 800,
              height: 550,
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
                            const Text('Sign-in', style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.black)),
                            const SizedBox(height: 32),

                            _buildTextField(
                              controller: _usernameCtr,
                              hintText: 'Username',
                              icon: Icons.person_outline,
                              validator: (v) => v != null && v.isNotEmpty ? null : 'Enter valid username',
                            ),
                            const SizedBox(height: 16),

                            _buildTextField(
                              controller: _passwordCtr,
                              hintText: 'Password',
                              icon: Icons.lock_outline,
                              isPassword: true,
                              validator: (v) => v != null && v.length >= 6 ? null : 'Min 6 chars',
                            ),
                            const SizedBox(height: 24),

                            SizedBox(
                              width: double.infinity,
                              height: 50,
                              child: LoadingButton(
                                loading: authState.status == AuthStatus.authenticating,
                                color: mainBlue,
                                textColor: Colors.white,
                                onPressed: () {
                                  if (_formKey.currentState!.validate()) {
                                    authVM.login(
                                      username: _usernameCtr.text.trim(),
                                      password: _passwordCtr.text,
                                    );
                                  }
                                },
                                label: 'Signin',
                              ),
                            ),
                            const SizedBox(height: 24),
                            const Align(alignment: Alignment.center, child: Text('or signin with', style: TextStyle(color: Colors.grey))),
                            const SizedBox(height: 16),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                _buildSocialButton(Icons.facebook, Colors.blue),
                                const SizedBox(width: 16),
                                _buildSocialButton(Icons.g_mobiledata, Colors.redAccent),
                                const SizedBox(width: 16),
                                _buildSocialButton(Icons.chat_bubble_outline, Colors.cyan),
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
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [Color(0xFF1A5699), Color(0xFF2967A6)],
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(32.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text('Welcome back!', style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.white)),
                            const SizedBox(height: 16),
                            const Text(
                              'Welcome back! We are so happy to have you here. It\'s great to see you again. We hope you are safe.',
                              textAlign: TextAlign.center,
                              style: TextStyle(fontSize: 16, color: Colors.white70, height: 1.5),
                            ),
                            const SizedBox(height: 32),
                            OutlinedButton(
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.white,
                                side: const BorderSide(color: Colors.white, width: 1),
                                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                              ),
                              onPressed: () => Navigator.of(context).pushReplacementNamed('/signup'),
                              child: const Text('No account yet? Signup.', style: TextStyle(fontSize: 16)),
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
    required TextEditingController controller,
    required String hintText,
    required IconData icon,
    bool isPassword = false,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: isPassword ? _obscurePassword : false,
      validator: validator,
      decoration: InputDecoration(
        hintText: hintText,
        prefixIcon: Icon(icon, color: mainBlue),
        hintStyle: const TextStyle(color: Colors.grey),
        filled: true,
        fillColor: inputFieldGray,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(4), borderSide: BorderSide.none),
        contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
        suffixIcon: isPassword
            ? IconButton(
                icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility, color: mainBlue),
                onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
              )
            : null,
      ),
    );
  }

  Widget _buildSocialButton(IconData icon, Color color) {
    return CircleAvatar(
      backgroundColor: color.withOpacity(0.1),
      child: Icon(icon, color: color),
    );
  }
}