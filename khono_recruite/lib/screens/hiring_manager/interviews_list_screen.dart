import 'dart:convert';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../services/auth_service.dart';
import '../../utils/api_endpoints.dart';

class InterviewListScreen extends StatefulWidget {
  const InterviewListScreen({super.key});

  @override
  State<InterviewListScreen> createState() => _InterviewListScreenState();
}

class _InterviewListScreenState extends State<InterviewListScreen> {
  List<dynamic> interviews = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    fetchInterviews();
  }

  // ---------------- Fetch Interviews ----------------
  Future<void> fetchInterviews() async {
    setState(() => loading = true);
    try {
      final response = await AuthService.authorizedGet(
        "${ApiEndpoints.adminBase}/interviews/all",
      );
      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        setState(() {
          interviews = decoded['interviews'] ?? [];
          loading = false;
        });
      } else {
        setState(() => loading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to load interviews')),
        );
      }
    } catch (e) {
      setState(() => loading = false);
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  // ---------------- Cancel Interview ----------------
  Future<void> cancelInterview(int id) async {
    final url = "${ApiEndpoints.adminBase}/interviews/cancel/$id";
    try {
      final response = await AuthService.authorizedDelete(url);
      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text("Interview cancelled")));
        fetchInterviews();
      } else {
        final err = jsonDecode(response.body);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(err['error'] ?? 'Failed to cancel')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  // ---------------- Reschedule Interview ----------------
  Future<void> rescheduleInterview(int id, DateTime newTime) async {
    final url = "${ApiEndpoints.adminBase}/interviews/reschedule/$id";
    try {
      final response = await AuthService.authorizedPut(url, {
        "new_time": newTime.toIso8601String(),
      });
      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Interview rescheduled")));
        fetchInterviews();
      } else {
        final err = jsonDecode(response.body);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(err['error'] ?? 'Failed to reschedule')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  // ---------------- Show Reschedule Dialog ----------------
  void showRescheduleDialog(int id) async {
    DateTime? picked = await showDatePicker(
      context: context,
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
      initialDate: DateTime.now(),
    );

    if (picked != null) {
      final time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.now(),
      );
      if (time != null) {
        final newDateTime = DateTime(
          picked.year,
          picked.month,
          picked.day,
          time.hour,
          time.minute,
        );
        rescheduleInterview(id, newDateTime);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final width = MediaQuery.of(context).size.width;

    final gradientColors = isDark
        ? [const Color(0xFF0D47A1), const Color(0xFF1A237E)]
        : [const Color(0xFFBBDEFB), const Color(0xFFE3F2FD)];

    final cardBgColor =
        isDark ? Colors.white.withOpacity(0.08) : Colors.white.withOpacity(0.4);

    final textPrimary = isDark ? Colors.white : Colors.black87;
    final textSecondary =
        isDark ? Colors.white70 : Colors.black.withOpacity(0.7);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text("Scheduled Interviews"),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: gradientColors,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: loading
            ? const Center(
                child: CircularProgressIndicator(color: Colors.white))
            : SafeArea(
                child: interviews.isEmpty
                    ? Center(
                        child: Text(
                          "No interviews found",
                          style: TextStyle(
                            color: textSecondary,
                            fontSize: 16,
                          ),
                        ),
                      )
                    : SingleChildScrollView(
                        padding: const EdgeInsets.all(16),
                        child: Center(
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 900),
                            child: Wrap(
                              spacing: 16,
                              runSpacing: 16,
                              alignment: WrapAlignment.center,
                              children: interviews.map((i) {
                                // Safe parsing
                                final scheduled = i['scheduled_time'] != null
                                    ? DateFormat('yyyy-MM-dd HH:mm').format(
                                        DateTime.parse(i['scheduled_time']))
                                    : 'N/A';

                                return ClipRRect(
                                  borderRadius: BorderRadius.circular(20),
                                  child: BackdropFilter(
                                    filter: ImageFilter.blur(
                                        sigmaX: 10, sigmaY: 10),
                                    child: AnimatedContainer(
                                      duration:
                                          const Duration(milliseconds: 300),
                                      width:
                                          width < 600 ? double.infinity : 420,
                                      padding: const EdgeInsets.all(16),
                                      decoration: BoxDecoration(
                                        color: cardBgColor,
                                        borderRadius: BorderRadius.circular(20),
                                        border: Border.all(
                                          color: Colors.white.withOpacity(0.15),
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color:
                                                Colors.black.withOpacity(0.15),
                                            blurRadius: 10,
                                            offset: const Offset(2, 4),
                                          )
                                        ],
                                      ),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            i['job_title'] ?? 'No Job Title',
                                            style: TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold,
                                              color: textPrimary,
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                          Text(
                                              "Candidate: ${i['candidate_name'] ?? 'Unknown'}",
                                              style: TextStyle(
                                                  color: textSecondary)),
                                          Text(
                                              "Type: ${i['interview_type'] ?? 'N/A'}",
                                              style: TextStyle(
                                                  color: textSecondary)),
                                          Text("Time: $scheduled",
                                              style: TextStyle(
                                                  color: textSecondary)),
                                          Text(
                                              "Status: ${i['status'] ?? 'N/A'}",
                                              style: TextStyle(
                                                  color: textSecondary)),
                                          const SizedBox(height: 12),
                                          Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.end,
                                            children: [
                                              ElevatedButton.icon(
                                                onPressed: () =>
                                                    cancelInterview(i['id']),
                                                icon: const Icon(
                                                    Icons.cancel_outlined),
                                                label: const Text("Cancel"),
                                                style: ElevatedButton.styleFrom(
                                                  backgroundColor: Colors
                                                      .redAccent
                                                      .withOpacity(0.9),
                                                  shape: RoundedRectangleBorder(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            12),
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(width: 10),
                                              ElevatedButton.icon(
                                                onPressed: () =>
                                                    showRescheduleDialog(
                                                        i['id']),
                                                icon:
                                                    const Icon(Icons.schedule),
                                                label: const Text("Reschedule"),
                                                style: ElevatedButton.styleFrom(
                                                  backgroundColor: Colors
                                                      .blueAccent
                                                      .withOpacity(0.9),
                                                  shape: RoundedRectangleBorder(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            12),
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                          ),
                        ),
                      ),
              ),
      ),
    );
  }
}
