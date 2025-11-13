import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:http/http.dart' as http;
import '../../services/admin_service.dart';
import '../../services/auth_service.dart';
import '../../utils/khono_icons.dart';
import '../../constants/app_colors.dart';
import 'candidate_management_screen.dart';
import 'cv_reviews_screen.dart';
import 'interviews_screen.dart';
import 'notifications_screen.dart';
import 'job_management.dart';
import 'hm_analytics_page.dart';
import 'hm_team_collaboration_page.dart';
import 'hm_profile_page.dart';

// Use AppColors for consistency
const Color kPrimaryRed = AppColors.primaryRed;

class HMMainDashboard extends StatefulWidget {
  const HMMainDashboard({super.key});

  @override
  _HMMainDashboardState createState() => _HMMainDashboardState();
}

class _HMMainDashboardState extends State<HMMainDashboard>
    with SingleTickerProviderStateMixin {
  String currentScreen = "dashboard";
  bool loadingStats = true;
  String userName = "User"; // User name for personalized greeting

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
    _loadUserInfo(); // Load user info for greeting

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

  Future<void> _loadUserInfo() async {
    try {
      final userInfo = await AuthService.getUserInfo();
      if (userInfo != null) {
        setState(() {
          // Try to get name from email (before @)
          final email = userInfo['email'] ?? '';
          userName = email.split('@')[0].replaceAll('.', ' ').toUpperCase();
          // Capitalize first letter of each word
          userName = userName
              .split(' ')
              .map((word) => word.isEmpty
                  ? ''
                  : word[0].toUpperCase() + word.substring(1).toLowerCase())
              .join(' ');
        });
      }
    } catch (e) {
      debugPrint("Error loading user info: $e");
    }
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
      body: Stack(
        children: [
          // ---------- Background Image ----------
          Positioned.fill(
            child: Image.asset(
              'assets/images/background_image.png',
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                // Fallback to a gradient background if image fails to load
                return Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        const Color(0xFF1E1E1E),
                        const Color(0xFF2D2D2D),
                        kPrimaryRed.withOpacity(0.1),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          // ---------- Main Content ----------
          SafeArea(
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
                        color: const Color(0xFF1E1E1E).withOpacity(0.85),
                        border: Border(
                          right: BorderSide(
                              color: kPrimaryRed.withOpacity(0.3), width: 1),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: kPrimaryRed.withOpacity(0.15),
                            blurRadius: 20,
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
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 6),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Center(
                                      child: sidebarCollapsed
                                          ? Image.asset(
                                              'assets/images/logo.png',
                                              width: 50,
                                              height: 40,
                                              fit: BoxFit.contain,
                                            )
                                          : Text(
                                              'KHONOLOGY',
                                              style: GoogleFonts.poppins(
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold,
                                                color: kPrimaryRed,
                                                letterSpacing: 3,
                                              ),
                                            ),
                                    ),
                                  ),
                                  if (!sidebarCollapsed)
                                    IconButton(
                                      constraints: const BoxConstraints(),
                                      padding: EdgeInsets.zero,
                                      icon: Icon(
                                        sidebarCollapsed
                                            ? Icons.arrow_forward_ios
                                            : Icons.arrow_back_ios,
                                        size: 16,
                                        color: kPrimaryRed,
                                      ),
                                      onPressed: toggleSidebar,
                                    ),
                                ],
                              ),
                            ),
                          ),
                          Divider(
                              height: 1, color: kPrimaryRed.withOpacity(0.2)),
                          Expanded(
                            child: ListView(
                              padding: EdgeInsets.zero,
                              children: [
                                _sidebarEntry(
                                    Icons.home_outlined, 'Home', 'dashboard'),
                                _sidebarEntry(
                                    Icons.work_outline, 'Jobs', 'jobs'),
                                _sidebarEntry(Icons.people_alt_outlined,
                                    'Candidates', 'candidates'),
                                _sidebarEntry(Icons.event_note, 'Interviews',
                                    'interviews'),
                                _sidebarEntry(Icons.assignment_outlined,
                                    'CV Reviews', 'cv_reviews'),
                                _sidebarEntry(Icons.analytics_outlined,
                                    'Analytics', 'analytics'),
                                _sidebarEntry(Icons.people_outline,
                                    'Team Collaboration', 'team_collaboration'),
                                _sidebarEntry(Icons.notifications_outlined,
                                    'Notifications', 'notifications'),
                              ],
                            ),
                          ),
                          Divider(
                              height: 1, color: kPrimaryRed.withOpacity(0.2)),
                          if (sidebarCollapsed)
                            Center(
                              child: IconButton(
                                icon: const Icon(Icons.arrow_forward_ios,
                                    size: 16),
                                color: kPrimaryRed,
                                onPressed: toggleSidebar,
                                tooltip: 'Expand Sidebar',
                              ),
                            ),
                          Padding(
                            padding: const EdgeInsets.symmetric(
                                vertical: 12.0, horizontal: 8),
                            child: Column(
                              children: [
                                InkWell(
                                  onTap: () =>
                                      setState(() => currentScreen = "profile"),
                                  borderRadius: BorderRadius.circular(8),
                                  child: Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: currentScreen == "profile"
                                          ? kPrimaryRed.withOpacity(0.2)
                                          : Colors.transparent,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: !sidebarCollapsed
                                        ? Row(
                                            children: [
                                              Container(
                                                width: 32,
                                                height: 32,
                                                decoration: BoxDecoration(
                                                  shape: BoxShape.circle,
                                                  border: Border.all(
                                                      color: kPrimaryRed,
                                                      width: 2),
                                                  color: Colors.grey.shade900,
                                                ),
                                                child: const Icon(Icons.person,
                                                    color: kPrimaryRed,
                                                    size: 16),
                                              ),
                                              const SizedBox(width: 12),
                                              Expanded(
                                                child: Text(
                                                  userName,
                                                  style: GoogleFonts.poppins(
                                                    color: Colors.white,
                                                    fontWeight: FontWeight.w600,
                                                    fontSize: 13,
                                                  ),
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                              ),
                                            ],
                                          )
                                        : Center(
                                            child: CircleAvatar(
                                              backgroundColor: kPrimaryRed,
                                              radius: 16,
                                              child: const Icon(Icons.person,
                                                  color: Colors.white,
                                                  size: 16),
                                            ),
                                          ),
                                  ),
                                ),
                                const SizedBox(height: 12),
                                if (!sidebarCollapsed)
                                  ElevatedButton.icon(
                                    onPressed: () {},
                                    icon: Image.asset(
                                      KhonoIcons.logoutIcon,
                                      width: 16,
                                      height: 16,
                                      color: Colors.white,
                                    ),
                                    label: Text("Logout",
                                        style: GoogleFonts.poppins()),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: kPrimaryRed,
                                      foregroundColor: Colors.white,
                                      minimumSize: const Size.fromHeight(40),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    ),
                                  )
                                else
                                  IconButton(
                                    onPressed: () {},
                                    icon: Image.asset(
                                      KhonoIcons.logoutIcon,
                                      width: 20,
                                      height: 20,
                                      color: Colors.grey,
                                    ),
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
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E1E1E).withOpacity(0.75),
                          border: Border(
                            bottom: BorderSide(
                                color: kPrimaryRed.withOpacity(0.3), width: 1),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: kPrimaryRed.withOpacity(0.15),
                              blurRadius: 12,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text("Welcome Back, Hiring Manager",
                                        style: GoogleFonts.poppins(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white)),
                                    const SizedBox(height: 2),
                                    Text("Manage recruitment operations",
                                        style: GoogleFonts.poppins(
                                            color: Colors.grey.shade400,
                                            fontSize: 12)),
                                  ],
                                ),
                              ),
                              Row(
                                children: [
                                  ElevatedButton.icon(
                                    onPressed: () =>
                                        setState(() => currentScreen = "jobs"),
                                    icon: const Icon(Icons.add, size: 18),
                                    label: Text("Create",
                                        style: GoogleFonts.poppins()),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: kPrimaryRed,
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 16, vertical: 12),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  IconButton(
                                    onPressed: () => setState(
                                        () => currentScreen = "notifications"),
                                    icon: const Icon(
                                        Icons.notifications_outlined,
                                        color: Colors.white),
                                  ),
                                  const SizedBox(width: 12),
                                  Container(
                                    width: 36,
                                    height: 36,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                          color: kPrimaryRed, width: 2),
                                      color: Colors.grey.shade900,
                                    ),
                                    child: const Icon(Icons.person,
                                        color: kPrimaryRed, size: 18),
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
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: kPrimaryRed,
        child: const Icon(Icons.refresh, color: Colors.white),
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
        decoration: BoxDecoration(
          color: selected ? kPrimaryRed.withOpacity(0.2) : Colors.transparent,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: kPrimaryRed,
                shape: BoxShape.circle,
                boxShadow: selected
                    ? [
                        BoxShadow(
                          color: kPrimaryRed.withOpacity(0.4),
                          blurRadius: 8,
                          spreadRadius: 1,
                        ),
                      ]
                    : null,
              ),
              child: Icon(
                icon,
                size: 24,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 12),
            if (!sidebarCollapsed)
              Expanded(
                child: Text(
                  label,
                  style: GoogleFonts.poppins(
                    color: selected ? Colors.white : Colors.grey.shade400,
                    fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
                    fontSize: 14,
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
        if (selectedJobId == null || selectedJobId == 0) {
          return const Center(
            child: Text(
              "Please select a job first",
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
          );
        }
        return CandidateManagementScreen(jobId: selectedJobId!);
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
      case "profile":
        return const HmProfilePage();
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
            const SizedBox(height: 16),
            // Personalized Greeting Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF1E1E1E).withOpacity(0.4),
                borderRadius: BorderRadius.circular(12),
                border:
                    Border.all(color: kPrimaryRed.withOpacity(0.5), width: 2),
              ),
              child: Row(
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: kPrimaryRed, width: 3),
                      color: Colors.grey.shade900,
                    ),
                    child: Image.asset(
                      KhonoIcons.hrTeamRed,
                      color: kPrimaryRed,
                      fit: BoxFit.contain,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          "Welcome back, $userName!",
                          style: GoogleFonts.poppins(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "Ready to find top talent today?",
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            color: Colors.grey.shade400,
                          ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: kPrimaryRed.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: kPrimaryRed),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.star, color: kPrimaryRed, size: 16),
                        const SizedBox(width: 4),
                        Text(
                          "Level 1",
                          style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            // Gamification Stats Grid
            GridView.count(
              crossAxisCount: 4,
              shrinkWrap: true,
              mainAxisSpacing: 16,
              crossAxisSpacing: 16,
              childAspectRatio: 1.5,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                _buildStatCard(
                  iconPath: KhonoIcons.projectRed,
                  value: "$jobsCount",
                  label: "Active Jobs",
                  color: kPrimaryRed,
                ),
                _buildStatCard(
                  iconPath: KhonoIcons.approvedRed,
                  value: "$candidatesCount",
                  label: "Shortlisted",
                  color: kPrimaryRed,
                ),
                _buildStatCard(
                  iconPath: KhonoIcons.goalRed,
                  value: "0",
                  label: "Points",
                  color: kPrimaryRed,
                ),
                _buildStatCard(
                  iconPath: KhonoIcons.taskRed,
                  value: "1 days",
                  label: "Current Streak",
                  color: const Color(0xFFFF9800),
                ),
                _buildStatCard(
                  iconPath: KhonoIcons.calendarRed,
                  value: "$interviewsCount",
                  label: "Today's Interviews",
                  color: kPrimaryRed,
                ),
                _buildStatCard(
                  iconPath: KhonoIcons.approvedRed,
                  value: "0",
                  label: "Badges",
                  color: const Color(0xFF4CAF50),
                ),
              ],
            ),
            const SizedBox(height: 32),
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

  // ---------------- Gamification Stat Card ----------------
  Widget _buildStatCard({
    IconData? icon,
    String? iconPath,
    required String value,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E).withOpacity(0.4),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: kPrimaryRed.withOpacity(0.4), width: 1),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 48,
            height: 48,
            padding: iconPath != null ? const EdgeInsets.all(10) : null,
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              shape: BoxShape.circle,
              border: Border.all(color: color, width: 2),
            ),
            child: iconPath != null
                ? Image.asset(
                    iconPath,
                    width: 28,
                    height: 28,
                    color: color,
                    fit: BoxFit.contain,
                  )
                : Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: Colors.grey.shade400,
            ),
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // ---------------- Charts ----------------
  Widget barChartCard(String title, List<_ChartData> data, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E).withOpacity(0.35),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: kPrimaryRed.withOpacity(0.4), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: GoogleFonts.poppins(
                  fontWeight: FontWeight.bold, color: Colors.white),
              overflow: TextOverflow.ellipsis,
              maxLines: 1),
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
        color: const Color(0xFF1E1E1E).withOpacity(0.35),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: kPrimaryRed.withOpacity(0.4), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: GoogleFonts.poppins(
                  fontWeight: FontWeight.bold, color: Colors.white),
              overflow: TextOverflow.ellipsis,
              maxLines: 1),
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
        color: const Color(0xFF1E1E1E).withOpacity(0.35),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: kPrimaryRed.withOpacity(0.4), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: const TextStyle(
                  fontWeight: FontWeight.bold, color: Colors.white),
              overflow: TextOverflow.ellipsis,
              maxLines: 1),
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
        color: const Color(0xFF1E1E1E).withOpacity(0.35),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: kPrimaryRed.withOpacity(0.4), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: GoogleFonts.poppins(
                  fontWeight: FontWeight.bold, color: Colors.white),
              overflow: TextOverflow.ellipsis,
              maxLines: 1),
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
                      Expanded(
                          child: Text(messages[index],
                              style: TextStyle(color: Colors.grey.shade300))),
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
        color: const Color(0xFF1E1E1E).withOpacity(0.35),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: kPrimaryRed.withOpacity(0.4), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Calendar',
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.bold,
              color: Colors.white,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 8),
          TableCalendar(
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
            calendarFormat:
                CalendarFormat.month, // Changed to month view by default
            availableCalendarFormats: const {
              CalendarFormat.month: 'Month',
              CalendarFormat.week: 'Week',
            },
            headerStyle: HeaderStyle(
              formatButtonVisible: true,
              titleCentered: true,
              formatButtonShowsNext: false,
              formatButtonDecoration: BoxDecoration(
                color: kPrimaryRed.withOpacity(0.3),
                borderRadius: BorderRadius.circular(8),
              ),
              formatButtonTextStyle: const TextStyle(
                color: Colors.white,
                fontSize: 12,
              ),
              titleTextStyle: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
              leftChevronIcon:
                  const Icon(Icons.chevron_left, color: Colors.white, size: 20),
              rightChevronIcon: const Icon(Icons.chevron_right,
                  color: Colors.white, size: 20),
            ),
            daysOfWeekStyle: const DaysOfWeekStyle(
              weekdayStyle: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w600),
              weekendStyle: TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                  fontWeight: FontWeight.w600),
            ),
            calendarStyle: CalendarStyle(
              selectedDecoration: BoxDecoration(
                color: kPrimaryRed,
                shape: BoxShape.circle,
              ),
              todayDecoration: BoxDecoration(
                color: kPrimaryRed.withOpacity(0.5),
                shape: BoxShape.circle,
              ),
              defaultTextStyle:
                  const TextStyle(color: Colors.white, fontSize: 12),
              weekendTextStyle:
                  const TextStyle(color: Colors.white70, fontSize: 12),
              outsideTextStyle:
                  const TextStyle(color: Colors.white38, fontSize: 12),
              selectedTextStyle: const TextStyle(
                  color: Colors.white, fontWeight: FontWeight.bold),
              todayTextStyle: const TextStyle(
                  color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget activitiesCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E).withOpacity(0.35),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: kPrimaryRed.withOpacity(0.4), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Recent Activities",
              style: GoogleFonts.poppins(
                  fontWeight: FontWeight.bold, color: Colors.white)),
          const SizedBox(height: 8),
          Expanded(
            child: ListView.builder(
              itemCount: recentActivities.length,
              itemBuilder: (context, index) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        margin: const EdgeInsets.only(top: 6, right: 8),
                        decoration: const BoxDecoration(
                          color: kPrimaryRed,
                          shape: BoxShape.circle,
                        ),
                      ),
                      Expanded(
                        child: Text(
                          recentActivities[index],
                          style: TextStyle(color: Colors.grey.shade300),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 2,
                        ),
                      ),
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
}

// ---------------- Chart Data Model ----------------
class _ChartData {
  final String label;
  final num value;
  _ChartData(this.label, this.value);
}
