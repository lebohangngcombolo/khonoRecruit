import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import '../../services/candidate_service.dart';
import 'job_details_page.dart';
import 'assessments_results_screen.dart';
import '../../screens/candidate/user_profile_page.dart';

class CandidateDashboard extends StatefulWidget {
  final String token;
  const CandidateDashboard({super.key, required this.token});

  @override
  _CandidateDashboardState createState() => _CandidateDashboardState();
}

class _CandidateDashboardState extends State<CandidateDashboard> {
  int selectedIndex = 0;
  bool sidebarCollapsed = false;
  List<String> sidebarItems = [
    "Dashboard",
    "Jobs Applied",
    "Assessment Results",
    "Profile",
    "Notifications",
  ];

  List<Map<String, dynamic>> availableJobs = [];
  bool loadingJobs = true;

  List<dynamic> applications = [];
  bool loadingApplications = true;

  List<Map<String, dynamic>> notifications = [];
  bool loadingNotifications = true;

  Map<String, dynamic>? candidateProfile;

  // Chatbot + CV Parser
  bool chatbotOpen = false;
  bool cvParserMode = false;
  final TextEditingController messageController = TextEditingController();
  final TextEditingController jobDescController = TextEditingController();
  final TextEditingController cvController = TextEditingController();
  final List<Map<String, String>> messages = [];
  Map<String, dynamic>? cvAnalysisResult;
  bool _isLoading = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    fetchCandidateProfile();
    fetchAvailableJobs();
    fetchApplications();
    fetchNotifications();
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

  Future<void> fetchApplications() async {
    setState(() => loadingApplications = true);
    try {
      final data = await CandidateService.getApplications(widget.token);
      setState(() {
        applications = data;
      });
    } catch (e) {
      debugPrint("Error fetching applications: $e");
    } finally {
      setState(() => loadingApplications = false);
    }
  }

  Future<void> fetchNotifications() async {
    setState(() => loadingNotifications = true);
    try {
      final data = await CandidateService.getNotifications(widget.token);
      setState(() {
        notifications = data;
      });
    } catch (e) {
      debugPrint("Error fetching notifications: $e");
    } finally {
      setState(() => loadingNotifications = false);
    }
  }

  Future<void> fetchCandidateProfile() async {
    try {
      final data = await CandidateService.getProfile(widget.token);
      setState(() => candidateProfile = data);
    } catch (e) {
      debugPrint("Error fetching profile: $e");
    }
  }

  Future<void> sendMessage() async {
    final text = messageController.text.trim();
    if (text.isEmpty) return;

    setState(() {
      messages.add({"type": "chat", "text": "You: $text"});
      messageController.clear();
    });

    try {
      final response = await http.post(
        Uri.parse("http://127.0.0.1:5000/api/ai/chat"),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer ${widget.token}",
        },
        body: jsonEncode({"message": text}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final reply = data["reply"] ?? "No reply from AI";

        setState(() {
          messages.add({"type": "chat", "text": "AI: $reply"});
        });
      } else {
        setState(() {
          messages.add({
            "type": "chat",
            "text": "AI: Failed to get response (status ${response.statusCode})"
          });
        });
      }
    } catch (e) {
      setState(() {
        messages.add({"type": "chat", "text": "AI: Error - $e"});
      });
    }
  }

