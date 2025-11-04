import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:url_launcher/url_launcher.dart';
import '../hiring_manager/hiring_manager_dashboard.dart';

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

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  bool loading = false;

  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
      lowerBound: 0.95,
      upperBound: 1.0,
    );
    _scaleAnimation =
        CurvedAnimation(parent: _animationController, curve: Curves.easeInOut);
    _animationController.value = 1.0;
  }

  @override
  void dispose() {
    _animationController.dispose();
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  // ------------------- EMAIL/PASSWORD LOGIN -------------------
  void _login() async {
    setState(() => loading = true);
    try {
      final result = await AuthService.login(
        emailController.text.trim(),
        passwordController.text.trim(),
      );

      if (result['success']) {
        _navigateToDashboard(
          token: result['access_token'],
          role: result['role'],
          dashboard: result['dashboard'],
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result['message'] ?? "Login failed")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Login error: $e")),
      );
    } finally {
      setState(() => loading = false);
    }
  }

  // ------------------- SOCIAL LOGIN -------------------
  void _socialLogin(String provider) async {
    setState(() => loading = true);
    try {
      final url = provider == "Google"
          ? AuthService.googleOAuthUrl
          : AuthService.githubOAuthUrl;

      if (kIsWeb) {
        if (await canLaunchUrl(Uri.parse(url))) {
          // Opens OAuth URL in the same tab
          await launchUrl(Uri.parse(url), webOnlyWindowName: "_self");
          // After redirect, GoRouter /oauth-callback handles the navigation
        }
      } else {
        // Mobile: native login
        final loginResult = provider == "Google"
            ? await AuthService.loginWithGoogle()
            : await AuthService.loginWithGithub();

        if (loginResult['access_token'] != null) {
          _navigateToDashboard(
            token: loginResult['access_token'],
            role: loginResult['role'],
            dashboard: loginResult['dashboard'],
          );
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Social login error: $e")));
    } finally {
      setState(() => loading = false);
    }
  }

  // ------------------- NAVIGATION HELPER -------------------
  void _navigateToDashboard({
    required String token,
    required String role,
    required String dashboard,
  }) {
    if (role == "admin") {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => AdminDAshboard(token: token)),
      );
    } else if (role == "hiring_manager") {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => HMMainDashboard()),
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
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: Stack(
        children: [
          // Background
          Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage("assets/images/dark.png"),
                fit: BoxFit.cover,
              ),
            ),
          ),

          // Logos at top-left and top-right
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Image.asset(
                    "assets/images/logo2.png",
                    width: 300,
                    height: 120,
                  ),
                  Image.asset(
                    "assets/images/logo.png",
                    width: 300,
                    height: 120,
                  ),
                ],
              ),
            ),
          ),

          // Centered Glass Card
          Center(
            child: SingleChildScrollView(
              child: MouseRegion(
                onEnter: (_) => kIsWeb ? _animationController.forward() : null,
                onExit: (_) => kIsWeb ? _animationController.reverse() : null,
                child: ScaleTransition(
                  scale: _scaleAnimation,
                  child: Container(
                    width: size.width > 800 ? 400 : size.width * 0.9,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 32),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(24),
                      gradient: LinearGradient(
                        colors: [
                          Colors.white.withOpacity(0.05),
                          Colors.white.withOpacity(0.05),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.1),
                        width: 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(24),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                        child: Container(
                          color: Colors.white.withOpacity(0.05),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const SizedBox(height: 16),
                              const Text(
                                "WELCOME BACK",
                                style: TextStyle(
                                  fontSize: 32,
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
                              const SizedBox(height: 24),
                              const Text(
                                "Login",
                                style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white),
                              ),
                              const SizedBox(height: 24),
                              CustomTextField(
                                label: "Email",
                                controller: emailController,
                                inputType: TextInputType.emailAddress,
                                backgroundColor:
                                    const Color.fromARGB(0, 129, 128, 128)
                                        .withOpacity(0.1),
                                textColor: const Color.fromARGB(255, 172, 0, 0),
                              ),
                              const SizedBox(height: 12),
                              CustomTextField(
                                label: "Password",
                                controller: passwordController,
                                obscureText: true,
                                backgroundColor:
                                    const Color.fromARGB(0, 123, 123, 123)
                                        .withOpacity(0.1),
                                textColor: const Color.fromARGB(255, 201, 0, 0),
                              ),
                              const SizedBox(height: 12),
                              Align(
                                alignment: Alignment.centerRight,
                                child: GestureDetector(
                                  onTap: () => Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (_) =>
                                            const ForgotPasswordScreen()),
                                  ),
                                  child: const Text(
                                    "Forgot Password?",
                                    style: TextStyle(
                                        color: Colors.blueAccent, fontSize: 14),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 20),
                              SizedBox(
                                width: double.infinity,
                                height: 48,
                                child: ElevatedButton(
                                  onPressed: _login,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor:
                                        Colors.white.withOpacity(0.8),
                                    foregroundColor: Colors.red,
                                    shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(20)),
                                    elevation: 5,
                                  ),
                                  child: const Text(
                                    "LOGIN",
                                    style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 24),
                              Row(
                                children: [
                                  Expanded(
                                      child: Divider(
                                          color:
                                              Colors.white.withOpacity(0.4))),
                                  const Padding(
                                    padding:
                                        EdgeInsets.symmetric(horizontal: 16),
                                    child: Text("Or login with",
                                        style: TextStyle(
                                            color: Colors.white70,
                                            fontSize: 14)),
                                  ),
                                  Expanded(
                                      child: Divider(
                                          color:
                                              Colors.white.withOpacity(0.4))),
                                ],
                              ),
                              const SizedBox(height: 20),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  IconButton(
                                    icon: const FaIcon(FontAwesomeIcons.google,
                                        color: Colors.white, size: 32),
                                    onPressed: () => _socialLogin("Google"),
                                  ),
                                  const SizedBox(width: 24),
                                  IconButton(
                                    icon: const FaIcon(FontAwesomeIcons.github,
                                        color: Colors.white, size: 32),
                                    onPressed: () => _socialLogin("GitHub"),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 24),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Text("Don't have an account? ",
                                      style: TextStyle(color: Colors.white70)),
                                  GestureDetector(
                                    onTap: () => Navigator.pushReplacement(
                                      context,
                                      MaterialPageRoute(
                                          builder: (_) =>
                                              const RegisterScreen()),
                                    ),
                                    child: const Text("Register",
                                        style:
                                            TextStyle(color: Colors.redAccent)),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              IconButton(
                                icon: Icon(
                                    themeProvider.isDarkMode
                                        ? Icons.light_mode
                                        : Icons.dark_mode,
                                    color: Colors.white),
                                onPressed: () => themeProvider.toggleTheme(),
                              ),
                              const SizedBox(height: 16),
                            ],
                          ),
                        ),
                      ),
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
