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

    final token = await AuthService.getAccessToken(); // get JWT

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
          "Authorization": "Bearer $token", // attach JWT here
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
    return Scaffold(
      appBar: AppBar(title: const Text("Schedule Interview")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              if (message.isNotEmpty)
                Text(
                  message,
                  style: TextStyle(
                    color:
                        message.startsWith("Error") ? Colors.red : Colors.green,
                  ),
                ),
              const SizedBox(height: 20),
              DropdownButtonFormField<String>(
                value: selectedApplication,
                decoration: const InputDecoration(
                  labelText: "Select Job Application",
                  border: OutlineInputBorder(),
                ),
                items: applications.map((a) {
                  final jobTitle =
                      a["job_title"] ?? "Unknown Position"; // updated key
                  return DropdownMenuItem<String>(
                    value: a["application_id"].toString(), // updated key
                    child: Text(jobTitle),
                  );
                }).toList(),
                onChanged: (val) => setState(() => selectedApplication = val),
                validator: (val) =>
                    val == null ? "Select a job application" : null,
              ),
              const SizedBox(height: 20),
              ListTile(
                title: Text(selectedDateTime != null
                    ? "Scheduled for: ${selectedDateTime!.toLocal()}"
                    : "Pick date and time"),
                trailing: const Icon(Icons.calendar_today),
                onTap: pickDateTime,
              ),
              const SizedBox(height: 20),
              DropdownButtonFormField<String>(
                value: interviewType,
                decoration: const InputDecoration(
                  labelText: "Interview Type",
                  border: OutlineInputBorder(),
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
                  decoration: const InputDecoration(
                    labelText: "Meeting Link (optional)",
                    border: OutlineInputBorder(),
                  ),
                ),
              const SizedBox(height: 30),
              ElevatedButton.icon(
                icon: const Icon(Icons.schedule),
                label:
                    Text(isSubmitting ? "Scheduling..." : "Schedule Interview"),
                onPressed: isSubmitting ? null : scheduleInterview,
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size.fromHeight(50),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
