import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:google_fonts/google_fonts.dart';
import '../../services/auth_service.dart';
import '../../providers/theme_provider.dart';

class ScheduleInterviewPage extends StatefulWidget {
  final int candidateId;
  const ScheduleInterviewPage({Key? key, required this.candidateId})
      : super(key: key);

  @override
  State<ScheduleInterviewPage> createState() => _ScheduleInterviewPageState();
}

class _ScheduleInterviewPageState extends State<ScheduleInterviewPage> {
  final _formKey = GlobalKey<FormState>();
  List<dynamic> applications = [];
  String? selectedApplication;
  DateTime? selectedDateTime;
  String interviewType = "Online";
  TextEditingController meetingLinkController = TextEditingController();

  bool isSubmitting = false;
  String message = "";

  @override
  void initState() {
    super.initState();
    fetchApplications();
  }

  Future<void> fetchApplications() async {
    try {
      final res = await AuthService.authorizedGet(
          "http://127.0.0.1:5000/api/admin/applications?candidate_id=${widget.candidateId}");
      if (res.statusCode == 200) {
        setState(() => applications = json.decode(res.body));
      } else {
        setState(
            () => message = "Failed to fetch applications: ${res.statusCode}");
      }
    } catch (e) {
      setState(() => message = "Error fetching applications: $e");
    }
  }

  Future<void> pickDateTime() async {
    final date = await showDatePicker(
      context: context,
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
      initialDate: DateTime.now(),
    );
    if (date == null) return;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (time == null) return;

    setState(() {
      selectedDateTime =
          DateTime(date.year, date.month, date.day, time.hour, time.minute);
    });
  }

