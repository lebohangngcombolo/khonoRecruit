import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../services/auth_service.dart';

class OAuthCallbackScreen extends StatelessWidget {
  const OAuthCallbackScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final uri = Uri.base;
    final accessToken = uri.queryParameters['access_token'];
    final refreshToken = uri.queryParameters['refresh_token'];
    final role = uri.queryParameters['role'];

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (accessToken != null && refreshToken != null && role != null) {
        await AuthService.storeTokens(accessToken, refreshToken, role);

        String path;
        switch (role) {
          case 'admin':
            path = '/admin-dashboard';
            break;
          case 'hiring_manager':
            path = '/hiring-manager-dashboard';
            break;
          case 'candidate':
            path = '/enrollment';
            break;
          default:
            path = '/candidate-dashboard';
        }

        context.go('$path?token=$accessToken');
      } else {
        context.go('/'); // fallback if query params missing
      }
    });

    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}
