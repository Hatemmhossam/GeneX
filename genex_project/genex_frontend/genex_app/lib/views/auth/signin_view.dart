// lib/views/auth/signin_view.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
  final _emailCtr = TextEditingController();
  final _passwordCtr = TextEditingController();

  @override
  void dispose() {
    _emailCtr.dispose();
    _passwordCtr.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authViewModelProvider);
    final authVM = ref.read(authViewModelProvider.notifier);

    // Listen for auth state changes
    ref.listen<AuthState>(authViewModelProvider, (previous, next) {
      if (next.status == AuthStatus.authenticated) {
        // Token is saved and ApiService headers updated in AuthViewModel
        Navigator.of(context).pushReplacementNamed('/home');
      } else if (next.status == AuthStatus.error && next.errorMessage != null) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(next.errorMessage!)));
      }
    });

    return Scaffold(
      appBar: AppBar(title: Text('Sign In')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _emailCtr,
                decoration: InputDecoration(labelText: 'Email'),
                validator: (v) =>
                    v != null && v.contains('@') ? null : 'Enter valid email',
              ),
              TextFormField(
                controller: _passwordCtr,
                decoration: InputDecoration(labelText: 'Password'),
                obscureText: true,
                validator: (v) => v != null && v.length >= 6 ? null : 'Min 6 chars',
              ),
              SizedBox(height: 20),
              LoadingButton(
                loading: authState.status == AuthStatus.authenticating,
                onPressed: () {
                  if (_formKey.currentState!.validate()) {
                    // Login with email/password
                    // AuthViewModel stores token and sets headers automatically
                    authVM.login(
                      email: _emailCtr.text.trim(),
                      password: _passwordCtr.text,
                    );
                  }
                },
                label: 'Sign In',
              ),
              TextButton(
                onPressed: () =>
                    Navigator.of(context).pushReplacementNamed('/signup'),
                child: Text('Create account'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
