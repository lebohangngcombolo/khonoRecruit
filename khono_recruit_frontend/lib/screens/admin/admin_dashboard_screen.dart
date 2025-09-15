import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import '../../widgets/nav_drawer.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/custom_button.dart';
import '../../utils/theme_utils.dart';
import 'user_list_screen.dart';
import 'job_list_screen.dart';
import 'applications_screen.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  int userCount = 0;
  int jobCount = 0;
  int applicationCount = 0;
  bool loading = true;

  final String baseUrl = 'http://127.0.0.1:5000/api/admin';
  final String token = ''; // Add your JWT token here

  @override
  void initState() {
    super.initState();
    fetchCounts();
  }

  Future<void> fetchCounts() async {
    try {
      setState(() => loading = true);

      final headers = {'Authorization': 'Bearer $token'};

      // Fetch Users
      final usersRes =
          await http.get(Uri.parse('$baseUrl/users'), headers: headers);
      if (usersRes.statusCode == 200) {
        final data = json.decode(usersRes.body);
        userCount = data['users']?.length ?? 0;
      }

      // Fetch Jobs
      final jobsRes =
          await http.get(Uri.parse('$baseUrl/jobs'), headers: headers);
      if (jobsRes.statusCode == 200) {
        final data = json.decode(jobsRes.body);
        jobCount = data['jobs']?.length ?? 0;
      }

      // Fetch Applications
      final appsRes =
          await http.get(Uri.parse('$baseUrl/applications'), headers: headers);
      if (appsRes.statusCode == 200) {
        final data = json.decode(appsRes.body);
        applicationCount = data['applications']?.length ?? 0;
      }

      setState(() => loading = false);
    } catch (e) {
      setState(() => loading = false);
      debugPrint('Error fetching admin counts: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to fetch admin data')),
      );
    }
  }

  Widget buildButtonWithBadge(
      String text, int count, Color badgeColor, VoidCallback onPressed) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        CustomButton(
          text: text,
          onPressed: onPressed,
        ),
        if (count > 0)
          Positioned(
            top: -5,
            right: -5,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: badgeColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white, width: 1),
              ),
              child: Text(
                '$count',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return Scaffold(
      drawer: const NavDrawer(),
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.dark_mode),
            onPressed: themeProvider.toggleTheme,
          )
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            GlassCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Admin Controls',
                    style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.white),
                  ),
                  const SizedBox(height: 15),
                  loading
                      ? const Center(
                          child: CircularProgressIndicator(color: Colors.white),
                        )
                      : Wrap(
                          spacing: 15,
                          runSpacing: 15,
                          children: [
                            buildButtonWithBadge(
                              'Users',
                              userCount,
                              Colors.blue,
                              () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => const UserListScreen(),
                                  ),
                                );
                              },
                            ),
                            buildButtonWithBadge(
                              'Jobs',
                              jobCount,
                              Colors.green,
                              () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => const JobListScreen(),
                                  ),
                                );
                              },
                            ),
                            buildButtonWithBadge(
                              'Applications',
                              applicationCount,
                              Colors.orange,
                              () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => const ApplicationsScreen(),
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
