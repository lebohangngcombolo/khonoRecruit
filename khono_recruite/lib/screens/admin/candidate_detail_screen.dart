import 'dart:html' as html; // For web download
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';
import '../../services/admin_service.dart';
import '../../widgets/custom_button.dart';
import 'interview_schedule_page.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import '../../providers/theme_provider.dart';

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

class _CandidateDetailScreenState extends State<CandidateDetailScreen> {
  final AdminService admin = AdminService();
  final storage = const FlutterSecureStorage();

  Map<String, dynamic>? candidateData;
  List<Map<String, dynamic>> interviews = [];
  bool loading = true;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    fetchAllData();
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
      final candidate = data['candidate'] ?? {};

      // Map data from all three sources
      candidateData = {
        // Personal Information - from candidate table
        "full_name": candidate['full_name'] ?? 'Unknown Candidate',
        "email": candidate['email'] ?? 'No email',
        "phone": candidate['phone'] ?? 'No phone',

        // Background Information - from candidate table
        "education": _formatEducation(candidate['education']),
        "skills": _formatSkills(candidate['skills']),
        "work_experience": _formatWorkExperience(candidate['work_experience']),

        // CV Data - from applications table
        "cv_score": application['cv_score']?.toDouble() ?? 0.0,
        "cv_file": application['resume_url'] ?? '',

        // Assessment Results - from assessment_results table
        "assessment_score": assessment['percentage_score']?.toDouble() ?? 0.0,
        "assessment_recommendation":
            assessment['recommendation'] ?? 'No assessment completed',

        // Status - from applications table
        "status": application['status'] ?? 'Pending',

        "candidate_id": application['candidate_id'] ?? widget.candidateId,
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

// Helper methods to format the data
  String _formatEducation(dynamic education) {
    if (education == null || (education is List && education.isEmpty)) {
      return 'No education information';
    }
    if (education is String) return education;
    if (education is List) {
      final formatted = education
          .map((edu) {
            if (edu is Map) {
              return '${edu['degree'] ?? ''} at ${edu['institution'] ?? ''} (${edu['year'] ?? ''})';
            }
            return edu.toString();
          })
          .where((item) => item.isNotEmpty)
          .join(', ');
      return formatted.isNotEmpty ? formatted : 'No education information';
    }
    return education.toString();
  }

  String _formatSkills(dynamic skills) {
    if (skills == null || (skills is List && skills.isEmpty)) {
      return 'No skills listed';
    }
    if (skills is String) return skills;
    if (skills is List) {
      final skillList = skills
          .where((skill) => skill != null && skill.toString().isNotEmpty)
          .toList();
      return skillList.isNotEmpty ? skillList.join(', ') : 'No skills listed';
    }
    return skills.toString();
  }

  String _formatWorkExperience(dynamic workExp) {
    if (workExp == null || (workExp is List && workExp.isEmpty)) {
      return 'No work experience';
    }
    if (workExp is String) return workExp;
    if (workExp is List) {
      final formatted = workExp
          .map((exp) {
            if (exp is Map) {
              return '${exp['role'] ?? ''} at ${exp['company'] ?? ''} (${exp['duration'] ?? ''})';
            }
            return exp.toString();
          })
          .where((item) => item.isNotEmpty)
          .join('; ');
      return formatted.isNotEmpty ? formatted : 'No work experience';
    }
    return workExp.toString();
  }

  Future<void> downloadCV(
      int applicationId, BuildContext context, String candidateName) async {
    try {
      final jwtToken = await storage.read(key: "access_token");

      if (jwtToken == null || jwtToken.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("No token found. Please log in again.")),
        );
        return;
      }

      final response = await http.get(
        Uri.parse(
            'http://127.0.0.1:5000/api/admin/applications/$applicationId/download-cv'),
        headers: {
          'Authorization': 'Bearer $jwtToken',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode != 200) {
        print("Backend error: ${response.statusCode} ${response.body}");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to get CV URL from backend")),
        );
        return;
      }

      final data = json.decode(response.body);
      final cvUrl = data['cv_url'];
      final fullName = data['candidate_name'] ?? candidateName;

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
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDarkMode;

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded,
              color: isDark ? Colors.white : Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "Candidate Profile",
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 20,
            color: isDark ? Colors.white : Colors.black87,
          ),
        ),
        backgroundColor:
            (isDark ? const Color(0xFF14131E) : Colors.white).withOpacity(0.95),
        elevation: 2,
        shadowColor: Colors.black.withOpacity(0.1),
        actions: [
          IconButton(
            onPressed: fetchAllData,
            icon: Icon(Icons.refresh_rounded,
                color: isDark ? Colors.white : Colors.black87),
            tooltip: "Refresh",
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage(themeProvider.backgroundImage),
            fit: BoxFit.cover,
          ),
        ),
        child: loading
            ? _buildLoadingState(isDark)
            : errorMessage != null
                ? _buildErrorState(errorMessage!, isDark)
                : _buildContent(isDark),
      ),
    );
  }

  Widget _buildLoadingState(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 60,
            height: 60,
            child: CircularProgressIndicator(
              strokeWidth: 3,
              valueColor: AlwaysStoppedAnimation<Color>(
                  isDark ? Colors.white : Colors.black87),
              backgroundColor:
                  (isDark ? Colors.white : Colors.black87).withOpacity(0.2),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            "Loading Candidate Details...",
            style: TextStyle(
              fontSize: 16,
              color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String error, bool isDark) {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.red.shade50.withOpacity(0.9),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.red.shade200),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline_rounded,
              color: Colors.red,
              size: 48,
            ),
            const SizedBox(height: 16),
            Text(
              "Unable to load candidate details",
              style: TextStyle(
                color: Colors.red.shade800,
                fontWeight: FontWeight.w600,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              error,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.red.shade600,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 20),
            CustomButton(
              text: "Try Again",
              onPressed: fetchAllData,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(bool isDark) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Section
          _buildHeaderSection(isDark),
          const SizedBox(height: 24),

          // Main Content Grid
          LayoutBuilder(
            builder: (context, constraints) {
              final crossAxisCount = constraints.maxWidth > 1200
                  ? 3
                  : constraints.maxWidth > 800
                      ? 2
                      : 1;

              return GridView.count(
                crossAxisCount: crossAxisCount,
                mainAxisSpacing: 20,
                crossAxisSpacing: 20,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  _buildPersonalInfoCard(isDark),
                  _buildCVCard(isDark),
                  _buildEducationCard(isDark),
                  _buildAssessmentCard(isDark),
                  _buildInterviewsCard(isDark),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderSection(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [
                  Color(0xFF1E1B2E).withOpacity(0.9),
                  Color(0xFF14131E).withOpacity(0.9),
                ]
              : [
                  Colors.white.withOpacity(0.95),
                  Colors.grey.shade50.withOpacity(0.95),
                ],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 25,
            offset: const Offset(0, 10),
          ),
        ],
        border: Border.all(
          color: isDark
              ? Colors.white.withOpacity(0.1)
              : Colors.black.withOpacity(0.05),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 80,
            height: 80,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.blueAccent.withOpacity(0.2),
                  Colors.purpleAccent.withOpacity(0.3),
                ],
              ),
              shape: BoxShape.circle,
            ),
            child: Text(
              _getInitials(candidateData!['full_name']),
              style: TextStyle(
                color: Colors.blueAccent,
                fontWeight: FontWeight.w700,
                fontSize: 24,
              ),
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  candidateData!['full_name'],
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.email_outlined,
                        size: 16,
                        color: isDark
                            ? Colors.grey.shade400
                            : Colors.grey.shade600),
                    const SizedBox(width: 8),
                    Text(
                      candidateData!['email'],
                      style: TextStyle(
                        color: isDark
                            ? Colors.grey.shade400
                            : Colors.grey.shade600,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.phone_outlined,
                        size: 16,
                        color: isDark
                            ? Colors.grey.shade400
                            : Colors.grey.shade600),
                    const SizedBox(width: 8),
                    Text(
                      candidateData!['phone'],
                      style: TextStyle(
                        color: isDark
                            ? Colors.grey.shade400
                            : Colors.grey.shade600,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: _getStatusColor(candidateData!['status']).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color:
                    _getStatusColor(candidateData!['status']).withOpacity(0.3),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  _getStatusIcon(candidateData!['status']),
                  size: 16,
                  color: _getStatusColor(candidateData!['status']),
                ),
                const SizedBox(width: 8),
                Text(
                  candidateData!['status'].toString().toUpperCase(),
                  style: TextStyle(
                    color: _getStatusColor(candidateData!['status']),
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPersonalInfoCard(bool isDark) {
    return _buildInfoCard(
      isDark: isDark,
      icon: Icons.person_outline_rounded,
      title: "Personal Information",
      children: [
        _buildInfoRow("Full Name", candidateData!['full_name'], isDark),
        _buildInfoRow("Email", candidateData!['email'], isDark),
        _buildInfoRow("Phone", candidateData!['phone'], isDark),
        _buildInfoRow("Status", candidateData!['status'], isDark,
            valueColor: _getStatusColor(candidateData!['status'])),
      ],
    );
  }

  Widget _buildCVCard(bool isDark) {
    return _buildInfoCard(
      isDark: isDark,
      icon: Icons.description_outlined,
      title: "CV Details",
      actionIcon: Icons.download_rounded,
      onAction: () {
        downloadCV(
          candidateData!['candidate_id'],
          context,
          candidateData!['full_name'] ?? "candidate",
        );
      },
      children: [
        _buildScoreRow(
            "CV Score", candidateData!['cv_score'].toDouble(), isDark),
        const SizedBox(height: 12),
        Text(
          "Click the download icon to get the candidate's CV",
          style: TextStyle(
            color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
            fontSize: 12,
            fontStyle: FontStyle.italic,
          ),
        ),
      ],
    );
  }

  Widget _buildEducationCard(bool isDark) {
    return _buildInfoCard(
      isDark: isDark,
      icon: Icons.school_outlined,
      title: "Background",
      children: [
        if (candidateData!['education'] != null &&
            candidateData!['education'].isNotEmpty)
          _buildInfoRow("Education", candidateData!['education'], isDark),
        if (candidateData!['skills'] != null &&
            candidateData!['skills'].isNotEmpty)
          _buildInfoRow("Skills", candidateData!['skills'], isDark),
        if (candidateData!['work_experience'] != null &&
            candidateData!['work_experience'].isNotEmpty)
          _buildInfoRow(
              "Work Experience", candidateData!['work_experience'], isDark),
      ],
    );
  }

  Widget _buildAssessmentCard(bool isDark) {
    return _buildInfoCard(
      isDark: isDark,
      icon: Icons.analytics_outlined,
      title: "Assessment Results",
      children: [
        _buildScoreRow(
            "Assessment Score",
            double.tryParse(candidateData!['assessment_score'].toString()) ?? 0,
            isDark),
        const SizedBox(height: 12),
        _buildInfoRow("Recommendation",
            candidateData!['assessment_recommendation'], isDark),
      ],
    );
  }

  Widget _buildInterviewsCard(bool isDark) {
    return _buildInfoCard(
      isDark: isDark,
      icon: Icons.calendar_today_outlined,
      title: "Scheduled Interviews",
      actionIcon: Icons.add_rounded,
      onAction: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ScheduleInterviewPage(
              candidateId: widget.candidateId,
            ),
          ),
        ).then((_) => fetchAllData());
      },
      children: [
        if (interviews.isEmpty)
          Center(
            child: Column(
              children: [
                Icon(
                  Icons.event_busy_outlined,
                  size: 48,
                  color: isDark ? Colors.grey.shade600 : Colors.grey.shade400,
                ),
                const SizedBox(height: 12),
                Text(
                  "No interviews scheduled",
                  style: TextStyle(
                    color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          )
        else
          ...interviews
              .map((interview) => _buildInterviewItem(interview, isDark))
              .toList(),
      ],
    );
  }

  Widget _buildInfoCard({
    required bool isDark,
    required IconData icon,
    required String title,
    required List<Widget> children,
    IconData? actionIcon,
    VoidCallback? onAction,
  }) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [
                  Color(0xFF1E1B2E).withOpacity(0.8),
                  Color(0xFF14131E).withOpacity(0.9),
                ]
              : [
                  Colors.white.withOpacity(0.95),
                  Colors.grey.shade50.withOpacity(0.95),
                ],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 15,
            offset: const Offset(0, 6),
          ),
        ],
        border: Border.all(
          color: isDark
              ? Colors.white.withOpacity(0.1)
              : Colors.black.withOpacity(0.05),
        ),
      ),
      child: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.blueAccent.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(icon, size: 20, color: Colors.blueAccent),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                ...children,
              ],
            ),
          ),
          if (actionIcon != null)
            Positioned(
              top: 16,
              right: 16,
              child: IconButton(
                onPressed: onAction,
                icon: Icon(actionIcon,
                    size: 20, color: isDark ? Colors.white : Colors.black87),
                style: IconButton.styleFrom(
                  backgroundColor: Colors.blueAccent.withOpacity(0.1),
                  padding: const EdgeInsets.all(6),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, bool isDark,
      {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              "$label:",
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 12,
                color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: TextStyle(
                fontSize: 12,
                color: valueColor ?? (isDark ? Colors.white : Colors.black87),
                fontWeight:
                    valueColor != null ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScoreRow(String label, double score, bool isDark) {
    final color = _getScoreColor(score);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(
            child: Text(
              "$label:",
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 12,
                color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: color.withOpacity(0.3)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  "${score.toStringAsFixed(1)}%",
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInterviewItem(Map<String, dynamic> interview, bool isDark) {
    final scheduled = DateTime.parse(interview['scheduled_time']);
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.05) : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? Colors.white.withOpacity(0.1) : Colors.grey.shade200,
        ),
      ),
      child: Row(
        children: [
          Icon(Icons.calendar_month_outlined,
              size: 16, color: Colors.blueAccent),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  DateFormat.yMd().add_jm().format(scheduled),
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
                Text(
                  "Interviewer: ${interview['hiring_manager_name'] ?? 'N/A'}",
                  style: TextStyle(
                    fontSize: 11,
                    color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
          CustomButton(
            text: "Cancel",
            color: Colors.redAccent,
            onPressed: () => cancelInterview(interview['id'] as int),
          ),
        ],
      ),
    );
  }

  // Helper methods
  String _getInitials(String fullName) {
    if (fullName.isEmpty) return "?";
    final parts = fullName.trim().split(' ');
    if (parts.length == 1) return parts[0].substring(0, 1).toUpperCase();
    return '${parts[0].substring(0, 1)}${parts[parts.length - 1].substring(0, 1)}'
        .toUpperCase();
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case "hired":
        return Colors.green;
      case "rejected":
        return Colors.red;
      case "interview":
        return Colors.blue;
      default:
        return Colors.orange;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case "hired":
        return Icons.work_outline;
      case "rejected":
        return Icons.cancel_outlined;
      case "interview":
        return Icons.calendar_today_outlined;
      default:
        return Icons.pending_outlined;
    }
  }

  Color _getScoreColor(double score) {
    if (score >= 70) return Colors.green;
    if (score >= 50) return Colors.orange;
    return Colors.redAccent;
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
