import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../services/admin_service.dart';
import '../../widgets/custom_button.dart';
import 'interview_schedule_page.dart';

class InterviewsScreen extends StatefulWidget {
  const InterviewsScreen({super.key});

  @override
  _InterviewsScreenState createState() => _InterviewsScreenState();
}

class _InterviewsScreenState extends State<InterviewsScreen> {
  final AdminService admin = AdminService();
  List<Map<String, dynamic>> interviews = [];
  bool loading = true;
  int currentPage = 1;
  int totalPages = 1;
  int totalInterviews = 0;
  String? filterStatus;
  String? filterType;

  @override
  void initState() {
    super.initState();
    fetchInterviews();
  }

  Future<void> fetchInterviews({int page = 1}) async {
    setState(() => loading = true);
    try {
      final response = await admin.getInterviewsPaginated(
        page: page,
        status: filterStatus,
        interviewType: filterType,
      );
      setState(() {
        interviews = List<Map<String, dynamic>>.from(response['interviews'] ?? []);
        currentPage = response['page'] ?? 1;
        totalPages = response['pages'] ?? 1;
        totalInterviews = response['total'] ?? 0;
        loading = false;
      });
    } catch (e) {
      debugPrint("Error fetching interviews: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load interviews: $e')),
        );
      }
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

  // Helper methods
  IconData _getStatusIcon(String? status) {
    switch (status?.toLowerCase()) {
      case 'scheduled':
        return Icons.calendar_today;
      case 'completed':
        return Icons.check_circle;
      case 'cancelled':
        return Icons.cancel;
      default:
        return Icons.help_outline;
    }
  }

  Color _getStatusColor(String? status) {
    switch (status?.toLowerCase()) {
      case 'scheduled':
        return Colors.blue;
      case 'completed':
        return Colors.green;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _formatDateTime(String? isoString) {
    if (isoString == null || isoString.isEmpty) return 'Not scheduled';
    try {
      final dateTime = DateTime.parse(isoString);
      return DateFormat('MMM dd, yyyy - hh:mm a').format(dateTime);
    } catch (e) {
      return 'Invalid date';
    }
  }

  String _capitalize(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1);
  }

  void _showCandidateSelection() async {
    try {
      final candidates = await admin.listCandidates();
      if (!mounted) return;

      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Select Candidate'),
          content: SizedBox(
            width: double.maxFinite,
            height: 300,
            child: ListView.builder(
              itemCount: candidates.length,
              itemBuilder: (context, index) {
                final candidate = candidates[index];
                final name = candidate['full_name'] ?? candidate['name'] ?? 'Unknown';
                final email = candidate['email'] ?? '';
                return ListTile(
                  leading: CircleAvatar(
                    child: Text(name.substring(0, 1).toUpperCase()),
                  ),
                  title: Text(name),
                  subtitle: Text(email),
                  onTap: () {
                    Navigator.pop(context);
                    _scheduleInterview(candidate['id']);
                  },
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
          ],
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load candidates: $e')),
      );
    }
  }

  void _scheduleInterview(int candidateId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ScheduleInterviewPage(candidateId: candidateId),
      ),
    ).then((_) => fetchInterviews());
  }

  Widget _buildInterviewItem(Map<String, dynamic> interview) {
    final scheduledTime = interview['scheduled_time'];
    final status = interview['status'] ?? 'scheduled';
    final candidateName = interview['candidate_name'] ?? 'Unknown Candidate';
    final jobTitle = interview['job_title'] ?? 'N/A';

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 0),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: _getStatusColor(status).withOpacity(0.2),
          child: Icon(_getStatusIcon(status), color: _getStatusColor(status)),
        ),
        title: Text(
          candidateName,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Job: $jobTitle"),
            Text("Date: ${_formatDateTime(scheduledTime)}"),
            Text(
              "Status: ${_capitalize(status)}",
              style: TextStyle(
                color: _getStatusColor(status),
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        isThreeLine: true,
        trailing: IconButton(
          icon: const Icon(Icons.delete_outline, color: Colors.red),
          onPressed: () => _confirmCancelInterview(interview['id']),
        ),
      ),
    );
  }

  void _confirmCancelInterview(int interviewId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Interview'),
        content: const Text('Are you sure you want to cancel this interview?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('No'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              cancelInterview(interviewId);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Yes, Cancel'),
          ),
        ],
      ),
    );
  }

  Widget _buildPaginationControls() {
    if (totalPages <= 1) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: Colors.grey.shade700)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: currentPage > 1
                ? () => fetchInterviews(page: currentPage - 1)
                : null,
          ),
          const SizedBox(width: 16),
          Text(
            'Page $currentPage of $totalPages',
            style: const TextStyle(color: Colors.white70),
          ),
          const SizedBox(width: 16),
          IconButton(
            icon: const Icon(Icons.arrow_forward),
            onPressed: currentPage < totalPages
                ? () => fetchInterviews(page: currentPage + 1)
                : null,
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.calendar_today, size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          const Text(
            'No Interviews Scheduled',
            style: TextStyle(fontSize: 18, color: Colors.white70),
          ),
          const SizedBox(height: 8),
          const Text(
            'Schedule your first interview to get started',
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _showCandidateSelection,
            icon: const Icon(Icons.add),
            label: const Text('Schedule Interview'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Interviews ($totalInterviews)",
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  shadows: [
                    Shadow(
                      color: Colors.black54,
                      blurRadius: 8,
                      offset: Offset(0, 2),
                    )
                  ],
                ),
              ),
              ElevatedButton.icon(
                icon: const Icon(Icons.add_circle_outline),
                label: const Text("Schedule Interview"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.redAccent,
                  foregroundColor: Colors.white,
                ),
                onPressed: _showCandidateSelection,
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: loading
                ? const Center(
                    child: CircularProgressIndicator(color: Colors.redAccent))
                : interviews.isEmpty
                    ? _buildEmptyState()
                    : ListView.builder(
                        itemCount: interviews.length,
                        itemBuilder: (_, index) => _buildInterviewItem(interviews[index]),
                      ),
          ),
          _buildPaginationControls(),
        ],
      ),
    );
  }
}
