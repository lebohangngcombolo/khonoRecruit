import 'package:flutter/material.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/register_screen.dart';
import '../screens/admin/admin_dashboard_screen.dart';
import '../screens/candidate/candidate_dashboard_mock.dart';
import '../screens/hiring_manager/hm_dashboard_mock.dart';

class AppRoutes {
  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case '/login':
        return MaterialPageRoute(builder: (_) => const LoginScreen());
      case '/register':
        return MaterialPageRoute(builder: (_) => const RegisterScreen());
      case '/admin_dashboard':
        return MaterialPageRoute(builder: (_) => const AdminDashboardScreen());
      case '/candidate_dashboard':
        return MaterialPageRoute(
            builder: (_) => const CandidateDashboardMock());
      case '/hm_dashboard':
        return MaterialPageRoute(builder: (_) => const HMDashboardMock());
      default:
        return MaterialPageRoute(builder: (_) => const LoginScreen());
    }
  }
}
