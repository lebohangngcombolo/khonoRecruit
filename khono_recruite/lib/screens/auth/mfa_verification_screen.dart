import 'package:flutter/material.dart';
import 'dart:ui'; // <-- needed for ImageFilter

import '../../widgets/custom_textfield.dart';

class MfaVerificationScreen extends StatefulWidget {
  final String mfaSessionToken;
  final String userId;
  final Function(String) onVerify; // 🆕 Should accept verification token
  final VoidCallback onBack;
  final bool isLoading;

  const MfaVerificationScreen({
    Key? key,
    required this.mfaSessionToken,
    required this.userId,
    required this.onVerify,
    required this.onBack,
    required this.isLoading,
  }) : super(key: key);

  @override
  _MfaVerificationScreenState createState() => _MfaVerificationScreenState();
}

class _MfaVerificationScreenState extends State<MfaVerificationScreen> {
  final TextEditingController _tokenController = TextEditingController();
  bool _isVerifying = false;

  void _verifyToken() {
    if (_tokenController.text.length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter a valid 6-digit code")),
      );
      return;
    }

    setState(() => _isVerifying = true);

    // 🆕 Call the onVerify callback with the token
    widget.onVerify(_tokenController.text);

    setState(() => _isVerifying = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background (same as login)
          Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage("assets/images/dark.png"),
                fit: BoxFit.cover,
              ),
            ),
          ),

          // Back button
          SafeArea(
            child: Align(
              alignment: Alignment.topLeft,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                  onPressed: widget.isLoading ? null : widget.onBack,
                ),
              ),
            ),
          ),

          // Centered MFA Card
          Center(
            child: SingleChildScrollView(
              child: Container(
                width: MediaQuery.of(context).size.width > 800
                    ? 400
                    : MediaQuery.of(context).size.width * 0.9,
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
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
                          const Icon(
                            Icons.security,
                            size: 64,
                            color: Colors.white,
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            "Two-Factor Authentication",
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            "Enter the 6-digit code from your authenticator app",
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 32),
                          CustomTextField(
                            label: "6-digit Code",
                            controller: _tokenController,
                            inputType: TextInputType.number,
                            maxLength: 6,
                            backgroundColor:
                                const Color.fromARGB(0, 129, 128, 128)
                                    .withOpacity(0.1),
                            textColor: const Color.fromARGB(255, 172, 0, 0),
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 18,
                              letterSpacing: 8,
                            ),
                          ),
                          const SizedBox(height: 16),
                          TextButton(
                            onPressed: widget.isLoading
                                ? null
                                : () {
                                    _showBackupCodeInfo(context);
                                  },
                            child: const Text(
                              "Using a backup code?",
                              style: TextStyle(color: Colors.blueAccent),
                            ),
                          ),
                          const SizedBox(height: 24),
                          SizedBox(
                            width: double.infinity,
                            height: 48,
                            child: ElevatedButton(
                              onPressed: widget.isLoading
                                  ? null
                                  : () {
                                      if (_tokenController.text.length == 6) {
                                        widget.onVerify(_tokenController.text);
                                      } else {
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          const SnackBar(
                                            content: Text(
                                                "Please enter a valid 6-digit code"),
                                          ),
                                        );
                                      }
                                    },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white.withOpacity(0.8),
                                foregroundColor: Colors.red,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                elevation: 5,
                              ),
                              child: widget.isLoading
                                  ? const SizedBox(
                                      height: 20,
                                      width: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                                Colors.red),
                                      ),
                                    )
                                  : const Text(
                                      "VERIFY & CONTINUE",
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                            ),
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

          if (widget.isLoading)
            const Center(child: CircularProgressIndicator(color: Colors.white)),
        ],
      ),
    );
  }

  void _showBackupCodeInfo(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Using Backup Codes"),
        content: const Text("If you've lost access to your authenticator app, "
            "you can use one of your backup codes. "
            "Enter the 10-character backup code in the verification field. "
            "Each backup code can only be used once."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Got it"),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _tokenController.dispose();
    super.dispose();
  }
}
