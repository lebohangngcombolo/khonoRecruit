import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import '../../services/auth_service.dart';
import 'assessment_page.dart';
import '../../services/drafts_service.dart';

class JobDetailsPage extends StatefulWidget {
  final Map<String, dynamic> job;
  final Map<String, dynamic>? draftForm;

  const JobDetailsPage({super.key, required this.job, this.draftForm});

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
    final df = widget.draftForm;
    if (df != null) {
      fullNameController.text = (df['full_name'] ?? '').toString();
      phoneController.text = (df['phone'] ?? '').toString();
      portfolioController.text = (df['portfolio'] ?? '').toString();
      coverLetterController.text = (df['cover_letter'] ?? '').toString();
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

  Future<void> saveDraft() async {
    final form = <String, dynamic>{
      'full_name': fullNameController.text,
      'phone': phoneController.text,
      'portfolio': portfolioController.text,
      'cover_letter': coverLetterController.text,
    };
    try {
      await DraftsService.saveDraft(job: widget.job, form: form);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Saved draft offline')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save draft: $e')),
        );
      }
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
      backgroundColor:
          Colors.transparent, // Set to transparent to show the background image
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/Frame 1.jpg'),
            fit: BoxFit.cover,
          ),
        ),
        child: SingleChildScrollView(
          child: Column(
            children: [
              // ---------- Top Banner ----------
              Image.asset(
                widget.job["banner"] ?? "assets/team1.jpg",
                width: double.infinity,
                height: 500,
                fit: BoxFit.cover,
              ),
              const SizedBox(height: 16),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Job Image
                    Image.asset(
                      widget.job["image"] ?? "assets/placeholder.png",
                      width: double.infinity,
                      height: 200,
                      fit: BoxFit.cover,
                    ),
                    const SizedBox(height: 16),

                    // Job Title & Company
                    Text(widget.job["title"] ?? "",
                        style: const TextStyle(
                            fontSize: 28, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text(
                        "${widget.job["company"] ?? ""} • ${widget.job["location"] ?? ""}",
                        style: const TextStyle(
                            fontSize: 16, color: Colors.black54)),
                    const SizedBox(height: 16),

                    // ---------- Two Column Layout ----------
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Left Column (Job Description, Responsibilities, etc.)
                        Expanded(
                          flex: 2,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildCard("Job Description", [
                                Text(widget.job["description"] ??
                                    "No description available.")
                              ]),
                              _buildCard(
                                  "Responsibilities",
                                  responsibilitiesList
                                      .map((r) => Row(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              const Text("• ",
                                                  style:
                                                      TextStyle(fontSize: 14)),
                                              Expanded(
                                                  child: Text(r,
                                                      style: const TextStyle(
                                                          fontSize: 14))),
                                            ],
                                          ))
                                      .toList()),
                              _buildCard(
                                  "Qualifications",
                                  qualificationsList
                                      .map((q) => Row(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              const Text("✔ ",
                                                  style:
                                                      TextStyle(fontSize: 14)),
                                              Expanded(
                                                  child: Text(q,
                                                      style: const TextStyle(
                                                          fontSize: 14))),
                                            ],
                                          ))
                                      .toList()),
                              _buildCard(
                                "Apply For This Job",
                                [
                                  Form(
                                    key: _formKey,
                                    child: Column(
                                      children: [
                                        buildTextField(
                                            controller: fullNameController,
                                            label: "Full Name"),
                                        const SizedBox(height: 12),
                                        buildTextField(
                                            controller: phoneController,
                                            label: "Phone Number"),
                                        const SizedBox(height: 12),
                                        buildTextField(
                                            controller: portfolioController,
                                            label: "Portfolio Link"),
                                        const SizedBox(height: 12),
                                        buildTextField(
                                            controller: coverLetterController,
                                            label: "Cover Letter",
                                            maxLines: 5),
                                        const SizedBox(height: 16),
                                        SizedBox(
                                          width: double.infinity,
                                          child: OutlinedButton.icon(
                                            onPressed: saveDraft,
                                            icon: const Icon(Icons.save,
                                                color: Colors.red),
                                            label: const Text('Save Draft',
                                                style: TextStyle(
                                                    color: Colors.red)),
                                            style: OutlinedButton.styleFrom(
                                              side: BorderSide(
                                                  color: Colors.red.shade700),
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      vertical: 14),
                                              shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                          12)),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(height: 10),
                                        SizedBox(
                                          width: double.infinity,
                                          child: ElevatedButton(
                                            onPressed:
                                                submitting ? null : applyJob,
                                            style: ElevatedButton.styleFrom(
                                                backgroundColor:
                                                    Colors.red.shade700,
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                        vertical: 16)),
                                            child: submitting
                                                ? const CircularProgressIndicator(
                                                    color: Colors.white)
                                                : const Text(
                                                    "Submit Application"),
                                          ),
                                        ),
                                        if (applicationId != null)
                                          Padding(
                                            padding: const EdgeInsets.only(
                                                top: 12.0),
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
                                                      Colors.red.shade900,
                                                  padding: const EdgeInsets
                                                      .symmetric(vertical: 16)),
                                              child:
                                                  const Text("Take Assessment"),
                                            ),
                                          )
                                      ],
                                    ),
                                  )
                                ],
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(width: 24),

                        // Right Column (Job Summary & Company Details)
                        Expanded(
                          flex: 1,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildCard("Job Summary", [
                                summaryRow(
                                    "Published On",
                                    widget.job["published_on"] ??
                                        "01 Jan, 2045"),
                                summaryRow("Vacancy",
                                    widget.job["vacancy"]?.toString() ?? "1"),
                                summaryRow("Job Nature",
                                    widget.job["type"] ?? "Full Time"),
                                summaryRow("Salary",
                                    widget.job["salary"] ?? "\$123 - \$456"),
                                summaryRow("Location",
                                    widget.job["location"] ?? "New York"),
                              ]),
                              _buildCard("Company Details", [
                                Text(widget.job["company_details"] ??
                                    "No details available.")
                              ]),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 40),

              // ---------- FOOTER ----------
              _buildFooter(),
            ],
          ),
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
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 25,
            offset: const Offset(0, 8),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
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
                    color: color.withValues(alpha: 0.1),
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
            'assets/logo3.png',
            width: 220,
            height: 120,
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
