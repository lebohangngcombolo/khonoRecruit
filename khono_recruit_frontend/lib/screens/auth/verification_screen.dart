import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_textfield.dart';
import '../../providers/theme_provider.dart';
import '../enrollment/enrollment_screen.dart';

class VerificationScreen extends StatefulWidget {
  final String email;
  const VerificationScreen({super.key, required this.email});

  @override
  _VerificationScreenState createState() => _VerificationScreenState();
}

class _VerificationScreenState extends State<VerificationScreen> {
  final TextEditingController codeController = TextEditingController();
  bool loading = false;

  void verify() async {
    if (codeController.text.length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Enter 6-digit code")),
      );
      return;
    }

    setState(() => loading = true);

    // Pass email and code as a Map
    final response = await AuthService.verifyEmail({
      "email": widget.email,
      "code": codeController.text.trim(),
    });

    setState(() => loading = false);

    if (response.containsKey('error')) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(response['error'])),
      );
    } else {
      // Navigate to EnrollmentScreen with token
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
    return Scaffold(
      appBar: AppBar(
        title: const Text("Verify Email"),
        actions: [
          IconButton(
            icon: Icon(
                themeProvider.isDarkMode ? Icons.light_mode : Icons.dark_mode),
            onPressed: () => themeProvider.toggleTheme(),
          )
        ],
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator(color: Colors.red))
          : Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Text("Enter the 6-digit code sent to ${widget.email}",
                      style: const TextStyle(fontSize: 16)),
                  const SizedBox(height: 16),
                  CustomTextField(
                      label: "6-digit Code",
                      controller: codeController,
                      inputType: TextInputType.number),
                  const SizedBox(height: 24),
                  CustomButton(text: "Verify", onPressed: verify),
                ],
              ),
            ),
    );
  }
}
