import 'dart:io' as io;
import 'dart:html' as html; // For web download
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'dart:convert'; // ✅ Needed for json.decode
import 'package:intl/intl.dart';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';
import '../../services/admin_service.dart';
import '../../widgets/custom_button.dart';
import 'interview_schedule_page.dart';
import 'package:http/http.dart' as http;

class CandidateDetailScreen extends StatefulWidget {
  final int candidateId;
  final int applicationId;

  const CandidateDetailScreen({
    super.key,
    required this.candidateId,
    required this.applicationId,
  });

  @override
  _CandidateDetailScreenState createState() => _CandidateDetailScreenState();
}

class _CandidateDetailScreenState extends State<CandidateDetailScreen>
    with SingleTickerProviderStateMixin {
  final AdminService admin = AdminService();
  Map<String, dynamic>? candidateData;
  List<Map<String, dynamic>> interviews = [];
  bool loading = true;
  String? errorMessage;
  String currentScreen = "candidates";

  late final AnimationController _hoverController;
  late final Animation<double> _hoverAnimation;

  @override
  void initState() {
    super.initState();
    fetchAllData();

    _hoverController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
      lowerBound: 0.0,
      upperBound: 0.05,
    );
    _hoverAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(parent: _hoverController, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _hoverController.dispose();
    super.dispose();
  }

  Future<void> fetchAllData() async {
    setState(() {
      loading = true;
      errorMessage = null;
    });

    try {
      final data = await admin.getApplication(widget.applicationId);
      final application = data['application'] ?? {};
      final assessment = data['assessment'] ?? {};

      candidateData = {
        "full_name": application['full_name'] ?? 'Unnamed',
        "email": application['email'] ?? '',
        "phone": application['phone'] ?? '',
        "cv_score": application['cv_score'] ?? 0,
        "cv_file": application['cv_url'] ?? '',
        "education": application['education'] ?? '',
        "skills": application['skills'] ?? '',
        "work_experience": application['work_experience'] ?? '',
        "assessment_score": assessment['score'] ?? 'N/A',
        "assessment_recommendation": assessment['recommendation'] ?? 'N/A',
        "status": application['status'] ?? 'Pending',
      };

      final interviewData =
          await admin.getCandidateInterviews(widget.candidateId);
      interviews = List<Map<String, dynamic>>.from(interviewData);
    } catch (e) {
      debugPrint("Error fetching candidate details: $e");
      errorMessage = "Failed to load data: $e";
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Error: $e")));
    } finally {
      setState(() => loading = false);
    }
  }

  Future<void> downloadCV(int candidateId, BuildContext context,
      String fullName, String jwtToken) async {
    try {
      // 1️⃣ Fetch CV URL from backend
      final response = await http.get(
        Uri.parse(
            'http://127.0.0.1:5000/api/admin/candidates/$candidateId/download-cv'),
        headers: {
          'Authorization': 'Bearer $jwtToken',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode != 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Failed to get CV URL from backend")),
        );
        return;
      }

      final data = json.decode(response.body);
      final cvUrl = data['cv_url'];

      if (cvUrl == null || cvUrl.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("CV URL is invalid")),
        );
        return;
      }

      // 2️⃣ Download CV
      if (kIsWeb) {
        // Web: use anchor tag to trigger download
        final anchor = html.AnchorElement(href: cvUrl)
          ..setAttribute("download", "cv_$fullName.pdf")
          ..click();

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Download started")),
        );
      } else {
        // Mobile/Desktop: use Dio to download
        final dir = await getApplicationDocumentsDirectory();
        final savePath = "${dir.path}/cv_$fullName.pdf";

        await Dio().download(cvUrl, savePath);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("CV downloaded successfully")),
        );

        // Open the downloaded file
        await OpenFile.open(savePath);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error downloading CV: $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: buildSidebar(),
      appBar: AppBar(
        title: Text(candidateData?['full_name'] ?? "Candidate Details"),
        backgroundColor: Colors.redAccent,
        elevation: 0,
      ),
      body: Container(
        color: const Color(0xFF1C1C28),
        child: loading
            ? const Center(
                child: CircularProgressIndicator(color: Colors.redAccent))
            : errorMessage != null
                ? Center(
                    child: Text(errorMessage!,
                        style: const TextStyle(color: Colors.white)),
                  )
                : _buildTilesGrid(),
      ),
    );
  }

  Widget _buildTilesGrid() {
    final List<Widget> tiles = [
      // Candidate Info
      _buildTile(
        icon: Icons.person_outline,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _dashboardText(candidateData!['full_name'], 20, FontWeight.bold),
            const SizedBox(height: 6),
            _dashboardInfo("Email", candidateData!['email']),
            _dashboardInfo("Phone", candidateData!['phone']),
            _dashboardInfo("Status", candidateData!['status'],
                bold: true,
                color: candidateData!['status'] == "hired"
                    ? Colors.greenAccent
                    : Colors.orangeAccent),
          ],
        ),
      ),

      // CV Info
      _buildTile(
        icon: Icons.insert_drive_file_outlined,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _dashboardInfo("CV Score", candidateData!['cv_score'].toString()),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: () {
                downloadCV(
                  candidateData!['candidate_id'], // Must match backend field
                  context,
                  candidateData!['full_name'] ?? "candidate",
                  "YOUR_JWT_TOKEN_HERE", // Pass actual JWT
                );
              },
              child: const Text("Download CV"),
            )
          ],
        ),
      ),

      // Education & Skills
      _buildTile(
        icon: Icons.school_outlined,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _dashboardInfo("Education", candidateData!['education']),
            _dashboardInfo("Skills", candidateData!['skills']),
            _dashboardInfo(
                "Work Experience", candidateData!['work_experience']),
          ],
        ),
      ),

      // Assessment
      _buildTile(
        icon: Icons.assignment_turned_in_outlined,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _dashboardInfo("Assessment Score",
                candidateData!['assessment_score'].toString()),
            _dashboardInfo("Assessment Recommendation",
                candidateData!['assessment_recommendation']),
          ],
        ),
      ),

      // Interviews
      _buildTile(
        icon: Icons.event_note_outlined,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("Scheduled Interviews",
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white)),
                CustomButton(
                  text: "Schedule New",
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ScheduleInterviewPage(
                          candidateId: widget.candidateId,
                        ),
                      ),
                    ).then((_) => fetchAllData());
                  },
                ),
              ],
            ),
            const SizedBox(height: 8),
            ...interviews.map((i) {
              final scheduled = DateTime.parse(i['scheduled_time']);
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: _buildHoverWrapper(
                  child: Card(
                    color: const Color(0xFF2C2C3C),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    child: ListTile(
                      title: Text(
                        DateFormat.yMd().add_jm().format(scheduled),
                        style: const TextStyle(color: Colors.white),
                      ),
                      subtitle: Text(
                          "Interviewer: ${i['hiring_manager_name'] ?? 'N/A'}",
                          style: const TextStyle(color: Colors.white70)),
                      trailing: CustomButton(
                        text: "Cancel",
                        onPressed: () => cancelInterview(i['id'] as int),
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ],
        ),
      ),
    ];

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: LayoutBuilder(
        builder: (context, constraints) {
          int crossAxisCount = 1;
          if (constraints.maxWidth > 1200)
            crossAxisCount = 3;
          else if (constraints.maxWidth > 800) crossAxisCount = 2;

          return GridView.count(
            crossAxisCount: crossAxisCount,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            shrinkWrap: true,
            physics: const BouncingScrollPhysics(),
            children: tiles,
          );
        },
      ),
    );
  }

  // ---------- Helpers (same as before) ----------
  Widget _buildTile({required Widget child, IconData? icon}) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF2C2C3C),
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(color: Colors.black26, blurRadius: 6, offset: Offset(0, 4))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (icon != null) Icon(icon, color: Colors.redAccent, size: 28),
          if (icon != null) const SizedBox(height: 6),
          child
        ],
      ),
    );
  }

  Widget _dashboardText(String text, double size, FontWeight weight) {
    return Text(text,
        style: TextStyle(
            fontSize: size,
            fontWeight: weight,
            color: Colors.white,
            shadows: const [
              Shadow(color: Colors.black26, blurRadius: 4, offset: Offset(2, 2))
            ]));
  }

  Widget _dashboardInfo(String label, String value,
      {bool bold = false, Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Text("$label: $value",
          style: TextStyle(
              fontSize: 14,
              fontWeight: bold ? FontWeight.bold : FontWeight.normal,
              color: color ?? Colors.white70)),
    );
  }

  Widget _buildHoverWrapper({required Widget child}) {
    return MouseRegion(
      onEnter: (_) => kIsWeb ? _hoverController.forward() : null,
      onExit: (_) => kIsWeb ? _hoverController.reverse() : null,
      child: AnimatedBuilder(
        animation: _hoverAnimation,
        builder: (context, _) {
          final scale = _hoverAnimation.value;
          return Transform.scale(scale: scale, child: child);
        },
      ),
    );
  }

  // Sidebar (same as before)
  Widget buildSidebar() {
    return Drawer(
      backgroundColor: const Color(0xFF1C1C28),
      child: SafeArea(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              child: Text(
                "Admin Panel",
                style: TextStyle(
                    color: Colors.redAccent,
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    shadows: const [
                      Shadow(
                          color: Colors.black26,
                          blurRadius: 4,
                          offset: Offset(2, 2))
                    ]),
              ),
            ),
            drawerItem("Dashboard", "dashboard", Icons.dashboard_outlined),
            drawerItem("Jobs", "jobs", Icons.work_outline),
            drawerItem("Candidates", "candidates", Icons.people_alt_outlined),
            drawerItem("Interviews", "interviews", Icons.event_note),
            drawerItem("CV Reviews", "cv_reviews", Icons.assignment_outlined),
            drawerItem("Audits", "audits", Icons.history),
            drawerItem("Role Access", "roles", Icons.security),
            drawerItem("Notifications", "notifications",
                Icons.notifications_active_outlined),
          ],
        ),
      ),
    );
  }

  Widget drawerItem(String title, String screen, IconData icon) {
    final bool selected = currentScreen == screen;
    return ListTile(
      leading: Icon(icon, color: Colors.redAccent),
      title: Text(title,
          style: TextStyle(
              color: selected ? Colors.redAccent : Colors.white70,
              fontWeight: selected ? FontWeight.bold : FontWeight.normal)),
      onTap: () {
        setState(() => currentScreen = screen);
        Navigator.pop(context);
      },
    );
  }

  Future<void> cancelInterview(int interviewId) async {
    try {
      await admin.cancelInterview(interviewId);
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text("Interview cancelled")));

      final interviewData =
          await admin.getCandidateInterviews(widget.candidateId);
      setState(
          () => interviews = List<Map<String, dynamic>>.from(interviewData));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error cancelling interview: $e")));
    }
  }
}
