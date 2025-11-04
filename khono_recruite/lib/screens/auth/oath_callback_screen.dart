// screens/auth/oauth_callback_screen.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class OAuthCallbackScreen extends StatelessWidget {
  const OAuthCallbackScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final uri = Uri.base;
    final accessToken = uri.queryParameters['access_token'];
    final refreshToken = uri.queryParameters['refresh_token'];
    final role = uri.queryParameters['role'];
    final dashboard = uri.queryParameters['dashboard'] ?? '';

    // Automatically navigate after frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (accessToken != null && role != null) {
        _navigateToDashboard(context, accessToken, role, dashboard);
      }
    });

    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }

  void _navigateToDashboard(
      BuildContext context, String token, String role, String dashboard) {
    String path;
    if (role == "admin") {
      path = '/admin-dashboard';
    } else if (role == "hiring_manager") {
      path = '/hiring-manager-dashboard';
    } else if (role == "candidate" && dashboard == "/enrollment") {
      path = '/enrollment';
    } else {
      path = '/candidate-dashboard';
    }

    // GoRouter navigation with token
    context.go('$path?token=$token');
  }
}
