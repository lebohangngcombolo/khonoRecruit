import 'dart:convert';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../services/candidate_service.dart';
import '../../services/auth_service.dart';
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
  void initState() {
    super.initState();
    fetchAvailableJobs();
    fetchApplications();
    fetchNotifications();
    fetchCandidateProfile();
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
      body: Row(
        children: [
          // ---------- Sidebar ----------
          LayoutBuilder(
            builder: (context, constraints) {
              if (constraints.maxHeight == 0) return const SizedBox();
              return AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                width: sidebarCollapsed ? 70 : 250,
                constraints: const BoxConstraints(minWidth: 70, maxWidth: 250),
                clipBehavior: Clip.hardEdge,
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border(
                      right: BorderSide(color: Colors.grey.shade200, width: 1)),
                  boxShadow: [
                    BoxShadow(
                        color: Colors.black.withOpacity(0.02),
                        blurRadius: 8,
                        offset: const Offset(2, 0))
                  ],
                ),
                child: Column(
                  children: [
                    SizedBox(
                      height: 72,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 6),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            if (!sidebarCollapsed)
                              Flexible(
                                child: Image.asset('assets/images/logo2.png',
                                    height: 40, fit: BoxFit.contain),
                              )
                            else
                              Image.asset('assets/images/icon.png',
                                  height: 40, fit: BoxFit.contain),
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
                              onPressed: () => setState(
                                  () => sidebarCollapsed = !sidebarCollapsed),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const Divider(height: 1, color: Colors.grey),
                    Expanded(
                      child: ListView.builder(
                        padding: EdgeInsets.zero,
                        itemCount: sidebarItems.length,
                        itemBuilder: (_, index) {
                          final isSelected = selectedIndex == index;
                          IconData icon;
                          switch (index) {
                            case 0:
                              icon = Icons.dashboard;
                              break;
                            case 1:
                              icon = Icons.work_outline;
                              break;
                            case 2:
                              icon = Icons.assessment;
                              break;
                            case 3:
                              icon = Icons.person;
                              break;
                            default:
                              icon = Icons.notifications;
                          }

                          return SizedBox(
                            height: 48,
                            child: ListTile(
                              leading: Icon(icon, color: Colors.grey.shade800),
                              title: sidebarCollapsed
                                  ? null
                                  : Text(
                                      sidebarItems[index],
                                      style: TextStyle(
                                          color: Colors.grey.shade800,
                                          fontWeight: FontWeight.w600),
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
                    const Divider(height: 1, color: Colors.grey),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          vertical: 12.0, horizontal: 8),
                      child: Column(
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
                                    radius: 16,
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
                                        ? const Icon(Icons.person,
                                            color: Colors.redAccent, size: 16)
                                        : null,
                                  )
                                : Row(
                                    children: [
                                      CircleAvatar(
                                        radius: 16,
                                        backgroundColor: Colors.grey.shade200,
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
                                            ? const Icon(Icons.person,
                                                color: Colors.redAccent,
                                                size: 16)
                                            : null,
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Text(
                                          candidateProfile != null
                                              ? candidateProfile![
                                                      'full_name'] ??
                                                  "Candidate User"
                                              : "Candidate User",
                                          style: TextStyle(
                                              color: Colors.grey.shade800,
                                              fontWeight: FontWeight.w600),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                          ),
                          const SizedBox(height: 12),
                          sidebarCollapsed
                              ? IconButton(
                                  onPressed: () {},
                                  icon: const Icon(Icons.logout,
                                      color: Colors.grey))
                              : ElevatedButton.icon(
                                  onPressed: () async {},
                                  icon: const Icon(Icons.logout, size: 16),
                                  label: const Text("Logout"),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.white,
                                    foregroundColor: Colors.redAccent,
                                    side:
                                        BorderSide(color: Colors.grey.shade300),
                                    minimumSize: const Size.fromHeight(40),
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

          // ---------- Main Content ----------
          Expanded(
            child: Stack(
              children: [
                LayoutBuilder(
                  builder: (context, constraints) {
                    return SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: ConstrainedBox(
                        constraints:
                            BoxConstraints(minHeight: constraints.maxHeight),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Navbar
                            Container(
                              height: 72,
                              decoration:
                                  const BoxDecoration(color: Colors.white),
                              child: Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 20),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            "Welcome Back, ${candidateProfile != null ? candidateProfile!['full_name'] ?? 'Candidate' : 'Candidate'}",
                                            style: TextStyle(
                                                fontSize: 18,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.grey.shade900),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            "Overview of the recruitment platform",
                                            style: TextStyle(
                                                color: Colors.grey.shade600,
                                                fontSize: 12),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Row(
                                      children: [
                                        TextButton.icon(
                                          onPressed: () =>
                                              setState(() => selectedIndex = 1),
                                          icon: const Icon(
                                              Icons.add_box_outlined,
                                              color: Colors.redAccent),
                                          label: const Text("Create",
                                              style: TextStyle(
                                                  color: Colors.black87)),
                                        ),
                                        const SizedBox(width: 12),
                                        IconButton(
                                          onPressed: () =>
                                              setState(() => selectedIndex = 4),
                                          icon: Stack(
                                            children: [
                                              const Icon(
                                                  Icons.notifications_none),
                                              if (notifications.isNotEmpty)
                                                Positioned(
                                                  right: 0,
                                                  top: 0,
                                                  child: Container(
                                                    padding:
                                                        const EdgeInsets.all(2),
                                                    decoration: BoxDecoration(
                                                        color: Colors.redAccent,
                                                        shape: BoxShape.circle),
                                                    constraints:
                                                        const BoxConstraints(
                                                            minWidth: 12,
                                                            minHeight: 12),
                                                    child: Text(
                                                      notifications.length
                                                          .toString(),
                                                      style: const TextStyle(
                                                          color: Colors.white,
                                                          fontSize: 8,
                                                          fontWeight:
                                                              FontWeight.bold),
                                                      textAlign:
                                                          TextAlign.center,
                                                    ),
                                                  ),
                                                ),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        CircleAvatar(
                                          radius: 18,
                                          backgroundColor: Colors.grey.shade200,
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
                                              ? const Icon(Icons.person,
                                                  color: Colors.redAccent)
                                              : null,
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 20),

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
                    );
                  },
                ),

                // Floating Chat Button
                Positioned(
                  right: 20,
                  bottom: 20,
                  child: FloatingActionButton(
                    backgroundColor: Colors.redAccent,
                    child: const Icon(Icons.chat),
                    onPressed: () => setState(() => chatbotOpen = !chatbotOpen),
                  ),
                ),

                // Chatbot Panel
                if (chatbotOpen)
                  Positioned(
                    right: 20,
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

  // ---------- Widgets ----------
  Widget buildDashboardContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ---------- Dashboard Banner ----------
        Container(
          height: 200,
          width: double.infinity,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: const LinearGradient(
              colors: [Colors.redAccent, Colors.red],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.redAccent.withOpacity(0.3),
                blurRadius: 12,
                offset: const Offset(0, 6),
              )
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "Hello, ${candidateProfile != null ? candidateProfile!['full_name'] ?? 'Candidate' : 'Candidate'}!",
                        style: GoogleFonts.poppins(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.white),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        "Explore your opportunities and applications today",
                        style: GoogleFonts.poppins(
                            fontSize: 14, color: Colors.white.withOpacity(0.9)),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.work_outline, size: 80, color: Colors.white30),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),

        // ---------- Available Jobs ----------
        Text(
          "Available Jobs",
          style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Colors.redAccent),
        ),
        const SizedBox(height: 12),
        if (loadingJobs)
          const Center(
              child: CircularProgressIndicator(color: Colors.redAccent))
        else
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 16,
              crossAxisSpacing: 16,
              childAspectRatio: 3,
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
                        color: Colors.redAccent.withOpacity(0.1),
                        blurRadius: 6,
                        offset: const Offset(0, 3),
                      )
                    ],
                    border:
                        Border.all(color: Colors.redAccent.withOpacity(0.2)),
                  ),
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        job['title'] ?? "Job Title",
                        style: GoogleFonts.poppins(
                            fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        job['company'] ?? "Company",
                        style: GoogleFonts.poppins(
                            fontSize: 14, color: Colors.grey.shade700),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.location_on,
                              size: 14, color: Colors.redAccent),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              job['location'] ?? "Location",
                              style: GoogleFonts.poppins(
                                  fontSize: 12, color: Colors.grey.shade600),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          ),

        const SizedBox(height: 24),

        // ---------- Quick Stats ----------
        Text(
          "Your Applications",
          style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Colors.redAccent),
        ),
        const SizedBox(height: 12),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 3,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 1.5,
          children: [
            buildStatCard("Applied", applications.length, Icons.send_to_mobile,
                Colors.redAccent),
            buildStatCard(
                "Interviews",
                applications.where((a) => a['status'] == 'Interview').length,
                Icons.mic,
                Colors.redAccent.shade700),
            buildStatCard(
                "Offers",
                applications.where((a) => a['status'] == 'Offered').length,
                Icons.check_circle,
                Colors.redAccent.shade400),
          ],
        ),
      ],
    );
  }

// ---------- Helper: Stat Card ----------
  Widget buildStatCard(String title, int count, IconData icon, Color color) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
              color: color.withOpacity(0.1),
              blurRadius: 6,
              offset: const Offset(0, 3))
        ],
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          CircleAvatar(
            backgroundColor: color.withOpacity(0.1),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                "$count",
                style: GoogleFonts.poppins(
                    fontSize: 18, fontWeight: FontWeight.bold),
              ),
              Text(
                title,
                style: GoogleFonts.poppins(
                    fontSize: 12, color: Colors.grey.shade700),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget buildJobsApplied() {
    if (loadingApplications)
      return const Center(child: CircularProgressIndicator());
    if (applications.isEmpty) return const Text("No applications yet.");
    return Column(
      children: applications
          .map((app) => Card(
                child: ListTile(
                  title: Text(app['job_title'] ?? "Job"),
                  subtitle: Text("Status: ${app['status'] ?? 'Pending'}"),
                  trailing: Text(app['applied_on'] ?? ""),
                ),
              ))
          .toList(),
    );
  }

  Widget buildNotifications() {
    if (loadingNotifications)
      return const Center(child: CircularProgressIndicator());
    if (notifications.isEmpty) return const Text("No notifications.");
    return Column(
      children: notifications
          .map((notif) => Card(
                child: ListTile(
                  title: Text(notif['title'] ?? ""),
                  subtitle: Text(notif['message'] ?? ""),
                ),
              ))
          .toList(),
    );
  }

  Widget buildChatbotPanel() {
    return Material(
      elevation: 8,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 360,
        height: 550,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
            color: Colors.white, borderRadius: BorderRadius.circular(12)),
        child: Column(
          children: [
            Row(
              children: [
                Text(cvParserMode ? "CV Parser" : "AI Chatbot",
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold)),
                const Spacer(),
                IconButton(
                    onPressed: () =>
                        setState(() => cvParserMode = !cvParserMode),
                    icon: const Icon(Icons.swap_horiz))
              ],
            ),
            const Divider(),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    if (cvParserMode)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          TextField(
                            controller: jobDescController,
                            maxLines: 4,
                            decoration: const InputDecoration(
                                hintText: "Paste Job Description here"),
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            controller: cvController,
                            maxLines: 4,
                            decoration: const InputDecoration(
                                hintText: "Paste CV here"),
                          ),
                          const SizedBox(height: 12),
                          ElevatedButton(
                              onPressed: _isLoading ? null : analyzeCV,
                              child: _isLoading
                                  ? const CircularProgressIndicator()
                                  : const Text("Analyze CV")),
                          const SizedBox(height: 12),
                          if (cvAnalysisResult != null)
                            Text("Result: ${cvAnalysisResult!['result']}"),
                        ],
                      )
                    else
                      Column(
                        children: messages
                            .map((msg) => Align(
                                  alignment: msg['type'] == "chat"
                                      ? Alignment.centerLeft
                                      : Alignment.centerRight,
                                  child: Container(
                                      padding: const EdgeInsets.all(8),
                                      margin: const EdgeInsets.symmetric(
                                          vertical: 4),
                                      decoration: BoxDecoration(
                                          color: msg['type'] == "chat"
                                              ? Colors.grey.shade200
                                              : Colors.redAccent,
                                          borderRadius:
                                              BorderRadius.circular(8)),
                                      child: Text(msg['text'] ?? "")),
                                ))
                            .toList(),
                      )
                  ],
                ),
              ),
            ),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: messageController,
                    decoration: const InputDecoration(
                        hintText: "Type a message...",
                        border: OutlineInputBorder()),
                  ),
                ),
                IconButton(
                    onPressed: sendMessage, icon: const Icon(Icons.send)),
              ],
            ),
          ],
        ),
      ),
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
          // Logo
          Image.asset(
            'assets/images/logo3.png',
            width: 220,
            height: 120,
            fit: BoxFit.contain,
          ),
          const SizedBox(height: 20),

          // Social icons row
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

          // Copyright text
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

// Reuse the social icon helper
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
