import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:url_launcher/url_launcher.dart';
import 'package:google_fonts/google_fonts.dart';
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
                image: AssetImage("assets/images/Frame 1.jpg"),
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

          // Centered content (no glass card)
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
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const SizedBox(height: 16),
                        Text(
                          "WELCOME BACK",
                          style: GoogleFonts.poppins(
                            fontSize: 32,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 24),
                        Text(
                          "Login",
                          style: GoogleFonts.poppins(
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 24),
                        CustomTextField(
                          label: "Email",
                          controller: emailController,
                          inputType: TextInputType.emailAddress,
                          backgroundColor: const Color(0xFF2A2A2A),
                          borderColor: const Color(0xFFC10D00),
                          textColor: Colors.white,
                        ),
                        const SizedBox(height: 12),
                        CustomTextField(
                          label: "Password",
                          controller: passwordController,
                          obscureText: true,
                          backgroundColor: const Color(0xFF2A2A2A),
                          borderColor: const Color(0xFFC10D00),
                          textColor: Colors.white,
                        ),
                        const SizedBox(height: 12),
                        Align(
                          alignment: Alignment.centerRight,
                          child: GestureDetector(
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => const ForgotPasswordScreen()),
                            ),
                            child: Text(
                              "Forgot Password?",
                              style: GoogleFonts.poppins(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),
                        FractionallySizedBox(
                          widthFactor: 0.5,
                          child: SizedBox(
                            width: double.infinity,
                            height: 35,
                            child: ElevatedButton(
                              onPressed: _login,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFC10D00),
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  side: const BorderSide(
                                      color: Color(0xFFC10D00), width: 2),
                                ),
                                elevation: 0,
                              ),
                              child: Text(
                                "LOGIN",
                                style: GoogleFonts.poppins(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        Row(
                          children: [
                            const Expanded(child: Divider(color: Colors.white)),
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 16),
                              child: Text(
                                "Or login with",
                                style: GoogleFonts.poppins(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            const Expanded(child: Divider(color: Colors.white)),
                          ],
                        ),
                        const SizedBox(height: 14),
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
                            Text(
                              "Don't have an account? ",
                              style: GoogleFonts.poppins(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600),
                            ),
                            GestureDetector(
                              onTap: () => Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(
                                    builder: (_) => const RegisterScreen()),
                              ),
                              child: Text(
                                "Register",
                                style: GoogleFonts.poppins(
                                    color: Color(0xFFC10D00),
                                    fontWeight: FontWeight.w600),
                              ),
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

          if (loading)
            const Center(child: CircularProgressIndicator(color: Colors.white)),
        ],
      ),
    );
  }
}
