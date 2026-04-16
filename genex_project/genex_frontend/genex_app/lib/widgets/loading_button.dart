// lib/widgets/loading_button.dart
import 'package:flutter/material.dart';

class LoadingButton extends StatelessWidget {
  final bool loading;
  final VoidCallback onPressed;
  final String label;
  final Color? color;        // Added
  final Color? textColor;    // Added

  const LoadingButton({
    super.key,
    required this.loading,
    required this.onPressed,
    required this.label,
    this.color,
    this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: color ?? Theme.of(context).primaryColor,
        foregroundColor: textColor ?? Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
        elevation: 0, // Matches the flat modern aesthetic
      ),
      onPressed: loading ? null : onPressed,
      child: loading
          ? SizedBox(
              height: 18, 
              width: 18, 
              child: CircularProgressIndicator(
                strokeWidth: 2, 
                valueColor: AlwaysStoppedAnimation<Color>(textColor ?? Colors.white),
              ),
            )
          : Text(label),
    );
  }
}