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
import 'mfa_verification_screen.dart'; // 🆕 Import MFA screen
import 'sso_enterprise_screen.dart'; // 🆕 Import SSO Enterprise screen

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

  // 🆕 MFA state variables - PROPERLY TYPED
  String? _mfaSessionToken;
  String? _userId; // 🆕 Ensure this is String, not int
  bool _showMfaForm = false;

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

  // 🆕 UPDATED LOGIN WITH MFA SUPPORT - Navigation approach
  void _login() async {
    setState(() => loading = true);
    try {
      final result = await AuthService.login(
        emailController.text.trim(),
        passwordController.text.trim(),
      );

      if (result['success']) {
        // 🆕 Check if MFA is required
        if (result['mfa_required'] == true) {
          // 🆕 STORE THE MFA SESSION TOKEN IN STATE
          setState(() {
            _mfaSessionToken = result['mfa_session_token'];
            _userId =
                result['user_id']?.toString() ?? ''; // 🆕 Convert to string
          });

          // Navigate to MFA verification screen
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => MfaVerificationScreen(
                mfaSessionToken: result['mfa_session_token'],
                userId:
                    result['user_id']?.toString() ?? '', // 🆕 Convert to string
                onVerify: _verifyMfa,
                onBack: () {
                  Navigator.pop(context);
                  // 🆕 Clear MFA state when going back
                  setState(() {
                    _mfaSessionToken = null;
                    _userId = null;
                  });
                },
                isLoading: false,
              ),
            ),
          );
        } else {
          // Normal login without MFA
          _navigateToDashboard(
            token: result['access_token'],
            role: result['role'],
            dashboard: result['dashboard'],
          );
        }
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

// 🆕 MFA VERIFICATION - Updated for navigation approach
  void _verifyMfa(String token) async {
    // 🆕 ADD NULL SAFETY CHECK
    if (_mfaSessionToken == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text("MFA session expired. Please login again.")),
      );
      return;
    }

    try {
      final result = await AuthService.verifyMfaLogin(_mfaSessionToken!, token);

      if (result['success']) {
        // 🆕 CLEAR MFA STATE AFTER SUCCESS
        setState(() {
          _mfaSessionToken = null;
          _userId = null;
        });

        // Pop MFA screen and navigate to dashboard
        Navigator.pop(context); // Close MFA screen
        _navigateToDashboard(
          token: result['access_token'],
          role: result['user']['role'],
          dashboard: result['dashboard'],
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(result['message'] ?? "MFA verification failed")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("MFA verification error: $e")),
      );
    }
  }

  // 🆕 BACK TO LOGIN FORM
  void _backToLogin() {
    setState(() {
      _showMfaForm = false;
      _mfaSessionToken = null;
      _userId = null;
    });
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
          await launchUrl(Uri.parse(url), webOnlyWindowName: "_self");
        }
      } else {
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
        MaterialPageRoute(
            builder: (_) => HMMainDashboard(
                  token: token,
                )),
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

    // 🆕 Show MFA form if required
    if (_showMfaForm) {
      return MfaVerificationScreen(
        mfaSessionToken: _mfaSessionToken!,
        userId: _userId!,
        onVerify: _verifyMfa,
        onBack: _backToLogin,
        isLoading: loading,
      );
    }

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

          // Centered Content - Glass container removed
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
                                  builder: (_) => const ForgotPasswordScreen()),
                            ),
                            child: const Text(
                              "Forgot Password?",
                              style: TextStyle(
                                  color: Colors.blueAccent, fontSize: 14),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        // Updated Login Button - Medium size and Red color
                        SizedBox(
                          width: 200, // Medium width
                          height: 44, // Medium height
                          child: ElevatedButton(
                            onPressed: loading ? null : _login,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red, // Red background
                              foregroundColor: Colors.white, // White text
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20)),
                              elevation: 5,
                            ),
                            child: loading
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                          Colors.white),
                                    ),
                                  )
                                : const Text(
                                    "LOGIN",
                                    style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold),
                                  ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        // 🆕 Enterprise SSO Button - White with red text and icon
                        SizedBox(
                          width: 200, // Same medium width as login button
                          height: 44, // Same medium height as login button
                          child: ElevatedButton(
                            onPressed: loading
                                ? null
                                : () => Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) =>
                                            const SsoEnterpriseScreen(),
                                      ),
                                    ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white, // White background
                              foregroundColor: Colors.red, // Red text
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20)),
                              elevation: 5,
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.business,
                                  size: 18,
                                  color: Colors.red,
                                ),
                                SizedBox(width: 8),
                                Text(
                                  "Enterprise SSO",
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                                child: Divider(
                                    color: Colors.white.withOpacity(0.4))),
                            const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 16),
                              child: Text("Or login with",
                                  style: TextStyle(
                                      color: Colors.white70, fontSize: 14)),
                            ),
                            Expanded(
                                child: Divider(
                                    color: Colors.white.withOpacity(0.4))),
                          ],
                        ),
                        const SizedBox(height: 20),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            IconButton(
                              icon: const FaIcon(FontAwesomeIcons.google,
                                  color: Colors.white, size: 32),
                              onPressed:
                                  loading ? null : () => _socialLogin("Google"),
                            ),
                            const SizedBox(width: 24),
                            IconButton(
                              icon: const FaIcon(FontAwesomeIcons.github,
                                  color: Colors.white, size: 32),
                              onPressed:
                                  loading ? null : () => _socialLogin("GitHub"),
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
                              onTap: loading
                                  ? null
                                  : () => Navigator.pushReplacement(
                                        context,
                                        MaterialPageRoute(
                                            builder: (_) =>
                                                const RegisterScreen()),
                                      ),
                              child: const Text("Register",
                                  style: TextStyle(color: Colors.redAccent)),
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
                          onPressed: loading
                              ? null
                              : () => themeProvider.toggleTheme(),
                        ),
                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

          if (loading && !_showMfaForm)
            const Center(child: CircularProgressIndicator(color: Colors.white)),
        ],
      ),
    );
  }
}
