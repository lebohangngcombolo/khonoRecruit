import 'dart:async';
import 'dart:convert';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'package:table_calendar/table_calendar.dart';
import '../../services/admin_service.dart';
import '../../services/auth_service.dart';
import 'candidate_management_screen.dart';
import 'cv_reviews_screen.dart';
import 'interviews_screen.dart';
import 'package:go_router/go_router.dart';
import 'hm_team_collaboration_page.dart';
import 'candidate_list_screen.dart';
import 'interviews_list_screen.dart';
import 'notifications_screen.dart';
import 'job_management.dart';
import 'user_management_screen.dart';
import 'package:http/http.dart' as http;

class AdminDAshboard extends StatefulWidget {
  const AdminDAshboard({super.key});

  @override
  _AdminDAshboardState createState() => _AdminDAshboardState();
}

class _AdminDAshboardState extends State<AdminDAshboard>
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

  // Power BI status
  bool powerBIConnected = false;
  bool checkingPowerBI = true;
  Timer? _statusTimer;

  // --- Audits ---
  List<Map<String, dynamic>> audits = [];
  List<_ChartData> auditTrendData = [];
  int auditPage = 1;
  int auditPerPage = 20;
  String? auditActionFilter;
  DateTime? auditStartDate;
  DateTime? auditEndDate;
  String? auditSearchQuery;
  bool loadingAudits = true;

  TextEditingController auditSearchController = TextEditingController();
  DateTime? filterStartDate;
  DateTime? filterEndDate;
  String? filterAction;

  final List<String> auditActions = [
    "login",
    "logout",
    "create",
    "update",
    "delete"
  ];

  @override
  void initState() {
    super.initState();
    fetchStats();
    fetchPowerBIStatus();
    fetchAudits(page: 1);

    _statusTimer = Timer.periodic(const Duration(seconds: 60), (_) {
      fetchPowerBIStatus();
    });

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
    _statusTimer?.cancel();
    auditSearchController.dispose();
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

  Future<void> fetchPowerBIStatus() async {
    setState(() => checkingPowerBI = true);
    try {
      final token = await AuthService.getAccessToken();
      final res = await http.get(
        Uri.parse("http://127.0.0.1:5000/api/admin/powerbi/status"),
        headers: {"Authorization": "Bearer $token"},
      );

      if (res.statusCode == 200) {
        final data = json.decode(res.body);
        setState(() {
          powerBIConnected = data["connected"] ?? false;
        });
      } else {
        setState(() => powerBIConnected = false);
      }
    } catch (e) {
      setState(() => powerBIConnected = false);
    } finally {
      setState(() => checkingPowerBI = false);
    }
  }

  Future<void> fetchAudits({int page = 1}) async {
    setState(() => loadingAudits = true);
    try {
      final token = await AuthService.getAccessToken();
      final queryParams = {
        "page": page.toString(),
        "per_page": auditPerPage.toString(),
        if (auditActionFilter != null) "action": auditActionFilter!,
        if (auditStartDate != null)
          "start_date":
              "${auditStartDate!.year}-${auditStartDate!.month.toString().padLeft(2, '0')}-${auditStartDate!.day.toString().padLeft(2, '0')}",
        if (auditEndDate != null)
          "end_date":
              "${auditEndDate!.year}-${auditEndDate!.month.toString().padLeft(2, '0')}-${auditEndDate!.day.toString().padLeft(2, '0')}",
        if (auditSearchQuery != null) "q": auditSearchQuery!,
      };
      final uri = Uri.http("127.0.0.1:5000", "/api/admin/audits", queryParams);
      final res =
          await http.get(uri, headers: {"Authorization": "Bearer $token"});

      if (res.statusCode == 200) {
        final data = json.decode(res.body);
        setState(() {
          audits = List<Map<String, dynamic>>.from(data["results"]);
          auditPage = data["page"];
          auditPerPage = data["per_page"];
          auditTrendData = audits
              .map((e) => DateTime.parse(e["timestamp"]))
              .fold<Map<String, int>>({}, (map, dt) {
                final day =
                    "${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}";
                map[day] = (map[day] ?? 0) + 1;
                return map;
              })
              .entries
              .map((e) => _ChartData(e.key, e.value))
              .toList();
          loadingAudits = false;
        });
      } else {
        setState(() => loadingAudits = false);
      }
    } catch (e) {
      setState(() => loadingAudits = false);
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
                                'Shortlisted', 'candidates'),
                            _sidebarEntry(
                                Icons.event_note, 'Interviews', 'interviews'),
                            _sidebarEntry(Icons.assignment_outlined,
                                'CV Reviews', 'cv_reviews'),
                            _sidebarEntry(Icons.history, 'Audits', 'audits'),
                            _sidebarEntry(
                                Icons.security, 'Role Access', 'roles'),
                            _sidebarEntry(Icons.people_outline, 'Candidates',
                                'all_candidates'),
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
                                onPressed: () async {},
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
                              // ---------- Power BI Status Icon ----------
                              Container(
                                width: 36,
                                height: 36,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: powerBIConnected
                                      ? Colors.green
                                      : Colors.red,
                                  boxShadow: [
                                    BoxShadow(
                                      color: powerBIConnected
                                          ? Colors.green.withOpacity(0.6)
                                          : Colors.red.withOpacity(0.6),
                                      blurRadius: 12,
                                      spreadRadius: 2,
                                    ),
                                  ],
                                ),
                                child: Center(
                                  child: checkingPowerBI
                                      ? const SizedBox(
                                          width: 16,
                                          height: 16,
                                          child: CircularProgressIndicator(
                                            color: Colors.white,
                                            strokeWidth: 2,
                                          ),
                                        )
                                      : const Icon(Icons.bar_chart,
                                          color: Colors.white, size: 20),
                                ),
                              ),
                              const SizedBox(width: 8),

                              // ---------- Team Collaboration Icon ----------
                              IconButton(
                                onPressed: () => setState(
                                    () => currentScreen = "team_collaboration"),
                                icon: const Icon(Icons.group_work_outlined,
                                    color: Colors.blueAccent),
                                tooltip: "Team Collaboration",
                              ),
                              const SizedBox(width: 8),

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
        if (selectedJobId == null) {
          return const Center(child: Text("Please select a job first"));
        }
        return CandidateManagementScreen(jobId: selectedJobId!);
      case "interviews":
        return const InterviewListScreen();
      case "cv_reviews":
        return const CVReviewsScreen();
      case "notifications":
        return const NotificationsScreen();
      case "all_candidates": // <-- New case
        return const CandidateListScreen();
      case "team_collaboration":
        return const HMTeamCollaborationPage();

      case "audits":
        return auditsScreen();
      case "roles":
        return const UserManagementScreen();
      default:
        return dashboardOverview();
    }
  }

  /// ------------------- AUDITS SCREEN -------------------
  Widget auditsScreen() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: auditSearchController,
                  decoration: InputDecoration(
                    hintText: "Search audits...",
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.search),
                      onPressed: () {
                        auditSearchQuery = auditSearchController.text;
                        fetchAudits(page: 1);
                      },
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              DropdownButton<String>(
                value: auditActionFilter,
                hint: const Text("Filter Action"),
                items: [null, ...auditActions]
                    .map((e) => DropdownMenuItem<String>(
                          value: e,
                          child: Text(e ?? "All"),
                        ))
                    .toList(),
                onChanged: (val) {
                  setState(() {
                    auditActionFilter = val;
                  });
                  fetchAudits(page: 1);
                },
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            height: 250,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: loadingAudits
                ? const Center(
                    child: CircularProgressIndicator(color: Colors.redAccent))
                : SfCartesianChart(
                    primaryXAxis: CategoryAxis(),
                    primaryYAxis: NumericAxis(),
                    title: ChartTitle(text: 'Audit Trends'),
                    series: <CartesianSeries<_ChartData, String>>[
                      SplineSeries<_ChartData, String>(
                        dataSource: auditTrendData,
                        xValueMapper: (d, _) => d.label,
                        yValueMapper: (d, _) => d.value,
                        color: Colors.purpleAccent,
                        width: 2.5,
                      )
                    ],
                  ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: loadingAudits
                ? const Center(
                    child: CircularProgressIndicator(color: Colors.redAccent))
                : ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: audits.length,
                    separatorBuilder: (_, __) =>
                        const Divider(height: 1, color: Colors.grey),
                    itemBuilder: (context, index) {
                      final audit = audits[index];
                      return ListTile(
                        leading:
                            Icon(Icons.history, color: Colors.purpleAccent),
                        title: Text(audit['action'] ?? ''),
                        subtitle: Text(audit['timestamp'] ?? ''),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget dashboardOverview() {
    if (loadingStats) {
      return const Center(
          child: CircularProgressIndicator(color: Colors.redAccent));
    }

    final stats = [
      {
        "title": "Jobs",
        "count": jobsCount,
        "color": Colors.redAccent,
        "icon": Icons.work
      },
      {
        "title": "Candidates",
        "count": candidatesCount,
        "color": Colors.orangeAccent,
        "icon": Icons.group
      },
      {
        "title": "Interviews",
        "count": interviewsCount,
        "color": Colors.green,
        "icon": Icons.schedule
      },
      {
        "title": "CV Reviews",
        "count": cvReviewsCount,
        "color": Colors.blueAccent,
        "icon": Icons.description
      },
      {
        "title": "Audits",
        "count": auditsCount,
        "color": Colors.purpleAccent,
        "icon": Icons.history
      },
    ];

    final jobsData = List.generate(jobsCount > 0 ? jobsCount : 5, (i) => i + 1);
    final candidatesData = List.generate(
        candidatesCount > 0 ? candidatesCount : 5, (i) => (i + 1) * 2);
    final interviewsData = List.generate(
        interviewsCount > 0 ? interviewsCount : 5, (i) => (i + 1) * 3);
    final cvReviewsData = List.generate(
        cvReviewsCount > 0 ? cvReviewsCount : 5, (i) => (i + 1) * 2);
    final auditsData =
        List.generate(auditsCount > 0 ? auditsCount : 5, (i) => (i + 1));

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
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: stats.length,
                separatorBuilder: (_, __) => const SizedBox(width: 16),
                itemBuilder: (_, index) {
                  final item = stats[index];
                  return kpiCard(item["title"].toString(), item["count"] as int,
                      item["color"] as Color, item["icon"] as IconData);
                },
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
                  chartCard("Jobs", jobsData, Colors.redAccent),
                  chartCard("Candidates", candidatesData, Colors.orangeAccent),
                  chartCard("Interviews", interviewsData, Colors.green),
                  chartCard("CV Reviews", cvReviewsData, Colors.blueAccent),
                  chartCard("Audits", auditsData, Colors.purpleAccent,
                      isLine: true),
                  // ---------- Calendar after Audits ----------
                  calendarCard(),
                  // ---------- Recent Activities ----------
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

  Widget calendarCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      constraints: const BoxConstraints(minHeight: 300, maxHeight: 400),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Calendar", style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Expanded(
            child: TableCalendar(
              focusedDay: focusedDay,
              firstDay: DateTime(2020),
              lastDay: DateTime(2030),
              selectedDayPredicate: (day) => isSameDay(selectedDay, day),
              onDaySelected: (selected, focused) {
                setState(() {
                  selectedDay = selected;
                  focusedDay = focused;
                });
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget activitiesCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      height: 250,
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
                  padding: const EdgeInsets.symmetric(vertical: 4.0),
                  child: Row(
                    children: [
                      const Icon(Icons.circle,
                          size: 8, color: Colors.redAccent),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(recentActivities[index],
                            style: const TextStyle(fontSize: 12)),
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

  Widget kpiCard(String title, int count, Color color, IconData icon) {
    return Container(
      width: 220,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            CircleAvatar(
                backgroundColor: color.withOpacity(0.12),
                child: Icon(icon, color: color)),
            const SizedBox(width: 12),
            Text(title,
                style: TextStyle(
                    color: Colors.grey.shade800, fontWeight: FontWeight.bold)),
          ]),
          const Spacer(),
          Text(count.toString(),
              style:
                  const TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget chartCard(String title, List<int> values, Color color,
      {bool isLine = false}) {
    final chartData = values
        .asMap()
        .entries
        .map((e) => _ChartData('Item ${e.key + 1}', e.value))
        .toList();
    final chartColor = color.withOpacity(0.85);

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
            child: LayoutBuilder(
              builder: (context, constraints) {
                return isLine
                    ? SfCartesianChart(
                        plotAreaBorderWidth: 0,
                        primaryXAxis: CategoryAxis(isVisible: false),
                        primaryYAxis: NumericAxis(isVisible: false),
                        series: <CartesianSeries<_ChartData, String>>[
                          SplineSeries<_ChartData, String>(
                            dataSource: chartData,
                            xValueMapper: (d, _) => d.label,
                            yValueMapper: (d, _) => d.value,
                            color: chartColor,
                            width: 2.5,
                          )
                        ],
                      )
                    : SfCircularChart(
                        legend: Legend(isVisible: true),
                        series: <CircularSeries>[
                          DoughnutSeries<_ChartData, String>(
                            dataSource: chartData,
                            xValueMapper: (d, _) => d.label,
                            yValueMapper: (d, _) => d.value,
                            innerRadius: '70%',
                            radius: '90%',
                          ),
                        ],
                      );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _ChartData {
  final String label;
  final int value;
  _ChartData(this.label, this.value);
}