  Future<void> analyzeCV() async {
    final jobDesc = jobDescController.text.trim();
    final cvText = cvController.text.trim();
    if (jobDesc.isEmpty || cvText.isEmpty) return;

    setState(() => _isLoading = true);
    try {
      final response = await http.post(
        Uri.parse("http://127.0.0.1:5000/api/ai/parse_cv"),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer ${widget.token}",
        },
        body: jsonEncode({
          "job_description": jobDesc,
          "cv_text": cvText,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() => cvAnalysisResult = data);
      } else {
        debugPrint("Failed to analyze CV: ${response.statusCode}");
      }
    } catch (e) {
      debugPrint("Error analyzing CV: $e");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: Row(
        children: [
          // ---------- Enhanced Sidebar ----------
          // ---------- Enhanced Sidebar ----------
          LayoutBuilder(
            builder: (context, constraints) {
              if (constraints.maxHeight == 0) return const SizedBox();
              return AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                width: sidebarCollapsed ? 70 : 250,
                constraints: BoxConstraints(
                  minWidth: 70,
                  maxWidth: 250,
                  maxHeight: constraints.maxHeight,
                ),
                clipBehavior: Clip.hardEdge,
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border(
                      right: BorderSide(color: Colors.grey.shade200, width: 1)),
                  boxShadow: [
                    BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 12,
                        offset: const Offset(2, 0))
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min, // Add this
                  children: [
                    // Enhanced Header - Fixed height
                    Container(
                      height: 80,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border(
                          bottom:
                              BorderSide(color: Colors.grey.shade200, width: 1),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          if (!sidebarCollapsed)
                            Flexible(
                              child: Image.asset('assets/images/logo2.png',
                                  height: 36, fit: BoxFit.contain),
                            )
                          else
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.redAccent.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Image.asset('assets/images/icon.png',
                                  height: 24, fit: BoxFit.contain),
                            ),
                          IconButton(
                            constraints: const BoxConstraints(),
                            padding: EdgeInsets.zero,
                            icon: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade100,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Icon(
                                sidebarCollapsed
                                    ? Icons.chevron_right
                                    : Icons.chevron_left,
                                size: 16,
                                color: Colors.grey.shade700,
                              ),
                            ),
                            onPressed: () => setState(
                                () => sidebarCollapsed = !sidebarCollapsed),
                          ),
                        ],
                      ),
                    ),

                    // Navigation Items - Fixed with limited items
                    Expanded(
                      child: ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        padding: const EdgeInsets.only(top: 16),
                        itemCount: sidebarItems.length,
                        itemBuilder: (_, index) {
                          final isSelected = selectedIndex == index;
                          IconData icon;
                          switch (index) {
                            case 0:
                              icon = Icons.dashboard_outlined;
                              break;
                            case 1:
                              icon = Icons.work_outline;
                              break;
                            case 2:
                              icon = Icons.assessment_outlined;
                              break;
                            case 3:
                              icon = Icons.person_outline;
                              break;
                            default:
                              icon = Icons.notifications_outlined;
                          }

                          return Container(
                            height: 52,
                            margin: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? Colors.redAccent.withOpacity(0.1)
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(8),
                              border: isSelected
                                  ? Border.all(
                                      color: Colors.redAccent.withOpacity(0.3))
                                  : null,
                            ),
                            child: ListTile(
                              contentPadding: sidebarCollapsed
                                  ? const EdgeInsets.symmetric(horizontal: 16)
                                  : const EdgeInsets.symmetric(horizontal: 16),
                              leading: Icon(
                                icon,
                                color: isSelected
                                    ? Colors.redAccent
                                    : Colors.grey.shade700,
                                size: 20,
                              ),
                              title: sidebarCollapsed
                                  ? null
                                  : Text(
                                      sidebarItems[index],
                                      style: GoogleFonts.inter(
                                        color: isSelected
                                            ? Colors.redAccent
                                            : Colors.grey.shade800,
                                        fontWeight: isSelected
                                            ? FontWeight.w600
                                            : FontWeight.w500,
                                        fontSize: 14,
                                      ),
                                    ),
                              selected: isSelected,
                              onTap: () {
                                setState(() => selectedIndex = index);
                                if (sidebarItems[index] ==
                                    "Assessment Results") {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (_) => AssessmentResultsPage(
                                            token: widget.token)),
                                  );
                                } else if (sidebarItems[index] == "Profile") {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (_) =>
                                            ProfilePage(token: widget.token)),
                                  );
                                }
                              },
                            ),
                          );
                        },
                      ),
                    ),

                    // Profile Section - Fixed height
                    Container(
                      padding: const EdgeInsets.symmetric(
                          vertical: 16, horizontal: 12),
                      decoration: BoxDecoration(
                        border: Border(
                          top:
                              BorderSide(color: Colors.grey.shade200, width: 1),
                        ),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min, // Add this
                        children: [
                          GestureDetector(
                            onTap: () {
                              Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (_) =>
                                          ProfilePage(token: widget.token)));
                            },
                            child: sidebarCollapsed
                                ? CircleAvatar(
                                    radius: 18,
                                    backgroundColor: Colors.grey.shade100,
                                    backgroundImage: candidateProfile != null &&
                                            candidateProfile![
                                                    'profile_picture'] !=
                                                null
                                        ? NetworkImage(candidateProfile![
                                            'profile_picture'])
                                        : null,
                                    child: candidateProfile == null ||
                                            candidateProfile![
                                                    'profile_picture'] ==
                                                null
                                        ? Icon(Icons.person,
                                            color: Colors.redAccent, size: 16)
                                        : null,
                                  )
                                : Row(
                                    children: [
                                      CircleAvatar(
                                        radius: 18,
                                        backgroundColor: Colors.grey.shade100,
                                        backgroundImage: candidateProfile !=
                                                    null &&
                                                candidateProfile![
                                                        'profile_picture'] !=
                                                    null
                                            ? NetworkImage(candidateProfile![
                                                'profile_picture'])
                                            : null,
                                        child: candidateProfile == null ||
                                                candidateProfile![
                                                        'profile_picture'] ==
                                                    null
                                            ? Icon(Icons.person,
                                                color: Colors.redAccent,
                                                size: 18)
                                            : null,
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Text(
                                              candidateProfile != null
                                                  ? candidateProfile![
                                                          'full_name'] ??
                                                      "Candidate User"
                                                  : "Candidate User",
                                              style: GoogleFonts.inter(
                                                color: Colors.grey.shade800,
                                                fontWeight: FontWeight.w600,
                                                fontSize: 14,
                                              ),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            Text(
                                              "View Profile",
                                              style: GoogleFonts.inter(
                                                color: Colors.grey.shade600,
                                                fontSize: 12,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                          ),
                          const SizedBox(height: 12),
                          sidebarCollapsed
                              ? IconButton(
                                  onPressed: () {},
                                  icon: Icon(Icons.logout,
                                      color: Colors.grey.shade600, size: 20),
                                )
                              : SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton.icon(
                                    onPressed: () async {},
                                    icon: Icon(Icons.logout, size: 16),
                                    label: Text("Logout",
                                        style: GoogleFonts.inter(fontSize: 13)),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.white,
                                      foregroundColor: Colors.redAccent,
                                      side: BorderSide(
                                          color: Colors.grey.shade300),
                                      minimumSize: const Size.fromHeight(42),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    ),
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

          // ---------- Enhanced Main Content ----------
          Expanded(
            child: Stack(
              children: [
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.grey.shade50,
                        Colors.grey.shade100,
                      ],
                    ),
                  ),
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Enhanced Navbar
                        Container(
                          height: 80,
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      "Welcome Back, ${candidateProfile != null ? candidateProfile!['full_name'] ?? 'Candidate' : 'Candidate'}!",
                                      style: GoogleFonts.poppins(
                                        fontSize: 20,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.grey.shade900,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      "Track your job applications and career progress",
                                      style: GoogleFonts.inter(
                                        color: Colors.grey.shade600,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Row(
                                children: [
                                  Container(
                                    decoration: BoxDecoration(
                                      color: Colors.redAccent.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: TextButton.icon(
                                      onPressed: () =>
                                          setState(() => selectedIndex = 1),
                                      icon: Icon(Icons.add,
                                          color: Colors.redAccent, size: 18),
                                      label: Text("New Application",
                                          style: GoogleFonts.inter(
                                            color: Colors.redAccent,
                                            fontWeight: FontWeight.w500,
                                            fontSize: 13,
                                          )),
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Container(
                                    decoration: BoxDecoration(
                                      color: Colors.grey.shade100,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: IconButton(
                                      onPressed: () =>
                                          setState(() => selectedIndex = 4),
                                      icon: Stack(
                                        children: [
                                          Icon(Icons.notifications_outlined,
                                              color: Colors.grey.shade700),
                                          if (notifications.isNotEmpty)
                                            Positioned(
                                              right: 0,
                                              top: 0,
                                              child: Container(
                                                padding:
                                                    const EdgeInsets.all(2),
                                                decoration: BoxDecoration(
                                                  color: Colors.redAccent,
                                                  shape: BoxShape.circle,
                                                ),
                                                constraints:
                                                    const BoxConstraints(
                                                  minWidth: 16,
                                                  minHeight: 16,
                                                ),
                                                child: Text(
                                                  notifications.length
                                                      .toString(),
                                                  style: const TextStyle(
                                                    color: Colors.white,
                                                    fontSize: 9,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                  textAlign: TextAlign.center,
                                                ),
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  CircleAvatar(
                                    radius: 20,
                                    backgroundColor: Colors.grey.shade200,
                                    backgroundImage: candidateProfile != null &&
                                            candidateProfile![
                                                    'profile_picture'] !=
                                                null
                                        ? NetworkImage(candidateProfile![
                                            'profile_picture'])
                                        : null,
                                    child: candidateProfile == null ||
                                            candidateProfile![
                                                    'profile_picture'] ==
                                                null
                                        ? Icon(Icons.person,
                                            color: Colors.redAccent)
                                        : null,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Page Content
                        if (selectedIndex == 0)
                          buildDashboardContent()
                        else if (selectedIndex == 1)
                          buildJobsApplied()
                        else if (selectedIndex == 2)
                          AssessmentResultsPage(token: widget.token)
                        else if (selectedIndex == 3)
                          ProfilePage(token: widget.token)
                        else if (selectedIndex == 4)
                          buildNotifications(),

                        const SizedBox(height: 40),
                        _buildFooter(),
                      ],
                    ),
                  ),
                ),

                // Enhanced Floating Chat Button
                Positioned(
                  right: 24,
                  bottom: 24,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    child: FloatingActionButton(
                      backgroundColor: Colors.redAccent,
                      elevation: 4,
                      child: Stack(
                        children: [
                          Image.asset(
                            'assets/images/chatbot.png',
                            width: 24,
                            height: 24,
                            color: Colors.white,
                          ),
                          if (messages.isNotEmpty && !chatbotOpen)
                            Positioned(
                              right: 0,
                              top: 0,
                              child: Container(
                                padding: const EdgeInsets.all(2),
                                decoration: const BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                ),
                                constraints: const BoxConstraints(
                                  minWidth: 12,
                                  minHeight: 12,
                                ),
                                child: Container(
                                  decoration: const BoxDecoration(
                                    color: Colors.orange,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                      onPressed: () =>
                          setState(() => chatbotOpen = !chatbotOpen),
                    ),
                  ),
                ),

                // Enhanced Chatbot Panel
                if (chatbotOpen)
                  Positioned(
                    right: 24,
                    bottom: 80,
                    child: buildChatbotPanel(),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ---------- Enhanced Widgets ----------
  Widget buildDashboardContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Enhanced Dashboard Banner
        Container(
          height: 180,
          width: double.infinity,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: const LinearGradient(
              colors: [Color(0xFFDC2626), Color(0xFFEF4444)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.redAccent.withOpacity(0.3),
                blurRadius: 16,
                offset: const Offset(0, 8),
              )
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(28.0),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "Career Dashboard",
                        style: GoogleFonts.poppins(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "Manage your job applications and track your progress in one place",
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          color: Colors.white.withOpacity(0.9),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.rocket_launch,
                      size: 60, color: Colors.white),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 32),

        // Enhanced Available Jobs Section
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              "Available Opportunities",
              style: GoogleFonts.poppins(
                fontSize: 22,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade900,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.redAccent.withOpacity(0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                "${availableJobs.length} positions",
                style: GoogleFonts.inter(
                  color: Colors.redAccent,
                  fontWeight: FontWeight.w500,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (loadingJobs)
          Center(
            child: Container(
              padding: const EdgeInsets.all(24),
              child: const CircularProgressIndicator(color: Colors.redAccent),
            ),
          )
        else
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 16,
              crossAxisSpacing: 16,
              childAspectRatio: 3.2,
            ),
            itemCount: availableJobs.length,
            itemBuilder: (context, index) {
              final job = availableJobs[index];
              return GestureDetector(
                onTap: () {
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => JobDetailsPage(job: job)));
                },
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      )
                    ],
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: Colors.redAccent.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child:
                            Icon(Icons.work_outline, color: Colors.redAccent),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              job['title'] ?? "Job Title",
                              style: GoogleFonts.inter(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey.shade900,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              job['company'] ?? "Company",
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                color: Colors.grey.shade700,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Icon(Icons.location_on_outlined,
                                    size: 14, color: Colors.grey.shade500),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    job['location'] ?? "Location",
                                    style: GoogleFonts.inter(
                                      fontSize: 12,
                                      color: Colors.grey.shade600,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      Icon(Icons.chevron_right, color: Colors.grey.shade400),
                    ],
                  ),
                ),
              );
            },
          ),

        const SizedBox(height: 32),

        // Enhanced Quick Stats
        Text(
          "Application Overview",
          style: GoogleFonts.poppins(
            fontSize: 22,
            fontWeight: FontWeight.w600,
            color: Colors.grey.shade900,
          ),
        ),
        const SizedBox(height: 16),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 3,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 1.6,
          children: [
            _buildEnhancedStatCard("Total Applied", applications.length,
                Icons.send_outlined, Colors.blueAccent),
            _buildEnhancedStatCard(
                "Interviews",
                applications.where((a) => a['status'] == 'Interview').length,
                Icons.video_call_outlined,
                Colors.greenAccent),
            _buildEnhancedStatCard(
                "Offers Received",
                applications.where((a) => a['status'] == 'Offered').length,
                Icons.celebration_outlined,
                Colors.orangeAccent),
          ],
        ),
      ],
    );
  }

  // Enhanced Stat Card
  Widget _buildEnhancedStatCard(
      String title, int count, IconData icon, Color color) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 3),
          )
        ],
        border: Border.all(color: Colors.grey.shade200),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "$count",
                style: GoogleFonts.poppins(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade900,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                title,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget buildJobsApplied() {
    if (loadingApplications)
      return Center(
        child: Container(
          padding: const EdgeInsets.all(40),
          child: const CircularProgressIndicator(color: Colors.redAccent),
        ),
      );
    if (applications.isEmpty)
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.work_outline, size: 64, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            Text(
              "No applications yet",
              style: GoogleFonts.inter(
                fontSize: 16,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Your Applications",
          style: GoogleFonts.poppins(
            fontSize: 22,
            fontWeight: FontWeight.w600,
            color: Colors.grey.shade900,
          ),
        ),
        const SizedBox(height: 16),
        ...applications
            .map((app) => Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 12),
                    leading: Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: Colors.redAccent.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(Icons.work_outline, color: Colors.redAccent),
                    ),
                    title: Text(
                      app['job_title'] ?? "Job Title",
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 4),
                        Text("Status: ${app['status'] ?? 'Pending'}"),
                        if (app['applied_on'] != null)
                          Text("Applied on: ${app['applied_on']}",
                              style: TextStyle(
                                  color: Colors.grey.shade600, fontSize: 12)),
                      ],
                    ),
                    trailing: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: _getStatusColor(app['status']).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        app['status'] ?? 'Pending',
                        style: GoogleFonts.inter(
                          color: _getStatusColor(app['status']),
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                ))
            .toList(),
      ],
    );
  }

  Color _getStatusColor(String? status) {
    switch (status?.toLowerCase()) {
      case 'interview':
        return Colors.orangeAccent;
      case 'offered':
        return Colors.greenAccent;
      case 'rejected':
        return Colors.redAccent;
      default:
        return Colors.blueAccent;
    }
  }

  Widget buildNotifications() {
    if (loadingNotifications)
      return Center(
        child: Container(
          padding: const EdgeInsets.all(40),
          child: const CircularProgressIndicator(color: Colors.redAccent),
        ),
      );
    if (notifications.isEmpty)
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.notifications_outlined,
                size: 64, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            Text(
              "No notifications",
              style: GoogleFonts.inter(
                fontSize: 16,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Notifications",
          style: GoogleFonts.poppins(
            fontSize: 22,
            fontWeight: FontWeight.w600,
            color: Colors.grey.shade900,
          ),
        ),
        const SizedBox(height: 16),
        ...notifications
            .map((notif) => Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 16),
                    leading: Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: Colors.redAccent.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(Icons.notifications_outlined,
                          color: Colors.redAccent),
                    ),
                    title: Text(
                      notif['title'] ?? "Notification",
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                    subtitle: Text(
                      notif['message'] ?? "",
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: Colors.grey.shade700,
                      ),
                    ),
                    trailing:
                        Icon(Icons.chevron_right, color: Colors.grey.shade400),
                  ),
                ))
            .toList(),
      ],
    );
  }

  Widget buildChatbotPanel() {
    return Material(
      elevation: 12,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: 380,
        height: 520,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Column(
          children: [
            // Enhanced Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.redAccent,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(cvParserMode ? Icons.description : Icons.chat,
                        color: Colors.white, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    cvParserMode ? "CV Analysis" : "Career Assistant",
                    style: GoogleFonts.inter(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () =>
                        setState(() => cvParserMode = !cvParserMode),
                    icon: Icon(Icons.swap_horiz, color: Colors.white, size: 20),
                  ),
                  IconButton(
                    onPressed: () => setState(() => chatbotOpen = false),
                    icon: Icon(Icons.close, color: Colors.white, size: 20),
                  ),
                ],
              ),
            ),

            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: cvParserMode ? _buildCVParser() : _buildChatInterface(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCVParser() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "CV Match Analysis",
            style: GoogleFonts.inter(
              fontWeight: FontWeight.w600,
              fontSize: 14,
              color: Colors.grey.shade800,
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: jobDescController,
            maxLines: 4,
            decoration: InputDecoration(
              hintText: "Paste job description here...",
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              filled: true,
              fillColor: Colors.grey.shade50,
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: cvController,
            maxLines: 4,
            decoration: InputDecoration(
              hintText: "Paste your CV content here...",
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              filled: true,
              fillColor: Colors.grey.shade50,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isLoading ? null : analyzeCV,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: _isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : Text("Analyze Match",
                      style: GoogleFonts.inter(fontWeight: FontWeight.w500)),
            ),
          ),
          const SizedBox(height: 16),
          if (cvAnalysisResult != null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.green.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Analysis Result:",
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.w600,
                      color: Colors.green.shade800,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Display all possible result fields
                  if (cvAnalysisResult!['matchPercentage'] != null)
                    _buildResultItem("Match Percentage",
                        "${cvAnalysisResult!['matchPercentage']}%"),

                  if (cvAnalysisResult!['missingKeywords'] != null)
                    _buildResultItem("Missing Keywords",
                        cvAnalysisResult!['missingKeywords']),

                  if (cvAnalysisResult!['matchingKeywords'] != null)
                    _buildResultItem("Matching Keywords",
                        cvAnalysisResult!['matchingKeywords']),

                  if (cvAnalysisResult!['skillsGap'] != null)
                    _buildResultItem(
                        "Skills Gap", cvAnalysisResult!['skillsGap']),

                  if (cvAnalysisResult!['recommendations'] != null)
                    _buildResultItem("Recommendations",
                        cvAnalysisResult!['recommendations']),

                  if (cvAnalysisResult!['result'] != null)
                    _buildResultItem(
                        "Detailed Analysis", cvAnalysisResult!['result']),

                  // Fallback - if no specific fields, show the entire result object
                  if (_shouldShowRawResult(cvAnalysisResult!))
                    _buildResultItem(
                        "Raw Analysis Result", cvAnalysisResult!.toString()),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildResultItem(String title, dynamic content) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.inter(
              fontWeight: FontWeight.w600,
              color: Colors.green.shade800,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 4),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: Colors.green.shade100),
            ),
            child: Text(
              content.toString(),
              style: GoogleFonts.inter(
                fontSize: 14,
                color: Colors.grey.shade700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  bool _shouldShowRawResult(Map<String, dynamic> result) {
    return result['matchPercentage'] == null &&
        result['missingKeywords'] == null &&
        result['matchingKeywords'] == null &&
        result['skillsGap'] == null &&
        result['recommendations'] == null &&
        result['result'] == null;
  }

  Widget _buildChatInterface() {
    return Column(
      children: [
        Expanded(
          child: messages.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.chat_bubble_outline,
                          size: 48, color: Colors.grey.shade300),
                      const SizedBox(height: 12),
                      Text(
                        "How can I help with your job search?",
                        style: GoogleFonts.inter(
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  reverse: false,
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final msg = messages[index];
                    final isUser = msg['text']?.startsWith("You:") ?? false;
                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        mainAxisAlignment: isUser
                            ? MainAxisAlignment.end
                            : MainAxisAlignment.start,
                        children: [
                          if (!isUser)
                            Container(
                              margin: const EdgeInsets.only(right: 8),
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: Colors.redAccent,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Icon(Icons.smart_toy,
                                  color: Colors.white, size: 12),
                            ),
                          Flexible(
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: isUser
                                    ? Colors.redAccent
                                    : Colors.grey.shade100,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                msg['text']
                                        ?.replaceFirst("You: ", "")
                                        .replaceFirst("AI: ", "") ??
                                    "",
                                style: GoogleFonts.inter(
                                  color: isUser
                                      ? Colors.white
                                      : Colors.grey.shade800,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: messageController,
                decoration: InputDecoration(
                  hintText: "Type your message...",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              decoration: BoxDecoration(
                color: Colors.redAccent,
                borderRadius: BorderRadius.circular(20),
              ),
              child: IconButton(
                onPressed: sendMessage,
                icon: const Icon(Icons.send, color: Colors.white),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildFooter() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 60, vertical: 40),
      color: const Color(0xFF111111),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Image.asset(
            'assets/images/logo3.png',
            width: 220,
            height: 120,
            fit: BoxFit.contain,
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _socialIcon(
                'assets/icons/Instagram1.png',
                'https://www.instagram.com/yourprofile',
              ),
              _socialIcon(
                'assets/icons/x1.png',
                'https://x.com/yourprofile',
              ),
              _socialIcon(
                'assets/icons/Linkedin1.png',
                'https://www.linkedin.com/in/yourprofile',
              ),
              _socialIcon(
                'assets/icons/facebook1.png',
                'https://www.facebook.com/yourprofile',
              ),
              _socialIcon(
                'assets/icons/YouTube1.png',
                'https://www.youtube.com/yourchannel',
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            "© 2025 Khonology. All rights reserved.",
            style: GoogleFonts.poppins(
              color: Colors.white54,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _socialIcon(String assetPath, String url) {
    return Padding(
      padding: const EdgeInsets.only(right: 16.0),
      child: InkWell(
        onTap: () async {
          final Uri uri = Uri.parse(url);
          if (await canLaunchUrl(uri)) {
            await launchUrl(uri);
          }
        },
        child: Image.asset(
          assetPath,
          width: 32,
          height: 32,
          fit: BoxFit.contain,
        ),
      ),
    );
  }
}
