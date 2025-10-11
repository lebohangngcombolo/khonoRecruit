import 'package:flutter/material.dart';
import '../../services/admin_service.dart';
import 'candidate_management_screen.dart';
import 'cv_reviews_screen.dart';
import 'interviews_screen.dart';
import 'notifications_screen.dart';
import 'job_management.dart';

// ----------------- Admin Dashboard -----------------
class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  _AdminDashboardState createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  String currentScreen = "dashboard";
  bool loadingStats = true;

  int jobsCount = 0;
  int candidatesCount = 0;
  int interviewsCount = 0;
  int cvReviewsCount = 0;

  int? selectedJobId; // selected job for candidate management

  final AdminService admin = AdminService();

  @override
  void initState() {
    super.initState();
    fetchStats();
  }

  Future<void> fetchStats() async {
    setState(() => loadingStats = true);
    try {
      final jobs = await admin.listJobs();
      final candidates = await admin.listCandidates();
      final interviews = await admin.getAllInterviews();
      final cvReviews = await admin.listCVReviews();

      setState(() {
        jobsCount = jobs.length;
        candidatesCount = candidates.length;
        interviewsCount = interviews.length;
        cvReviewsCount = cvReviews.length;
        loadingStats = false;
      });
    } catch (e) {
      setState(() => loadingStats = false);
      debugPrint("Error fetching dashboard stats: $e");
    }
  }

  Widget dashboardOverview() {
    if (loadingStats) {
      return const Center(child: CircularProgressIndicator(color: Colors.red));
    }

    final stats = [
      {"title": "Jobs", "count": jobsCount, "color": Colors.redAccent},
      {
        "title": "Candidates",
        "count": candidatesCount,
        "color": Colors.orangeAccent
      },
      {"title": "Interviews", "count": interviewsCount, "color": Colors.green},
      {
        "title": "CV Reviews",
        "count": cvReviewsCount,
        "color": Colors.blueAccent
      },
    ];

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Welcome Back, Admin",
            style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 2.5,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16),
              itemCount: stats.length,
              itemBuilder: (_, index) {
                final item = stats[index];
                final Color color = item["color"] as Color;
                return Card(
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                  elevation: 5,
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [color.withOpacity(0.7), color],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(item["title"].toString(),
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.bold)),
                        Text(item["count"].toString(),
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 24,
                                fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget getCurrentScreen() {
    switch (currentScreen) {
      case "jobs":
        return JobManagement(
          onJobSelected: (jobId) {
            setState(() {
              selectedJobId = jobId;
              currentScreen = "candidates";
            });
          },
        );
      case "candidates":
        if (selectedJobId == null) {
          return const Center(child: Text("Please select a job first"));
        }
        return CandidateManagementScreen(jobId: selectedJobId!);
      case "interviews":
        return const InterviewsScreen();
      case "cv_reviews":
        return const CVReviewsScreen();
      case "notifications":
        return const NotificationsScreen();
      default:
        return dashboardOverview();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        title:
            const Text("Admin Dashboard", style: TextStyle(color: Colors.red)),
        elevation: 2,
      ),
      drawer: Drawer(
        child: Container(
          color: Colors.red,
          child: ListView(
            children: [
              const DrawerHeader(
                child: Text("Admin Panel",
                    style: TextStyle(color: Colors.white, fontSize: 24)),
              ),
              drawerItem("Dashboard", "dashboard", Icons.dashboard),
              drawerItem("Jobs", "jobs", Icons.work),
              drawerItem("Candidates", "candidates", Icons.group),
              drawerItem("Interviews", "interviews", Icons.schedule),
              drawerItem("CV Reviews", "cv_reviews", Icons.description),
              drawerItem("Notifications", "notifications", Icons.notifications),
            ],
          ),
        ),
      ),
      body: getCurrentScreen(),
    );
  }

  Widget drawerItem(String title, String screen, IconData icon) {
    return ListTile(
      leading: Icon(icon, color: Colors.white),
      title: Text(title, style: const TextStyle(color: Colors.white)),
      onTap: () {
        setState(() => currentScreen = screen);
        Navigator.pop(context);
      },
    );
  }
}
