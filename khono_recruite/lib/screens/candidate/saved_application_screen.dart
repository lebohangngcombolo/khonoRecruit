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
        setState(() {
          savedApplications = data;
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

  void _navigateToDraft(Map<String, dynamic> draft) {
    final lastScreen = draft['last_saved_screen'] ?? 'job_details';
    final applicationId = draft['id'];
    final job = draft['job'] ?? {};

    if (lastScreen == 'assessment') {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => AssessmentPage(applicationId: applicationId),
        ),
      );
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => JobDetailsPage(
            job: job,
            draftData: draft, // pass the draft to prefill form
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: Colors.redAccent),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("Saved Applications"),
        backgroundColor: Colors.redAccent,
      ),
      body: savedApplications.isEmpty
          ? Center(
              child: Text(
                "No saved applications yet.",
                style: GoogleFonts.poppins(fontSize: 16),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: savedApplications.length,
              itemBuilder: (context, index) {
                final draft = savedApplications[index];
                final job = draft['job'] ?? {};
                final savedDate = draft['updated_at'] ?? '';

                return Card(
                  elevation: 3,
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: const BorderSide(color: Colors.redAccent, width: 1),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          job['title'] ?? "Job Title Not Available",
                          style: GoogleFonts.poppins(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.redAccent,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          job['company'] ?? "Company Not Available",
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            color: Colors.grey.shade700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "Saved on: $savedDate",
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: () => _navigateToDraft(draft),
                            icon: const Icon(Icons.edit_outlined),
                            label: Text("Continue Application",
                                style: GoogleFonts.poppins(fontSize: 14)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.redAccent,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
