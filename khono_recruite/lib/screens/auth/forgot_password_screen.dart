import 'dart:ui';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_textfield.dart';
import '../../providers/theme_provider.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  _ForgotPasswordScreenState createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController emailController = TextEditingController();
  bool loading = false;

  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
      lowerBound: 0.95,
      upperBound: 1.0,
    );
    _scaleAnimation =
        CurvedAnimation(parent: _animationController, curve: Curves.easeOut);
  }

  @override
  void dispose() {
    _animationController.dispose();
    emailController.dispose();
    super.dispose();
  }

  void submit() async {
    if (emailController.text.trim().isEmpty) return;

    setState(() => loading = true);
    final response =
        await AuthService.forgotPassword(emailController.text.trim());
    setState(() => loading = false);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(response['message'] ?? "Check your email")),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: Stack(
        children: [
          // ---------- Background Image ----------
          Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage("assets/images/dark.png"),
                fit: BoxFit.cover,
              ),
            ),
          ),

          // ---------- Centered Glass Card ----------
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
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const SizedBox(height: 16),
                            const Text(
                              "GLASS CARD",
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
                              "Forgot Password",
                              style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white),
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              "Enter your email to receive reset instructions",
                              style: TextStyle(
                                  fontSize: 16, color: Colors.white70),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 16),
                            CustomTextField(
                              label: "Email",
                              controller: emailController,
                              inputType: TextInputType.emailAddress,
                              textColor: Colors.white,
                              backgroundColor: Colors.white.withOpacity(0.1),
                            ),
                            const SizedBox(height: 20),
                            SizedBox(
                              width: double.infinity,
                              height: 48,
                              child: CustomButton(
                                  text: "Submit", onPressed: submit),
                            ),
                            const SizedBox(height: 24),
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

          if (loading)
            const Center(child: CircularProgressIndicator(color: Colors.white)),
        ],
      ),
    );
  }
}
