// lib/views/auth/signin_view.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart'; // <--- ADDED THIS IMPORT
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

    // Listen for auth state changes
    ref.listen<AuthState>(authViewModelProvider, (previous, next) async {
      if (next.status == AuthStatus.authenticated) {
        final role = next.role; 

        // --- NEW: Save Session Data for Dashboard Protection ---
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('role', role ?? '');
        
        // NOTE: Ensure your AuthState has a 'token' field. 
        // If 'token' is inside a 'user' object, change this to: next.user?.token
        if (next.token != null) {
          await prefs.setString('token', next.token!);
        }
        // -------------------------------------------------------

        if (!context.mounted) return; // Safety check

        if (role == 'patient') {
          Navigator.of(context).pushReplacementNamed('/home');
        } else if (role == 'doctor') {
          Navigator.of(context).pushReplacementNamed('/doctor'); // Ensure this matches your route name
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
                    // Optionally clear prefs if access is denied
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
      appBar: AppBar(title: const Text('Sign In')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _usernameCtr,
                decoration: const InputDecoration(labelText: 'Username'),
                validator: (v) =>
                    v != null && v.isNotEmpty ? null : 'Enter valid username', // Simplified validator
              ),
              TextFormField(
                controller: _passwordCtr,
                obscureText: _obscurePassword,
                decoration: InputDecoration(
                  labelText: 'Password', 
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword ? Icons.visibility_off : Icons.visibility,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscurePassword = !_obscurePassword;
                      });
                    },
                  ),
                ),
                validator: (v) => v != null && v.length >= 6 ? null : 'Min 6 chars',
              ),
              const SizedBox(height: 20),
              LoadingButton(
                loading: authState.status == AuthStatus.authenticating,
                onPressed: () {
                  if (_formKey.currentState!.validate()) {
                    // Login with email/password
                    authVM.login(
                      username: _usernameCtr.text.trim(),
                      password: _passwordCtr.text,
                    );
                  }
                },
                label: 'Sign In',
              ),
              TextButton(
                onPressed: () =>
                    Navigator.of(context).pushReplacementNamed('/signup'),
                child: const Text('Create account'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}