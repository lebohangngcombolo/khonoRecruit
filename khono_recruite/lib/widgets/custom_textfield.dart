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
        color: backgroundColor ??
            const Color.fromARGB(255, 147, 146, 146).withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color.fromARGB(255, 236, 0, 0).withOpacity(0.3),
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
          color: textColor ?? const Color.fromARGB(255, 199, 0, 0),
        ),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(
            color: textColor?.withOpacity(0.7) ??
                const Color.fromARGB(179, 255, 3, 3),
          ),
          hintText: hintText.isNotEmpty ? hintText : null,
          hintStyle: TextStyle(
            color: textColor?.withOpacity(0.5) ??
                const Color.fromARGB(137, 98, 98, 98),
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
