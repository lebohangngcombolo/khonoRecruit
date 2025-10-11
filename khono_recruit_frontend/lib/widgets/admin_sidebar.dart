import 'package:flutter/material.dart';

class Sidebar extends StatelessWidget {
  final Function(String) onTap;

  const Sidebar({super.key, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Container(
        color: Colors.red,
        child: ListView(
          children: [
            const DrawerHeader(
              child: Text("Khono Admin",
                  style: TextStyle(color: Colors.white, fontSize: 24)),
            ),
            ListTile(
              leading: const Icon(Icons.dashboard, color: Colors.white),
              title: const Text("Dashboard",
                  style: TextStyle(color: Colors.white)),
              onTap: () => onTap("dashboard"),
            ),
            ListTile(
              leading: const Icon(Icons.work, color: Colors.white),
              title: const Text("Jobs", style: TextStyle(color: Colors.white)),
              onTap: () => onTap("jobs"),
            ),
            ListTile(
              leading: const Icon(Icons.people, color: Colors.white),
              title: const Text("Shortlisting",
                  style: TextStyle(color: Colors.white)),
              onTap: () => onTap("shortlisting"),
            ),
            ListTile(
              leading: const Icon(Icons.schedule, color: Colors.white),
              title: const Text("Interviews",
                  style: TextStyle(color: Colors.white)),
              onTap: () => onTap("interviews"),
            ),
            ListTile(
              leading: const Icon(Icons.description, color: Colors.white),
              title: const Text("CV Review",
                  style: TextStyle(color: Colors.white)),
              onTap: () => onTap("cv_review"),
            ),
          ],
        ),
      ),
    );
  }
}
