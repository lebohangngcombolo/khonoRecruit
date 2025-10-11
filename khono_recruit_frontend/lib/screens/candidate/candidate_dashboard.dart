import 'dart:convert';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;

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
                                        builder: (_) => UserAccountPage(
                                            token: widget.token)),
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
                                      builder: (_) => UserAccountPage(
                                          token: widget.token)));
                            },
                            child: sidebarCollapsed
                                ? CircleAvatar(
                                    backgroundColor: Colors.redAccent,
                                    radius: 16,
                                    child: const Icon(Icons.person,
                                        color: Colors.white, size: 16),
                                  )
                                : Row(
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
                                          "Candidate User",
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
                                  onPressed: () {},
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
                SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Navbar
                      Container(
                        height: 72,
                        decoration: const BoxDecoration(color: Colors.white),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      "Welcome Back, Candidate",
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
                                    icon: const Icon(Icons.add_box_outlined,
                                        color: Colors.redAccent),
                                    label: const Text("Create",
                                        style:
                                            TextStyle(color: Colors.black87)),
                                  ),
                                  const SizedBox(width: 12),
                                  IconButton(
                                      onPressed: () =>
                                          setState(() => selectedIndex = 4),
                                      icon:
                                          const Icon(Icons.notifications_none)),
                                  const SizedBox(width: 12),
                                  CircleAvatar(
                                      radius: 18,
                                      backgroundColor: Colors.grey.shade200,
                                      child: const Icon(Icons.person,
                                          color: Colors.redAccent)),
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
                        UserAccountPage(token: widget.token)
                      else if (selectedIndex == 4)
                        buildNotifications(),

                      const SizedBox(height: 40),
                      _buildFooter(),
                    ],
                  ),
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
        Container(
          height: 300,
          width: double.infinity,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: Colors.grey.shade100,
          ),
          child: const Center(
              child: Text("Dashboard Banner", style: TextStyle(fontSize: 20))),
        ),
        const SizedBox(height: 16),
        Text("Available Jobs",
            style:
                GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.w600)),
        const SizedBox(height: 12),
        if (loadingJobs)
          const Center(child: CircularProgressIndicator())
        else
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2, mainAxisSpacing: 12, crossAxisSpacing: 12),
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
                child: Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(job['title'] ?? "Job Title",
                            style: const TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 16)),
                        const SizedBox(height: 6),
                        Text(job['company'] ?? "Company",
                            style: const TextStyle(
                                color: Colors.grey, fontSize: 14)),
                        const SizedBox(height: 6),
                        Text(job['location'] ?? "Location",
                            style: const TextStyle(
                                color: Colors.grey, fontSize: 12)),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
      ],
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
          .map((notif) => ListTile(
                leading: const Icon(Icons.notifications),
                title: Text(notif['title'] ?? ""),
                subtitle: Text(notif['body'] ?? ""),
              ))
          .toList(),
    );
  }

  // ---------- Chatbot Panel ----------
  Widget buildChatbotPanel() {
    return Container(
      width: 400,
      height: 550,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(2, 4))
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Text("AI Chatbot",
                  style: TextStyle(fontWeight: FontWeight.bold)),
              const Spacer(),
              IconButton(
                  onPressed: () => setState(() => chatbotOpen = false),
                  icon: const Icon(Icons.close)),
            ],
          ),
          const Divider(),

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
          const Divider(),

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
                      child: Text(msg['text'] ?? ""),
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
                decoration: const InputDecoration(hintText: "Type message..."),
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
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: cvController,
                maxLines: 6,
                decoration: const InputDecoration(
                  hintText: "Paste Candidate CV here...",
                  border: OutlineInputBorder(),
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
                        if (jobDesc.isEmpty &&
                            cvText.isEmpty &&
                            uploadedResume == null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content:
                                      Text("Provide job description or CV")));
                          return;
                        }

                        setState(() {
                          _isParsing = true;
                          cvAnalysisResult = null;
                        });

                        var uri =
                            Uri.parse("http://127.0.0.1:5000/api/ai/parse_cv");
                        var request = http.MultipartRequest("POST", uri);
                        request.headers['Authorization'] =
                            "Bearer ${widget.token}";
                        request.fields['job_description'] = jobDesc;
                        if (cvText.isNotEmpty)
                          request.fields['cv_text'] = cvText;
                        if (uploadedResume != null) {
                          request.files.add(await http.MultipartFile.fromPath(
                              'resume', uploadedResume!.path!));
                        }

                        try {
                          final streamed = await request.send();
                          final response =
                              await http.Response.fromStream(streamed);
                          if (response.statusCode == 200) {
                            final data = jsonDecode(response.body);
                            setState(
                                () => cvAnalysisResult = data['parser_result']);
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                                content: Text(
                                    "Failed to parse CV (status ${response.statusCode})")));
                          }
                        } catch (e) {
                          ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text("Error: $e")));
                        } finally {
                          setState(() => _isParsing = false);
                        }
                      },
                style:
                    ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
                child: _isParsing
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                    : const Text("Analyze CV"),
              ),
              const SizedBox(height: 12),

              if (cvAnalysisResult != null)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                          "Match Score: ${cvAnalysisResult!['match_score'] ?? 0}"),
                      const SizedBox(height: 4),
                      Text(
                          "Missing Skills: ${(cvAnalysisResult!['missing_skills'] as List<dynamic>?)?.join(', ') ?? ''}"),
                      const SizedBox(height: 4),
                      Text(
                          "Suggestions: ${(cvAnalysisResult!['suggestions'] as List<dynamic>?)?.join(', ') ?? ''}"),
                      const SizedBox(height: 4),
                      Text(
                          "Interview Questions: ${(cvAnalysisResult!['interview_questions'] as List<dynamic>?)?.join(', ') ?? ''}"),
                      if (cvAnalysisResult!.containsKey('error'))
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            "AI Error: ${cvAnalysisResult!['error']}",
                            style: const TextStyle(color: Colors.red),
                          ),
                        ),
                      if (cvAnalysisResult!.containsKey('cv_url'))
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            "Uploaded CV URL: ${cvAnalysisResult!['cv_url']}",
                            style: const TextStyle(color: Colors.blue),
                          ),
                        ),
                    ],
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFooter() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Text("© 2025 Recruitment Platform. All rights reserved.",
            style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
      ),
    );
  }
}
