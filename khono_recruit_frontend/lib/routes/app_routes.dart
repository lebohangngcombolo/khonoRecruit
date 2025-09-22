import 'package:flutter/material.dart';

// Auth Screens
import '../screens/auth/login_screen.dart';
import '../screens/auth/register_screen.dart';

// Admin Screens
import '../screens/admin/admin_dashboard_screen.dart';

// Candidate Screens
import '../screens/candidate/candidate_dashboard.dart';
import '../screens/candidate/cv_upload_screen.dart';
import '../screens/candidate/profile_screen.dart';
import '../screens/candidate/jobs_screen.dart';
import '../screens/candidate/job_application_screen.dart';
import '../screens/candidate/assessment_screen.dart';

// Hiring Manager Screens
import '../screens/hiring_manager/hm_dashboard_mock.dart';

class AppRoutes {
  static Route<dynamic> generateRoute(RouteSettings settings) {
    final args = settings.arguments;

    switch (settings.name) {
      // Auth
      case '/login':
        return MaterialPageRoute(builder: (_) => const LoginScreen());
      case '/register':
        return MaterialPageRoute(builder: (_) => const RegisterScreen());

      // Admin
      case '/admin_dashboard':
        return MaterialPageRoute(builder: (_) => const AdminDashboardScreen());

      // Candidate Dashboard
      case '/candidate_dashboard':
        if (args is String) {
          return MaterialPageRoute(
              builder: (_) => CandidateDashboard(token: args));
        }
        return _errorRoute();

      // Candidate CV Upload
      case '/candidate/cv_upload':
        if (args is String) {
          return MaterialPageRoute(builder: (_) => CVUploadScreen(token: args));
        }
        return _errorRoute();

      // Candidate Profile
      case '/candidate/profile':
        if (args is String) {
          return MaterialPageRoute(builder: (_) => ProfileScreen(token: args));
        }
        return _errorRoute();

      // Candidate Jobs
      case '/candidate/jobs':
        if (args is String) {
          return MaterialPageRoute(builder: (_) => JobsScreen(token: args));
        }
        return _errorRoute();

      // Candidate Job Application (needs jobId + token)
      case '/candidate/job_application':
        if (args is Map<String, dynamic>) {
          final jobId = args['jobId'] as int;
          final token = args['token'] as String;
          return MaterialPageRoute(
              builder: (_) => JobApplicationScreen(jobId: jobId, token: token));
        }
        return _errorRoute();

      // Candidate Assessment (needs applicationId + token + jobId)
      case '/candidate/assessment':
        if (args is Map<String, dynamic>) {
          final applicationId = args['applicationId'] as int;
          final token = args['token'] as String;
          final jobId = args['jobId'] as int; // required now
          return MaterialPageRoute(
            builder: (_) => AssessmentScreen(
              applicationId: applicationId,
              token: token,
              jobId: jobId,
            ),
          );
        }
        return _errorRoute();

      // Hiring Manager
      case '/hm_dashboard':
        return MaterialPageRoute(builder: (_) => const HMDashboardMock());

      // Default
      default:
        return MaterialPageRoute(builder: (_) => const LoginScreen());
    }
  }

  static Route<dynamic> _errorRoute() {
    return MaterialPageRoute(
      builder: (_) => Scaffold(
        appBar: AppBar(title: const Text('Error')),
        body: const Center(child: Text('Page not found')),
      ),
    );
  }
}
