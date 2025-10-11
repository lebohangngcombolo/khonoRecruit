import 'package:flutter/material.dart';
import '../../services/admin_service.dart';
import '../../widgets/custom_button.dart';

class InterviewsScreen extends StatefulWidget {
  const InterviewsScreen({super.key}); // ✅ token removed

  @override
  _InterviewsScreenState createState() => _InterviewsScreenState();
}

class _InterviewsScreenState extends State<InterviewsScreen> {
  final AdminService admin = AdminService();
  List<Map<String, dynamic>> interviews = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    fetchInterviews();
  }

  Future<void> fetchInterviews() async {
    setState(() => loading = true);
    try {
      final data = await admin.getAllInterviews(); // ✅ token handled internally
      setState(() => interviews = data);
    } catch (e) {
      debugPrint("Error fetching interviews: $e");
    } finally {
      setState(() => loading = false);
    }
  }

  Future<void> cancelInterview(int interviewId) async {
    try {
      await admin.cancelInterview(interviewId); // ✅ token handled internally
      fetchInterviews();
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text("Interview cancelled")));
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Error: $e")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return loading
        ? const Center(child: CircularProgressIndicator(color: Colors.red))
        : Padding(
            padding: const EdgeInsets.all(16),
            child: interviews.isEmpty
                ? const Center(child: Text("No interviews scheduled"))
                : ListView.builder(
                    itemCount: interviews.length,
                    itemBuilder: (_, index) {
                      final i = interviews[index];
                      return Card(
                        margin: const EdgeInsets.symmetric(vertical: 8),
                        child: ListTile(
                          title: Text("Candidate: ${i['candidate_name']}"),
                          subtitle: Text(
                              "Job: ${i['job_title']}\nDate: ${i['date']}"),
                          trailing: CustomButton(
                              text: "Cancel",
                              onPressed: () => cancelInterview(i['id'] as int)),
                        ),
                      );
                    },
                  ),
          );
  }
}
