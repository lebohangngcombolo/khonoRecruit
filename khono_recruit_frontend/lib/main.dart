import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'screens/auth/login_screen.dart';
import 'screens/candidate/candidate_dashboard.dart';
import 'screens/enrollment/enrollment_screen.dart';
import 'screens/admin/admin_dashboard.dart';

import 'providers/theme_provider.dart';
import 'utils/theme_utils.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
      ],
      child: const KhonoRecruiteApp(
        token: '',
      ),
    ),
  );
}

class KhonoRecruiteApp extends StatelessWidget {
  final String token;
  const KhonoRecruiteApp({Key? key, required this.token}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return MaterialApp(
      title: "Khono_Recruite",
      debugShowCheckedModeBanner: false,
      themeMode: themeProvider.isDarkMode ? ThemeMode.dark : ThemeMode.light,
      theme: ThemeUtils.lightTheme,
      darkTheme: ThemeUtils.darkTheme,
      home: const StartupScreen(),
    );
  }
}

/// ✅ This screen decides where to send the user
class StartupScreen extends StatefulWidget {
  const StartupScreen({super.key});

  @override
  State<StartupScreen> createState() => _StartupScreenState();
}

class _StartupScreenState extends State<StartupScreen> {
  final FlutterSecureStorage storage = const FlutterSecureStorage();

  @override
  void initState() {
    super.initState();
    _checkLogin();
  }

  Future<void> _checkLogin() async {
    final role = await storage.read(key: "role");
    final dashboard = await storage.read(key: "dashboard");
    final token = await storage.read(key: "access_token");

    await Future.delayed(const Duration(seconds: 1)); // splash-like effect

    if (token != null && role != null) {
      if (role == "admin") {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => AdminDashboard(),
          ),
        );
      } else if (role == "candidate" && dashboard == "/enrollment") {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => EnrollmentScreen(token: token)),
        );
      } else {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => CandidateDashboard(token: token),
          ),
        );
      }
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}
