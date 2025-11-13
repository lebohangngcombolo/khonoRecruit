import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../services/auth_service.dart';
import 'cv_upload_page.dart';

class AssessmentPage extends StatefulWidget {
  final int applicationId;
  const AssessmentPage({super.key, required this.applicationId});

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
      final payload = {
        "draft_data":
            answers.map((key, value) => MapEntry(key.toString(), value)),
        "last_step": "assessment"
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

        // Redirect to dashboard after a short delay
        await Future.delayed(const Duration(milliseconds: 700));
        if (context.mounted) {
          Navigator.pushNamedAndRemoveUntil(
            context,
            '/dashboard',
            (route) => false,
          );
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
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(color: Colors.red)),
      );
    }

    if (questions.isEmpty) {
      return Scaffold(
        appBar: AppBar(
            title: const Text("Assessment"), backgroundColor: Colors.red),
        body: const Center(child: Text("No assessment available")),
      );
    }

    return Scaffold(
      appBar:
          AppBar(title: const Text("Assessment"), backgroundColor: Colors.red),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView.builder(
          itemCount: questions.length + 2, // ✅ Added 1 more for Save & Exit
          itemBuilder: (context, index) {
            if (index == questions.length) {
              // Submit button
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
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
            } else if (index == questions.length + 1) {
              // ✅ New Save & Exit button
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: saveDraftAndExit,
                    icon: const Icon(Icons.save, color: Colors.red),
                    label: const Text(
                      "Save & Exit",
                      style: TextStyle(color: Colors.red),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.red, width: 1.5),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
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
                    SegmentedButton<String>(
                      segments: List.generate(options.length, (i) {
                        final optionLabel = ["A", "B", "C", "D"][i];
                        final optionText = options[i];
                        return ButtonSegment<String>(
                          value: optionLabel,
                          label: Text(
                            "$optionLabel. $optionText",
                            style: const TextStyle(color: Colors.black),
                          ),
                        );
                      }),
                      selected: {
                        if (answers[index] != null) answers[index]!
                      },
                      onSelectionChanged: (Set<String> newSelection) {
                        setState(() {
                          if (newSelection.isEmpty) {
                            answers.remove(index);
                          } else {
                            answers[index] = newSelection.first;
                          }
                        });
                      },
                      multiSelectionEnabled: false,
                      emptySelectionAllowed: true,
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
