import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../services/auth_service.dart';

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
    final primaryRed = const Color.fromRGBO(151, 18, 8, 1);
    return Scaffold(
      appBar: AppBar(
        title: const Text("Schedule Interview"),
        backgroundColor: primaryRed,
        elevation: 0,
      ),
      body: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.grey.shade50, Colors.grey.shade100],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              if (message.isNotEmpty)
                Container(
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: message.startsWith("Error")
                        ? Colors.red.shade50
                        : Colors.green.shade50,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    message,
                    style: TextStyle(
                      color: message.startsWith("Error")
                          ? Colors.red
                          : Colors.green.shade800,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              DropdownButtonFormField<String>(
                initialValue: selectedApplication,
                decoration: InputDecoration(
                  labelText: "Select Job Application",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                ),
                items: applications.map((a) {
                  final jobTitle = a["job_title"] ?? "Unknown Position";
                  return DropdownMenuItem<String>(
                    value: a["application_id"].toString(),
                    child: Text(jobTitle),
                  );
                }).toList(),
                onChanged: (val) => setState(() => selectedApplication = val),
                validator: (val) =>
                    val == null ? "Select a job application" : null,
              ),
              const SizedBox(height: 20),
              ListTile(
                tileColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(color: Colors.grey.shade300)),
                title: Text(selectedDateTime != null
                    ? "Scheduled for: ${selectedDateTime!.toLocal()}"
                    : "Pick date and time"),
                trailing: const Icon(Icons.calendar_today),
                onTap: pickDateTime,
              ),
              const SizedBox(height: 20),
              DropdownButtonFormField<String>(
                initialValue: interviewType,
                decoration: InputDecoration(
                  labelText: "Interview Type",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                ),
                items: ["Online", "In-Person", "Phone"]
                    .map((type) =>
                        DropdownMenuItem(value: type, child: Text(type)))
                    .toList(),
                onChanged: (val) => setState(() => interviewType = val!),
              ),
              const SizedBox(height: 20),
              if (interviewType == "Online")
                TextFormField(
                  controller: meetingLinkController,
                  decoration: InputDecoration(
                    labelText: "Meeting Link (optional)",
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                ),
              const SizedBox(height: 30),
              ElevatedButton.icon(
                icon: const Icon(Icons.schedule),
                label: Text(
                  isSubmitting ? "Scheduling..." : "Schedule Interview",
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                onPressed: isSubmitting ? null : scheduleInterview,
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryRed,
                  foregroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(50),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  elevation: 5,
                  shadowColor: primaryRed.withOpacity(0.5),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
