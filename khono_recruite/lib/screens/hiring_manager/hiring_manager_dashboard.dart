import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'package:table_calendar/table_calendar.dart';
import '../../services/admin_service.dart';
import '../../services/auth_service.dart';
import 'candidate_management_screen.dart';
import 'cv_reviews_screen.dart';
import 'interviews_screen.dart';
import 'notifications_screen.dart';
import 'job_management.dart';
import 'hm_analytics_page.dart';
import 'hm_team_collaboration_page.dart';
import 'package:http/http.dart' as http;

class HMMainDashboard extends StatefulWidget {
  const HMMainDashboard({super.key});

  @override
  _HMMainDashboardState createState() => _HMMainDashboardState();
}

class _HMMainDashboardState extends State<HMMainDashboard>
    with SingleTickerProviderStateMixin {
  String currentScreen = "dashboard";
  bool loadingStats = true;

  int jobsCount = 0;
  int candidatesCount = 0;
  int interviewsCount = 0;
  int cvReviewsCount = 0;
  int auditsCount = 0;

  int? selectedJobId;

  // Calendar state
  DateTime focusedDay = DateTime.now();
  DateTime selectedDay = DateTime.now();

  final AdminService admin = AdminService();

  List<String> recentActivities = [];

  bool sidebarCollapsed = false;
  late final AnimationController _sidebarAnimController;
  late final Animation<double> _sidebarWidthAnimation;

  // --- Team Collaboration mock data (previously audits) ---
  List<String> teamMessages = [
    "John: Completed the candidate screening.",
    "Mary: Scheduled interviews for next week.",
    "Alex: Uploaded new CVs to review.",
    "Lisa: Updated job descriptions.",
  ];

  @override
  void initState() {
    super.initState();
    fetchStats();

    _sidebarAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );
    _sidebarWidthAnimation = Tween<double>(begin: 260, end: 72).animate(
      CurvedAnimation(parent: _sidebarAnimController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _sidebarAnimController.dispose();
    super.dispose();
  }

  Future<void> fetchStats() async {
    setState(() => loadingStats = true);
    try {
      final counts = await admin.getDashboardCounts();
      final token = await AuthService.getAccessToken();

      final res = await http.get(
        Uri.parse("http://127.0.0.1:5000/api/admin/recent-activities"),
        headers: {"Authorization": "Bearer $token"},
      );

      List<String> activities = [];
      if (res.statusCode == 200) {
        final data = json.decode(res.body);
        activities = List<String>.from(data["recent_activities"] ?? []);
      }

      setState(() {
        jobsCount = counts["jobs"] ?? 0;
        candidatesCount = counts["candidates"] ?? 0;
        interviewsCount = counts["interviews"] ?? 0;
        cvReviewsCount = counts["cv_reviews"] ?? 0;
        auditsCount = counts["audits"] ?? 0;
        recentActivities = activities;
        loadingStats = false;
      });
    } catch (e) {
      setState(() => loadingStats = false);
      debugPrint("Error fetching dashboard stats: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F7FB),
      body: SafeArea(
        child: Row(
          children: [
            // ---------- Collapsible Sidebar ----------
            AnimatedBuilder(
              animation: _sidebarAnimController,
              builder: (context, child) {
                final width = _sidebarWidthAnimation.value;
                return Container(
                  width: width,
                  height: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border(
                      right: BorderSide(color: Colors.grey.shade200, width: 1),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.02),
                        blurRadius: 8,
                        offset: const Offset(2, 0),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      // Sidebar header
                      SizedBox(
                        height: 72,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 6),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Flexible(
                                child: Align(
                                  alignment: Alignment.centerLeft,
                                  child: sidebarCollapsed
                                      ? Image.asset(
                                          'assets/images/icon.png',
                                          height: 40,
                                          fit: BoxFit.contain,
                                        )
                                      : Image.asset(
                                          'assets/images/logo2.png',
                                          height: 40,
                                          fit: BoxFit.contain,
                                        ),
                                ),
                              ),
                              IconButton(
                                constraints: const BoxConstraints(),
                                padding: EdgeInsets.zero,
                                icon: Icon(
                                  sidebarCollapsed
                                      ? Icons.arrow_forward_ios
                                      : Icons.arrow_back_ios,
                                  size: 16,
                                  color: Colors.grey.shade600,
                                ),
                                onPressed: toggleSidebar,
                              ),
                            ],
                          ),
                        ),
                      ),
                      const Divider(height: 1, color: Colors.grey),
                      Expanded(
                        child: ListView(
                          padding: EdgeInsets.zero,
                          children: [
                            _sidebarEntry(
                                Icons.home_outlined, 'Home', 'dashboard'),
                            _sidebarEntry(Icons.work_outline, 'Jobs', 'jobs'),
                            _sidebarEntry(Icons.people_alt_outlined,
                                'Candidates', 'candidates'),
                            _sidebarEntry(
                                Icons.event_note, 'Interviews', 'interviews'),
                            _sidebarEntry(Icons.assignment_outlined,
                                'CV Reviews', 'cv_reviews'),
                            _sidebarEntry(Icons.analytics_outlined, 'Analytics',
                                'analytics'),
                            _sidebarEntry(Icons.group_outlined,
                                'Team Collaboration', 'team_collaboration'),
                            _sidebarEntry(Icons.notifications_active_outlined,
                                'Notifications', 'notifications'),
                          ],
                        ),
                      ),
                      const Divider(height: 1, color: Colors.grey),
                      Padding(
                        padding: const EdgeInsets.symmetric(
                            vertical: 12.0, horizontal: 8),
                        child: Column(
                          children: [
                            if (!sidebarCollapsed)
                              Row(
                                children: [
                                  CircleAvatar(
                                    backgroundColor: Colors.redAccent,
                                    radius: 16,
                                    child: const Icon(Icons.person,
                                        color: Colors.white, size: 16),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      "Admin User",
                                      style: TextStyle(
                                        color: Colors.grey.shade800,
                                        fontWeight: FontWeight.w600,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              )
                            else
                              Center(
                                child: CircleAvatar(
                                  backgroundColor: Colors.redAccent,
                                  radius: 16,
                                  child: const Icon(Icons.person,
                                      color: Colors.white, size: 16),
                                ),
                              ),
                            const SizedBox(height: 12),
                            if (!sidebarCollapsed)
                              ElevatedButton.icon(
                                onPressed: () {},
                                icon: const Icon(Icons.logout, size: 16),
                                label: const Text("Logout"),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.white,
                                  foregroundColor: Colors.redAccent,
                                  side: BorderSide(color: Colors.grey.shade300),
                                  minimumSize: const Size.fromHeight(40),
                                ),
                              )
                            else
                              IconButton(
                                onPressed: () {},
                                icon: const Icon(Icons.logout,
                                    color: Colors.grey),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
            // ---------- Main content ----------
            Expanded(
              child: Column(
                children: [
                  Container(
                    height: 72,
                    color: Colors.white,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text("Welcome Back, Admin",
                                    style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.grey.shade900)),
                                const SizedBox(height: 2),
                                Text("Overview of the recruitment platform",
                                    style: TextStyle(
                                        color: Colors.grey.shade600,
                                        fontSize: 12)),
                              ],
                            ),
                          ),
                          Row(
                            children: [
                              TextButton.icon(
                                onPressed: () =>
                                    setState(() => currentScreen = "jobs"),
                                icon: const Icon(Icons.add_box_outlined,
                                    color: Colors.redAccent),
                                label: const Text("Create",
                                    style: TextStyle(color: Colors.black87)),
                              ),
                              const SizedBox(width: 12),
                              IconButton(
                                onPressed: () => setState(
                                    () => currentScreen = "notifications"),
                                icon: const Icon(Icons.notifications_none),
                              ),
                              const SizedBox(width: 12),
                              CircleAvatar(
                                radius: 18,
                                backgroundColor: Colors.grey.shade200,
                                child: const Icon(Icons.person,
                                    color: Colors.redAccent),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  Expanded(child: getCurrentScreen()),
                ],
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.redAccent,
        child: const Icon(Icons.refresh),
        onPressed: fetchStats,
        tooltip: "Refresh stats",
      ),
    );
  }

  void toggleSidebar() {
    setState(() {
      sidebarCollapsed = !sidebarCollapsed;
      if (sidebarCollapsed) {
        _sidebarAnimController.forward();
      } else {
        _sidebarAnimController.reverse();
      }
    });
  }

  Widget _sidebarEntry(IconData icon, String label, String screenKey) {
    final selected = currentScreen == screenKey;
    return InkWell(
      onTap: () => setState(() => currentScreen = screenKey),
      child: Container(
        color:
            selected ? Colors.redAccent.withOpacity(0.06) : Colors.transparent,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        child: Row(
          children: [
            Icon(icon,
                color: selected ? Colors.redAccent : Colors.grey.shade800),
            const SizedBox(width: 12),
            if (!sidebarCollapsed)
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    color: selected ? Colors.redAccent : Colors.grey.shade800,
                    fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ),
          ],
        ),
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
        return CandidateManagementScreen(jobId: selectedJobId ?? 0);
      case "interviews":
        return InterviewsScreen();
      case "cv_reviews":
        return CVReviewsScreen();
      case "analytics":
        return HMAnalyticsPage();
      case "team_collaboration":
        return HMTeamCollaborationPage();
      case "notifications":
        return NotificationsScreen();
      default:
        return dashboardOverview();
    }
  }

  // ---------------- Dashboard widgets ----------------
  Widget dashboardOverview() {
    if (loadingStats) {
      return const Center(
          child: CircularProgressIndicator(color: Colors.redAccent));
    }

    final candidatePipeline = [
      _ChartData("Applied", 40),
      _ChartData("Screened", 30),
      _ChartData("Interviewed", 20),
      _ChartData("Offered", 10),
      _ChartData("Hired", 5),
    ];

    final timeToFill = [
      _ChartData("Jan", 25),
      _ChartData("Feb", 20),
      _ChartData("Mar", 30),
      _ChartData("Apr", 22),
      _ChartData("May", 18),
    ];

    final genderData = [
      _ChartData("Male", 60),
      _ChartData("Female", 40),
    ];

    final ethnicityData = [
      _ChartData("Black", 50),
      _ChartData("White", 30),
      _ChartData("Asian", 15),
      _ChartData("Other", 5),
    ];

    final sourcePerformance = [
      _ChartData("LinkedIn", 30),
      _ChartData("Referral", 40),
      _ChartData("Job Board", 25),
      _ChartData("Other", 10),
    ];

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            const Text("Welcome Back, Admin",
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            SizedBox(
              height: 120,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  kpiCard("Jobs", jobsCount, Colors.redAccent, Icons.work),
                  kpiCard("Candidates", candidatesCount, Colors.orangeAccent,
                      Icons.group),
                  kpiCard("Interviews", interviewsCount, Colors.green,
                      Icons.schedule),
                  kpiCard("CV Reviews", cvReviewsCount, Colors.blueAccent,
                      Icons.description),
                  kpiCard("Audits", auditsCount, Colors.purpleAccent,
                      Icons.history),
                ],
              ),
            ),
            const SizedBox(height: 24),
            LayoutBuilder(builder: (context, constraints) {
              int crossAxisCount = constraints.maxWidth > 900 ? 2 : 1;
              double aspectRatio = constraints.maxWidth > 900 ? 2.7 : 2.2;
              return GridView.count(
                crossAxisCount: crossAxisCount,
                shrinkWrap: true,
                childAspectRatio: aspectRatio,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  barChartCard("Candidate Pipeline", candidatePipeline,
                      Colors.orangeAccent),
                  lineChartCard(
                      "Time to Fill Trend", timeToFill, Colors.blueAccent),
                  dualDonutCard("Diversity Metrics", genderData, ethnicityData),
                  barChartCard(
                      "Source Performance", sourcePerformance, Colors.green),
                  teamCollaborationCard("Team Collaboration", teamMessages),
                  calendarCard(),
                  activitiesCard(),
                ],
              );
            }),
            const SizedBox(height: 50),
          ],
        ),
      ),
    );
  }

  Widget teamCollaborationWidget() {
    return teamCollaborationCard("Team Collaboration", teamMessages);
  }

  // ---------------- KPI Card ----------------
  Widget kpiCard(String label, int value, Color color, IconData icon) {
    return Container(
      width: 200,
      margin: const EdgeInsets.only(right: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 12),
          Text(value.toString(),
              style: TextStyle(
                  fontSize: 24, fontWeight: FontWeight.bold, color: color)),
          const SizedBox(height: 4),
          Text(label, style: TextStyle(color: Colors.grey.shade600)),
        ],
      ),
    );
  }

  // ---------------- Charts ----------------
  Widget barChartCard(String title, List<_ChartData> data, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Expanded(
            child: SfCartesianChart(
              primaryXAxis: CategoryAxis(),
              series: <ColumnSeries<_ChartData, String>>[
                ColumnSeries<_ChartData, String>(
                  dataSource: data,
                  xValueMapper: (d, _) => d.label,
                  yValueMapper: (d, _) => d.value,
                  color: color,
                )
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget lineChartCard(String title, List<_ChartData> data, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Expanded(
            child: SfCartesianChart(
              primaryXAxis: CategoryAxis(),
              series: <SplineSeries<_ChartData, String>>[
                SplineSeries<_ChartData, String>(
                  dataSource: data,
                  xValueMapper: (d, _) => d.label,
                  yValueMapper: (d, _) => d.value,
                  color: color,
                  width: 2.5,
                )
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget dualDonutCard(
      String title, List<_ChartData> data1, List<_ChartData> data2) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Expanded(
            child: Row(
              children: [
                Expanded(
                  child: SfCircularChart(
                    title: ChartTitle(text: "Gender"),
                    legend: Legend(isVisible: true),
                    series: <DoughnutSeries<_ChartData, String>>[
                      DoughnutSeries<_ChartData, String>(
                        dataSource: data1,
                        xValueMapper: (d, _) => d.label,
                        yValueMapper: (d, _) => d.value,
                        innerRadius: '60%',
                      )
                    ],
                  ),
                ),
                Expanded(
                  child: SfCircularChart(
                    title: ChartTitle(text: "Ethnicity"),
                    legend: Legend(isVisible: true),
                    series: <DoughnutSeries<_ChartData, String>>[
                      DoughnutSeries<_ChartData, String>(
                        dataSource: data2,
                        xValueMapper: (d, _) => d.label,
                        yValueMapper: (d, _) => d.value,
                        innerRadius: '60%',
                      )
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget teamCollaborationCard(String title, List<String> messages) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Expanded(
            child: ListView.builder(
              itemCount: messages.length,
              itemBuilder: (context, index) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CircleAvatar(
                        radius: 8,
                        backgroundColor: Colors.blueAccent,
                      ),
                      const SizedBox(width: 8),
                      Expanded(child: Text(messages[index])),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget calendarCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: TableCalendar(
        firstDay: DateTime.utc(2020, 1, 1),
        lastDay: DateTime.utc(2030, 12, 31),
        focusedDay: focusedDay,
        selectedDayPredicate: (day) => isSameDay(selectedDay, day),
        onDaySelected: (selectedDayValue, focusedDayValue) {
          setState(() {
            selectedDay = selectedDayValue;
            focusedDay = focusedDayValue;
          });
        },
      ),
    );
  }

  Widget activitiesCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Recent Activities",
              style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Expanded(
            child: ListView.builder(
              itemCount: recentActivities.length,
              itemBuilder: (context, index) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Text(recentActivities[index]),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------- Chart Data Model ----------------
class _ChartData {
  final String label;
  final num value;
  _ChartData(this.label, this.value);
}
