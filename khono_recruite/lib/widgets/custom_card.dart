import 'dart:ui';
import 'package:flutter/material.dart';

class CustomCard extends StatefulWidget {
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback? onTap;
  final bool shadow;
  final Widget? extraWidget; // <-- add this

  const CustomCard({
    super.key,
    required this.title,
    required this.subtitle,
    this.color = Colors.white,
    this.shadow = false,
    this.onTap,
    this.extraWidget, // <-- add this
  });

  @override
  _CustomCardState createState() => _CustomCardState();
}

class _CustomCardState extends State<CustomCard> {
  bool isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => isHovered = true),
      onExit: (_) => setState(() => isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.white.withOpacity(isHovered ? 0.1 : 0.05),
                      Colors.white.withOpacity(isHovered ? 0.15 : 0.08)
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: Colors.white.withOpacity(isHovered ? 0.25 : 0.15),
                    width: 1.5,
                  ),
                  boxShadow: [
                    if (widget.shadow)
                      BoxShadow(
                        color:
                            Colors.black.withOpacity(isHovered ? 0.25 : 0.15),
                        blurRadius: isHovered ? 15 : 8,
                        offset: const Offset(0, 8),
                      ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      widget.title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      widget.subtitle,
                      style:
                          const TextStyle(fontSize: 14, color: Colors.white70),
                    ),
                    if (widget.extraWidget != null) ...[
                      const SizedBox(height: 12),
                      widget.extraWidget!,
                    ],
                    const SizedBox(height: 16),
                    Align(
                      alignment: Alignment.bottomRight,
                      child: ElevatedButton(
                        onPressed: widget.onTap,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.redAccent,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text("Apply"),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
