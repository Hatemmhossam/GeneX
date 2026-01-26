// lib/widgets/loading_button.dart
import 'package:flutter/material.dart';

class LoadingButton extends StatelessWidget {
  final bool loading;
  final VoidCallback onPressed;
  final String label;
  const LoadingButton({required this.loading, required this.onPressed, required this.label, super.key});

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: loading ? null : onPressed,
      child: loading
          ? SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2))
          : Text(label),
    );
  }
}
