import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'glass_card.dart';

class AnimatedGlassButton extends StatelessWidget {
  final String lottieAsset;
  final String text;
  final VoidCallback onTap;
  final double width;
  final double height;

  const AnimatedGlassButton({
    super.key,
    required this.lottieAsset,
    required this.text,
    required this.onTap,
    this.width = 160,
    this.height = 160,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: GlassCard(
        width: width,
        height: height,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 80,
              height: 80,
              child: Lottie.asset(lottieAsset, repeat: true, animate: true),
            ),
            const SizedBox(height: 10),
            Text(
              text,
              style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }
}
