import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

import '../../widgets/custom_card.dart';
import '../../providers/theme_provider.dart';
import 'job_details_page.dart';
import '../../services/candidate_service.dart';
import 'assessments_results_screen.dart';

class CandidateDashboard extends StatefulWidget {
  final String token;
  const CandidateDashboard({super.key, required this.token});

  @override
  _CandidateDashboardState createState() => _CandidateDashboardState();
}

class _CandidateDashboardState extends State<CandidateDashboard> {
  int selectedIndex = 0;
  List<String> sidebarItems = [
    "Dashboard",
    "Jobs Applied",
    "Assessment Results",
    "Profile",
  ];

  List<Map<String, dynamic>> availableJobs = [];
  bool loadingJobs = true;

  @override
  void initState() {
    super.initState();
    fetchAvailableJobs();
  }

  Future<void> fetchAvailableJobs() async {
    setState(() => loadingJobs = true);
    try {
      final jobs = await CandidateService.getAvailableJobs(widget.token);
      setState(() {
        availableJobs = List<Map<String, dynamic>>.from(jobs);
      });
    } catch (e) {
      debugPrint("Error fetching jobs: $e");
    } finally {
      setState(() => loadingJobs = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return Scaffold(
      body: Row(
        children: [
          // ---------------- Glass Sidebar ----------------
          Container(
            width: 220,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: const BorderRadius.only(
                  topRight: Radius.circular(24),
                  bottomRight: Radius.circular(24)),
              border: Border.all(color: Colors.white.withOpacity(0.2)),
            ),
            child: Column(
              children: [
                const SizedBox(height: 40),
                const Text(
                  "Khono Recruite",
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 40),
                ...List.generate(
                  sidebarItems.length,
                  (index) => ListTile(
                    leading: Icon(
                      index == 0
                          ? Icons.dashboard
                          : index == 1
                              ? Icons.work_outline
                              : index == 2
                                  ? Icons.assessment
                                  : Icons.person,
                      color: Colors.white,
                    ),
                    title: Text(
                      sidebarItems[index],
                      style: const TextStyle(color: Colors.white),
                    ),
                    selected: selectedIndex == index,
                    selectedTileColor: Colors.red.shade700.withOpacity(0.5),
                    onTap: () => setState(() => selectedIndex = index),
                  ),
                ),
                const Spacer(),
                ListTile(
                  leading: const Icon(Icons.logout, color: Colors.white),
                  title: const Text("Logout",
                      style: TextStyle(color: Colors.white)),
                  onTap: () {},
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),

          // ---------------- Main Content ----------------
          Expanded(
            child: Column(
              children: [
                // ---------- Top Navbar ----------
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  height: 70,
                  color: themeProvider.isDarkMode
                      ? Colors.grey.shade900
                      : Colors.white,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.search, color: Colors.red),
                        onPressed: () {},
                      ),
                      Stack(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.notifications,
                                color: Colors.red),
                            onPressed: () {},
                          ),
                          Positioned(
                            right: 8,
                            top: 8,
                            child: Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                color: Colors.red,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                        ],
                      ),
                      IconButton(
                        icon: Icon(
                          themeProvider.isDarkMode
                              ? Icons.light_mode
                              : Icons.dark_mode,
                          color: Colors.red,
                        ),
                        onPressed: () => themeProvider.toggleTheme(),
                      ),
                    ],
                  ),
                ),

                // ---------- Dashboard Body ----------
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: getSelectedPage(),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget getSelectedPage() {
    switch (selectedIndex) {
      case 0:
        return dashboardPage();
      case 1:
        return jobsAppliedPage();
      case 2:
        return AssessmentResultsPage(token: widget.token);
      case 3:
        return profilePage();
      default:
        return dashboardPage();
    }
  }

  // ---------- Pages ----------
  Widget dashboardPage() {
    if (loadingJobs) {
      return const Center(child: CircularProgressIndicator());
    }

    if (availableJobs.isEmpty) {
      return const Center(child: Text("No jobs available at the moment"));
    }

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Available Jobs",
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 16,
            runSpacing: 16,
            children: availableJobs.map((job) {
              return SizedBox(
                width: 300,
                height: 180,
                child: CustomCard(
                  title: job["title"] ?? "",
                  subtitle:
                      "${job["company"] ?? ""} - ${job["location"] ?? ""}",
                  color: Colors.red.shade50,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => JobDetailsPage(job: job),
                      ),
                    );
                  },
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget jobsAppliedPage() {
    return const Center(child: Text("Jobs Applied Page"));
  }

  Widget profilePage() {
    return const Center(child: Text("Profile Page"));
  }
}
