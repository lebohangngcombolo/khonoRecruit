import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/admin_service.dart';
import '../../widgets/custom_button.dart';
import 'interview_schedule_page.dart'; // ✅ Import the schedule interview page
import '../../providers/theme_provider.dart';

class InterviewsScreen extends StatefulWidget {
  const InterviewsScreen({super.key});

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
    final themeProvider = Provider.of<ThemeProvider>(context);

    return Scaffold(
      // 🌆 Dynamic background implementation
      body: Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage(themeProvider.backgroundImage),
            fit: BoxFit.cover,
          ),
        ),
        child: Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(
            title: Text(
              "Scheduled Interviews",
              style: TextStyle(
                color: themeProvider.isDarkMode ? Colors.white : Colors.black87,
              ),
            ),
            backgroundColor: (themeProvider.isDarkMode
                    ? const Color(0xFF14131E)
                    : Colors.white)
                .withOpacity(0.9),
            iconTheme: IconThemeData(
              color: themeProvider.isDarkMode ? Colors.white : Colors.black87,
            ),
            actions: [
              // ✅ Schedule Interview Button
              IconButton(
                icon: const Icon(Icons.add_circle_outline),
                tooltip: "Schedule Interview",
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const ScheduleInterviewPage(
                        candidateId: 1, // ✅ Replace with selected candidate ID
                      ),
                    ),
                  ).then((_) => fetchInterviews());
                },
              ),
            ],
          ),
          body: loading
              ? const Center(
                  child: CircularProgressIndicator(color: Colors.red))
              : Padding(
                  padding: const EdgeInsets.all(16),
                  child: interviews.isEmpty
                      ? Center(
                          child: Text(
                            "No interviews scheduled",
                            style: TextStyle(
                              color: themeProvider.isDarkMode
                                  ? Colors.grey.shade400
                                  : Colors.black54,
                            ),
                          ),
                        )
                      : ListView.builder(
                          itemCount: interviews.length,
                          itemBuilder: (_, index) {
                            final i = interviews[index];
                            return Card(
                              color: (themeProvider.isDarkMode
                                      ? const Color(0xFF14131E)
                                      : Colors.white)
                                  .withOpacity(0.9),
                              margin: const EdgeInsets.symmetric(vertical: 8),
                              child: ListTile(
                                title: Text(
                                  "Candidate: ${i['candidate_name']}",
                                  style: TextStyle(
                                    color: themeProvider.isDarkMode
                                        ? Colors.white
                                        : Colors.black87,
                                  ),
                                ),
                                subtitle: Text(
                                  "Job: ${i['job_title']}\nDate: ${i['date']}",
                                  style: TextStyle(
                                    color: themeProvider.isDarkMode
                                        ? Colors.grey.shade400
                                        : Colors.black54,
                                  ),
                                ),
                                trailing: CustomButton(
                                  text: "Cancel",
                                  onPressed: () =>
                                      cancelInterview(i['id'] as int),
                                ),
                              ),
                            );
                          },
                        ),
                ),
        ),
      ),
    );
  }
}
