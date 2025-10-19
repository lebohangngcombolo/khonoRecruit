import 'dart:html' as html; // For web download
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'dart:convert';
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
        "candidate_id": application['id'] ?? widget.candidateId,
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

      if (kIsWeb) {
        final anchor = html.AnchorElement(href: cvUrl)
          ..setAttribute("download", "cv_$fullName.pdf")
          ..click();

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Download started")),
        );
      } else {
        final dir = await getApplicationDocumentsDirectory();
        final savePath = "${dir.path}/cv_$fullName.pdf";

        await Dio().download(cvUrl, savePath);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("CV downloaded successfully")),
        );

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
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(candidateData?['full_name'] ?? "Candidate Details"),
        backgroundColor: Colors.black87,
        elevation: 0,
      ),
      body: Container(
        color: Colors.grey[100],
        child: loading
            ? const Center(
                child: CircularProgressIndicator(color: Colors.black87))
            : errorMessage != null
                ? Center(
                    child: Text(errorMessage!,
                        style: const TextStyle(color: Colors.black87)),
                  )
                : _buildTilesGrid(),
      ),
    );
  }

  Widget _buildTilesGrid() {
    final List<Widget> tiles = [
      _buildFlatTile(
        icon: Icons.person_outline,
        topRightIcon: Icons.edit_outlined,
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
                    ? Colors.green
                    : Colors.black87),
          ],
        ),
      ),
      _buildFlatTile(
        icon: Icons.insert_drive_file_outlined,
        topRightIcon: Icons.download_outlined,
        onTopRightTap: () {
          downloadCV(
            candidateData!['candidate_id'],
            context,
            candidateData!['full_name'] ?? "candidate",
            "YOUR_JWT_TOKEN_HERE",
          );
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _dashboardInfo("CV Score", candidateData!['cv_score'].toString()),
            const SizedBox(height: 8),
            Text("Click top-right icon to download CV",
                style: TextStyle(color: Colors.black54, fontSize: 12)),
          ],
        ),
      ),
      _buildFlatTile(
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
      _buildFlatTile(
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
      _buildFlatTile(
        icon: Icons.event_note_outlined,
        topRightIcon: Icons.add,
        onTopRightTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ScheduleInterviewPage(
                candidateId: widget.candidateId,
              ),
            ),
          ).then((_) => fetchAllData());
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Scheduled Interviews",
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87)),
            const SizedBox(height: 8),
            ...interviews.map((i) {
              final scheduled = DateTime.parse(i['scheduled_time']);
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: _buildHoverWrapper(
                  child: Card(
                    color: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                    elevation: 3,
                    shadowColor: Colors.black26,
                    child: ListTile(
                      title: Text(
                        DateFormat.yMd().add_jm().format(scheduled),
                        style: const TextStyle(color: Colors.black87),
                      ),
                      subtitle: Text(
                          "Interviewer: ${i['hiring_manager_name'] ?? 'N/A'}",
                          style: const TextStyle(color: Colors.black87)),
                      trailing: CustomButton(
                        text: "Cancel",
                        color: Colors.black87,
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
            mainAxisSpacing: 16,
            crossAxisSpacing: 16,
            shrinkWrap: true,
            physics: const BouncingScrollPhysics(),
            children: tiles,
          );
        },
      ),
    );
  }

  Widget _buildFlatTile({
    required Widget child,
    IconData? icon,
    IconData? topRightIcon,
    VoidCallback? onTopRightTap,
  }) {
    return Stack(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white, width: 1.5),
            boxShadow: const [
              BoxShadow(
                color: Colors.black26,
                blurRadius: 6,
                offset: Offset(0, 4),
                spreadRadius: 0.5,
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (icon != null)
                Row(
                  children: [
                    Icon(icon, color: Colors.black87, size: 28),
                    const SizedBox(width: 8),
                    Expanded(child: child),
                  ],
                )
              else
                child,
            ],
          ),
        ),
        if (topRightIcon != null)
          Positioned(
            top: 12,
            right: 12,
            child: GestureDetector(
              onTap: onTopRightTap,
              child: Icon(topRightIcon, color: Colors.black87, size: 24),
            ),
          ),
      ],
    );
  }

  Widget _dashboardText(String text, double size, FontWeight weight) {
    return Text(text,
        style: TextStyle(
            fontSize: size,
            fontWeight: weight,
            color: Colors.black87,
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
              color: color ?? Colors.black87)),
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

  Widget buildSidebar() {
    return Drawer(
      backgroundColor: Colors.white,
      child: SafeArea(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              child: Text(
                "Admin Panel",
                style: TextStyle(
                    color: Colors.black87,
                    fontSize: 26,
                    fontWeight: FontWeight.bold),
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
      leading: Icon(icon, color: Colors.black87),
      title: Text(title,
          style: TextStyle(
              color: selected ? Colors.black87 : Colors.black54,
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
