import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../services/auth_service.dart';
import 'cv_upload_page.dart';
import 'package:go_router/go_router.dart';

class AssessmentPage extends StatefulWidget {
  final int applicationId;
  final Map<String, dynamic>? draftData; // <-- add this line
  const AssessmentPage(
      {super.key, required this.applicationId, this.draftData});

  @override
  State<AssessmentPage> createState() => _AssessmentPageState();
}

class _AssessmentPageState extends State<AssessmentPage> {
  bool loading = true;
  List<dynamic> questions = [];
  Map<int, String> answers = {}; // index -> selected option
  bool submitting = false;

  String? token;

  @override
  void initState() {
    super.initState();
    loadTokenAndFetch();

    // ✅ Autofill from draft if available
    if (widget.draftData != null && widget.draftData!['assessment'] != null) {
      final savedAnswers =
          Map<String, dynamic>.from(widget.draftData!['assessment']);
      answers = savedAnswers
          .map((key, value) => MapEntry(int.parse(key), value.toString()));
    }
  }

  Future<void> loadTokenAndFetch() async {
    final t = await AuthService.getAccessToken();
    setState(() => token = t);
    fetchAssessment();
  }

  Future<void> fetchAssessment() async {
    if (token == null) return;

    setState(() => loading = true);
    try {
      final res = await http.get(
        Uri.parse(
            "http://127.0.0.1:5000/api/candidate/applications/${widget.applicationId}/assessment"),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token"
        },
      );

      if (res.statusCode == 200) {
        final data = json.decode(res.body);
        setState(() {
          questions = (data['assessment_pack']?['questions'] as List? ?? [])
              .take(11)
              .toList();
        });
      } else {
        throw Exception("Failed to load assessment: ${res.body}");
      }
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Error: $e")));
    } finally {
      setState(() => loading = false);
    }
  }

  Future<void> submitAssessment() async {
    if (token == null) return;

    setState(() => submitting = true);
    try {
      final payload = {
        "answers": answers.map((key, value) => MapEntry(key.toString(), value)),
      };

      final res = await http.post(
        Uri.parse(
            "http://127.0.0.1:5000/api/candidate/applications/${widget.applicationId}/assessment"),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token"
        },
        body: json.encode(payload),
      );

      if (res.statusCode == 201) {
        final data = json.decode(res.body);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(
                "Assessment Submitted! Score: ${data['total_score']}%, Result: ${data['recommendation']}")));

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => CVUploadScreen(applicationId: widget.applicationId),
          ),
        );
      } else {
        throw Exception("Failed to submit: ${res.body}");
      }
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Error: $e")));
    } finally {
      setState(() => submitting = false);
    }
  }

  // ✅ NEW: Save draft progress and redirect to dashboard
  Future<void> saveDraftAndExit() async {
    if (token == null) return;

    try {
      // Wrap assessment answers under 'assessment' key
      final payload = {
        "draft_data": {
          "assessment":
              answers.map((key, value) => MapEntry(key.toString(), value))
        },
        "last_saved_screen": "assessment"
      };

      final res = await http.post(
        Uri.parse(
            "http://127.0.0.1:5000/api/candidate/apply/save_draft/${widget.applicationId}"),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token"
        },
        body: json.encode(payload),
      );

      if (res.statusCode == 200 || res.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Progress saved successfully.")),
        );

        // ✅ Use GoRouter to navigate
        await Future.delayed(const Duration(milliseconds: 700));
        if (context.mounted) {
          GoRouter.of(context).go('/candidate-dashboard');
        }
      } else {
        throw Exception("Failed to save draft: ${res.body}");
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error saving draft: $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return Scaffold(
        body: Container(
          decoration: const BoxDecoration(
            image: DecorationImage(
              image: AssetImage('assets/images/Frame 1.jpg'),
              fit: BoxFit.cover,
            ),
          ),
          child:
              const Center(child: CircularProgressIndicator(color: Colors.red)),
        ),
      );
    }

    if (questions.isEmpty) {
      return Scaffold(
        appBar: AppBar(
            title: Text("Assessment",
                style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w600, color: Colors.white)),
            backgroundColor: Colors.red),
        body: Container(
          decoration: const BoxDecoration(
            image: DecorationImage(
              image: AssetImage('assets/images/Frame 1.jpg'),
              fit: BoxFit.cover,
            ),
          ),
          child: const Center(child: Text("No assessment available")),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
          title: Text("Assessment",
              style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w600, color: Colors.white)),
          backgroundColor: Colors.red),
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/Frame 1.jpg'),
            fit: BoxFit.cover,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: ListView.builder(
            itemCount: questions.length + 1,
            itemBuilder: (context, index) {
              if (index == questions.length) {
                // Submit button at the end
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: submitting ? null : submitAssessment,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: submitting
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text("Submit Assessment"),
                    ),
                  ),
                );
              }

              final q = questions[index];
              final String questionText =
                  q['question'] ?? "Question not available";
              final List options = q['options'] ?? [];

            return Card(
              color: Colors.white,
              elevation: 3,
              margin: const EdgeInsets.symmetric(vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: const BorderSide(color: Colors.red, width: 1),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Q${index + 1}: $questionText",
                      style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.red),
                    ),
                    const SizedBox(height: 12),
                    Column(
                      children: List.generate(options.length, (i) {
                        final optionLabel = ["A", "B", "C", "D"][i];
                        final optionText = options[i];
                        return RadioListTile<String>(
                          title: Text(
                            "$optionLabel. $optionText",
                            style: const TextStyle(color: Colors.black),
                          ),
                          value: optionLabel,
                          groupValue:
                              answers[index], // already prefilled from draft
                          onChanged: (val) {
                            setState(() {
                              answers[index] = val!;
                            });
                          },
                        );
                      }),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
