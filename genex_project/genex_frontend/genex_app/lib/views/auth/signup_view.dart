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
  int height = 160;
  int weight = 60;
  String role = 'patient';

  // Specific Blue color palette
  static const Color mainBlue = Color(0xFF1A5699); // Darker blue for primary accents
  static const Color backgroundLightGray = Color(0xFFE5E5E5);
  static const Color inputFieldGray = Color(0xFFF3F3F3);

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

    // Maintain existing logic for auth state changes
    ref.listen<AuthState>(authViewModelProvider, (previous, next) {
      if (next.status == AuthStatus.authenticated) {
        Navigator.of(context).pushReplacementNamed('/home');
      } else if (next.status == AuthStatus.error && next.errorMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(next.errorMessage!)));
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
              width: 550, // Single panel width
              padding: const EdgeInsets.all(40.0), // Padding applied to the main container
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min, // Constrain height to content
                  children: [
                    const Text('Create Account', style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.black)),
                    const SizedBox(height: 32),
                    
                    // --- Text Fields with Blue Hints ---
                    _buildTextField(controller: _nameCtr, hintText: 'Full Name', icon: Icons.person_outline),
                    const SizedBox(height: 16),
                    _buildTextField(controller: _emailCtr, hintText: 'Email', icon: Icons.email_outlined),
                    const SizedBox(height: 16),
                    _buildTextField(controller: _passwordCtr, hintText: 'Password', icon: Icons.lock_outline, isPassword: true,),
                    
                    const SizedBox(height: 24),
                    
                    // --- Grouped Dropdowns (Single Panel) ---
                    Row(
                      children: [
                        Expanded(child: _buildDropdown('Age', age, List.generate(83, (i) => i + 18), (v) => setState(() => age = v!))),
                        const SizedBox(width: 16),
                        Expanded(child: _buildDropdown('Gender', gender, ['male', 'female'], (v) => setState(() => gender = v!))),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(child: _buildDropdown('Height (cm)', height, List.generate(91, (i) => i + 120), (v) => setState(() => height = v!))),
                        const SizedBox(width: 16),
                        Expanded(child: _buildDropdown('Weight (kg)', weight, List.generate(141, (i) => i + 30), (v) => setState(() => weight = v!))),
                      ],
                    ),

                    const SizedBox(height: 32),
                    
                    // --- Main Blue Sign Up Button ---
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: LoadingButton(
                        loading: authState.status == AuthStatus.authenticating,
                        color: mainBlue, // Changed to Blue
                        textColor: Colors.white,
                        label: 'Sign Up',
                        onPressed: () {
                          if (_formKey.currentState!.validate()) {
                            authVM.signup(
                              name: _nameCtr.text.trim(), email: _emailCtr.text.trim(),
                              password: _passwordCtr.text, role: role, age: age,
                              gender: gender, height: height.toDouble(), weight: weight.toDouble(),
                            );
                          }
                        },
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    // --- Sign In Redirect ---
                    Align(
                      alignment: Alignment.center,
                      child: TextButton(
                        onPressed: () => Navigator.of(context).pushReplacementNamed('/signin'),
                        child: const Text('Already have an account? Sign in', style: TextStyle(color: mainBlue, fontWeight: FontWeight.normal)),
                      ),
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

  // --- Reusable Modern Input Field with blue hint accents ---
  // Updated Helper: Added optional 'isPassword' boolean to trigger the toggle icon
  Widget _buildTextField({
    required TextEditingController controller,
    required String hintText,
    required IconData icon,
    bool obscure = false,
    bool isPassword = false, // Add this
  }) {
    return TextFormField(
      controller: controller,
      obscureText: isPassword ? _obscurePassword : obscure, // Toggle based on state
      style: const TextStyle(color: Colors.black),
      decoration: InputDecoration(
        hintText: hintText,
        prefixIcon: Icon(icon, color: mainBlue),
        hintStyle: const TextStyle(color: Colors.grey),
        filled: true,
        fillColor: inputFieldGray,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(4), borderSide: BorderSide.none),
        contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
        // Add the visibility toggle icon here
        suffixIcon: isPassword
            ? IconButton(
                icon: Icon(
                  _obscurePassword ? Icons.visibility_off : Icons.visibility,
                  color: mainBlue,
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

  // --- Reusable Modern Dropdown Field ---
  Widget _buildDropdown<T>(String label, T value, List<T> items, ValueChanged<T?> onChanged) {
    return DropdownButtonFormField<T>(
      value: value,
      style: const TextStyle(color: Colors.black),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: mainBlue), // Label changed to blue
        filled: true,
        fillColor: inputFieldGray,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(4), borderSide: BorderSide.none),
        contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
      ),
      items: items.map((item) => DropdownMenuItem(value: item, child: Text(item.toString()))).toList(),
      onChanged: onChanged,
    );
  }
}