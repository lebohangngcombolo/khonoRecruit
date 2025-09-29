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
    final t = await AuthService.getToken();
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
          questions = (data['assessment_pack']?['questions'] as List?)
                  ?.take(11)
                  .toList() ??
              [];
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
      // convert int keys to string for backend
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

        // Navigate to CV Upload after assessment
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
          itemCount: questions.length + 1,
          itemBuilder: (context, index) {
            if (index == questions.length) {
              // Submit button at the end
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
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
              );
            }

            final q = questions[index];
            final String questionText = q['question_text'] ?? "";
            final List options = q['options'] ??
                ["Option A", "Option B", "Option C", "Option D"];

            return Card(
              margin: const EdgeInsets.symmetric(vertical: 12),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Q${index + 1}. $questionText",
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    Column(
                      children: List.generate(options.length, (i) {
                        final optionLabel = ["A", "B", "C", "D"][i];
                        final optionText = options[i];
                        return RadioListTile<String>(
                          title: Text("$optionLabel. $optionText"),
                          value: optionLabel,
                          groupValue: answers[index], // ✅ use index here
                          onChanged: (val) {
                            setState(() {
                              answers[index] = val!; // ✅ index instead of qId
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
