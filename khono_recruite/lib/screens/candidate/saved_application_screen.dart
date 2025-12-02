import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import '../../services/auth_service.dart';
import '../candidate/job_details_page.dart';
import '../candidate/assessment_page.dart';

class SavedApplicationsScreen extends StatefulWidget {
  final String token;
  const SavedApplicationsScreen({super.key, required this.token});

  @override
  State<SavedApplicationsScreen> createState() =>
      _SavedApplicationsScreenState();
}

class _SavedApplicationsScreenState extends State<SavedApplicationsScreen> {
  bool loading = true;
  List<dynamic> savedApplications = [];

  @override
  void initState() {
    super.initState();
    _fetchSavedApplications();
  }

  Future<void> _fetchSavedApplications() async {
    setState(() => loading = true);
    final token = await AuthService.getAccessToken();

    try {
      final res = await http.get(
        Uri.parse("http://127.0.0.1:5000/api/candidate/applications/drafts"),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
      );

      if (res.statusCode == 200) {
        final data = json.decode(res.body);
        final normalized = List<Map<String, dynamic>>.from(
          data.map((e) => Map<String, dynamic>.from(e)),
        );

        setState(() {
          savedApplications = normalized;
        });
      } else {
        throw Exception("Failed to load saved applications");
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    } finally {
      setState(() => loading = false);
    }
  }

  void _navigateToDraft(Map<dynamic, dynamic> draft) {
    // Normalize draft into a clean Map<String, dynamic>
    final normalizedDraft = Map<String, dynamic>.from(
      draft.map((key, value) {
        if (value is Map) {
          return MapEntry(key.toString(), Map<String, dynamic>.from(value));
        }
        return MapEntry(key.toString(), value);
      }),
    );

    final lastScreen = normalizedDraft['last_saved_screen'] ?? 'job_details';
    final applicationId = normalizedDraft['id'];
    final job = normalizedDraft['job'] != null
        ? Map<String, dynamic>.from(normalizedDraft['job'])
        : <String, dynamic>{};

    // Extract draft_data for the specific screen
    final draftDataMap = normalizedDraft['draft_data'] != null
        ? Map<String, dynamic>.from(normalizedDraft['draft_data'])
        : <String, dynamic>{};

    Map<String, dynamic> draftDataForPage = {};
    if (lastScreen == 'assessment') {
      draftDataForPage = draftDataMap['assessment'] != null
          ? Map<String, dynamic>.from(draftDataMap['assessment'])
          : {};
    } else {
      draftDataForPage = draftDataMap['job_details'] != null
          ? Map<String, dynamic>.from(draftDataMap['job_details'])
          : {};
    }

    // Include the applicationId
    draftDataForPage['application_id'] = applicationId;

    if (lastScreen == 'assessment') {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => AssessmentPage(
            applicationId: applicationId,
            draftData: draftDataForPage,
          ),
        ),
      );
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => JobDetailsPage(
            job: job,
            draftData: draftDataForPage,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return Scaffold(
        backgroundColor: Colors.transparent,
        body: Stack(
          children: [
            // Background Image
            Container(
              decoration: BoxDecoration(
                image: DecorationImage(
                  image: AssetImage("assets/images/dark.png"),
                  fit: BoxFit.cover,
                ),
              ),
            ),
            Center(
              child: Container(
                padding: EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.9),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(color: Colors.redAccent),
                    SizedBox(height: 16),
                    Text(
                      "Loading your applications...",
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
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

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          // Background Image
          Container(
            decoration: BoxDecoration(
              image: DecorationImage(
                image: AssetImage("assets/images/dark.png"),
                fit: BoxFit.cover,
              ),
            ),
          ),
          Column(
            children: [
              // App Bar
              Container(
                width: double.infinity,
                padding: EdgeInsets.only(
                  top: MediaQuery.of(context).padding.top + 16,
                  bottom: 16,
                  left: 16,
                  right: 16,
                ),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withOpacity(0.7),
                      Colors.transparent,
                    ],
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.9),
                        borderRadius: BorderRadius.circular(30),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 8,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: IconButton(
                        icon: Icon(Icons.arrow_back, color: Colors.black87),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ),
                    SizedBox(width: 16),
                    Text(
                      "Saved Applications",
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: savedApplications.isEmpty
                    ? Center(
                        child: Container(
                          padding: EdgeInsets.all(24),
                          margin: EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.9),
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 20,
                                offset: Offset(0, 10),
                              ),
                            ],
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.drafts_outlined,
                                size: 64,
                                color: const Color.fromARGB(255, 112, 16, 16),
                              ),
                              SizedBox(height: 16),
                              Text(
                                "No saved applications yet",
                                style: GoogleFonts.poppins(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.grey.shade800,
                                ),
                              ),
                              SizedBox(height: 8),
                              Text(
                                "Your draft applications will appear here",
                                style: GoogleFonts.poppins(
                                  fontSize: 14,
                                  color: Colors.grey.shade600,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      )
                    : ListView.builder(
                        padding: EdgeInsets.all(16),
                        itemCount: savedApplications.length,
                        itemBuilder: (context, index) {
                          final draft = savedApplications[index];
                          final job = draft['job'] ?? {};
                          final savedDate = draft['updated_at'] ?? '';

                          return Container(
                            margin: EdgeInsets.symmetric(vertical: 8),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.15),
                                  blurRadius: 20,
                                  offset: Offset(0, 8),
                                ),
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  blurRadius: 10,
                                  offset: Offset(0, 2),
                                ),
                              ],
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(16),
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.9),
                                  border: Border.all(
                                    color:
                                        const Color.fromARGB(255, 112, 16, 16)
                                            .withOpacity(0.3),
                                    width: 1,
                                  ),
                                ),
                                child: Padding(
                                  padding: EdgeInsets.all(20),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Container(
                                            padding: EdgeInsets.all(8),
                                            decoration: BoxDecoration(
                                              color: const Color.fromARGB(
                                                      255, 112, 16, 16)
                                                  .withOpacity(0.1),
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                            ),
                                            child: Icon(
                                              Icons.work_outline,
                                              color: const Color.fromARGB(
                                                  255, 112, 16, 16),
                                              size: 24,
                                            ),
                                          ),
                                          SizedBox(width: 12),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  job['title'] ??
                                                      "Job Title Not Available",
                                                  style: GoogleFonts.poppins(
                                                    fontSize: 18,
                                                    fontWeight: FontWeight.bold,
                                                    color: const Color.fromARGB(
                                                        255, 112, 16, 16),
                                                  ),
                                                  maxLines: 2,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                                SizedBox(height: 4),
                                                Text(
                                                  job['company'] ??
                                                      "Company Not Available",
                                                  style: GoogleFonts.poppins(
                                                    fontSize: 14,
                                                    color: Colors.grey.shade700,
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                      SizedBox(height: 12),
                                      Container(
                                        padding: EdgeInsets.symmetric(
                                            horizontal: 12, vertical: 6),
                                        decoration: BoxDecoration(
                                          color: Colors.grey.shade100,
                                          borderRadius:
                                              BorderRadius.circular(8),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(
                                              Icons.access_time_outlined,
                                              size: 16,
                                              color: Colors.grey.shade600,
                                            ),
                                            SizedBox(width: 6),
                                            Text(
                                              "Saved on: $savedDate",
                                              style: GoogleFonts.poppins(
                                                fontSize: 12,
                                                color: Colors.grey.shade600,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      SizedBox(height: 16),
                                      SizedBox(
                                        width: double.infinity,
                                        child: ElevatedButton.icon(
                                          onPressed: () =>
                                              _navigateToDraft(draft),
                                          icon: Icon(Icons.edit_outlined,
                                              size: 20),
                                          label: Text(
                                            "Continue Application",
                                            style: GoogleFonts.poppins(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor:
                                                const Color.fromARGB(
                                                    255, 112, 16, 16),
                                            foregroundColor: Colors.white,
                                            padding: EdgeInsets.symmetric(
                                                vertical: 16),
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                            ),
                                            elevation: 2,
                                            shadowColor: const Color.fromARGB(
                                                    255, 112, 16, 16)
                                                .withOpacity(0.3),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
