import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../services/auth_service.dart';
import '../../widgets/custom_textfield.dart';
import '../../providers/theme_provider.dart';
import 'register_screen.dart';
import 'forgot_password_screen.dart';
import '../candidate/candidate_dashboard.dart';
import '../enrollment/enrollment_screen.dart';
import '../admin/admin_dashboard.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  bool loading = false;

  void _login() async {
    setState(() => loading = true);
    final result = await AuthService().login(
      emailController.text,
      passwordController.text,
    );
    setState(() => loading = false);

    if (result['success']) {
      final role = result['role'];
      final dashboard = result['dashboard'];
      final token = result['access_token'];

      if (role == "admin") {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => AdminDashboard()),
        );
      } else if (role == "candidate" && dashboard == "/enrollment") {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => EnrollmentScreen(token: token)),
        );
      } else {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => CandidateDashboard(token: token)),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result['message'] ?? "Login failed")),
      );
    }
  }

  void _socialLogin(String provider) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("$provider login is not implemented")),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: Stack(
        children: [
          // Background gradient
          Container(
            decoration: const BoxDecoration(
              gradient: RadialGradient(
                colors: [
                  Color(0xFFB03AB2),
                  Color(0xFF417FD7),
                  Color(0xFF38DBFF)
                ],
                center: Alignment.topLeft,
                radius: 1.5,
              ),
            ),
          ),
          // Decorative blur circles
          Positioned(
            top: 50,
            left: 30,
            child: Container(
              width: 180,
              height: 180,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.purple.withOpacity(0.2),
                    Colors.red.withOpacity(0.4),
                    Colors.blue.withOpacity(0.3),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
              ),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                child: Container(color: Colors.transparent),
              ),
            ),
          ),
          Center(
            child: SingleChildScrollView(
              child: Container(
                width: size.width * 0.45,
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(40),
                  gradient: LinearGradient(
                    colors: [
                      Colors.white.withOpacity(0.2),
                      Colors.red.withOpacity(0.1),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  border: Border(
                    top: BorderSide(
                        color: Colors.white.withOpacity(0.6), width: 1),
                    left: BorderSide(
                        color: Colors.white.withOpacity(0.6), width: 1),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.red.withOpacity(0.2),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(40),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Logo / Title
                        const Text(
                          "GLASS CARD",
                          style: TextStyle(
                            fontSize: 36,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            shadows: [
                              Shadow(
                                  color: Colors.black26,
                                  blurRadius: 4,
                                  offset: Offset(2, 2))
                            ],
                          ),
                        ),
                        const SizedBox(height: 32),
                        const Text(
                          "Login Form",
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 32),
                        // Email field
                        CustomTextField(
                          label: "Email",
                          controller: emailController,
                          inputType: TextInputType.emailAddress,
                          backgroundColor: Colors.white.withOpacity(0.1),
                          textColor: Colors.white,
                        ),
                        const SizedBox(height: 16),
                        // Password field
                        CustomTextField(
                          label: "Password",
                          controller: passwordController,
                          obscureText: true,
                          backgroundColor: Colors.white.withOpacity(0.1),
                          textColor: Colors.white,
                        ),
                        const SizedBox(height: 16),
                        // Forgot password
                        Align(
                          alignment: Alignment.centerRight,
                          child: GestureDetector(
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => const ForgotPasswordScreen()),
                            ),
                            child: const Text(
                              "Forgot Password?",
                              style: TextStyle(
                                  color: Colors.blueAccent, fontSize: 14),
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        // Login button
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton(
                            onPressed: _login,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white.withOpacity(0.8),
                              foregroundColor: Colors.red,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                              elevation: 5,
                            ),
                            child: const Text(
                              "LOGIN",
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 32),
                        // Social login divider
                        Row(
                          children: [
                            Expanded(
                                child: Divider(
                                    color: Colors.white.withOpacity(0.4))),
                            const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 16),
                              child: Text(
                                "Or login with",
                                style: TextStyle(
                                    color: Colors.white70, fontSize: 14),
                              ),
                            ),
                            Expanded(
                                child: Divider(
                                    color: Colors.white.withOpacity(0.4))),
                          ],
                        ),
                        const SizedBox(height: 24),
                        // Social login buttons
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            IconButton(
                              icon: const FaIcon(FontAwesomeIcons.google,
                                  color: Colors.white, size: 32),
                              onPressed: () => _socialLogin("Google"),
                            ),
                            const SizedBox(width: 32),
                            IconButton(
                              icon: const FaIcon(FontAwesomeIcons.github,
                                  color: Colors.white, size: 32),
                              onPressed: () => _socialLogin("GitHub"),
                            ),
                          ],
                        ),
                        const SizedBox(height: 32),
                        // Register link
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text("Don't have an account? ",
                                style: TextStyle(color: Colors.white70)),
                            GestureDetector(
                              onTap: () => Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(
                                    builder: (_) => const RegisterScreen()),
                              ),
                              child: const Text("Register",
                                  style: TextStyle(color: Colors.redAccent)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        // Theme toggle
                        IconButton(
                          icon: Icon(
                            themeProvider.isDarkMode
                                ? Icons.light_mode
                                : Icons.dark_mode,
                            color: Colors.white,
                          ),
                          onPressed: () => themeProvider.toggleTheme(),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          if (loading)
            const Center(child: CircularProgressIndicator(color: Colors.white)),
        ],
      ),
    );
  }
}
