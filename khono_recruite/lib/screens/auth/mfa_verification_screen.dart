import 'package:flutter/material.dart';
// <-- needed for ImageFilter

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
  final List<FocusNode> _focusNodes = List.generate(6, (index) => FocusNode());
  final List<TextEditingController> _digitControllers =
      List.generate(6, (index) => TextEditingController());
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

  void _onDigitChanged(String value, int index) {
    if (value.isNotEmpty) {
      // Update the main token controller
      final currentText = _tokenController.text;
      final newText = currentText.padRight(index, '0').substring(0, index) +
          value +
          currentText.padRight(6, '0').substring(index + 1);
      _tokenController.text = newText.substring(0, 6);

      // Move to next field if available
      if (index < 5) {
        FocusScope.of(context).requestFocus(_focusNodes[index + 1]);
      } else {
        // Last digit entered, remove focus
        _focusNodes[index].unfocus();
      }
    } else if (value.isEmpty && index > 0) {
      // Move to previous field when backspace is pressed on empty field
      FocusScope.of(context).requestFocus(_focusNodes[index - 1]);
    }
  }

  void _onDigitPasted(String value) {
    // Handle paste by filling all boxes with the pasted value
    if (value.length == 6) {
      for (int i = 0; i < 6; i++) {
        _digitControllers[i].text = value[i];
      }
      _tokenController.text = value;
      // Move focus to last field
      FocusScope.of(context).requestFocus(_focusNodes[5]);
    }
  }

  @override
  void initState() {
    super.initState();

    // Initialize focus nodes
    for (int i = 0; i < _focusNodes.length; i++) {
      _focusNodes[i].addListener(() {
        if (!_focusNodes[i].hasFocus && _digitControllers[i].text.isEmpty) {
          _digitControllers[i].text = '';
        }
      });
    }
  }

  @override
  void dispose() {
    _tokenController.dispose();
    for (var node in _focusNodes) {
      node.dispose();
    }
    for (var controller in _digitControllers) {
      controller.dispose();
    }
    super.dispose();
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

          // Centered MFA Content - Glass container removed
          Center(
            child: SingleChildScrollView(
              child: Container(
                width: MediaQuery.of(context).size.width > 800
                    ? 400
                    : MediaQuery.of(context).size.width * 0.9,
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
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

                    // 6-digit box input with red borders and transparent background
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: List.generate(6, (index) {
                          return SizedBox(
                            width: 45,
                            height: 60,
                            child: TextField(
                              controller: _digitControllers[index],
                              focusNode: _focusNodes[index],
                              textAlign: TextAlign.center,
                              keyboardType: TextInputType.number,
                              maxLength: 1,
                              style: const TextStyle(
                                fontSize: 24,
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                              decoration: InputDecoration(
                                counterText: '',
                                filled: true,
                                fillColor:
                                    Colors.transparent, // 100% transparent
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(
                                    color: Colors.red, // Red border
                                    width: 2,
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(
                                    color: Colors
                                        .redAccent, // Brighter red when focused
                                    width: 2,
                                  ),
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(
                                    color: Colors.red,
                                    width: 2,
                                  ),
                                ),
                              ),
                              onChanged: (value) =>
                                  _onDigitChanged(value, index),
                              onTap: () {
                                // Select all text when tapped
                                _digitControllers[index].selection =
                                    TextSelection(
                                  baseOffset: 0,
                                  extentOffset:
                                      _digitControllers[index].text.length,
                                );
                              },
                            ),
                          );
                        }),
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
                    // Shrunk red button with white text
                    SizedBox(
                      width: 200, // Shrunk width
                      height: 44, // Shrunk height
                      child: ElevatedButton(
                        onPressed: widget.isLoading
                            ? null
                            : () {
                                if (_tokenController.text.length == 6) {
                                  widget.onVerify(_tokenController.text);
                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                          "Please enter a valid 6-digit code"),
                                    ),
                                  );
                                }
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red, // Red background
                          foregroundColor: Colors.white, // White text
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
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white),
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
}
