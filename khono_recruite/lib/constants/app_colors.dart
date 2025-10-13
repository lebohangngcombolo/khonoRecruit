import 'package:flutter/material.dart';

class AppColors {
  // Primary colors
  static const Color primaryRed = Color(0xFFE53935);
  static const Color primaryWhite = Colors.white;
  static const Color primaryDark = Color(0xFF121212);

  // Secondary colors
  static const Color secondaryRed = Color(0xFFEF5350);
  static const Color lightGrey = Color(0xFFF5F5F5);
  static const Color darkGrey = Color(0xFF424242);

  // Text colors
  static const Color textDark = Color(0xFF212121);
  static const Color textLight = Colors.white;
  static const Color textGrey = Color(0xFF757575);

  // Glass morphism colors
  static Color glassWhite = Colors.white.withValues(alpha: 0.1);
  static Color glassDark = Colors.black.withValues(alpha: 0.1);
  static Color glassRed = const Color(0xFFE53935).withValues(alpha: 0.2);
}
