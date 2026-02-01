// lib/views/auth/signup_view.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../viewmodels/providers.dart';
import '../../viewmodels/auth_state.dart';
import '../../widgets/loading_button.dart';

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
  int height = 160; // cm
  int weight = 60;  // kg
  String role = 'patient';

  @override
  void dispose() {
    _nameCtr.dispose();
    _emailCtr.dispose();
    _passwordCtr.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authViewModelProvider);
    final authVM = ref.read(authViewModelProvider.notifier);

    ref.listen<AuthState>(authViewModelProvider, (previous, next) {
      if (next.status == AuthStatus.authenticated) {
        Navigator.of(context).pushReplacementNamed('/home');
      } else if (next.status == AuthStatus.error && next.errorMessage != null) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(next.errorMessage!)));
      }
    });

    return Scaffold(
      // Same default background as the Sign In view
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Card(
            elevation: 8,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            color: Colors.white,
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.person_add, size: 50, color: Colors.blue),
                    const SizedBox(height: 10),
                    const Text(
                      "Create Account",
                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 20),

                    /// NAME
                    TextFormField(
                      controller: _nameCtr,
                      decoration: const InputDecoration(
                        labelText: 'Full name',
                        prefixIcon: Icon(Icons.badge_outlined),
                      ),
                      validator: (v) =>
                          v == null || v.trim().isEmpty ? 'Enter name' : null,
                    ),
                    const SizedBox(height: 15),

                    /// EMAIL
                    TextFormField(
                      controller: _emailCtr,
                      decoration: const InputDecoration(
                        labelText: 'Email',
                        prefixIcon: Icon(Icons.email_outlined),
                      ),
                      validator: (v) =>
                          v != null && v.contains('@') ? null : 'Enter valid email',
                    ),
                    const SizedBox(height: 15),

                    /// PASSWORD
                    TextFormField(
                      controller: _passwordCtr,
                      obscureText: _obscurePassword,
                      decoration: InputDecoration(
                        labelText: 'Password',
                        prefixIcon: const Icon(Icons.lock_outline),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword ? Icons.visibility_off : Icons.visibility,
                          ),
                          onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                        ),
                      ),
                      validator: (v) =>
                          v != null && v.length >= 6 ? null : 'Min 6 characters',
                    ),
                    const SizedBox(height: 15),

                    /// MEDICAL DETAILS (Row for Age/Gender)
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<int>(
                            value: age,
                            decoration: const InputDecoration(labelText: 'Age'),
                            items: List.generate(
                              83,
                              (index) => DropdownMenuItem(
                                value: index + 18,
                                child: Text('${index + 18}'),
                              ),
                            ),
                            onChanged: (v) => setState(() => age = v!),
                          ),
                        ),
                        const SizedBox(width: 15),
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: gender,
                            decoration: const InputDecoration(labelText: 'Gender'),
                            items: const [
                              DropdownMenuItem(value: 'male', child: Text('Male')),
                              DropdownMenuItem(value: 'female', child: Text('Female')),
                            ],
                            onChanged: (v) => setState(() => gender = v!),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 15),

                    /// HEIGHT & WEIGHT (Row)
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<int>(
                            value: height,
                            decoration: const InputDecoration(labelText: 'Height'),
                            items: List.generate(
                              91,
                              (index) => DropdownMenuItem(
                                value: index + 120,
                                child: Text('${index + 120} cm'),
                              ),
                            ),
                            onChanged: (v) => setState(() => height = v!),
                          ),
                        ),
                        const SizedBox(width: 15),
                        Expanded(
                          child: DropdownButtonFormField<int>(
                            value: weight,
                            decoration: const InputDecoration(labelText: 'Weight'),
                            items: List.generate(
                              141,
                              (index) => DropdownMenuItem(
                                value: index + 30,
                                child: Text('${index + 30} kg'),
                              ),
                            ),
                            onChanged: (v) => setState(() => weight = v!),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 30),

                    /// SIGN UP BUTTON
                    LoadingButton(
                      loading: authState.status == AuthStatus.authenticating,
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
                      label: 'Sign Up',
                    ),

                    const SizedBox(height: 10),

                    TextButton(
                      onPressed: () =>
                          Navigator.of(context).pushReplacementNamed('/signin'),
                      child: const Text('Already have an account? Sign in'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}