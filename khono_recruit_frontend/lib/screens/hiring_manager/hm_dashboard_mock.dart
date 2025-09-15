import 'package:flutter/material.dart';
import '../../widgets/nav_drawer.dart';
import '../../widgets/animated_glass_button.dart';
import 'package:provider/provider.dart';
import '../../utils/theme_utils.dart';

class HMDashboardMock extends StatelessWidget {
  const HMDashboardMock({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return Scaffold(
      drawer: const NavDrawer(),
      appBar: AppBar(
        title: const Text('Hiring Manager Dashboard'),
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
              lottieAsset: 'assets/animations/jobs.json',
              text: 'My Jobs',
              onTap: () {
                // TODO: Navigate to Job List Screen
              },
            ),
            const SizedBox(height: 20),
            AnimatedGlassButton(
              lottieAsset: 'assets/animations/applications.json',
              text: 'Candidate Applications',
              onTap: () {
                // TODO: Navigate to Applications Screen
              },
            ),
            const SizedBox(height: 20),
            AnimatedGlassButton(
              lottieAsset: 'assets/animations/reports.json',
              text: 'Reports',
              onTap: () {
                // TODO: Navigate to Reports Screen
              },
            ),
          ],
        ),
      ),
    );
  }
}
