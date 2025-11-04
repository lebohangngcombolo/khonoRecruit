import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider extends ChangeNotifier {
  bool _isDarkMode = false;
  bool get isDarkMode => _isDarkMode;

  ThemeProvider() {
    _loadTheme(); // Load saved preference when the provider initializes
  }

  /// Toggle between light and dark mode
  void toggleTheme() async {
    _isDarkMode = !_isDarkMode;
    notifyListeners(); // Notify UI immediately for animation

    // Save preference
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isDarkMode', _isDarkMode);
  }

  /// Load saved theme from storage
  Future<void> _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    _isDarkMode = prefs.getBool('isDarkMode') ?? false;
    notifyListeners();
  }

  ThemeData get themeData => _isDarkMode ? darkTheme : lightTheme;

  /// 🌆 Dynamic background image based on theme
  String get backgroundImage =>
      _isDarkMode ? 'assets/images/dark.png' : 'assets/images/logy.jpg';

  // Light Theme
  final ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    primaryColor: const Color(0xFF971208),
    colorScheme: ColorScheme.light(
      primary: const Color(0xFF971208),
      secondary: const Color(0xFFCF2030),
    ),
    scaffoldBackgroundColor: const Color(0xFFF8F8F8),
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFF971208),
      foregroundColor: Colors.white,
      elevation: 0,
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: Color(0xFF971208),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF971208),
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)),
        ),
      ),
    ),
  );

  // Dark Theme
  final ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    primaryColor: const Color(0xFF14131E),
    colorScheme: ColorScheme.dark(
      primary: const Color(0xFF14131E),
      secondary: const Color(0xFF272A3D),
    ),
    scaffoldBackgroundColor: const Color(0xFF121212),
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFF14131E),
      foregroundColor: Colors.white,
      elevation: 0,
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: Color(0xFF14131E),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF14131E),
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)),
        ),
      ),
    ),
  );
}
