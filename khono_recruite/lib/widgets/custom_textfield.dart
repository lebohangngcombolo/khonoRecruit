import 'package:flutter/material.dart';

class CustomTextField extends StatelessWidget {
  final String label;
  final TextEditingController? controller;
  final String? initialValue;
  final String hintText;
  final TextInputType inputType;
  final int maxLines;
  final int? maxLength;
  final Function(String)? onChanged;
  final String? Function(String?)? validator;
  final Color? backgroundColor;
  final Color? textColor;
  final bool obscureText;
  final TextAlign? textAlign;
  final TextStyle? style;

  final Color? labelColor;
  final Color? borderColor;

  // ⭐ NEW: Accept custom border
  final InputBorder? border;

  const CustomTextField({
    super.key,
    required this.label,
    this.controller,
    this.initialValue,
    this.hintText = '',
    this.inputType = TextInputType.text,
    this.maxLines = 1,
    this.maxLength,
    this.onChanged,
    this.validator,
    this.backgroundColor,
    this.textColor,
    this.obscureText = false,
    this.textAlign,
    this.style,
    this.labelColor,
    this.borderColor,

    // ⭐ NEW parameter
    this.border,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: backgroundColor ?? Colors.black.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),

        // Only apply container border if NO custom border was passed
        border: border == null
            ? Border.all(
                color: borderColor ?? Colors.white.withOpacity(0.3),
              )
            : null,
      ),
      child: TextFormField(
        controller: controller,
        initialValue: controller == null ? initialValue : null,
        keyboardType: inputType,
        maxLines: maxLines,
        maxLength: maxLength,
        onChanged: onChanged,
        validator: validator,
        obscureText: obscureText,
        textAlign: textAlign ?? TextAlign.start,
        style: style ??
            TextStyle(
              color: textColor ?? Colors.white,
            ),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(
            color: labelColor ?? textColor?.withOpacity(0.7) ?? Colors.white70,
          ),

          hintText: hintText.isNotEmpty ? hintText : null,
          hintStyle: TextStyle(
            color: textColor?.withOpacity(0.5) ?? Colors.white54,
          ),

          // ⭐ Apply the border you passed
          border: border,
          enabledBorder: border,
          focusedBorder: border,

          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      ),
    );
  }
}
