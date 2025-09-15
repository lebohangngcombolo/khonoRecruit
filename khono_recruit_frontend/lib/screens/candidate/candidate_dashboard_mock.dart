import 'package:flutter/material.dart';
import '../../widgets/nav_drawer.dart';
import '../../widgets/animated_glass_button.dart';
import 'package:provider/provider.dart';
import '../../utils/theme_utils.dart';

class CandidateDashboardMock extends StatelessWidget {
  const CandidateDashboardMock({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return Scaffold(
      drawer: const NavDrawer(),
      appBar: AppBar(
        title: const Text('Candidate Dashboard'),
        actions: [
          IconButton(
            icon: Icon(
                themeProvider.isDarkMode ? Icons.wb_sunny : Icons.dark_mode),
            onPressed: () => themeProvider.toggleTheme(),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            AnimatedGlassButton(
              lottieAsset: 'assets/animations/applications.json',
              text: 'My Applications',
              onTap: () {
                // TODO: Navigate to Applications Screen
              },
            ),
            const SizedBox(height: 20),
            AnimatedGlassButton(
              lottieAsset: 'assets/animations/interview.json',
              text: 'Upcoming Interviews',
              onTap: () {
                // TODO: Navigate to Interviews Screen
              },
            ),
            const SizedBox(height: 20),
            AnimatedGlassButton(
              lottieAsset: 'assets/animations/profile.json',
              text: 'Profile',
              onTap: () {
                // TODO: Navigate to Profile Screen
              },
            ),
          ],
        ),
      ),
    );
  }
}
