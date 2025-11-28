import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/auth_service.dart';
import '../../utils/api_endpoints.dart';
import '../../providers/theme_provider.dart';

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

  Future<void> cancelInterview(int id) async {
    final url = "${ApiEndpoints.adminBase}/interviews/cancel/$id";

    try {
      // Make DELETE request with authorization
      final response = await AuthService.authorizedDelete(url);

      if (response.statusCode == 200) {
        // Success message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Interview cancelled successfully")),
        );
        // Refresh interview list
        fetchInterviews();
      } else {
        // Parse backend error message
        final err = jsonDecode(response.body);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(err['error'] ?? 'Failed to cancel interview')),
        );
      }
    } catch (e) {
      // Network or unexpected errors
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  Future<void> rescheduleInterview(int id, DateTime newTime) async {
    final url = "${ApiEndpoints.adminBase}/interviews/reschedule/$id";
    try {
      final response = await AuthService.authorizedPut(url, {
        "scheduled_time": newTime.toIso8601String(), // match Flask
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

  void showRescheduleDialog(int id) async {
    DateTime? picked = await showDatePicker(
      context: context,
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
      initialDate: DateTime.now(),
    );

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (time != null && picked != null) { 
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

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final width = MediaQuery.of(context).size.width;
    final redColor = const Color.fromRGBO(151, 18, 8, 1);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Scheduled Interviews"),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : interviews.isEmpty
              ? const Center(child: Text("No interviews found"))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Wrap(
                    spacing: 16,
                    runSpacing: 16,
                    children: interviews.map((i) {
                      final scheduled = i['scheduled_time'] != null
                          ? DateFormat('yyyy-MM-dd HH:mm')
                              .format(DateTime.parse(i['scheduled_time']))
                          : 'N/A';

                      return Container(
                        width: width < 600 ? double.infinity : 420,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.grey.shade300),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withAlpha((255 * 0.1).round()), // Use withAlpha
                              blurRadius: 8,
                              offset: const Offset(2, 4),
                            ),
                          ],
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            CircleAvatar(
                              radius: 40,
                              backgroundImage: (() {
                                final dynamic v = i['candidate_picture'];
                                if (v is String && v.isNotEmpty) {
                                  return NetworkImage(v) as ImageProvider<Object>;
                                }
                                return null;
                              })(),
                              child: (i['candidate_picture'] is! String ||
                                      (i['candidate_picture'] as String).isEmpty)
                                  ? const Icon(Icons.person, size: 40)
                                  : null,
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          "Interview Schedule",
                                          style: GoogleFonts.poppins(
                                            fontSize: 20,
                                            fontWeight: FontWeight.w600,
                                            color: themeProvider.isDarkMode
                                                ? Colors.white
                                                : Colors.black87,
                                          ),
                                        ),
                                        Text(
                                          "Scheduled at: $scheduled",
                                          style: GoogleFonts.inter(
                                            color: themeProvider.isDarkMode
                                                ? Colors.grey.shade400
                                                : Colors.grey.shade600,
                                            fontSize: 14,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 16, vertical: 8),
                                    decoration: BoxDecoration(
                                      color: redColor.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      "Active",
                                      style: GoogleFonts.inter(
                                        color: redColor,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
            );
  }
}
