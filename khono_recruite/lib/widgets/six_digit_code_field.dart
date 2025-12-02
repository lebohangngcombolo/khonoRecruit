import 'package:flutter/material.dart';

class SixDigitCodeField extends StatefulWidget {
  final ValueChanged<String> onCodeChanged;
  final ValueChanged<String> onCodeCompleted;
  final bool autoFocus;

  const SixDigitCodeField({
    super.key,
    required this.onCodeChanged,
    required this.onCodeCompleted,
    this.autoFocus = false,
  });

  @override
  State<SixDigitCodeField> createState() => _SixDigitCodeFieldState();
}

class _SixDigitCodeFieldState extends State<SixDigitCodeField> {
  final List<TextEditingController> _controllers =
      List.generate(6, (index) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(6, (index) => FocusNode());
  final List<String> _code = List.filled(6, '');

  @override
  void initState() {
    super.initState();

    // Setup focus node listeners
    for (int i = 0; i < _focusNodes.length; i++) {
      _focusNodes[i].addListener(() {
        if (!_focusNodes[i].hasFocus && _controllers[i].text.isEmpty && i > 0) {
          _focusNodes[i - 1].requestFocus();
        }
      });
    }

    // Auto-focus first field if requested
    if (widget.autoFocus) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _focusNodes[0].requestFocus();
      });
    }
  }

  @override
  void dispose() {
    for (var controller in _controllers) {
      controller.dispose();
    }
    for (var focusNode in _focusNodes) {
      focusNode.dispose();
    }
    super.dispose();
  }

  void _handleInput(String value, int index) {
    if (value.isNotEmpty) {
      _code[index] = value;

      // Move to next field if available
      if (index < 5) {
        _focusNodes[index + 1].requestFocus();
      } else {
        // Last field - unfocus
        _focusNodes[index].unfocus();
      }
    } else {
      _code[index] = '';

      // Move to previous field if available
      if (index > 0) {
        _focusNodes[index - 1].requestFocus();
      }
    }

    final currentCode = _code.join();
    widget.onCodeChanged(currentCode);

    // Check if code is complete
    if (currentCode.length == 6) {
      widget.onCodeCompleted(currentCode);
    }
  }

  void _handlePaste(String pastedText) {
    final digits = pastedText.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.length >= 6) {
      for (int i = 0; i < 6; i++) {
        _controllers[i].text = digits[i];
        _code[i] = digits[i];
      }
      final code = digits.substring(0, 6);
      widget.onCodeChanged(code);
      widget.onCodeCompleted(code);
      _focusNodes[5].requestFocus();
    }
  }

  Widget _buildDigitBox(int index) {
    return Container(
      width: 48,
      height: 56,
      margin: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        color: Colors.transparent, // Changed to transparent
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _focusNodes[index].hasFocus
              ? Colors.white.withOpacity(0.8)
              : Colors.white.withOpacity(0.3),
          width: _focusNodes[index].hasFocus ? 2 : 1,
        ),
        boxShadow: [
          if (_focusNodes[index].hasFocus)
            BoxShadow(
              color: Colors.white.withOpacity(0.3),
              blurRadius: 8,
              spreadRadius: 1,
            ),
        ],
      ),
      child: TextField(
        controller: _controllers[index],
        focusNode: _focusNodes[index],
        textAlign: TextAlign.center,
        keyboardType: TextInputType.number,
        maxLength: 1,
        style: const TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.bold,
          color: Colors.red, // Changed to red
        ),
        decoration: const InputDecoration(
          counterText: '',
          border: InputBorder.none,
          contentPadding: EdgeInsets.zero,
          filled: false, // Ensure no fill color
        ),
        onChanged: (value) => _handleInput(value, index),
        onTap: () {
          // Select all text when tapped
          _controllers[index].selection = TextSelection(
            baseOffset: 0,
            extentOffset: _controllers[index].text.length,
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        // Focus first empty field or last field
        final firstEmptyIndex = _code.indexWhere((digit) => digit.isEmpty);
        if (firstEmptyIndex != -1) {
          _focusNodes[firstEmptyIndex].requestFocus();
        } else {
          _focusNodes[5].requestFocus();
        }
      },
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          for (int i = 0; i < 6; i++) _buildDigitBox(i),
        ],
      ),
    );
  }
}
