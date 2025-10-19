import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'package:syncfusion_flutter_calendar/calendar.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import '../auth/login_screen.dart';

import '../../services/admin_service.dart';
import '../../services/auth_service.dart';
import 'candidate_management_screen.dart';
import 'cv_reviews_screen.dart';
import 'hm_team_collaboration_page.dart';
import 'candidate_list_screen.dart';
import 'interviews_list_screen.dart';
import 'notifications_screen.dart';
import 'job_management.dart';
import 'user_management_screen.dart';

class AdminDAshboard extends StatefulWidget {
  final String token;
  const AdminDAshboard({super.key, required this.token});

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

  // ---------- Profile image state ----------
  XFile? _profileImage;
  Uint8List? _profileImageBytes;
  String _profileImageUrl = "";
  final ImagePicker _picker = ImagePicker();
  final String apiBase = "http://127.0.0.1:5000/api/candidate";

  @override
  void initState() {
    super.initState();
    fetchStats();
    fetchPowerBIStatus();
    fetchAudits(page: 1);
    fetchProfileImage();

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

  // ---------- Profile Image Methods ----------
  Future<void> fetchProfileImage() async {
    try {
      final profileRes = await http.get(
        Uri.parse("$apiBase/profile"),
        headers: {
          'Authorization': 'Bearer ${widget.token}',
          'Content-Type': 'application/json'
        },
      );

      if (profileRes.statusCode == 200) {
        final data = json.decode(profileRes.body)['data'];
        final candidate = data['candidate'] ?? {};
        setState(() {
          _profileImageUrl = candidate['profile_picture'] ?? "";
        });
      }
    } catch (e) {
      debugPrint("Error fetching profile image: $e");
    }
  }

  Future<void> _pickProfileImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      if (kIsWeb) _profileImageBytes = await pickedFile.readAsBytes();
      setState(() => _profileImage = pickedFile);
      await uploadProfileImage();
    }
  }

  Future<void> uploadProfileImage() async {
    if (_profileImage == null) return;
    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse("$apiBase/upload_profile_picture"),
      );
      request.headers['Authorization'] = 'Bearer ${widget.token}';
      request.files.add(
        http.MultipartFile.fromBytes(
          'image',
          kIsWeb
              ? _profileImageBytes!
              : File(_profileImage!.path).readAsBytesSync(),
          filename: _profileImage!.name,
        ),
      );

      var response = await request.send();
      final respStr = await response.stream.bytesToString();
      final respJson = json.decode(respStr);

      if (response.statusCode == 200 && respJson['success'] == true) {
        setState(() {
          _profileImageUrl = respJson['data']['profile_picture'];
          _profileImage = null;
          _profileImageBytes = null;
        });
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Profile picture updated")));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Upload failed: ${response.statusCode}")));
      }
    } catch (e) {
      debugPrint("Profile image upload error: $e");
    }
  }

  ImageProvider<Object> _getProfileImageProvider() {
    if (_profileImage != null) {
      if (kIsWeb) return MemoryImage(_profileImageBytes!);
      return FileImage(File(_profileImage!.path));
    }
    if (_profileImageUrl.isNotEmpty) return NetworkImage(_profileImageUrl);
    return const AssetImage("assets/images/profile_placeholder.png");
  }

  // ---------- Dashboard Stats & PowerBI ----------
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

  void _showLogoutConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Logout"),
          content: const Text("Are you sure you want to logout?"),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text("Cancel"),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close confirmation dialog first
                _performLogout(context);
              },
              child: const Text("Logout", style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  void _performLogout(BuildContext context) async {
    // Close confirmation dialog immediately
    Navigator.of(context).pop();

    // Perform logout without UI feedback (it's fast enough)
    await AuthService.logout();

    // Navigate after a brief delay to ensure previous navigation is complete
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const LoginScreen()),
          (Route<dynamic> route) => false,
        );
      }
    });
  }

