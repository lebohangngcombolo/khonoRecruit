import 'package:flutter/material.dart';

class ThemeUtils {
  static final Color primaryColor = Colors.red;
  static final Color secondaryColor = Colors.blue;

  static ThemeData get lightTheme => ThemeData(
        useMaterial3: true, // ✅ Enable Material 3
        brightness: Brightness.light,
        colorScheme: ColorScheme.light(
          primary: primaryColor,
          secondary: secondaryColor,
          surface: Colors.white,
        ),
        scaffoldBackgroundColor: Colors.white,
        appBarTheme: AppBarTheme(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          elevation: 2,
        ),
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          filled: true,
          fillColor: Colors.blue.shade50, // Light mode: blue shade
        ),
        cardTheme: CardThemeData(
          // ✅ Correct type
          color: Colors.white,
          elevation: 2,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          margin: EdgeInsets.all(8),
        ),
      );

  static ThemeData get darkTheme => ThemeData(
        useMaterial3: true, // ✅ Enable Material 3
        brightness: Brightness.dark,
        colorScheme: ColorScheme.dark(
          primary: primaryColor,
          secondary: secondaryColor,
          surface:
              const Color.fromARGB(255, 9, 13, 18), // Dark mode: blue shade
        ),
        scaffoldBackgroundColor:
            const Color.fromARGB(255, 7, 11, 17), // Dark mode: blue shade
        appBarTheme: AppBarTheme(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          elevation: 2,
        ),
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          filled: true,
          fillColor:
              const Color.fromARGB(255, 35, 43, 53), // Dark mode: blue shade
        ),
        cardTheme: CardThemeData(
          // ✅ Correct type
          color: const Color.fromARGB(255, 16, 26, 37), // Dark mode: blue shade
          elevation: 4,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          margin: EdgeInsets.all(8),
        ),
      );
}
