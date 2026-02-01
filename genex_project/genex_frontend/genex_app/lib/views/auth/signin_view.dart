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
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailCtr.dispose();
    _passwordCtr.dispose();
    super.dispose();
  }

  // --- Forgot Password Flow with Email Validation ---
  // (Kept exactly as provided in your prompt)
  void _showForgotPasswordDialog() {
    final emailController = TextEditingController();
    final dialogFormKey = GlobalKey<FormState>(); // Key for dialog validation

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset Password'),
        content: Form(
          key: dialogFormKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Enter your email to receive a 6-digit OTP.'),
              const SizedBox(height: 15),
              TextFormField(
                controller: emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'Email Address',
                  border: OutlineInputBorder(),
                ),
                // VALIDATION LOGIC
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your email';
                  }
                  if (!value.contains('@') || !value.contains('.')) {
                    return 'Enter a valid email address';
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              // Check if the email field is valid before proceeding
              if (dialogFormKey.currentState!.validate()) {
                // TODO: authVM.sendOTP(emailController.text) logic here
                Navigator.pop(context);
                _showOtpResetDialog(emailController.text);
              }
            },
            child: const Text('Send OTP'),
          ),
        ],
      ),
    );
  }

  void _showOtpResetDialog(String email) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Verify OTP'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('OTP sent to $email'),
            const SizedBox(height: 10),
            const TextField(decoration: InputDecoration(labelText: 'OTP Code')),
            const TextField(
              obscureText: true,
              decoration: InputDecoration(labelText: 'New Password'),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Reset Password'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authViewModelProvider);
    final authVM = ref.read(authViewModelProvider.notifier);

<<<<<<< Updated upstream
    // Listen for auth state changes
    ref.listen<AuthState>(authViewModelProvider, (previous, next) {
      if (next.status == AuthStatus.authenticated) {
        // Token is saved and ApiService headers updated in AuthViewModel
        Navigator.of(context).pushReplacementNamed('/home');
      } else if (next.status == AuthStatus.error && next.errorMessage != null) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(next.errorMessage!)));
=======
    ref.listen<AuthState>(authViewModelProvider, (previous, next) {
      if (next.status == AuthStatus.authenticated) {
        if (next.role == 'patient') {
          Navigator.of(context).pushReplacementNamed('/home');
        } else if (next.role == 'doctor') {
          Navigator.of(context).pushReplacementNamed('/doctor');
        }
      } else if (next.status == AuthStatus.error && next.errorMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(next.errorMessage!)));
>>>>>>> Stashed changes
      }
    });

    return Scaffold(
<<<<<<< Updated upstream
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
                obscureText: _obscurePassword,
                decoration: InputDecoration(
                  labelText: 'Password', 
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword ? Icons.visibility_off : Icons.visibility,
=======
      // Stack removed. Body is now directly the Center widget.
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Card(
            elevation: 8,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            // Changed opacity to 1.0 since the background is now solid
            color: Colors.white, 
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.local_hospital, size: 50, color: Colors.blue),
                    const SizedBox(height: 10),
                    const Text("Welcome Back", 
                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 20),
                    TextFormField(
                      controller: _usernameCtr,
                      decoration: const InputDecoration(
                        labelText: 'Email',
                        prefixIcon: Icon(Icons.person),
                      ),
                      validator: (v) => v != null && v.contains('@') ? null : 'Enter valid email',
>>>>>>> Stashed changes
                    ),
                    const SizedBox(height: 15),
                    TextFormField(
                      controller: _passwordCtr,
                      obscureText: _obscurePassword,
                      decoration: InputDecoration(
                        labelText: 'Password',
                        prefixIcon: const Icon(Icons.lock),
                        suffixIcon: IconButton(
                          icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility),
                          onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                        ),
                      ),
                      validator: (v) => v != null && v.length >= 6 ? null : 'Min 6 chars',
                    ),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: _showForgotPasswordDialog,
                        child: const Text('Forgot Password?'),
                      ),
                    ),
                    const SizedBox(height: 20),
                    LoadingButton(
                      loading: authState.status == AuthStatus.authenticating,
                      onPressed: () {
                        if (_formKey.currentState!.validate()) {
                          authVM.login(
                            username: _usernameCtr.text.trim(),
                            password: _passwordCtr.text,
                          );
                        }
                      },
                      label: 'Sign In',
                    ),
                    const SizedBox(height: 10),
                    TextButton(
                      onPressed: () => Navigator.of(context).pushReplacementNamed('/signup'),
                      child: const Text('Don\'t have an account? Sign Up'),
                    ),
                  ],
                ),
              ),
<<<<<<< Updated upstream
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
=======
            ),
>>>>>>> Stashed changes
          ),
        ),
      ),
    );
  }
}