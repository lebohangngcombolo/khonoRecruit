import 'package:flutter/material.dart';
import '../screens/admin/admin_dashboard_screen.dart';
import '../screens/candidate/candidate_dashboard.dart';
import '../screens/hiring_manager/hm_dashboard_mock.dart';

class NavDrawer extends StatelessWidget {
  final String? token; // Add token parameter

  const NavDrawer({super.key, this.token});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          const DrawerHeader(
            decoration: BoxDecoration(color: Colors.redAccent),
            child: Text(
              'KhonoRecruit',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.dashboard),
            title: const Text('Admin Dashboard'),
            onTap: () => Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const AdminDashboardScreen()),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.person),
            title: const Text('Candidate Dashboard'),
            onTap: () {
              if (token != null) {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (_) => CandidateDashboard(token: token!),
                  ),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Token not found. Please login again.'),
                  ),
                );
              }
            },
          ),
          ListTile(
            leading: const Icon(Icons.work),
            title: const Text('Hiring Manager Dashboard'),
            onTap: () => Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const HMDashboardMock()),
            ),
          ),
        ],
      ),
    );
  }
}
