import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/candidate_service.dart';
import '../../utils/theme_utils.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class AssessmentScreen extends StatefulWidget {
  final int jobId;
  final int applicationId;
  final String token;

  const AssessmentScreen({
    super.key,
    required this.applicationId,
    required this.token,
    required this.jobId,
  });

  @override
  _AssessmentScreenState createState() => _AssessmentScreenState();
}

class _AssessmentScreenState extends State<AssessmentScreen> {
  bool _loading = false;
  final Map<String, dynamic> _answers = {};
  final storage = const FlutterSecureStorage();
  List<Map<String, dynamic>> _questions = [];

  @override
  void initState() {
    super.initState();
    _fetchQuestions();
  }

  /// Fetch assessment questions from backend
  Future<void> _fetchQuestions() async {
    setState(() => _loading = true);

    try {
      final token = await storage.read(key: 'jwt_token') ?? widget.token;

      final response = await CandidateService.getAssessmentQuestions(
        token,
        widget.jobId,
      );

      if (response.success && response.data != null) {
        setState(() {
          _questions = response.data!;
          // Initialize answers map using question IDs as string keys
          for (var question in _questions) {
            _answers[question['id'].toString()] = '';
          }
        });
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:
                Text('Failed to load questions: ${response.message ?? ""}'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load questions: $e')),
      );
    } finally {
      setState(() => _loading = false);
    }
  }

  /// Submit candidate answers
  Future<void> _submitAssessment() async {
    setState(() => _loading = true);

    try {
      final token = await storage.read(key: 'jwt_token') ?? widget.token;

      final response = await CandidateService.submitAssessment(
        token,
        widget.applicationId,
        _answers,
      );

      if (!mounted) return;

      if (response.success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Assessment submitted successfully!'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Submission failed: ${response.message ?? ""}'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Submission failed: $e'),
          backgroundColor: Colors.redAccent,
        ),
      );
    } finally {
      setState(() => _loading = false);
    }
  }

  /// Build text field for each question
  Widget _buildQuestionField(Map<String, dynamic> question) {
    final qId = question['id'].toString();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          question['question'] ?? 'No question text', // Use actual key from API
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        const SizedBox(height: 8),
        TextField(
          decoration: InputDecoration(
            hintText: 'Your answer',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            filled: true,
            fillColor: Colors.grey[100],
          ),
          onChanged: (val) => _answers[qId] = val,
          maxLines: null,
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Assessment"),
        backgroundColor: Colors.redAccent,
        actions: [
          IconButton(
            icon: Icon(
              themeProvider.isDarkMode ? Icons.light_mode : Icons.dark_mode,
            ),
            onPressed: () => themeProvider.toggleTheme(),
          ),
        ],
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.redAccent, Colors.deepOrange],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: _loading
            ? const Center(
                child: CircularProgressIndicator(color: Colors.white),
              )
            : _questions.isEmpty
                ? const Center(
                    child: Text(
                      "No assessment questions available",
                      style: TextStyle(color: Colors.white),
                    ),
                  )
                : SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Card(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 8,
                      color: Colors.white,
                      child: Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const Text(
                              "Complete your assessment below",
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 20),
                            ..._questions
                                .map((q) => _buildQuestionField(q))
                                .toList(),
                            const SizedBox(height: 24),
                            SizedBox(
                              height: 50,
                              child: ElevatedButton(
                                onPressed: _loading ? null : _submitAssessment,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.redAccent,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: _loading
                                    ? const SizedBox(
                                        height: 24,
                                        width: 24,
                                        child: CircularProgressIndicator(
                                          color: Colors.white,
                                          strokeWidth: 2,
                                        ),
                                      )
                                    : const Text(
                                        "Submit Assessment",
                                        style: TextStyle(fontSize: 16),
                                      ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
      ),
    );
  }
}
