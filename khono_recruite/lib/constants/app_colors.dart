import 'package:flutter/material.dart';

class AppColors {
  // Primary colors - Khonology Brand
  static const Color primaryRed = Color(0xFFC10D00);  // Official Khonology Red
  static const Color primaryWhite = Colors.white;
  static const Color primaryDark = Color(0xFF121212);

  // Secondary colors
  static const Color secondaryRed = Color(0xFFD32F2F);
  static const Color lightGrey = Color(0xFFF5F5F5);
  static const Color darkGrey = Color(0xFF424242);

  // Text colors
  static const Color textDark = Color(0xFF212121);
  static const Color textLight = Colors.white;
  static const Color textGrey = Color(0xFF757575);

  // Score Colors (for CV Reviews and Analytics)
  static const Color scoreHigh = Color(0xFF4CAF50);    // Green
  static const Color scoreMedium = Color(0xFFFF9800);  // Orange
  static const Color scoreLow = Color(0xFFC10D00);     // Khonology Red

  // Status Colors
  static const Color statusSuccess = Color(0xFF4CAF50);
  static const Color statusWarning = Color(0xFFFF9800);
  static const Color statusError = Color(0xFFC10D00);
  static const Color statusInfo = Color(0xFF2196F3);

  // Glass morphism colors
  static Color glassWhite = Colors.white.withValues(alpha: 0.1);
  static Color glassDark = Colors.black.withValues(alpha: 0.1);
  static Color glassRed = const Color(0xFFC10D00).withValues(alpha: 0.2);
}
