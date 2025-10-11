import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../services/auth_service.dart';
import 'assessment_page.dart';

class JobDetailsPage extends StatefulWidget {
  final Map<String, dynamic> job;

  const JobDetailsPage({super.key, required this.job});

  @override
  State<JobDetailsPage> createState() => _JobDetailsPageState();
}

class _JobDetailsPageState extends State<JobDetailsPage> {
  int? applicationId; // store application id after applying
  bool submitting = false;

  final _formKey = GlobalKey<FormState>();
  final TextEditingController fullNameController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController portfolioController = TextEditingController();
  final TextEditingController coverLetterController = TextEditingController();

  Future<void> applyJob() async {
    if (!_formKey.currentState!.validate()) return;

    final token = await AuthService.getToken();

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
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text("Job Detail"),
        backgroundColor: Colors.red,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Text(widget.job["title"] ?? "",
                  style: const TextStyle(
                      fontSize: 28, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              Text(
                  "${widget.job["company"] ?? ""} • ${widget.job["location"] ?? ""}"),
              const SizedBox(height: 20),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(widget.job["description"] ?? ""),
                ),
              ),
              const SizedBox(height: 20),

              // ---------- Apply Form ----------
              if (applicationId == null)
                Card(
                  elevation: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "Apply for this Job",
                            style: TextStyle(
                                fontSize: 20, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: fullNameController,
                            decoration: const InputDecoration(
                                labelText: "Full Name",
                                border: OutlineInputBorder()),
                            validator: (val) =>
                                val == null || val.isEmpty ? "Required" : null,
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: phoneController,
                            decoration: const InputDecoration(
                                labelText: "Phone Number",
                                border: OutlineInputBorder()),
                            validator: (val) =>
                                val == null || val.isEmpty ? "Required" : null,
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: portfolioController,
                            decoration: const InputDecoration(
                                labelText: "Portfolio Link",
                                border: OutlineInputBorder()),
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: coverLetterController,
                            maxLines: 5,
                            decoration: const InputDecoration(
                                labelText: "Cover Letter",
                                border: OutlineInputBorder()),
                          ),
                          const SizedBox(height: 16),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: submitting ? null : applyJob,
                              style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.red,
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 16)),
                              child: submitting
                                  ? const CircularProgressIndicator(
                                      color: Colors.white)
                                  : const Text("Submit Application"),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                )
              else
                // ---------- Take Assessment Button ----------
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              AssessmentPage(applicationId: applicationId!),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red.shade700,
                        padding: const EdgeInsets.symmetric(vertical: 16)),
                    child: const Text("Take Assessment"),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
