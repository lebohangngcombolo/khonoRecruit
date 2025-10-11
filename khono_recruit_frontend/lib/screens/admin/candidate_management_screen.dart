import 'package:flutter/material.dart';
import '../../services/admin_service.dart';
import '../../widgets/custom_button.dart';

class CandidateManagementScreen extends StatefulWidget {
  final int jobId; // <-- pass jobId into this screen

  const CandidateManagementScreen({super.key, required this.jobId});

  @override
  _CandidateManagementScreenState createState() =>
      _CandidateManagementScreenState();
}

class _CandidateManagementScreenState extends State<CandidateManagementScreen> {
  final AdminService admin = AdminService();
  List<Map<String, dynamic>> candidates = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    fetchShortlist();
  }

  Future<void> fetchShortlist() async {
    setState(() => loading = true);
    try {
      final data = await admin.shortlistCandidates(widget.jobId);
      candidates = List<Map<String, dynamic>>.from(data);
    } catch (e) {
      debugPrint("Error fetching shortlist: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error fetching shortlist: $e")),
      );
    } finally {
      setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Center(child: CircularProgressIndicator(color: Colors.red));
    }

    if (candidates.isEmpty) {
      return const Center(child: Text("No shortlisted candidates found"));
    }

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Refresh shortlist button
          Align(
            alignment: Alignment.centerRight,
            child: CustomButton(
              text: "Refresh Shortlist",
              onPressed: fetchShortlist,
            ),
          ),
          const SizedBox(height: 16),

          // Candidate list
          Expanded(
            child: ListView.builder(
              itemCount: candidates.length,
              itemBuilder: (_, index) {
                final c = candidates[index];
                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Colors.red.shade100,
                      child: Text(
                        c['full_name']?.substring(0, 1) ?? "?",
                        style: const TextStyle(color: Colors.red),
                      ),
                    ),
                    title: Text(c['full_name'] ?? 'Unnamed Candidate'),
                    subtitle: Text(
                      "CV: ${c['cv_score'] ?? 'N/A'} | "
                      "Assessment: ${c['assessment_score'] ?? 'N/A'} | "
                      "Overall: ${c['overall_score']?.toStringAsFixed(1) ?? 'N/A'}",
                    ),
                    trailing: Text(
                      c['status'] ?? "Pending",
                      style: TextStyle(
                        color: c['status'] == "hired"
                            ? Colors.green
                            : Colors.orange,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
