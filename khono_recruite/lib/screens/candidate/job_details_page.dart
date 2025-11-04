import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import '../../services/auth_service.dart';
import 'assessment_page.dart';

class JobDetailsPage extends StatefulWidget {
  final Map<String, dynamic> job;
  final Map<String, dynamic>? draftData;

  const JobDetailsPage({
    super.key,
    required this.job,
    this.draftData,
  });

  @override
  State<JobDetailsPage> createState() => _JobDetailsPageState();
}

class _JobDetailsPageState extends State<JobDetailsPage> {
  int? applicationId;
  bool submitting = false;

  final _formKey = GlobalKey<FormState>();
  final TextEditingController fullNameController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController portfolioController = TextEditingController();
  final TextEditingController coverLetterController = TextEditingController();

  @override
  void initState() {
    super.initState();

    if (widget.draftData != null) {
      final draft = widget.draftData!;
      fullNameController.text = draft["full_name"] ?? "";
      phoneController.text = draft["phone"] ?? "";
      portfolioController.text = draft["portfolio"] ?? "";
      coverLetterController.text = draft["cover_letter"] ?? "";
      applicationId = draft["application_id"];
    }
  }

  Future<void> loadDraft() async {
    if (applicationId == null) return;

    final token = await AuthService.getAccessToken();
    try {
      final res = await http.get(
        Uri.parse(
            "http://127.0.0.1:5000/api/candidate/applications/$applicationId/draft"),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
      );

      if (res.statusCode == 200) {
        final data = json.decode(res.body);
        setState(() {
          fullNameController.text = data["full_name"] ?? "";
          phoneController.text = data["phone"] ?? "";
          portfolioController.text = data["portfolio"] ?? "";
          coverLetterController.text = data["cover_letter"] ?? "";
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Error loading draft: $e")));
    }
  }

  Future<void> saveDraftAndExit() async {
    if (applicationId == null) return;

    final token = await AuthService.getAccessToken();
    try {
      final res = await http.post(
        Uri.parse(
            "http://127.0.0.1:5000/api/candidate/applications/$applicationId/draft"),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
        body: json.encode({
          "full_name": fullNameController.text,
          "phone": phoneController.text,
          "portfolio": portfolioController.text,
          "cover_letter": coverLetterController.text,
        }),
      );

      if (res.statusCode == 200 || res.statusCode == 201) {
        Navigator.pushReplacementNamed(context, '/dashboard');
      } else {
        final data = json.decode(res.body);
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(data["error"] ?? "Failed to save draft")));
      }
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Error: $e")));
    }
  }

  Future<void> applyJob() async {
    if (!_formKey.currentState!.validate()) return;

    final token = await AuthService.getAccessToken();
    setState(() => submitting = true);

    try {
      final res = await http.post(
        Uri.parse(
            "http://127.0.0.1:5000/api/candidate/apply/${widget.job["id"]}"),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
        body: json.encode({
          "full_name": fullNameController.text,
          "phone": phoneController.text,
          "portfolio": portfolioController.text,
          "cover_letter": coverLetterController.text,
        }),
      );

      if (res.statusCode == 201) {
        final data = json.decode(res.body);
        setState(() {
          applicationId = data["application_id"];
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Applied successfully!")),
        );
      } else {
        final data = json.decode(res.body);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(data["error"] ?? "Apply failed")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Error: $e")));
    } finally {
      setState(() => submitting = false);
    }
  }

  @override
  void dispose() {
    fullNameController.dispose();
    phoneController.dispose();
    portfolioController.dispose();
    coverLetterController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final responsibilities = widget.job["responsibilities"];
    final List<String> responsibilitiesList = (responsibilities is List)
        ? List<String>.from(responsibilities)
        : ["Responsibility 1", "Responsibility 2", "Responsibility 3"];

    final qualifications = widget.job["qualifications"];
    final List<String> qualificationsList = (qualifications is List)
        ? List<String>.from(qualifications)
        : ["Qualification 1", "Qualification 2", "Qualification 3"];

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Banner
            Stack(
              children: [
                Image.asset(
                  widget.job["banner"] ?? "assets/images/team1.jpg",
                  width: double.infinity,
                  height: 400,
                  fit: BoxFit.cover,
                ),
                Container(
                  height: 400,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withOpacity(0.6),
                        Colors.transparent,
                        Colors.black.withOpacity(0.3),
                      ],
                    ),
                  ),
                ),
                Positioned(
                  top: 40,
                  left: 16,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(30),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.black87),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ),
                ),
                Positioned(
                  bottom: 40,
                  left: 24,
                  right: 24,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.job["title"] ?? "",
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "${widget.job["company"] ?? ""} • ${widget.job["location"] ?? ""}",
                        style: GoogleFonts.poppins(
                          color: Colors.white.withOpacity(0.9),
                          fontSize: 18,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Main Column
                      Expanded(
                        flex: 2,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildEnhancedCard(
                              Icons.description_outlined,
                              "Job Description",
                              Colors.blue,
                              [
                                Text(
                                  widget.job["description"] ??
                                      "No description available.",
                                  style: GoogleFonts.poppins(
                                    fontSize: 14,
                                    color: Colors.grey.shade700,
                                    height: 1.6,
                                  ),
                                )
                              ],
                            ),
                            _buildEnhancedCard(
                              Icons.checklist_outlined,
                              "Responsibilities",
                              Colors.green,
                              responsibilitiesList
                                  .map((r) => Padding(
                                        padding: const EdgeInsets.symmetric(
                                            vertical: 4),
                                        child: Row(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Icon(Icons.circle,
                                                size: 8, color: Colors.green),
                                            const SizedBox(width: 12),
                                            Expanded(
                                              child: Text(
                                                r,
                                                style: GoogleFonts.poppins(
                                                  fontSize: 14,
                                                  color: Colors.grey.shade700,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ))
                                  .toList(),
                            ),
                            _buildEnhancedCard(
                              Icons.school_outlined,
                              "Qualifications",
                              Colors.orange,
                              qualificationsList
                                  .map((q) => Padding(
                                        padding: const EdgeInsets.symmetric(
                                            vertical: 4),
                                        child: Row(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Icon(Icons.verified,
                                                size: 16, color: Colors.orange),
                                            const SizedBox(width: 12),
                                            Expanded(
                                              child: Text(
                                                q,
                                                style: GoogleFonts.poppins(
                                                  fontSize: 14,
                                                  color: Colors.grey.shade700,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ))
                                  .toList(),
                            ),
                            _buildEnhancedCard(
                              Icons.work_outline,
                              "Apply For This Job",
                              Colors.red,
                              [
                                Form(
                                  key: _formKey,
                                  child: Column(
                                    children: [
                                      _buildEnhancedTextField(
                                        controller: fullNameController,
                                        label: "Full Name",
                                        icon: Icons.person_outline,
                                      ),
                                      const SizedBox(height: 16),
                                      _buildEnhancedTextField(
                                        controller: phoneController,
                                        label: "Phone Number",
                                        icon: Icons.phone_outlined,
                                      ),
                                      const SizedBox(height: 16),
                                      _buildEnhancedTextField(
                                        controller: portfolioController,
                                        label: "Portfolio Link",
                                        icon: Icons.link_outlined,
                                      ),
                                      const SizedBox(height: 16),
                                      _buildEnhancedTextField(
                                        controller: coverLetterController,
                                        label: "Cover Letter",
                                        icon: Icons.article_outlined,
                                        maxLines: 5,
                                      ),
                                      const SizedBox(height: 24),
                                      // Submit Application Button
                                      SizedBox(
                                        width: double.infinity,
                                        child: ElevatedButton(
                                          onPressed:
                                              submitting ? null : applyJob,
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.redAccent,
                                            foregroundColor: Colors.white,
                                            padding: const EdgeInsets.symmetric(
                                                vertical: 16),
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                            ),
                                            elevation: 2,
                                          ),
                                          child: submitting
                                              ? const SizedBox(
                                                  height: 20,
                                                  width: 20,
                                                  child:
                                                      CircularProgressIndicator(
                                                    strokeWidth: 2,
                                                    color: Colors.white,
                                                  ),
                                                )
                                              : Row(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment.center,
                                                  children: [
                                                    Icon(Icons.send_outlined,
                                                        size: 20),
                                                    const SizedBox(width: 8),
                                                    Text(
                                                      "Submit Application",
                                                      style:
                                                          GoogleFonts.poppins(
                                                        fontWeight:
                                                            FontWeight.w600,
                                                        fontSize: 16,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                        ),
                                      ),
                                      // Take Assessment Button
                                      if (applicationId != null) ...[
                                        const SizedBox(height: 16),
                                        SizedBox(
                                          width: double.infinity,
                                          child: ElevatedButton(
                                            onPressed: () {
                                              Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                  builder: (_) =>
                                                      AssessmentPage(
                                                          applicationId:
                                                              applicationId!),
                                                ),
                                              );
                                            },
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor:
                                                  Colors.deepPurpleAccent,
                                              foregroundColor: Colors.white,
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      vertical: 16),
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                              ),
                                              elevation: 2,
                                            ),
                                            child: Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              children: [
                                                Icon(Icons.quiz_outlined,
                                                    size: 20),
                                                const SizedBox(width: 8),
                                                Text(
                                                  "Take Assessment",
                                                  style: GoogleFonts.poppins(
                                                    fontWeight: FontWeight.w600,
                                                    fontSize: 16,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ],
                                      // Save & Exit Button
                                      if (applicationId != null ||
                                          widget.draftData != null) ...[
                                        const SizedBox(height: 16),
                                        SizedBox(
                                          width: double.infinity,
                                          child: ElevatedButton(
                                            onPressed: saveDraftAndExit,
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor:
                                                  Colors.grey.shade600,
                                              foregroundColor: Colors.white,
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      vertical: 16),
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                              ),
                                              elevation: 2,
                                            ),
                                            child: Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              children: [
                                                const Icon(Icons.save_outlined,
                                                    size: 20),
                                                const SizedBox(width: 8),
                                                Text(
                                                  "Save & Exit",
                                                  style: GoogleFonts.poppins(
                                                    fontWeight: FontWeight.w600,
                                                    fontSize: 16,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                )
                              ],
                            ),
                          ],
                        ),
                      ),
                      // Right Column
                      const SizedBox(width: 24),
                      Expanded(
                        flex: 1,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildEnhancedCard(
                              Icons.assignment_outlined,
                              "Job Summary",
                              Colors.purple,
                              [
                                _buildSummaryRow(
                                    Icons.calendar_today_outlined,
                                    "Published On",
                                    widget.job["published_on"] ??
                                        "01 Jan, 2045"),
                                _buildSummaryRow(
                                    Icons.people_outline,
                                    "Vacancy",
                                    widget.job["vacancy"]?.toString() ?? "1"),
                                _buildSummaryRow(
                                    Icons.schedule_outlined,
                                    "Job Nature",
                                    widget.job["type"] ?? "Full Time"),
                                _buildSummaryRow(
                                    Icons.attach_money_outlined,
                                    "Salary",
                                    widget.job["salary"] ?? "\$123 - \$456"),
                                _buildSummaryRow(
                                    Icons.location_on_outlined,
                                    "Location",
                                    widget.job["location"] ?? "New York"),
                              ],
                            ),
                            const SizedBox(height: 16),
                            _buildEnhancedCard(
                              Icons.business_outlined,
                              "Company Details",
                              Colors.teal,
                              [
                                Text(
                                  widget.job["company_details"] ??
                                      "No details available.",
                                  style: GoogleFonts.poppins(
                                    fontSize: 14,
                                    color: Colors.grey.shade700,
                                    height: 1.6,
                                  ),
                                )
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),
            _buildEnhancedFooter(),
          ],
        ),
      ),
    );
  }

  // ---------------- Helper Widgets ----------------
  Widget _buildEnhancedCard(
      IconData icon, String title, Color color, List<Widget> children) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 25,
            offset: const Offset(0, 8),
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(color: Colors.grey.shade100, width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: color, size: 24),
                ),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade800,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryRow(IconData icon, String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: Colors.grey.shade600),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEnhancedTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      style: GoogleFonts.poppins(fontSize: 14),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.poppins(color: Colors.grey.shade600),
        prefixIcon: Icon(icon, color: Colors.grey.shade500),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.redAccent, width: 2),
        ),
        filled: true,
        fillColor: Colors.grey.shade50,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
      validator: (val) => val == null || val.isEmpty ? "Required" : null,
    );
  }

  Widget _socialIcon(String assetPath, String url) {
    return Container(
      margin: const EdgeInsets.only(right: 12),
      child: InkWell(
        onTap: () async {
          final Uri uri = Uri.parse(url);
          if (await canLaunchUrl(uri)) {
            await launchUrl(uri);
          }
        },
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Image.asset(
            assetPath,
            width: 20,
            height: 20,
            fit: BoxFit.contain,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  Widget _buildEnhancedFooter() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.grey.shade900,
            Colors.black,
          ],
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 60, vertical: 50),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Image.asset(
            'assets/images/logo3.png',
            width: 200,
            height: 100,
            fit: BoxFit.contain,
            color: Colors.white,
          ),
          const SizedBox(height: 30),
          // Footer Content...
        ],
      ),
    );
  }
}
