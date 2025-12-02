import 'dart:html' as html;
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:go_router/go_router.dart';

final storage = FlutterSecureStorage();

class SsoRedirectHandler extends StatefulWidget {
  const SsoRedirectHandler({super.key});

  @override
  State<SsoRedirectHandler> createState() => _SsoRedirectHandlerState();
}

class _SsoRedirectHandlerState extends State<SsoRedirectHandler> {
  @override
  void initState() {
    super.initState();
    _handleRedirect();
  }

  Future<void> _handleRedirect() async {
    final uri = Uri.base;

    final accessToken = uri.queryParameters['access_token'];
    final refreshToken = uri.queryParameters['refresh_token'];
    final id = uri.queryParameters['id'];
    final email = uri.queryParameters['email'];
    final role = uri.queryParameters['role'];
    final firstName = uri.queryParameters['first_name'];
    final lastName = uri.queryParameters['last_name'];
    final enrollmentCompleted = uri.queryParameters['enrollment_completed'];
    final dashboard = uri.queryParameters['dashboard'];

    if (accessToken != null && refreshToken != null) {
      await storage.write(key: 'access_token', value: accessToken);
      await storage.write(key: 'refresh_token', value: refreshToken);
      await storage.write(key: 'user_id', value: id);
      await storage.write(key: 'user_email', value: email);
      await storage.write(key: 'user_role', value: role);
      await storage.write(key: 'user_first_name', value: firstName);
      await storage.write(key: 'user_last_name', value: lastName);
      await storage.write(
          key: 'enrollment_completed', value: enrollmentCompleted);

      html.window.history.replaceState(null, 'Dashboard', '/');

      if (dashboard != null && dashboard.isNotEmpty) {
        GoRouter.of(context).go(dashboard);
      } else {
        GoRouter.of(context).go('/');
      }
    } else {
      GoRouter.of(context).go('/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}
