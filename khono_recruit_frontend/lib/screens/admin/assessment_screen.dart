import 'package:flutter/material.dart';
import '../../services/admin_service.dart';
import '../../models/assessment_model.dart';
import '../../widgets/glass_card.dart';

class AssessmentScreen extends StatefulWidget {
  final int applicationId;
  const AssessmentScreen({super.key, required this.applicationId});

  @override
  _AssessmentScreenState createState() => _AssessmentScreenState();
}

class _AssessmentScreenState extends State<AssessmentScreen> {
  bool _loading = true;
  Assessment? _assessment;

  @override
  void initState() {
    super.initState();
    _fetchAssessment();
  }

  Future<void> _fetchAssessment() async {
    try {
      final data = await AdminService.getAssessment(widget.applicationId);
      setState(() {
        _assessment = data;
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error fetching assessment: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Assessment')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _assessment == null
              ? const Center(child: Text('No assessment found'))
              : GlassCard(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Score: ${_assessment!.score}',
                            style: const TextStyle(
                                color: Colors.white, fontSize: 20)),
                        const SizedBox(height: 10),
                        Text('Feedback: ${_assessment!.feedback}',
                            style: const TextStyle(
                                color: Colors.white70, fontSize: 16)),
                      ],
                    ),
                  ),
                ),
    );
  }
}
