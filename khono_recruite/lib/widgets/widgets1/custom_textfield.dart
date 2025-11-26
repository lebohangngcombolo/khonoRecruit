import 'package:flutter/material.dart';

class CustomTextField extends StatelessWidget {
  final String label;
  final TextEditingController? controller;
  final String? initialValue;
  final String hintText;
  final TextInputType inputType;
  final int maxLines;
  final Function(String)? onChanged;
  final String? Function(String?)? validator;
  final Color? backgroundColor; // new
  final Color? textColor; // new
  final bool obscureText;

  const CustomTextField({
    super.key,
    required this.label,
    this.controller,
    this.initialValue,
    this.hintText = '',
    this.inputType = TextInputType.text,
    this.maxLines = 1,
    this.onChanged,
    this.validator,
    this.backgroundColor,
    this.textColor,
    this.obscureText = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
<<<<<<<< HEAD:khono_recruite/lib/widgets/widgets1/custom_textfield.dart
        color: backgroundColor ?? Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.3),
========
        color: backgroundColor ??
            const Color.fromARGB(255, 147, 146, 146).withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color.fromARGB(255, 236, 0, 0).withOpacity(0.3),
>>>>>>>> 75016d5ebef202b71a7cc69eab1f3a3c6c746981:khono_recruite/lib/widgets/custom_textfield.dart
        ),
      ),
      child: TextFormField(
        controller: controller,
        initialValue: initialValue,
        keyboardType: inputType,
        maxLines: maxLines,
        onChanged: onChanged,
        validator: validator,
        obscureText: obscureText,
        style: TextStyle(
<<<<<<<< HEAD:khono_recruite/lib/widgets/widgets1/custom_textfield.dart
          color: textColor ?? Colors.white,
========
          color: textColor ?? const Color.fromARGB(255, 199, 0, 0),
>>>>>>>> 75016d5ebef202b71a7cc69eab1f3a3c6c746981:khono_recruite/lib/widgets/custom_textfield.dart
        ),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(
            color: textColor?.withValues(alpha: 0.7) ?? Colors.white70,
          ),
          hintText: hintText.isNotEmpty ? hintText : null,
          hintStyle: TextStyle(
            color: textColor?.withValues(alpha: 0.5) ?? Colors.white54,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
      ),
    );
  }
}
