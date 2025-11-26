import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import 'package:file_picker/file_picker.dart';
import '../../services/candidate_service.dart';
import 'job_details_page.dart';
import 'assessments_results_screen.dart';
import '../../screens/candidate/user_profile_page.dart';
import 'saved_application_screen.dart'; // Add this import
import '../../services/auth_service.dart';
import '../../screens/auth/login_screen.dart';

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
    "Offline Drafts",
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

  void _showLogoutConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Logout", style: TextStyle(fontFamily: 'Poppins')),
          content: const Text("Are you sure you want to logout?",
              style: TextStyle(fontFamily: 'Poppins')),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child:
                  const Text("Cancel", style: TextStyle(fontFamily: 'Poppins')),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _performLogout(context);
              },
              child: const Text("Logout",
                  style: TextStyle(color: Colors.red, fontFamily: 'Poppins')),
            ),
          ],
        );
      },
    );
  }

  void _performLogout(BuildContext context) async {
    Navigator.of(context).pop();
    await AuthService.logout();
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const LoginScreen()),
          (Route<dynamic> route) => false,
        );
      }
    });
  }

  bool _isLoggingOut = false;

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
                  color:
                      const Color(0xFF14131E).withOpacity(0.8), // Updated color
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
                        itemCount: sidebarItems.length + 1, // +1 for draft icon
                        itemBuilder: (_, index) {
                          // Draft Application Icon (added as first item)
                          if (index == 0) {
                            return SizedBox(
                              height: 48,
                              child: ListTile(
                                leading: Icon(Icons.drafts,
                                    color: Colors.white), // Updated color
                                title: sidebarCollapsed
                                    ? null
                                    : Text(
                                        "Draft Applications",
                                        style: TextStyle(
                                            color:
                                                Colors.white, // Updated color
                                            fontWeight: FontWeight.w600),
                                      ),
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => SavedApplicationsScreen(
                                          token: widget.token),
                                    ),
                                  );
                                },
                              ),
                            );
                          }

                          // Original sidebar items (adjusted index)
                          final adjustedIndex = index - 1;
                          final isSelected = selectedIndex == adjustedIndex;
                          IconData icon;
                          switch (adjustedIndex) {
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
                              leading: Icon(icon,
                                  color: Colors.white), // Updated color
                              title: sidebarCollapsed
                                  ? null
                                  : Text(
                                      sidebarItems[adjustedIndex],
                                      style: TextStyle(
                                          color: Colors.white, // Updated color
                                          fontWeight: FontWeight.w600),
                                    ),
                              selected: isSelected,
                              onTap: () {
                                setState(() => selectedIndex = adjustedIndex);
                                if (sidebarItems[adjustedIndex] ==
                                    "Assessment Results") {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (_) => AssessmentResultsPage(
                                            token: widget.token)),
                                  );
                                } else if (sidebarItems[adjustedIndex] ==
                                    "Profile") {
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
                                              color:
                                                  Colors.white, // Updated color
                                              fontWeight: FontWeight.w600),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                          ),
                          const SizedBox(height: 12),
                          if (!sidebarCollapsed)
                            ElevatedButton.icon(
                              onPressed: () => _showLogoutConfirmation(context),
                              icon: const Icon(Icons.logout, size: 16),
                              label: const Text("Logout",
                                  style: TextStyle(fontFamily: 'Poppins')),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.redAccent,
                                foregroundColor: Colors.redAccent,
                                side: BorderSide(color: Colors.grey.shade300),
                                minimumSize: const Size.fromHeight(40),
                              ),
                            )
                          else
                            IconButton(
                              onPressed: () => _showLogoutConfirmation(context),
                              icon:
                                  const Icon(Icons.logout, color: Colors.grey),
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
                // Background Image for entire main content
                Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFF14131E)
                        .withOpacity(0.8), // Updated color
                    image: const DecorationImage(
                      image: AssetImage('assets/images/dark.png'),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),

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
                            // Navbar - Made translucent
                            Container(
                              height: 72,
                              decoration: BoxDecoration(
                                color: const Color(0xFF14131E)
                                    .withOpacity(0.8), // Updated color
                                borderRadius: BorderRadius.circular(12),
                              ),
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
                                                color: Colors
                                                    .white), // Updated color
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            "Overview of the recruitment platform",
                                            style: TextStyle(
                                                color: Colors.white.withOpacity(
                                                    0.8), // Updated color
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
                                                  color: Colors
                                                      .white)), // Updated color
                                        ),
                                        const SizedBox(width: 12),
                                        IconButton(
                                          onPressed: () =>
                                              setState(() => selectedIndex = 4),
                                          icon: Stack(
                                            children: [
                                              Icon(Icons.notifications_none,
                                                  color: Colors
                                                      .white), // Updated color
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
              fontSize: 20, fontWeight: FontWeight.w600, color: Colors.white),
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
                    color: const Color(0xFF14131E)
                        .withOpacity(0.8), // Updated color
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      )
                    ],
                    border: Border.all(
                      color: Colors.white.withOpacity(0.3), // Light border
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          job['title'] ?? "Job Title",
                          style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white), // Updated color
                        ),
                        const SizedBox(height: 4),
                        Text(
                          job['company'] ?? "Company",
                          style: GoogleFonts.poppins(
                              fontSize: 14,
                              color: Colors.white
                                  .withOpacity(0.8)), // Updated color
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
                                    fontSize: 12,
                                    color: Colors.white
                                        .withOpacity(0.8)), // Updated color
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
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
              fontSize: 20, fontWeight: FontWeight.w600, color: Colors.white),
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
        color: const Color(0xFF14131E).withOpacity(0.8), // Updated color
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          )
        ],
        border: Border.all(
          color: Colors.white.withOpacity(0.3), // Light border
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            CircleAvatar(
              backgroundColor: color.withOpacity(0.2),
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
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white), // Updated color
                ),
                Text(
                  title,
                  style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: Colors.white.withOpacity(0.8)), // Updated color
                ),
              ],
            ),
          ],
        ),
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
                color:
                    const Color(0xFF14131E).withOpacity(0.8), // Updated color
                child: ListTile(
                  title: Text(app['job_title'] ?? "Job",
                      style: TextStyle(color: Colors.white)), // Updated color
                  subtitle: Text("Status: ${app['status'] ?? 'Pending'}",
                      style: TextStyle(
                          color:
                              Colors.white.withOpacity(0.8))), // Updated color
                  trailing: Text(app['applied_on'] ?? "",
                      style: TextStyle(color: Colors.white)), // Updated color
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
                color:
                    const Color(0xFF14131E).withOpacity(0.8), // Updated color
                child: ListTile(
                  title: Text(notif['title'] ?? "",
                      style: TextStyle(color: Colors.white)), // Updated color
                  subtitle: Text(notif['message'] ?? "",
                      style: TextStyle(
                          color:
                              Colors.white.withOpacity(0.8))), // Updated color
                ),
              ))
          .toList(),
    );
  }

  Widget buildChatbotPanel() {
    return Container(
      width: 400,
      height: 550,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF14131E).withOpacity(0.95), // Updated color
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 12,
              offset: const Offset(2, 4))
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Text("AI Chatbot",
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.white)), // Updated color
              const Spacer(),
              IconButton(
                  onPressed: () => setState(() => chatbotOpen = false),
                  icon: const Icon(Icons.close,
                      color: Colors.white)), // Updated color
            ],
          ),
          const Divider(color: Colors.grey),

          // Toggle Tabs
          Row(
            children: [
              TextButton(
                  onPressed: () => setState(() => cvParserMode = false),
                  child: Text("Chat",
                      style: TextStyle(
                          color:
                              cvParserMode ? Colors.grey : Colors.redAccent))),
              TextButton(
                  onPressed: () => setState(() => cvParserMode = true),
                  child: Text("CV Parser",
                      style: TextStyle(
                          color:
                              cvParserMode ? Colors.redAccent : Colors.grey))),
            ],
          ),
          const Divider(color: Colors.grey),

          // Content
          Expanded(
            child: cvParserMode ? buildCVParserTab() : buildChatMessages(),
          ),
        ],
      ),
    );
  }

  Widget buildChatMessages() {
    return Column(
      children: [
        Expanded(
          child: ListView(
            children: messages
                .map((msg) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Text(msg['text'] ?? "",
                          style:
                              TextStyle(color: Colors.white)), // Updated color
                    ))
                .toList(),
          ),
        ),
        if (_isLoading) const LinearProgressIndicator(),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: messageController,
                decoration: const InputDecoration(
                  hintText: "Type message...",
                  filled: true,
                  fillColor: Colors.white,
                ),
              ),
            ),
            IconButton(
              onPressed: sendMessage,
              icon: const Icon(Icons.send, color: Colors.redAccent),
            ),
          ],
        ),
      ],
    );
  }

  Widget buildCVParserTab() {
    PlatformFile? uploadedResume;
    bool _isParsing = false;

    return StatefulBuilder(
      builder: (context, setState) {
        return SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: jobDescController,
                maxLines: 4,
                decoration: const InputDecoration(
                  hintText: "Paste Job Description here...",
                  border: OutlineInputBorder(),
                  filled: true,
                  fillColor: Colors.white,
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: cvController,
                maxLines: 6,
                decoration: const InputDecoration(
                  hintText: "Paste Candidate CV here...",
                  border: OutlineInputBorder(),
                  filled: true,
                  fillColor: Colors.white,
                ),
              ),
              const SizedBox(height: 12),

              // Upload Resume
              Row(
                children: [
                  ElevatedButton.icon(
                    onPressed: () async {
                      final result = await FilePicker.platform.pickFiles(
                        type: FileType.custom,
                        allowedExtensions: ['pdf', 'doc', 'docx', 'txt'],
                      );
                      if (result != null && result.files.isNotEmpty) {
                        setState(() => uploadedResume = result.files.first);
                      }
                    },
                    icon: const Icon(Icons.upload_file),
                    label: const Text("Upload Resume (Optional)"),
                  ),
                  const SizedBox(width: 12),
                  if (uploadedResume != null)
                    Text(uploadedResume!.name,
                        style: const TextStyle(color: Colors.grey)),
                ],
              ),
              const SizedBox(height: 12),

              ElevatedButton(
                onPressed: _isParsing
                    ? null
                    : () async {
                        final jobDesc = jobDescController.text.trim();
                        final cvText = cvController.text.trim();
                        if (jobDesc.isEmpty || cvText.isEmpty) return;

                        setState(() => _isParsing = true);
                        await analyzeCV();
                        setState(() => _isParsing = false);
                      },
                child: const Text("Analyze CV"),
              ),

              const SizedBox(height: 12),
              if (cvAnalysisResult != null)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    jsonEncode(cvAnalysisResult),
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFooter() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 60, vertical: 40),
      color: const Color(0xFF14131E).withOpacity(0.9), // Updated color
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