  Future<void> scheduleInterview() async {
    if (!_formKey.currentState!.validate()) return;

    if (selectedDateTime == null) {
      setState(() => message = "Please pick a date & time.");
      return;
    }

    setState(() {
      isSubmitting = true;
      message = "";
    });

    final token = await AuthService.getAccessToken();

    final data = {
      "candidate_id": widget.candidateId,
      "application_id": selectedApplication,
      "scheduled_time": selectedDateTime!.toIso8601String(),
      "interview_type": interviewType,
      "meeting_link":
          interviewType == "Online" ? meetingLinkController.text : null,
    };

    try {
      final res = await http.post(
        Uri.parse("http://127.0.0.1:5000/api/admin/interviews"),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
        body: json.encode(data),
      );

      if (res.statusCode == 201) {
        final jsonResponse = json.decode(res.body);
        setState(() => message =
            jsonResponse["message"] ?? "Interview scheduled successfully.");
      } else {
        final err = json.decode(res.body);
        setState(() => message =
            "Error: ${err["error"] ?? "Failed to schedule interview."}");
      }
    } catch (e) {
      setState(() => message = "Request failed: $e");
    }

    setState(() => isSubmitting = false);
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final primaryRed = const Color.fromRGBO(151, 18, 8, 1);

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
              "Schedule Interview",
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w600,
              ),
            ),
            backgroundColor: (themeProvider.isDarkMode
                    ? const Color(0xFF14131E)
                    : Colors.white)
                .withOpacity(0.9),
            elevation: 0,
            foregroundColor:
                themeProvider.isDarkMode ? Colors.white : Colors.black87,
            iconTheme: IconThemeData(
                color:
                    themeProvider.isDarkMode ? Colors.white : Colors.black87),
          ),
          body: Container(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header Section
                  Container(
                    padding: const EdgeInsets.all(20),
                    margin: const EdgeInsets.only(bottom: 24),
                    decoration: BoxDecoration(
                      color: (themeProvider.isDarkMode
                              ? const Color(0xFF14131E)
                              : Colors.white)
                          .withOpacity(0.9),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: primaryRed.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            Icons.calendar_today,
                            color: primaryRed,
                            size: 28,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Schedule Interview",
                                style: GoogleFonts.poppins(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w600,
                                  color: themeProvider.isDarkMode
                                      ? Colors.white
                                      : Colors.black87,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                "Set up interview details for the candidate",
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
                      ],
                    ),
                  ),

                  // Message Alert
                  if (message.isNotEmpty)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      margin: const EdgeInsets.only(bottom: 20),
                      decoration: BoxDecoration(
                        color: (message.startsWith("Error")
                                ? Colors.red.shade50
                                : Colors.green.shade50)
                            .withOpacity(0.9),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: message.startsWith("Error")
                              ? Colors.red.shade200
                              : Colors.green.shade200,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            message.startsWith("Error")
                                ? Icons.error_outline
                                : Icons.check_circle_outline,
                            color: message.startsWith("Error")
                                ? Colors.red
                                : Colors.green.shade600,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              message,
                              style: GoogleFonts.inter(
                                color: message.startsWith("Error")
                                    ? Colors.red
                                    : Colors.green.shade800,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                  // Form Content
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        children: [
                          // Job Application Dropdown
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: (themeProvider.isDarkMode
                                      ? const Color(0xFF14131E)
                                      : Colors.white)
                                  .withOpacity(0.9),
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.05),
                                  blurRadius: 15,
                                  offset: const Offset(0, 6),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      Icons.work_outline,
                                      color: primaryRed,
                                      size: 20,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      "Job Application",
                                      style: GoogleFonts.inter(
                                        fontWeight: FontWeight.w600,
                                        color: themeProvider.isDarkMode
                                            ? Colors.white
                                            : Colors.black87,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                DropdownButtonFormField<String>(
                                  value: selectedApplication,
                                  decoration: InputDecoration(
                                    labelText: "Select Job Application",
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide(
                                        color: Colors.grey.shade300,
                                      ),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide(
                                        color: Colors.grey.shade300,
                                      ),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide(
                                        color: primaryRed,
                                        width: 2,
                                      ),
                                    ),
                                    filled: true,
                                    fillColor: (themeProvider.isDarkMode
                                            ? const Color(0xFF14131E)
                                            : Colors.grey.shade50)
                                        .withOpacity(0.9),
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 16,
                                    ),
                                    labelStyle: GoogleFonts.inter(
                                      color: themeProvider.isDarkMode
                                          ? Colors.grey.shade400
                                          : Colors.black87,
                                    ),
                                  ),
                                  items: applications.map((a) {
                                    final jobTitle =
                                        a["job_title"] ?? "Unknown Position";
                                    return DropdownMenuItem<String>(
                                      value: a["application_id"].toString(),
                                      child: Text(
                                        jobTitle,
                                        style: GoogleFonts.inter(
                                          color: themeProvider.isDarkMode
                                              ? Colors.white
                                              : Colors.black87,
                                        ),
                                      ),
                                    );
                                  }).toList(),
                                  onChanged: (val) =>
                                      setState(() => selectedApplication = val),
                                  validator: (val) => val == null
                                      ? "Select a job application"
                                      : null,
                                  style: GoogleFonts.inter(
                                    color: themeProvider.isDarkMode
                                        ? Colors.white
                                        : Colors.black87,
                                  ),
                                  dropdownColor: (themeProvider.isDarkMode
                                          ? const Color(0xFF14131E)
                                          : Colors.white)
                                      .withOpacity(0.95),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Date & Time Picker
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: (themeProvider.isDarkMode
                                      ? const Color(0xFF14131E)
                                      : Colors.white)
                                  .withOpacity(0.9),
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.05),
                                  blurRadius: 15,
                                  offset: const Offset(0, 6),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      Icons.access_time,
                                      color: primaryRed,
                                      size: 20,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      "Schedule Date & Time",
                                      style: GoogleFonts.inter(
                                        fontWeight: FontWeight.w600,
                                        color: themeProvider.isDarkMode
                                            ? Colors.white
                                            : Colors.black87,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Material(
                                  color: Colors.transparent,
                                  child: InkWell(
                                    onTap: pickDateTime,
                                    borderRadius: BorderRadius.circular(12),
                                    child: Container(
                                      width: double.infinity,
                                      padding: const EdgeInsets.all(16),
                                      decoration: BoxDecoration(
                                        color: (themeProvider.isDarkMode
                                                ? const Color(0xFF14131E)
                                                : Colors.grey.shade50)
                                            .withOpacity(0.9),
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: themeProvider.isDarkMode
                                              ? Colors.grey.shade800
                                              : Colors.grey.shade300,
                                        ),
                                      ),
                                      child: Row(
                                        children: [
                                          Icon(
                                            Icons.calendar_today,
                                            color: primaryRed,
                                            size: 20,
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Text(
                                              selectedDateTime != null
                                                  ? "Scheduled for: ${selectedDateTime!.toLocal()}"
                                                  : "Pick date and time",
                                              style: GoogleFonts.inter(
                                                color: selectedDateTime != null
                                                    ? (themeProvider.isDarkMode
                                                        ? Colors.white
                                                        : Colors.black87)
                                                    : Colors.grey.shade600,
                                                fontWeight:
                                                    selectedDateTime != null
                                                        ? FontWeight.w500
                                                        : FontWeight.normal,
                                              ),
                                            ),
                                          ),
                                          Icon(
                                            Icons.arrow_drop_down,
                                            color: Colors.grey.shade500,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Interview Type & Meeting Link
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: (themeProvider.isDarkMode
                                      ? const Color(0xFF14131E)
                                      : Colors.white)
                                  .withOpacity(0.9),
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.05),
                                  blurRadius: 15,
                                  offset: const Offset(0, 6),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      Icons.video_call_outlined,
                                      color: primaryRed,
                                      size: 20,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      "Interview Details",
                                      style: GoogleFonts.inter(
                                        fontWeight: FontWeight.w600,
                                        color: themeProvider.isDarkMode
                                            ? Colors.white
                                            : Colors.black87,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                DropdownButtonFormField<String>(
                                  value: interviewType,
                                  decoration: InputDecoration(
                                    labelText: "Interview Type",
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide(
                                        color: Colors.grey.shade300,
                                      ),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide(
                                        color: Colors.grey.shade300,
                                      ),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide(
                                        color: primaryRed,
                                        width: 2,
                                      ),
                                    ),
                                    filled: true,
                                    fillColor: (themeProvider.isDarkMode
                                            ? const Color(0xFF14131E)
                                            : Colors.grey.shade50)
                                        .withOpacity(0.9),
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 16,
                                    ),
                                    labelStyle: GoogleFonts.inter(
                                      color: themeProvider.isDarkMode
                                          ? Colors.grey.shade400
                                          : Colors.black87,
                                    ),
                                  ),
                                  items: ["Online", "In-Person", "Phone"]
                                      .map((type) => DropdownMenuItem(
                                            value: type,
                                            child: Text(
                                              type,
                                              style: GoogleFonts.inter(
                                                color: themeProvider.isDarkMode
                                                    ? Colors.white
                                                    : Colors.black87,
                                              ),
                                            ),
                                          ))
                                      .toList(),
                                  onChanged: (val) =>
                                      setState(() => interviewType = val!),
                                  style: GoogleFonts.inter(
                                    color: themeProvider.isDarkMode
                                        ? Colors.white
                                        : Colors.black87,
                                  ),
                                  dropdownColor: (themeProvider.isDarkMode
                                          ? const Color(0xFF14131E)
                                          : Colors.white)
                                      .withOpacity(0.95),
                                ),
                                const SizedBox(height: 16),
                                if (interviewType == "Online")
                                  TextFormField(
                                    controller: meetingLinkController,
                                    decoration: InputDecoration(
                                      labelText: "Meeting Link (optional)",
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: BorderSide(
                                          color: Colors.grey.shade300,
                                        ),
                                      ),
                                      enabledBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: BorderSide(
                                          color: Colors.grey.shade300,
                                        ),
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: BorderSide(
                                          color: primaryRed,
                                          width: 2,
                                        ),
                                      ),
                                      filled: true,
                                      fillColor: (themeProvider.isDarkMode
                                              ? const Color(0xFF14131E)
                                              : Colors.grey.shade50)
                                          .withOpacity(0.9),
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                        horizontal: 16,
                                        vertical: 16,
                                      ),
                                      labelStyle: GoogleFonts.inter(
                                        color: themeProvider.isDarkMode
                                            ? Colors.grey.shade400
                                            : Colors.black87,
                                      ),
                                    ),
                                    style: GoogleFonts.inter(
                                      color: themeProvider.isDarkMode
                                          ? Colors.white
                                          : Colors.black87,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),

                          // Schedule Button
                          Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: primaryRed.withOpacity(0.3),
                                  blurRadius: 15,
                                  offset: const Offset(0, 8),
                                ),
                              ],
                            ),
                            child: ElevatedButton.icon(
                              icon: Icon(
                                isSubmitting
                                    ? Icons.hourglass_top
                                    : Icons.schedule,
                                size: 20,
                              ),
                              label: Text(
                                isSubmitting
                                    ? "Scheduling Interview..."
                                    : "Schedule Interview",
                                style: GoogleFonts.inter(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 16,
                                ),
                              ),
                              onPressed:
                                  isSubmitting ? null : scheduleInterview,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: primaryRed,
                                foregroundColor: Colors.white,
                                minimumSize: const Size.fromHeight(60),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
                        ],
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
