import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../services/auth_service.dart';

class OAuthCallbackScreen extends StatefulWidget {
  const OAuthCallbackScreen({super.key});

  @override
  State<OAuthCallbackScreen> createState() => _OAuthCallbackScreenState();
}

class _OAuthCallbackScreenState extends State<OAuthCallbackScreen> {
  @override
  void initState() {
    super.initState();
    // Run after first frame to ensure context is available
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _handleOAuthRedirect();
    });
  }

  Future<void> _handleOAuthRedirect() async {
    final uri = Uri.base; // Gets full current browser URL
    final accessToken = uri.queryParameters['access_token'];
    final refreshToken = uri.queryParameters['refresh_token'];
    final role = uri.queryParameters['role'];

    if (accessToken != null && role != null) {
      // Store tokens securely
      await AuthService.storeTokens(accessToken, refreshToken, role);

      if (!mounted) return;

      // Navigate based on user role
      switch (role) {
        case 'admin':
          context.go('/admin-dashboard?token=$accessToken');
          break;
        case 'hiring_manager':
          context.go('/hiring-manager-dashboard?token=$accessToken');
          break;
        case 'candidate':
          // Check if enrollment is complete
          final user = await AuthService.getUserInfo();
          final completed = user?['enrollment_completed'] ?? false;
          if (completed) {
            context.go('/candidate-dashboard?token=$accessToken');
          } else {
            context.go('/enrollment?token=$accessToken');
          }
          break;
        default:
          context.go('/candidate-dashboard?token=$accessToken');
      }
    } else {
      // Fallback to login if tokens missing
      if (mounted) context.go('/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Background gradient
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color(0xFF0F2027),
                  Color(0xFF203A43),
                  Color(0xFF2C5364)
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
          // Frosted glass loader
          Center(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(25),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                child: Container(
                  width: 360,
                  padding: const EdgeInsets.all(30),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(25),
                    border: Border.all(
                        color: Colors.white.withOpacity(0.3), width: 1),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        strokeWidth: 4,
                      ),
                      SizedBox(height: 24),
                      Text(
                        "Completing sign-in...",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        "Please wait while we set up your session.",
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.white70, fontSize: 14),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
