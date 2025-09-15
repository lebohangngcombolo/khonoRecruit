import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'utils/theme_utils.dart';
import 'screens/landing/landing_screen.dart';
import 'routes/app_routes.dart';

void main() {
  runApp(const KhonoRecruitApp());
}

class KhonoRecruitApp extends StatelessWidget {
  const KhonoRecruitApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ThemeProvider(),
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, _) {
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            title: 'KhonoRecruit',
            theme: themeProvider.currentTheme,
            initialRoute: '/',
            routes: {
              '/': (_) => const LandingScreen(),
              '/login': (_) =>
                  const LandingScreen(), // redirect handled in LandingScreen
            },
            onGenerateRoute: AppRoutes.generateRoute,
          );
        },
      ),
    );
  }
}
