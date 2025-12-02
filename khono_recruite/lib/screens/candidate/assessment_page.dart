import 'package:flutter/material.dart';
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

  // Theme Colors
  final Color _primaryDark = Colors.white; // Background
  final Color _cardDark = Colors.white; // Card background
  final Color _accentRed = Color(0xFFE53935); // Main red
  final Color _accentPurple = Color(0xFFD32F2F); // Dark red
  final Color _accentBlue = Color(0xFFEF5350); // Light red
  final Color _accentGreen = Color(0xFF43A047); // Success
  final Color _textPrimary = Colors.black; // Main text
  final Color _textSecondary = Colors.redAccent; // Secondary text
  final Color _surfaceOverlay = Colors.red.withOpacity(0.1); // subtle overlay

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
        backgroundColor: _primaryDark,
        body: Container(
          decoration: const BoxDecoration(
            image: DecorationImage(
              image: AssetImage("assets/images/dark.png"),
              fit: BoxFit.cover,
            ),
          ),
          child: Center(
            child: CircularProgressIndicator(color: _accentRed),
          ),
        ),
      );
    }

    if (questions.isEmpty) {
      return Scaffold(
        backgroundColor: _primaryDark,
        appBar: AppBar(
          title: Text(
            "Assessment",
            style: TextStyle(color: _textPrimary),
          ),
          backgroundColor: Colors.transparent,
          elevation: 0,
          iconTheme: IconThemeData(color: _textPrimary),
        ),
        body: Container(
          decoration: const BoxDecoration(
            image: DecorationImage(
              image: AssetImage("assets/images/dark.png"),
              fit: BoxFit.cover,
            ),
          ),
          child: Center(
            child: Text(
              "No assessment available",
              style: TextStyle(color: _textPrimary, fontSize: 16),
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: _primaryDark,
      appBar: AppBar(
        title: Text(
          "Assessment",
          style: TextStyle(
            color: _textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: _textPrimary),
      ),
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage("assets/images/dark.png"),
            fit: BoxFit.cover,
          ),
        ),
        child: Padding(
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
                        backgroundColor: _accentRed,
                        foregroundColor: _textPrimary,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: submitting
                          ? SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                color: _textPrimary,
                                strokeWidth: 2,
                              ),
                            )
                          : Text(
                              "Submit Assessment",
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: _textPrimary,
                              ),
                            ),
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
                      icon: Icon(Icons.save, color: _accentRed),
                      label: Text(
                        "Save & Exit",
                        style: TextStyle(color: _accentRed),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: _accentRed, width: 1.5),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                );
              }

              final q = questions[index];
              final String questionText =
                  q['question'] ?? "Question not available";
              final List options = q['options'] ?? [];

              return Container(
                margin: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: _cardDark,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: _accentRed.withOpacity(0.3)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Q${index + 1}: $questionText",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: _textPrimary,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Column(
                        children: List.generate(options.length, (i) {
                          final optionLabel = ["A", "B", "C", "D"][i];
                          final optionText = options[i];
                          return Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            decoration: BoxDecoration(
                              color: _primaryDark.withOpacity(0.5),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: _accentRed.withOpacity(0.2),
                              ),
                            ),
                            child: RadioListTile<String>(
                              title: Text(
                                "$optionLabel. $optionText",
                                style: TextStyle(color: _textPrimary),
                              ),
                              value: optionLabel,
                              groupValue: answers[
                                  index], // already prefilled from draft
                              onChanged: (val) {
                                setState(() {
                                  answers[index] = val!;
                                });
                              },
                              activeColor: _accentRed,
                              tileColor: Colors.transparent,
                              selectedTileColor: _accentRed.withOpacity(0.1),
                            ),
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
      ),
    );
  }
}
