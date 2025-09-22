import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import '../../widgets/glass_card.dart';
import 'job_list_screen.dart';
import 'applications_screen.dart';
import 'candidates_screen.dart';
import 'assessment_screen.dart';
import 'user_list_screen.dart';
import '../../services/admin_service.dart';
import '../../models/job_model.dart';
import '../../models/application_model.dart';
import '../../models/user_model.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  _AdminDashboardScreenState createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  bool _loadingJobs = true;
  bool _loadingApplications = true;
  bool _loadingUsers = true;

  List<Job> _jobs = [];
  List<Application> _applications = [];
  List<User> _users = [];

  String _searchQuery = "";
  List<String> _notifications = [
    "New candidate applied",
    "Job expired",
    "Assessment submitted"
  ];
  int _unreadNotifications = 3;

  // Primary red matching sidebar (Colors.redAccent.shade700)
  static const Color _primaryRed = Color(0xFFD50000);
  // Light red accent for backgrounds/highlights
  static const Color _lightRedBg = Color(0xFFFDECEA);

  @override
  void initState() {
    super.initState();
    _fetchJobs();
    _fetchApplications();
    _fetchUsers();
  }

  Future<void> _fetchJobs() async {
    try {
      final jobs = await AdminService.getJobs();
      setState(() {
        _jobs = jobs;
        _loadingJobs = false;
      });
    } catch (e) {
      setState(() => _loadingJobs = false);
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Error fetching jobs: $e')));
    }
  }

  Future<void> _fetchApplications() async {
    try {
      final apps = await AdminService.getApplications();
      setState(() {
        _applications = apps;
        _loadingApplications = false;
      });
    } catch (e) {
      setState(() => _loadingApplications = false);
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error fetching applications: $e')));
    }
  }

  Future<void> _fetchUsers() async {
    try {
      final users = await AdminService.getUsers();
      setState(() {
        _users = users;
        _loadingUsers = false;
      });
    } catch (e) {
      setState(() => _loadingUsers = false);
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Error fetching users: $e')));
    }
  }

  void _navigate(Widget page) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => page));
  }

  void _logout() {
    // TODO: implement logout functionality
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('Logged out successfully')));
  }

  List<Job> get _filteredJobs => _searchQuery.isEmpty
      ? _jobs
      : _jobs
          .where(
              (j) => j.title.toLowerCase().contains(_searchQuery.toLowerCase()))
          .toList();

  List<Application> get _filteredApplications => _searchQuery.isEmpty
      ? _applications
      : _applications
          .where((a) =>
              a.jobTitle.toLowerCase().contains(_searchQuery.toLowerCase()))
          .toList();

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
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Icon(Icons.work, color: Color(0xFFD50000), size: 28),
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
                _sidebarItem(Icons.dashboard, "Dashboard", () {}),
                _sidebarItem(Icons.people, "Users", () {
                  if (_applications.isNotEmpty) {
                    _navigate(UserListScreen(jobId: _applications.first.jobId));
                  }
                }),
                _sidebarItem(Icons.person_search, "Candidates", () {
                  if (_loadingJobs || _jobs.isEmpty) return;
                  _navigate(CandidatesScreen(jobId: _jobs.first.id));
                }),
                _sidebarItem(Icons.fact_check, "Assessments", () {
                  if (_loadingApplications || _applications.isEmpty) return;
                  _navigate(AssessmentScreen(jobId: _applications.first.jobId));
                }),
                _sidebarItem(
                    Icons.work, "Jobs", () => _navigate(const JobListScreen())),
                _sidebarItem(Icons.assignment, "Applications",
                    () => _navigate(const ApplicationsScreen())),
                const Spacer(),
                _sidebarItem(Icons.logout, "Logout", _logout),
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
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: const [
                            Text(
                              "Hi, Admin!",
                              style: TextStyle(
                                  color: Color.fromARGB(255, 211, 0, 0),
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold),
                            ),
                            SizedBox(height: 4),
                            Text(
                              "Welcome to your admin dashboard",
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
                            style: const TextStyle(color: Colors.black87),
                            decoration: const InputDecoration(
                              hintText: "Search jobs/applications",
                              hintStyle: TextStyle(color: Color(0xFF7f8c8d)),
                              border: InputBorder.none,
                              prefixIcon:
                                  Icon(Icons.search, color: Color(0xFF7f8c8d)),
                              contentPadding:
                                  EdgeInsets.symmetric(vertical: 10),
                            ),
                            onChanged: (value) =>
                                setState(() => _searchQuery = value),
                          ),
                        ),
                        Row(
                          children: [
                            Stack(
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.notifications,
                                      color: Color(0xFF2c3e50)),
                                  onPressed: () {
                                    showDialog(
                                      context: context,
                                      builder: (_) => AlertDialog(
                                        title: const Text("Notifications"),
                                        content: SizedBox(
                                          height: 200,
                                          child: ListView(
                                            children: _notifications
                                                .map((n) =>
                                                    ListTile(title: Text(n)))
                                                .toList(),
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                                if (_unreadNotifications > 0)
                                  Positioned(
                                    right: 8,
                                    top: 8,
                                    child: Container(
                                      padding: const EdgeInsets.all(4),
                                      decoration: const BoxDecoration(
                                          color: Colors.red,
                                          shape: BoxShape.circle),
                                      child: Text(
                                        '$_unreadNotifications',
                                        style: const TextStyle(
                                            color: Colors.white, fontSize: 12),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(width: 10),
                            const CircleAvatar(
                              backgroundColor: Color(0xFFD50000),
                              child: Icon(Icons.person, color: Colors.white),
                            ),
                            const SizedBox(width: 10),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Dashboard Metrics + Charts
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        children: [
                          // First Row of Cards
                          Row(
                            children: [
                              // Overall Information Card
                              Expanded(
                                child: _buildCard(
                                  "Overall Information",
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        _jobs.length.toString(),
                                        style: const TextStyle(
                                          fontSize: 32,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFFD50000),
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      const Text(
                                        "Total Jobs",
                                        style: TextStyle(
                                          color: Color(0xFF7f8c8d),
                                        ),
                                      ),
                                      const SizedBox(height: 16),
                                      _buildInfoItem(
                                          Icons.work, "Jobs management system"),
                                      _buildInfoItem(Icons.people,
                                          "${_users.length} Users"),
                                      _buildInfoItem(Icons.assignment,
                                          "${_applications.length} Applications"),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(width: 20),
                              // Weekly Progress Card
                              Expanded(
                                child: _buildCard(
                                  "Weekly Progress",
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        "Active",
                                        style: TextStyle(
                                          color: Color(0xFF7f8c8d),
                                        ),
                                      ),
                                      const SizedBox(height: 10),
                                      Container(
                                        height: 8,
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFecf0f1),
                                          borderRadius:
                                              BorderRadius.circular(4),
                                        ),
                                        child: FractionallySizedBox(
                                          alignment: Alignment.centerLeft,
                                          widthFactor: 0.65,
                                          child: Container(
                                            decoration: BoxDecoration(
                                              color: const Color(0xFFD50000),
                                              borderRadius:
                                                  BorderRadius.circular(4),
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      const Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text("65%",
                                              style: TextStyle(
                                                  color: Color(0xFF7f8c8d))),
                                          Text("Complete",
                                              style: TextStyle(
                                                  color: Color(0xFF7f8c8d))),
                                        ],
                                      ),
                                      const SizedBox(height: 16),
                                      _buildInfoItem(
                                          Icons.work, "Job Postings"),
                                      _buildInfoItem(
                                          Icons.people, "Candidate Reviews"),
                                      _buildInfoItem(Icons.assignment,
                                          "Application Processing"),
                                      _buildInfoItem(Icons.assessment,
                                          "Assessment Grading"),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),

                          // Second Row of Cards
                          Row(
                            children: [
                              // Monthly Progress Card
                              Expanded(
                                child: _buildCard(
                                  "Monthly Progress",
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        "+15% compared to last month",
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFFD50000),
                                        ),
                                      ),
                                      const SizedBox(height: 16),
                                      _buildInfoItem(Icons.access_time,
                                          "Last updated: 12:00 PM"),
                                      const SizedBox(height: 16),
                                      ElevatedButton.icon(
                                        onPressed: () {},
                                        icon: const Icon(Icons.download,
                                            size: 16),
                                        label: const Text("Download Report"),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor:
                                              const Color(0xFFD50000),
                                          foregroundColor: Colors.white,
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(5),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(width: 20),
                              // Monthly Goals Card
                              Expanded(
                                child: _buildCard(
                                  "Monthly Goals",
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      _buildGoalItem("Hire 5 new candidates"),
                                      _buildGoalItem(
                                          "Review all pending applications"),
                                      _buildGoalItem("Create new job postings"),
                                      _buildGoalItem("Update assessment tests"),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),

                          // Tasks in Progress Card
                          _buildCard(
                            "Tasks in Process (${_applications.where((a) => !a.graded).length})",
                            Column(
                              children: [
                                _buildTaskItem(
                                    "Review candidate applications", "Today"),
                                _buildTaskItem(
                                    "Schedule interviews", "Tomorrow"),
                                _buildTaskItem(
                                    "Post new job openings", "This week"),
                                const SizedBox(height: 16),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    TextButton.icon(
                                      onPressed: () {},
                                      icon: const Icon(Icons.archive, size: 16),
                                      label: const Text("Open archive >"),
                                      style: TextButton.styleFrom(
                                        foregroundColor:
                                            const Color(0xFFD50000),
                                      ),
                                    ),
                                    ElevatedButton.icon(
                                      onPressed: () {},
                                      icon: const Icon(Icons.add, size: 16),
                                      label: const Text("Add task"),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor:
                                            const Color(0xFFD50000),
                                        foregroundColor: Colors.white,
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(5),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 20),

                          // Last Projects Card
                          _buildCard(
                            "Recent Projects",
                            Column(
                              children: [
                                _buildProjectItem("User Management System",
                                    "In progress - User management module development"),
                                _buildProjectItem("Assessment Platform",
                                    "Planning - Designing new assessment features"),
                              ],
                            ),
                          ),
                        ],
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

  Widget _buildCard(String title, Widget content) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Color(0xFF2c3e50),
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          content,
        ],
      ),
    );
  }

  Widget _buildInfoItem(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFFD50000), size: 16),
          const SizedBox(width: 10),
          Text(
            text,
            style: const TextStyle(color: Color(0xFF7f8c8d)),
          ),
        ],
      ),
    );
  }

  Widget _buildGoalItem(String goal) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              border: Border.all(color: const Color(0xFFD50000)),
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(width: 10),
          Text(
            goal,
            style: const TextStyle(color: Color(0xFF7f8c8d)),
          ),
        ],
      ),
    );
  }

  Widget _buildTaskItem(String task, String due) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFf8f9fa),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            task,
            style: const TextStyle(color: Color(0xFF2c3e50)),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFFffeded),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              due,
              style: const TextStyle(
                color: Color(0xFFe74c3c),
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProjectItem(String title, String description) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFf8f9fa),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Color(0xFF2c3e50),
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            description,
            style: const TextStyle(
              color: Color(0xFF7f8c8d),
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: _lightRedBg,
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Text(
              "In progress",
              style: TextStyle(
                color: Color(0xFFD50000),
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------- Chart Data Classes ----------------
class JobChartData {
  final String title;
  final int count;
  JobChartData(this.title, this.count);
}

class ApplicationChartData {
  final String jobTitle;
  final int count;
  ApplicationChartData(this.jobTitle, this.count);
}
