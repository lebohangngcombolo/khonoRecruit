import 'dart:ui';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/six_digit_code_field.dart'; // Import the custom widget
import '../../providers/theme_provider.dart';
import '../enrollment/enrollment_screen.dart';

class VerificationScreen extends StatefulWidget {
  final String email;
  const VerificationScreen({super.key, required this.email});

  @override
  _VerificationScreenState createState() => _VerificationScreenState();
}

class _VerificationScreenState extends State<VerificationScreen>
    with SingleTickerProviderStateMixin {
  String verificationCode = '';
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
    super.dispose();
  }

  void _onCodeChanged(String code) {
    setState(() {
      verificationCode = code;
    });
  }

  void _onCodeCompleted(String code) {
    setState(() {
      verificationCode = code;
    });
    // Optionally auto-submit when code is complete
    // verify();
  }

  void verify() async {
    if (verificationCode.length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter the complete 6-digit code")),
      );
      return;
    }

    setState(() => loading = true);

    final response = await AuthService.verifyEmail({
      "email": widget.email,
      "code": verificationCode.trim(),
    });

    setState(() => loading = false);

    if (response.containsKey('error')) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(response['error'])),
      );
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => EnrollmentScreen(token: response['access_token']),
        ),
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
          // ---------- Background Image ----------
          Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage("assets/images/dark.png"),
                fit: BoxFit.cover,
              ),
            ),
          ),

          // ---------- Top Left Logo ----------
          Positioned(
            top: 40,
            left: 24,
            child: Image.asset(
              'assets/images/logo2.png', // Replace with your left logo path
              width: 300,
              height: 120,
              fit: BoxFit.contain,
            ),
          ),

          // ---------- Top Right Logo ----------
          Positioned(
            top: 40,
            right: 24,
            child: Image.asset(
              'assets/images/logo.png', // Replace with your right logo path
              width: 300,
              height: 120,
              fit: BoxFit.contain,
            ),
          ),

          // ---------- Centered Glass Card ----------
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: MouseRegion(
                onEnter: (_) => kIsWeb ? _animationController.forward() : null,
                onExit: (_) => kIsWeb ? _animationController.reverse() : null,
                child: ScaleTransition(
                  scale: _scaleAnimation,
                  child: Container(
                    width: size.width > 800 ? 420 : size.width * 0.85,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 32),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(24),
                      gradient: LinearGradient(
                        colors: [
                          Colors.white.withOpacity(0.08),
                          Colors.white.withOpacity(0.02),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.15),
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 30,
                          offset: const Offset(0, 15),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(24),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const SizedBox(height: 16),
                            // Modern header with icon
                            Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.1),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.verified_user_outlined,
                                size: 28,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              "Email Verification",
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                                letterSpacing: 0.5,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 8),
                              child: Text(
                                "Code sent to ${widget.email}",
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: Colors.white70,
                                  fontWeight: FontWeight.w400,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                            const SizedBox(height: 24),

                            // 6-Digit Code Input using custom widget
                            Container(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 4),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Padding(
                                    padding: EdgeInsets.only(left: 4),
                                    child: Text(
                                      "Enter verification code",
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: Colors.white70,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  SixDigitCodeField(
                                    onCodeChanged: _onCodeChanged,
                                    onCodeCompleted: _onCodeCompleted,
                                    autoFocus: true,
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(height: 24),

                            // Verify Button
                            SizedBox(
                              width: double.infinity,
                              height: 48,
                              child: CustomButton(
                                text: "Verify & Continue",
                                onPressed: verify,
                              ),
                            ),

                            const SizedBox(height: 16),

                            // Resend code option
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 8),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    "Didn't receive code? ",
                                    style: TextStyle(
                                      color: Colors.white.withOpacity(0.7),
                                      fontSize: 13,
                                    ),
                                  ),
                                  GestureDetector(
                                    onTap: () {
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        const SnackBar(
                                            content: Text(
                                                "Resend code functionality")),
                                      );
                                    },
                                    child: const Text(
                                      "Resend",
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        decoration: TextDecoration.underline,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(height: 20),

                            // Theme toggle
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: IconButton(
                                icon: Icon(
                                  themeProvider.isDarkMode
                                      ? Icons.light_mode
                                      : Icons.dark_mode,
                                  color: Colors.white,
                                  size: 18,
                                ),
                                onPressed: () => themeProvider.toggleTheme(),
                              ),
                            ),
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
            Container(
              color: Colors.black.withOpacity(0.5),
              child: const Center(
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 3,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
