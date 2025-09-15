import 'package:flutter/material.dart';
import '../screens/admin/admin_dashboard_screen.dart';
import '../screens/candidate/candidate_dashboard_mock.dart';
import '../screens/hiring_manager/hm_dashboard_mock.dart';

class NavDrawer extends StatelessWidget {
  const NavDrawer({super.key});

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
                MaterialPageRoute(
                    builder: (_) => const AdminDashboardScreen())),
          ),
          ListTile(
            leading: const Icon(Icons.person),
            title: const Text('Candidate Dashboard'),
            onTap: () => Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                    builder: (_) => const CandidateDashboardMock())),
          ),
          ListTile(
            leading: const Icon(Icons.work),
            title: const Text('Hiring Manager Dashboard'),
            onTap: () => Navigator.pushReplacement(context,
                MaterialPageRoute(builder: (_) => const HMDashboardMock())),
          ),
        ],
      ),
    );
  }
}
