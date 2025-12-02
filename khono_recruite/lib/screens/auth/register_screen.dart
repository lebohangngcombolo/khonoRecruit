import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_textfield2.dart';
import '../../providers/theme_provider.dart';
import 'verification_screen.dart';
import 'login_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  _RegisterScreenState createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController firstNameController = TextEditingController();
  final TextEditingController lastNameController = TextEditingController();
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
    passwordController.dispose();
    firstNameController.dispose();
    lastNameController.dispose();
    super.dispose();
  }

  void register() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => loading = true);

    final data = {
      "email": emailController.text.trim(),
      "password": passwordController.text.trim(),
      "first_name": firstNameController.text.trim(),
      "last_name": lastNameController.text.trim(),
      "role": "candidate",
    };

    final result = await AuthService.register(data);
    setState(() => loading = false);

    final status = result['status'];
    final body = result['body'];

    if (status != 201) {
      final errorMessage =
          body["errors"]?.join("\n") ?? body["error"] ?? "Registration failed.";

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(errorMessage)),
      );
      return; // Do NOT navigate
    }

    // SUCCESS: Only navigate on 201
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => VerificationScreen(
          email: emailController.text.trim(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: Stack(
        children: [
          // Background Image
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
                    child: Form(
                      key: _formKey,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const SizedBox(height: 16),
                          const Text(
                            "GET STARTED",
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
                            "Register Account",
                            style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.white),
                          ),
                          const SizedBox(height: 24),
                          // Text Fields with transparent background
                          CustomTextField(
                            label: "First Name",
                            controller: firstNameController,
                            textColor: const Color.fromARGB(255, 183, 10, 10),
                            backgroundColor: Colors.transparent,
                          ),
                          const SizedBox(height: 12),
                          CustomTextField(
                            label: "Last Name",
                            controller: lastNameController,
                            textColor: const Color.fromARGB(255, 188, 7, 7),
                            backgroundColor: Colors.transparent,
                          ),
                          const SizedBox(height: 12),
                          CustomTextField(
                            label: "Email",
                            controller: emailController,
                            inputType: TextInputType.emailAddress,
                            textColor: const Color.fromARGB(255, 189, 4, 4),
                            backgroundColor: Colors.transparent,
                          ),
                          const SizedBox(height: 12),
                          CustomTextField(
                            label: "Password",
                            controller: passwordController,
                            inputType: TextInputType.visiblePassword,
                            textColor: const Color.fromARGB(255, 199, 12, 12),
                            backgroundColor: Colors.transparent,
                          ),
                          const SizedBox(height: 20),
                          // Medium sized button
                          SizedBox(
                            width: 200, // Medium width
                            height: 44, // Medium height
                            child: CustomButton(
                              text: "Register",
                              onPressed: register,
                            ),
                          ),
                          const SizedBox(height: 24),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Text("Already have an account? ",
                                  style: TextStyle(color: Colors.white70)),
                              GestureDetector(
                                onTap: () {
                                  Navigator.pushReplacement(
                                    context,
                                    MaterialPageRoute(
                                        builder: (_) => const LoginScreen()),
                                  );
                                },
                                child: const Text(
                                  "Login",
                                  style: TextStyle(color: Colors.redAccent),
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
                              color: Colors.white,
                            ),
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

          if (loading)
            const Center(child: CircularProgressIndicator(color: Colors.white)),
        ],
      ),
    );
  }
}
