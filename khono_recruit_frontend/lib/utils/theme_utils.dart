import 'package:flutter/material.dart';

class ThemeProvider extends ChangeNotifier {
  bool isDarkMode = false;

  void toggleTheme() {
    isDarkMode = !isDarkMode;
    notifyListeners();
  }

  ThemeData get currentTheme => isDarkMode
      ? ThemeData.dark().copyWith(
          primaryColor: const Color.fromARGB(255, 17, 17, 17),
          scaffoldBackgroundColor: Colors.black87,
        )
      : ThemeData.light().copyWith(
          primaryColor: Colors.redAccent,
          scaffoldBackgroundColor: Colors.white,
        );
}
