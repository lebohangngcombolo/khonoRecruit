import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_web_plugins/flutter_web_plugins.dart'; // ⚡ Web URL strategy

import 'screens/auth/login_screen.dart';
import 'screens/candidate/candidate_dashboard.dart';
import 'screens/enrollment/enrollment_screen.dart';
import 'screens/admin/admin_dashboard.dart';
import 'screens/hiring_manager/hiring_manager_dashboard.dart';
import 'screens/landing_page/landing_page.dart';
import 'screens/auth/reset_password.dart';
import 'screens/admin/profile_page.dart';
import 'screens/auth/oath_callback_screen.dart';
import 'screens/auth/mfa_verification_screen.dart';
import 'screens/auth/sso_handler_screen.dart';

import 'providers/theme_provider.dart';
import 'utils/theme_utils.dart';

void main() {
  // ⚡ Fix Flutter Web initial route handling
  setUrlStrategy(PathUrlStrategy());

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
      ],
      child: const KhonoRecruiteApp(),
    ),
  );
}

// ✅ Persistent router
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
      path: '/mfa-verification',
      builder: (context, state) {
        final mfaSessionToken =
            state.uri.queryParameters['mfa_session_token'] ?? '';
        final userId = state.uri.queryParameters['user_id'] ?? '';
        return MfaVerificationScreen(
          mfaSessionToken: mfaSessionToken,
          userId: userId,
          onVerify: (String token) {},
          onBack: () {
            context.go('/login');
          },
          isLoading: false,
        );
      },
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
        builder: (context, state) {
          final token = state.uri.queryParameters['token'] ?? '';
          return HMMainDashboard(token: token);
        }),
    GoRoute(
      path: '/profile',
      builder: (context, state) {
        final token = state.uri.queryParameters['token'] ?? '';
        return ProfilePage(token: token);
      },
    ),
    // ⚡ OAuth callback screen reads tokens directly from URL
    GoRoute(
      path: '/oauth-callback',
      builder: (context, state) => const OAuthCallbackScreen(),
    ),
    GoRoute(
      path: '/sso-redirect',
      builder: (context, state) => const SsoRedirectHandler(),
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
      routerConfig: _router,
    );
  }
}
