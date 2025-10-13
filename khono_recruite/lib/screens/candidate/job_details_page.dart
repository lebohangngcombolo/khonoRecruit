import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import '../../services/auth_service.dart';
import 'assessment_page.dart';

class JobDetailsPage extends StatefulWidget {
  final Map<String, dynamic> job;

  const JobDetailsPage({super.key, required this.job});

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
      backgroundColor: Colors.grey[100],
      body: SingleChildScrollView(
        child: Column(
          children: [
            // ---------- Top Banner ----------
            Image.asset(
              widget.job["banner"] ?? "assets/images/team1.jpg",
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
                    widget.job["image"] ?? "assets/images/job_default.jpg",
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
                      style:
                          const TextStyle(fontSize: 16, color: Colors.black54)),
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
                                                style: TextStyle(fontSize: 14)),
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
                                                style: TextStyle(fontSize: 14)),
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
                                          padding:
                                              const EdgeInsets.only(top: 12.0),
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
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                        vertical: 16)),
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
                              summaryRow("Published On",
                                  widget.job["published_on"] ?? "01 Jan, 2045"),
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
    );
  }

  Widget _buildCard(String title, List<Widget> children) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title,
              style:
                  const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          ...children
        ]),
      ),
    );
  }

  Widget summaryRow(String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Text("$title: ",
              style:
                  const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  Widget buildTextField(
      {required TextEditingController controller,
      required String label,
      int maxLines = 1}) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        filled: true,
        fillColor: Colors.white,
      ),
      validator: (val) => val == null || val.isEmpty ? "Required" : null,
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

  Widget _buildFooter() {
    return Container(
      width: double.infinity,
      color: const Color(0xFF111111),
      padding: const EdgeInsets.symmetric(horizontal: 60, vertical: 40),
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
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Quick Links
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Quick Links",
                        style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold)),
                    const SizedBox(height: 10),
                    linkText("About Us", () {}),
                    linkText("Careers", () {}),
                    linkText("Blog", () {}),
                    linkText("Privacy Policy", () {}),
                  ],
                ),
              ),
              const SizedBox(width: 40),
              // Contacts + Social
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Contact",
                        style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold)),
                    const SizedBox(height: 10),
                    Text("Email: info@khonology.com",
                        style: GoogleFonts.poppins(color: Colors.white54)),
                    const SizedBox(height: 4),
                    Text("Phone: +27 123 456 7890",
                        style: GoogleFonts.poppins(color: Colors.white54)),
                    const SizedBox(height: 4),
                    Text("Address: 123 Main Street, Johannesburg",
                        style: GoogleFonts.poppins(color: Colors.white54)),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        _socialIcon('assets/icons/Instagram1.png',
                            'https://www.instagram.com/yourprofile'),
                        _socialIcon(
                            'assets/icons/x1.png', 'https://x.com/yourprofile'),
                        _socialIcon('assets/icons/Linkedin1.png',
                            'https://www.linkedin.com/in/yourprofile'),
                        _socialIcon('assets/icons/facebook1.png',
                            'https://www.facebook.com/yourprofile'),
                        _socialIcon('assets/icons/YouTube1.png',
                            'https://www.youtube.com/yourchannel'),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 40),
              // Newsletter
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Newsletter",
                        style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold)),
                    const SizedBox(height: 10),
                    TextField(
                      decoration: InputDecoration(
                        hintText: "Enter your email",
                        hintStyle: const TextStyle(color: Colors.white54),
                        filled: true,
                        fillColor: Colors.grey[900],
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                            vertical: 12, horizontal: 12),
                      ),
                      style: const TextStyle(color: Colors.white),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {},
                        style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red.shade700,
                            padding: const EdgeInsets.symmetric(vertical: 12)),
                        child: const Text("Subscribe"),
                      ),
                    ),
                  ],
                ),
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

  Widget linkText(String text, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Text(
          text,
          style: const TextStyle(
              color: Colors.white54, decoration: TextDecoration.underline),
        ),
      ),
    );
  }
}