// Add this variable to your widget state
  bool _isLoggingOut = false;

  // ---------- UI Build ----------
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
                                  GestureDetector(
                                    onTap: () {
                                      context.push(
                                          '/profile?token=${widget.token}');
                                    },
                                    child: CircleAvatar(
                                      radius: 18,
                                      backgroundColor: Colors.grey.shade200,
                                      backgroundImage:
                                          _getProfileImageProvider(),
                                      child: _getProfileImageProvider() == null
                                          ? const Icon(Icons.person,
                                              color: Colors.redAccent)
                                          : null,
                                    ),
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
                                child: GestureDetector(
                                  onTap: () {
                                    context
                                        .push('/profile?token=${widget.token}');
                                  },
                                  child: CircleAvatar(
                                    radius: 18,
                                    backgroundColor: Colors.grey.shade200,
                                    backgroundImage: _getProfileImageProvider(),
                                    child: _getProfileImageProvider() == null
                                        ? const Icon(Icons.person,
                                            color: Colors.redAccent)
                                        : null,
                                  ),
                                ),
                              ),
                            const SizedBox(height: 12),
                            if (!sidebarCollapsed)
                              ElevatedButton.icon(
                                onPressed: () =>
                                    _showLogoutConfirmation(context),
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
                                onPressed: () =>
                                    _showLogoutConfirmation(context),
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
                              GestureDetector(
                                onTap: () {
                                  context
                                      .push('/profile?token=${widget.token}');
                                },
                                child: CircleAvatar(
                                  radius: 18,
                                  backgroundColor: Colors.grey.shade200,
                                  backgroundImage: _getProfileImageProvider(),
                                  child: _getProfileImageProvider() == null
                                      ? const Icon(Icons.person,
                                          color: Colors.redAccent)
                                      : null,
                                ),
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
        color: selected
            ? const Color.fromRGBO(151, 18, 8, 1).withOpacity(0.06)
            : Colors.transparent,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        child: Row(
          children: [
            Icon(icon,
                color: selected
                    ? const Color.fromRGBO(151, 18, 8, 1)
                    : Colors.grey.shade800),
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
      case "all_candidates":
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
    // Sample data for stacked lines - different audit types
    final List<StackedLineData> stackedAuditData = [
      StackedLineData('Jan', 12, 8, 5, 3, 2),
      StackedLineData('Feb', 15, 10, 7, 4, 3),
      StackedLineData('Mar', 18, 12, 9, 6, 4),
      StackedLineData('Apr', 14, 9, 6, 5, 3),
      StackedLineData('May', 20, 15, 11, 7, 5),
      StackedLineData('Jun', 22, 16, 12, 8, 6),
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: const [
                  Icon(Icons.analytics_outlined,
                      color: Colors.redAccent, size: 28),
                  SizedBox(width: 8),
                  Text(
                    "Audit Analytics Dashboard",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.redAccent.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Row(
                  children: [
                    Icon(Icons.history, color: Colors.redAccent, size: 18),
                    const SizedBox(width: 6),
                    Text(
                      "${audits.length} Records",
                      style: TextStyle(
                          color: Colors.redAccent, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Search and filters
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: auditSearchController,
                  decoration: InputDecoration(
                    hintText: "Search audit logs...",
                    prefixIcon: const Icon(Icons.search),
                    filled: true,
                    fillColor: Colors.white.withOpacity(0.6),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 10),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  onSubmitted: (val) {
                    auditSearchQuery = val;
                    fetchAudits(page: 1);
                  },
                ),
              ),
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.6),
                  borderRadius: BorderRadius.circular(30),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: auditActionFilter,
                    hint: const Text("Action Type"),
                    items: [null, ...auditActions]
                        .map((e) => DropdownMenuItem<String>(
                              value: e,
                              child: Text(e ?? "All"),
                            ))
                        .toList(),
                    onChanged: (val) {
                      setState(() => auditActionFilter = val);
                      fetchAudits(page: 1);
                    },
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Stacked Line Chart for Audits
          Container(
            height: 300,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.redAccent.withOpacity(0.1),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            padding: const EdgeInsets.all(16),
            child: loadingAudits
                ? const Center(
                    child: CircularProgressIndicator(color: Colors.redAccent))
                : SfCartesianChart(
                    title: ChartTitle(
                        text: "Audit Activity Trend - Stacked Lines",
                        textStyle: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: Colors.black87)),
                    plotAreaBorderWidth: 0,
                    primaryXAxis: CategoryAxis(
                      axisLine: const AxisLine(width: 1, color: Colors.grey),
                      majorGridLines: const MajorGridLines(width: 0),
                      labelStyle: const TextStyle(color: Colors.black54),
                    ),
                    primaryYAxis: NumericAxis(
                      axisLine: const AxisLine(width: 1, color: Colors.grey),
                      majorGridLines: MajorGridLines(
                        color: Colors.grey.shade300,
                        width: 1,
                      ),
                      labelStyle: const TextStyle(color: Colors.black54),
                    ),
                    tooltipBehavior: TooltipBehavior(
                      enable: true,
                      color: Colors.redAccent,
                      borderColor: Colors.redAccent,
                      textStyle: const TextStyle(color: Colors.white),
                    ),
                    legend: Legend(
                      isVisible: true,
                      position: LegendPosition.bottom,
                      overflowMode: LegendItemOverflowMode.wrap,
                    ),
                    series: <CartesianSeries<StackedLineData, String>>[
                      StackedLineSeries<StackedLineData, String>(
                        dataSource: stackedAuditData,
                        xValueMapper: (data, _) => data.month,
                        yValueMapper: (data, _) => data.login,
                        name: 'Login',
                        color: Colors.redAccent,
                        width: 3,
                        markerSettings: const MarkerSettings(isVisible: true),
                      ),
                      StackedLineSeries<StackedLineData, String>(
                        dataSource: stackedAuditData,
                        xValueMapper: (data, _) => data.month,
                        yValueMapper: (data, _) => data.logout,
                        name: 'Logout',
                        color: Colors.orangeAccent,
                        width: 3,
                        markerSettings: const MarkerSettings(isVisible: true),
                      ),
                      StackedLineSeries<StackedLineData, String>(
                        dataSource: stackedAuditData,
                        xValueMapper: (data, _) => data.month,
                        yValueMapper: (data, _) => data.create,
                        name: 'Create',
                        color: Colors.green,
                        width: 3,
                        markerSettings: const MarkerSettings(isVisible: true),
                      ),
                      StackedLineSeries<StackedLineData, String>(
                        dataSource: stackedAuditData,
                        xValueMapper: (data, _) => data.month,
                        yValueMapper: (data, _) => data.update,
                        name: 'Update',
                        color: Colors.blueAccent,
                        width: 3,
                        markerSettings: const MarkerSettings(isVisible: true),
                      ),
                      StackedLineSeries<StackedLineData, String>(
                        dataSource: stackedAuditData,
                        xValueMapper: (data, _) => data.month,
                        yValueMapper: (data, _) => data.delete,
                        name: 'Delete',
                        color: Colors.purpleAccent,
                        width: 3,
                        markerSettings: const MarkerSettings(isVisible: true),
                      ),
                    ],
                  ),
          ),
          const SizedBox(height: 24),

          // Audit Log List
          Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.7),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  blurRadius: 15,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            padding: const EdgeInsets.all(12),
            child: loadingAudits
                ? const Center(
                    child: CircularProgressIndicator(color: Colors.redAccent))
                : ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    separatorBuilder: (_, __) =>
                        Divider(color: Colors.grey.shade200, height: 1),
                    itemCount: audits.length,
                    itemBuilder: (context, index) {
                      final audit = audits[index];
                      final action = audit['action'] ?? 'Unknown';
                      final timestamp = audit['timestamp'] ?? '';
                      final user = audit['user'] ?? 'System';
                      final icon = {
                            "login": Icons.login,
                            "logout": Icons.logout,
                            "create": Icons.add_circle_outline,
                            "update": Icons.edit_outlined,
                            "delete": Icons.delete_outline
                          }[action] ??
                          Icons.info_outline;

                      final color = {
                            "login": Colors.green,
                            "logout": Colors.orange,
                            "create": Colors.blueAccent,
                            "update": Colors.purpleAccent,
                            "delete": Colors.redAccent
                          }[action] ??
                          Colors.grey;

                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: color.withOpacity(0.15),
                          child: Icon(icon, color: color),
                        ),
                        title: Text(
                          "${action.toUpperCase()} • $user",
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        subtitle: Text(
                          timestamp,
                          style: TextStyle(color: Colors.grey.shade600),
                        ),
                        trailing: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: color.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            action,
                            style: TextStyle(
                                color: color, fontWeight: FontWeight.w600),
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

    // Sample data for charts
    final departmentData = [
      _DepartmentData('IT', 35, Colors.redAccent),
      _DepartmentData('Finance', 28, Colors.redAccent.shade200),
      _DepartmentData('Data Science', 22, Colors.redAccent.shade400),
      _DepartmentData('Marketing', 18, Colors.redAccent.shade100),
      _DepartmentData('HR', 15, Colors.red.shade300),
    ];

    final candidateHistogramData = [
      _HistogramData('Software Engineer', 45),
      _HistogramData('Data Analyst', 32),
      _HistogramData('Financial Analyst', 28),
      _HistogramData('Marketing Manager', 22),
      _HistogramData('HR Specialist', 18),
    ];

    final interviewData = [
      _InterviewData('Scheduled', 25),
      _InterviewData('Rescheduled', 12),
      _InterviewData('Cancelled', 8),
    ];

    final cvReviewData = [
      _CvReviewData('Week 1', 15, 12),
      _CvReviewData('Week 2', 22, 18),
      _CvReviewData('Week 3', 18, 15),
      _CvReviewData('Week 4', 25, 20),
      _CvReviewData('Week 5', 30, 25),
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

            // FIXED: KPI Cards with proper height constraint
            SizedBox(
              height: 140, // Increased height to prevent overflow
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

            // FIXED: Grid layout with proper constraints
            LayoutBuilder(builder: (context, constraints) {
              int crossAxisCount = constraints.maxWidth > 900 ? 2 : 1;
              double aspectRatio = constraints.maxWidth > 900
                  ? 1.8
                  : 1.6; // Adjusted aspect ratio
              return GridView.count(
                crossAxisCount: crossAxisCount,
                shrinkWrap: true,
                childAspectRatio: aspectRatio,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                physics: const NeverScrollableScrollPhysics(),
                padding:
                    const EdgeInsets.only(bottom: 20), // Added bottom padding
                children: [
                  // Jobs by Department - Radial Bar with Image
                  departmentRadialChart(departmentData),
                  // Candidates Histogram
                  candidateHistogram(candidateHistogramData),
                  // Interviews Column Chart
                  interviewColumnChart(interviewData),
                  // CV Reviews Mixed Chart
                  cvReviewsMixedChart(cvReviewData),
                  // FIXED: Calendar with proper height constraint
                  modernCalendarCard(),
                  // Recent Activities
                  activitiesCard(),
                ],
              );
            }),
          ],
        ),
      ),
    );
  }

  // NEW: Department Radial Bar Chart with Image Placeholder
  Widget departmentRadialChart(List<_DepartmentData> data) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "Jobs by Department",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Colors.black87,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.redAccent.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  "Distribution",
                  style: TextStyle(
                    color: Colors.redAccent,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Expanded(
            child: Stack(
              alignment: Alignment.center,
              children: [
                SfCircularChart(
                  tooltipBehavior: TooltipBehavior(
                    enable: true,
                    color: Colors.redAccent,
                  ),
                  series: <CircularSeries>[
                    RadialBarSeries<_DepartmentData, String>(
                      dataSource: data,
                      xValueMapper: (d, _) => d.department,
                      yValueMapper: (d, _) => d.count,
                      maximumValue: 50,
                      trackOpacity: 0.3,
                      trackColor: Colors.grey.shade200,
                      trackBorderWidth: 0,
                      cornerStyle: CornerStyle.bothCurve,
                      gap: '8%',
                      innerRadius: '60%',
                      radius: '90%',
                      pointColorMapper: (d, _) => d.color,
                      dataLabelSettings: const DataLabelSettings(
                        isVisible: true,
                        textStyle: TextStyle(
                            fontSize: 10, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
                // Image placeholder in the center
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: Colors.redAccent.withOpacity(0.1),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.redAccent, width: 2),
                  ),
                  child: const Icon(
                    Icons.work_outline,
                    color: Colors.redAccent,
                    size: 30,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // NEW: Candidate Histogram (replaces Pyramid)
  Widget candidateHistogram(List<_HistogramData> data) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "Candidates by Job Role",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Colors.black87,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.redAccent.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  "Histogram",
                  style: TextStyle(
                    color: Colors.redAccent,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Expanded(
            child: SfCartesianChart(
              plotAreaBorderWidth: 0,
              primaryXAxis: CategoryAxis(
                axisLine: const AxisLine(width: 0),
                majorGridLines: const MajorGridLines(width: 0),
                labelStyle: const TextStyle(fontSize: 10),
              ),
              primaryYAxis: NumericAxis(
                axisLine: const AxisLine(width: 0),
                majorGridLines: const MajorGridLines(width: 0),
                labelStyle: const TextStyle(fontSize: 10),
              ),
              tooltipBehavior: TooltipBehavior(
                enable: true,
                color: Colors.redAccent,
              ),
              series: <CartesianSeries<_HistogramData, String>>[
                ColumnSeries<_HistogramData, String>(
                  dataSource: data,
                  xValueMapper: (d, _) => d.jobRole,
                  yValueMapper: (d, _) => d.candidateCount,
                  color: Colors.redAccent,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(4),
                    topRight: Radius.circular(4),
                  ),
                  dataLabelSettings: const DataLabelSettings(
                    isVisible: true,
                    textStyle:
                        TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                  ),
                )
              ],
            ),
          ),
        ],
      ),
    );
  }

  // NEW: Interview Column Chart
  Widget interviewColumnChart(List<_InterviewData> data) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "Interview Status",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Colors.black87,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.redAccent.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  "Overview",
                  style: TextStyle(
                    color: Colors.redAccent,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Expanded(
            child: SfCartesianChart(
              plotAreaBorderWidth: 0,
              primaryXAxis: CategoryAxis(
                axisLine: const AxisLine(width: 0),
                majorGridLines: const MajorGridLines(width: 0),
              ),
              primaryYAxis: NumericAxis(
                axisLine: const AxisLine(width: 0),
                majorGridLines: const MajorGridLines(width: 0),
              ),
              tooltipBehavior: TooltipBehavior(
                enable: true,
                color: Colors.redAccent,
              ),
              series: <CartesianSeries<_InterviewData, String>>[
                ColumnSeries<_InterviewData, String>(
                  dataSource: data,
                  xValueMapper: (d, _) => d.status,
                  yValueMapper: (d, _) => d.count,
                  color: Colors.redAccent,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(4),
                    topRight: Radius.circular(4),
                  ),
                  dataLabelSettings: const DataLabelSettings(
                    isVisible: true,
                    textStyle:
                        TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                  ),
                )
              ],
            ),
          ),
        ],
      ),
    );
  }

  // NEW: CV Reviews Mixed Chart (Line + Bar)
  Widget cvReviewsMixedChart(List<_CvReviewData> data) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "CV Reviews Trend",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Colors.black87,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.redAccent.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  "Weekly",
                  style: TextStyle(
                    color: Colors.redAccent,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Expanded(
            child: SfCartesianChart(
              plotAreaBorderWidth: 0,
              primaryXAxis: CategoryAxis(
                axisLine: const AxisLine(width: 0),
                majorGridLines: const MajorGridLines(width: 0),
              ),
              primaryYAxis: NumericAxis(
                axisLine: const AxisLine(width: 0),
                majorGridLines: const MajorGridLines(width: 0),
              ),
              tooltipBehavior: TooltipBehavior(
                enable: true,
                color: Colors.redAccent,
              ),
              series: <CartesianSeries<_CvReviewData, String>>[
                ColumnSeries<_CvReviewData, String>(
                  dataSource: data,
                  xValueMapper: (d, _) => d.week,
                  yValueMapper: (d, _) => d.reviewsCompleted,
                  name: 'Completed',
                  color: Colors.redAccent,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(4),
                    topRight: Radius.circular(4),
                  ),
                ),
                LineSeries<_CvReviewData, String>(
                  dataSource: data,
                  xValueMapper: (d, _) => d.week,
                  yValueMapper: (d, _) => d.reviewsPending,
                  name: 'Pending',
                  color: Colors.orangeAccent,
                  width: 3,
                  markerSettings: const MarkerSettings(
                    isVisible: true,
                    color: Colors.orangeAccent,
                    borderWidth: 2,
                    borderColor: Colors.white,
                  ),
                ),
              ],
              legend: Legend(
                isVisible: true,
                position: LegendPosition.bottom,
                overflowMode: LegendItemOverflowMode.wrap,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget modernCalendarCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.blueGrey.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.blue.shade50,
            Colors.purple.shade50,
          ],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Section
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.blueAccent.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.calendar_month,
                        color: Colors.blueAccent, size: 22),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    "Today's Date",
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                      color: Colors.blueAccent,
                    ),
                  ),
                ],
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.blueAccent.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: StreamBuilder(
                  stream: Stream.periodic(const Duration(seconds: 1)),
                  builder: (context, snapshot) {
                    return Text(
                      DateFormat('hh:mm a').format(DateTime.now()),
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Colors.blueAccent,
                        fontSize: 12,
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Today's Date Display Section
          Container(
            height: 140,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Date number
                  Text(
                    DateTime.now().day.toString(),
                    style: const TextStyle(
                      fontSize: 48,
                      fontWeight: FontWeight.w800,
                      color: Colors.blueAccent,
                      height: 1.0,
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Month and Year
                  Text(
                    DateFormat('MMMM yyyy').format(DateTime.now()),
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade700,
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

  Widget _calendarStat(String label, String value, Color color) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(6), // Smaller padding
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.circle_rounded,
            color: color,
            size: 6, // Smaller icon
          ),
        ),
        const SizedBox(height: 4), // Reduced spacing
        Text(
          value,
          style: TextStyle(
            fontSize: 12, // Smaller font
            fontWeight: FontWeight.w600, // Slightly less bold
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 9, // Smaller font
            color: Colors.grey.shade600,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _calendarLegend(Color color, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min, // Prevent horizontal overflow
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          text,
          style: const TextStyle(
              fontSize: 11, fontWeight: FontWeight.w500), // Smaller font
        ),
      ],
    );
  }

  List<Appointment> _getAppointments() {
    final now = DateTime.now();
    return [
      Appointment(
        startTime: now.add(const Duration(days: 1, hours: 10)),
        endTime: now.add(const Duration(days: 1, hours: 11)),
        subject: 'Technical Interview',
        color: Colors.blueAccent,
      ),
      Appointment(
        startTime: now.add(const Duration(days: 2, hours: 14)),
        endTime: now.add(const Duration(days: 2, hours: 15)),
        subject: 'HR Meeting',
        color: Colors.green,
      ),
      Appointment(
        startTime: now.add(const Duration(days: 3, hours: 9)),
        endTime: now.add(const Duration(days: 3, hours: 10)),
        subject: 'CV Review Deadline',
        color: Colors.orange,
      ),
      Appointment(
        startTime: now.add(const Duration(days: 5, hours: 11)),
        endTime: now.add(const Duration(days: 5, hours: 12)),
        subject: 'Candidate Screening',
        color: Colors.purple,
      ),
    ];
  }

  Widget activitiesCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.redAccent.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.timeline,
                    color: Colors.redAccent, size: 20),
              ),
              const SizedBox(width: 8),
              const Text("Recent Activities",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            ],
          ),
          const SizedBox(height: 12),
          // FIXED: Activities list with constrained height
          ConstrainedBox(
            constraints: const BoxConstraints(
              maxHeight: 120, // Fixed maximum height
            ),
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: recentActivities.length,
              itemBuilder: (context, index) {
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: const BoxDecoration(
                          color: Colors.redAccent,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          recentActivities[index],
                          style: const TextStyle(fontSize: 13),
                          overflow:
                              TextOverflow.ellipsis, // Prevent text overflow
                        ),
                      ),
                      Text(
                        DateFormat('HH:mm').format(DateTime.now()
                            .subtract(Duration(minutes: index * 15))),
                        style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 11,
                            fontWeight: FontWeight.w500),
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
      width: 200, // Slightly reduced width
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.1),
            blurRadius: 15,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment:
            MainAxisAlignment.spaceBetween, // Better space distribution
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child:
                    Icon(icon, color: color, size: 20), // Slightly smaller icon
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 6, vertical: 3), // Smaller padding
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  "+${((count / 10) * 100).round()}%",
                  style: TextStyle(
                    color: color,
                    fontSize: 10, // Smaller font
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            count.toString(),
            style: const TextStyle(
              fontSize: 24, // Slightly smaller font
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 13, // Slightly smaller font
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

// Data classes for new charts
class _DepartmentData {
  final String department;
  final int count;
  final Color color;
  _DepartmentData(this.department, this.count, this.color);
}

class _HistogramData {
  final String jobRole;
  final int candidateCount;
  _HistogramData(this.jobRole, this.candidateCount);
}

class _InterviewData {
  final String status;
  final int count;
  _InterviewData(this.status, this.count);
}

class _CvReviewData {
  final String week;
  final int reviewsCompleted;
  final int reviewsPending;
  _CvReviewData(this.week, this.reviewsCompleted, this.reviewsPending);
}

class StackedLineData {
  final String month;
  final int login;
  final int logout;
  final int create;
  final int update;
  final int delete;
  StackedLineData(this.month, this.login, this.logout, this.create, this.update,
      this.delete);
}

class _ChartData {
  final String label;
  final int value;
  _ChartData(this.label, this.value);
}

class _MeetingDataSource extends CalendarDataSource {
  _MeetingDataSource(List<Appointment> source) {
    appointments = source;
  }
}
