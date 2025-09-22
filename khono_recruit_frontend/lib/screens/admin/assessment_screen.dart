import 'package:flutter/material.dart';
import '../../services/admin_service.dart';
import '../../models/assessment_model.dart';

class AssessmentScreen extends StatefulWidget {
  final int jobId;
  const AssessmentScreen({super.key, required this.jobId});

  @override
  _AssessmentScreenState createState() => _AssessmentScreenState();
}

class _AssessmentScreenState extends State<AssessmentScreen> {
  bool _loading = true;
  bool _submitting = false;
  Assessment? _assessment;

  final TextEditingController _newQuestionController = TextEditingController();
  final TextEditingController _newAnswerController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchAssessment();
  }

  Future<void> _fetchAssessment() async {
    setState(() => _loading = true);
    try {
      final data = await AdminService.getJobAssessment(widget.jobId);
      setState(() {
        _assessment = data ?? Assessment(questions: []);
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error fetching assessment: $e')));
    }
  }

  Future<void> _addQuestion() async {
    if (_newQuestionController.text.isEmpty) return;
    setState(() => _submitting = true);
    try {
      final newQuestion = AssessmentQuestion(
        question: _newQuestionController.text,
        correctAnswer: _newAnswerController.text,
      );
      final updatedAssessment = Assessment(
        questions: [..._assessment!.questions, newQuestion],
      );
      await AdminService.createAssessment(widget.jobId, updatedAssessment);
      setState(() {
        _assessment = updatedAssessment;
        _newQuestionController.clear();
        _newAnswerController.clear();
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Question added successfully'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error adding question: $e'),
          backgroundColor: Colors.redAccent,
        ),
      );
    } finally {
      setState(() => _submitting = false);
    }
  }

  Future<void> _saveAssessment() async {
    if (_assessment == null) return;
    setState(() => _submitting = true);
    try {
      await AdminService.updateAssessment(widget.jobId, _assessment!);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Assessment saved successfully'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Error saving assessment: $e')));
    } finally {
      setState(() => _submitting = false);
    }
  }

  Future<void> _deleteAssessment() async {
    setState(() => _submitting = true);
    try {
      await AdminService.deleteAssessment(widget.jobId);
      setState(() => _assessment = Assessment(questions: []));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Assessment deleted'),
          backgroundColor: Colors.redAccent,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error deleting assessment: $e')));
    } finally {
      setState(() => _submitting = false);
    }
  }

  Widget _sidebarItem(IconData icon, String label, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
        child: Row(
          children: [
            Icon(icon, color: Colors.white, size: 24),
            const SizedBox(width: 16),
            Text(label,
                style: const TextStyle(color: Colors.white, fontSize: 16)),
          ],
        ),
      ),
    );
  }

  Widget _buildSidebar() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      width: 220,
      decoration: BoxDecoration(
        color: Colors.redAccent.shade700,
        boxShadow: const [
          BoxShadow(color: Colors.black45, blurRadius: 6, offset: Offset(2, 0)),
        ],
      ),
      child: Column(
        children: [
          const SizedBox(height: 40),
          const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.work, color: Colors.white, size: 28),
              SizedBox(width: 10),
              Text(
                "iDraft",
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 30),
          _sidebarItem(Icons.work, "Jobs", () {}),
          _sidebarItem(Icons.group, "Users", () {}),
          _sidebarItem(Icons.assignment, "Applications", () {}),
          const Spacer(),
          _sidebarItem(Icons.logout, "Logout", () {}),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _metricCard(String label, int count, Color color) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 6),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.15),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Text(
              count.toString(),
              style: TextStyle(
                  fontSize: 22, fontWeight: FontWeight.bold, color: color),
            ),
            const SizedBox(height: 4),
            Text(label, style: TextStyle(color: color.withOpacity(0.9))),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricsBar() {
    final total = _assessment?.questions.length ?? 0;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Row(
        children: [
          _metricCard("Total Questions", total, Colors.redAccent),
        ],
      ),
    );
  }

  Widget _buildAssessmentCard() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          _buildMetricsBar(),
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: const [
                BoxShadow(
                    color: Colors.black12, blurRadius: 8, offset: Offset(0, 4)),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Assessment Questions',
                  style: TextStyle(
                      color: Colors.redAccent,
                      fontSize: 22,
                      fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                if (_assessment!.questions.isEmpty)
                  const Text(
                    'No questions yet. Add new ones below:',
                    style: TextStyle(color: Colors.black54),
                  ),
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _assessment!.questions.length,
                  itemBuilder: (context, index) {
                    final question = _assessment!.questions[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          TextField(
                            decoration: InputDecoration(
                              labelText: 'Question ${index + 1}',
                              filled: true,
                              fillColor: Colors.grey[200],
                              border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12)),
                            ),
                            controller:
                                TextEditingController(text: question.question),
                            onChanged: (val) =>
                                _assessment!.questions[index].question = val,
                          ),
                          const SizedBox(height: 4),
                          TextField(
                            decoration: InputDecoration(
                              labelText: 'Correct Answer',
                              filled: true,
                              fillColor: Colors.grey[100],
                              border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12)),
                            ),
                            controller: TextEditingController(
                                text: question.correctAnswer),
                            onChanged: (val) => _assessment!
                                .questions[index].correctAnswer = val,
                          ),
                        ],
                      ),
                    );
                  },
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _newQuestionController,
                  decoration: InputDecoration(
                    hintText: 'New question',
                    filled: true,
                    fillColor: Colors.grey[200],
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  onChanged: (val) => setState(() {}),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _newAnswerController,
                  decoration: InputDecoration(
                    hintText: 'Correct answer for new question',
                    filled: true,
                    fillColor: Colors.grey[100],
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    ElevatedButton(
                      onPressed: _submitting ? null : _addQuestion,
                      style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          padding: const EdgeInsets.symmetric(horizontal: 16)),
                      child: const Text('Add Question'),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton(
                      onPressed: _submitting ? null : _saveAssessment,
                      style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.redAccent,
                          padding: const EdgeInsets.symmetric(horizontal: 16)),
                      child: const Text('Save Assessment'),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton(
                      onPressed: _submitting ? null : _deleteAssessment,
                      style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red.shade900,
                          padding: const EdgeInsets.symmetric(horizontal: 16)),
                      child: const Text('Delete Assessment'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Row(
        children: [
          _buildSidebar(),
          Expanded(
            child: _loading
                ? const Center(
                    child: CircularProgressIndicator(color: Colors.redAccent),
                  )
                : _buildAssessmentCard(),
          ),
        ],
      ),
    );
  }
}
