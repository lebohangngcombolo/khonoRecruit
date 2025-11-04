import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';

import 'screens/auth/login_screen.dart';
import 'screens/candidate/candidate_dashboard.dart';
import 'screens/enrollment/enrollment_screen.dart';
import 'screens/admin/admin_dashboard.dart';
import 'screens/hiring_manager/hiring_manager_dashboard.dart';
import 'screens/landing_page/landing_page.dart';
import 'screens/auth/reset_password.dart';
import 'screens/admin/profile_page.dart';
import 'screens/auth/oath_callback_screen.dart';

import 'providers/theme_provider.dart';
import 'utils/theme_utils.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
      ],
      child: const KhonoRecruiteApp(),
    ),
  );
}

// ✅ Move router outside build so it doesn’t rebuild every theme toggle
final GoRouter _router = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const LandingPage(),
    ),
    GoRoute(
      path: '/login',
      builder: (context, state) => const LoginScreen(),
    ),
    GoRoute(
      path: '/reset-password',
      builder: (context, state) {
        final token = state.uri.queryParameters['token'] ?? '';
        return ResetPasswordPage(token: token);
      },
    ),
    GoRoute(
      path: '/candidate-dashboard',
      builder: (context, state) {
        final token = state.uri.queryParameters['token'] ?? '';
        return CandidateDashboard(token: token);
      },
    ),
    GoRoute(
      path: '/enrollment',
      builder: (context, state) {
        final token = state.uri.queryParameters['token'] ?? '';
        return EnrollmentScreen(token: token);
      },
    ),
    GoRoute(
      path: '/admin-dashboard',
      builder: (context, state) {
        final token = state.uri.queryParameters['token'] ?? '';
        return AdminDAshboard(token: token);
      },
    ),
    GoRoute(
      path: '/hiring-manager-dashboard',
      builder: (context, state) => HMMainDashboard(),
    ),
    GoRoute(
      path: '/profile',
      builder: (context, state) {
        final token = state.uri.queryParameters['token'] ?? '';
        return ProfilePage(token: token);
      },
    ),
    GoRoute(
      path: '/oauth-callback',
      builder: (context, state) => const OAuthCallbackScreen(),
    ),
  ],
);

class KhonoRecruiteApp extends StatelessWidget {
  const KhonoRecruiteApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return MaterialApp.router(
      title: "Khono_Recruite",
      debugShowCheckedModeBanner: false,
      themeMode: themeProvider.isDarkMode ? ThemeMode.dark : ThemeMode.light,
      theme: ThemeUtils.lightTheme,
      darkTheme: ThemeUtils.darkTheme,
      routerConfig: _router, // ✅ Uses the persistent router
    );
  }
}
