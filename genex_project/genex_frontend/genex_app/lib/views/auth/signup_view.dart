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
      appBar: AppBar(title: const Text('Sign Up')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [

              /// NAME
              TextFormField(
                controller: _nameCtr,
                decoration: const InputDecoration(labelText: 'Full name'),
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Enter name' : null,
              ),

              /// EMAIL
              TextFormField(
                controller: _emailCtr,
                decoration: const InputDecoration(labelText: 'Email'),
                validator: (v) =>
                    v != null && v.contains('@') ? null : 'Enter valid email',
              ),

              /// PASSWORD
              TextFormField(
                controller: _passwordCtr,
                decoration: const InputDecoration(labelText: 'Password'),
                obscureText: true,
                validator: (v) =>
                    v != null && v.length >= 6 ? null : 'Min 6 characters',
              ),

              const SizedBox(height: 16),

              /// AGE (Dropdown)
              DropdownButtonFormField<int>(
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

              /// GENDER
              DropdownButtonFormField<String>(
                value: gender,
                decoration: const InputDecoration(labelText: 'Gender'),
                items: const [
                  DropdownMenuItem(value: 'male', child: Text('Male')),
                  DropdownMenuItem(value: 'female', child: Text('Female')),
                ],
                onChanged: (v) => setState(() => gender = v!),
              ),

              /// HEIGHT (cm)
              DropdownButtonFormField<int>(
                value: height,
                decoration: const InputDecoration(labelText: 'Height (cm)'),
                items: List.generate(
                  91,
                  (index) => DropdownMenuItem(
                    value: index + 120,
                    child: Text('${index + 120} cm'),
                  ),
                ),
                onChanged: (v) => setState(() => height = v!),
              ),

              /// WEIGHT (kg)
              DropdownButtonFormField<int>(
                value: weight,
                decoration: const InputDecoration(labelText: 'Weight (kg)'),
                items: List.generate(
                  141,
                  (index) => DropdownMenuItem(
                    value: index + 30,
                    child: Text('${index + 30} kg'),
                  ),
                ),
                onChanged: (v) => setState(() => weight = v!),
              ),

              const SizedBox(height: 24),

              /// SIGN UP BUTTON
              LoadingButton(
                loading: authState.status == AuthStatus.authenticating,
                label: 'Sign Up',
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
              ),

              TextButton(
                onPressed: () =>
                    Navigator.of(context).pushReplacementNamed('/signin'),
                child: const Text('Already have an account? Sign in'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
