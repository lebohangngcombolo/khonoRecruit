import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:provider/provider.dart';
import '../../utils/theme_utils.dart';
import '../auth/login_screen.dart';
import '../auth/register_screen.dart';
import '../../widgets/animated_glass_button.dart';

class LandingScreen extends StatelessWidget {
  const LandingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return Scaffold(
      body: Stack(
        children: [
          // 3D Animated Background using Lottie
          Lottie.asset(
            'assets/animations/landing_animation.json',
            width: double.infinity,
            height: double.infinity,
            fit: BoxFit.cover,
            repeat: true,
            animate: true,
          ),
          // Dark overlay for readability
          Container(
            color: themeProvider.isDarkMode
                ? Colors.black.withOpacity(0.4)
                : Colors.white.withOpacity(0.3),
          ),
          // Center content
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Welcome to KhonoRecruit',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Color.fromARGB(255, 244, 10, 10),
                  ),
                ),
                const SizedBox(height: 20),
                // Glassmorphic animated Login button
                AnimatedGlassButton(
                  lottieAsset: 'assets/animations/profile.json',
                  text: 'Login',
                  onTap: () {
                    Navigator.push(context,
                        MaterialPageRoute(builder: (_) => const LoginScreen()));
                  },
                  width: 200,
                  height: 200,
                ),
                const SizedBox(height: 20),
                // Glassmorphic animated Register button
                AnimatedGlassButton(
                  lottieAsset: 'assets/animations/applications.json',
                  text: 'Register',
                  onTap: () {
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const RegisterScreen()));
                  },
                  width: 200,
                  height: 200,
                ),
                const SizedBox(height: 20),
                // Theme toggle
                IconButton(
                  icon: Icon(themeProvider.isDarkMode
                      ? Icons.wb_sunny
                      : Icons.dark_mode),
                  onPressed: () => themeProvider.toggleTheme(),
                  color: Colors.white,
                  iconSize: 32,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
