import 'package:flutter/material.dart';
import '../../services/admin_service.dart';
import '../../models/application_model.dart';
import 'assessment_screen.dart';
import '../../screens/admin/user_list_screen.dart';
import '../../screens/admin/job_list_screen.dart';
import '../../screens/admin/candidates_screen.dart';

class ApplicationsScreen extends StatefulWidget {
  const ApplicationsScreen({super.key});

  @override
  _ApplicationsScreenState createState() => _ApplicationsScreenState();
}

class _ApplicationsScreenState extends State<ApplicationsScreen> {
  bool _loading = true;
  List<Application> _applications = [];
  List<Application> _filteredApplications = [];
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchApplications();
    _searchController.addListener(_filterApplications);
  }

  void _filterApplications() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredApplications = _applications
          .where((app) =>
              app.candidateName.toLowerCase().contains(query) ||
              app.jobTitle.toLowerCase().contains(query))
          .toList();
    });
  }

  Future<void> _fetchApplications() async {
    try {
      final apps = await AdminService.getApplications();
      setState(() {
        _applications = apps;
        _filteredApplications = apps;
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error fetching applications: $e')));
    }
  }

  void _navigateTo(Widget page) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => page));
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: const Color(0xFFf5f7fa),
      body: Row(
        children: [
          // ---------------- Sidebar ----------------
          Container(
            width: 250,
            height: size.height,
            color: Colors.redAccent.shade700,
            child: Column(
              children: [
                const SizedBox(height: 30),
                const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.work, color: Color(0xFF3498db), size: 28),
                    SizedBox(width: 10),
                    Text(
                      "iDraft",
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 30),
                _sidebarItem(Icons.people, "Users", () {
                  if (_applications.isNotEmpty) {
                    _navigateTo(
                        UserListScreen(jobId: _applications.first.jobId));
                  }
                }),
                _sidebarItem(Icons.person_search, "Candidates", () {
                  _navigateTo(CandidatesScreen(jobId: 1));
                }),
                _sidebarItem(Icons.work, "Jobs", () {
                  _navigateTo(const JobListScreen());
                }),
                _sidebarItem(Icons.assignment, "Applications", () {
                  // current page
                }),
                _sidebarItem(Icons.fact_check, "Assessments", () {
                  if (_applications.isNotEmpty) {
                    _navigateTo(
                        AssessmentScreen(jobId: _applications.first.jobId));
                  }
                }),
                const Spacer(),
                _sidebarItem(Icons.logout, "Logout", () {
                  // handle logout
                }),
                const SizedBox(height: 20),
              ],
            ),
          ),

          // ---------------- Main Content ----------------
          Expanded(
            child: Container(
              width: size.width - 250,
              height: size.height,
              color: const Color(0xFFf5f7fa),
              child: Column(
                children: [
                  // Header
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 30, vertical: 20),
                    color: Colors.white,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Applications",
                              style: TextStyle(
                                  color: Color(0xFF2c3e50),
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold),
                            ),
                            SizedBox(height: 4),
                            Text(
                              "Manage all candidate applications",
                              style: TextStyle(
                                color: Color(0xFF7f8c8d),
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                        Container(
                          width: 300,
                          height: 40,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 5,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: TextField(
                            controller: _searchController,
                            style: const TextStyle(color: Colors.black87),
                            decoration: const InputDecoration(
                              hintText: "Search applications...",
                              hintStyle: TextStyle(color: Color(0xFF7f8c8d)),
                              border: InputBorder.none,
                              prefixIcon:
                                  Icon(Icons.search, color: Color(0xFF7f8c8d)),
                              contentPadding:
                                  EdgeInsets.symmetric(vertical: 10),
                            ),
                          ),
                        ),
                        Row(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.notifications,
                                  color: Color(0xFF2c3e50)),
                              onPressed: () {},
                            ),
                            const SizedBox(width: 10),
                            const CircleAvatar(
                              backgroundColor: Color(0xFF3498db),
                              child: Icon(Icons.person, color: Colors.white),
                            ),
                            const SizedBox(width: 10),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Applications List (as cards)
                  Expanded(
                    child: _loading
                        ? const Center(
                            child: CircularProgressIndicator(
                                color: Color(0xFF3498db)))
                        : _filteredApplications.isEmpty
                            ? const Center(
                                child: Text(
                                  'No applications found',
                                  style: TextStyle(
                                      color: Color(0xFF7f8c8d), fontSize: 16),
                                ),
                              )
                            : SingleChildScrollView(
                                padding: const EdgeInsets.all(20),
                                child: Column(
                                  children: _filteredApplications.map((app) {
                                    return Container(
                                      margin: const EdgeInsets.only(bottom: 16),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(12),
                                        boxShadow: [
                                          BoxShadow(
                                            color:
                                                Colors.black.withOpacity(0.05),
                                            blurRadius: 8,
                                            offset: const Offset(0, 2),
                                          ),
                                        ],
                                      ),
                                      child: ListTile(
                                        contentPadding:
                                            const EdgeInsets.symmetric(
                                                horizontal: 20, vertical: 12),
                                        title: Text(
                                          app.candidateName,
                                          style: const TextStyle(
                                              color: Color(0xFF3498db),
                                              fontWeight: FontWeight.bold),
                                        ),
                                        subtitle: Text(
                                          app.jobTitle,
                                          style: const TextStyle(
                                              color: Color(0xFF7f8c8d)),
                                        ),
                                        trailing: IconButton(
                                          icon: const Icon(Icons.remove_red_eye,
                                              color: Color(0xFF2c3e50)),
                                          onPressed: () {
                                            _navigateTo(AssessmentScreen(
                                                jobId: app.id));
                                          },
                                        ),
                                      ),
                                    );
                                  }).toList(),
                                ),
                              ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sidebarItem(IconData icon, String title, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon, color: Colors.white),
      title: Text(title, style: const TextStyle(color: Colors.white)),
      onTap: onTap,
    );
  }
}
