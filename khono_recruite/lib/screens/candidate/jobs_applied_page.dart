import 'package:flutter/material.dart';
import '../../../widgets/custom_card.dart';
import '../../../services/candidate_service.dart';

class JobsAppliedPage extends StatefulWidget {
  final String token;
  const JobsAppliedPage({super.key, required this.token});

  @override
  _JobsAppliedPageState createState() => _JobsAppliedPageState();
}

class _JobsAppliedPageState extends State<JobsAppliedPage> {
  List<dynamic> applications = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    fetchApplications();
  }

  Future<void> fetchApplications() async {
    setState(() => loading = true);
    try {
      final apps = await CandidateService.getApplications(widget.token);
      setState(() => applications = apps);
    } catch (e) {
      debugPrint("Error fetching applications: $e");
    } finally {
      setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (applications.isEmpty) {
      return const Center(
        child: Text(
          "You haven't applied to any jobs yet",
          style: TextStyle(color: Colors.white, fontSize: 16),
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Jobs You've Applied To",
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 20),
          Wrap(
            spacing: 20,
            runSpacing: 20,
            children: applications.map((app) {
              return SizedBox(
                width: 340,
                child: CustomCard(
                  title: app['job_title'] ?? "No title",
                  subtitle: app['job_description'] != null
                      ? (app['job_description'].length > 50
                          ? "${app['job_description'].substring(0, 50)}..."
                          : app['job_description'])
                      : "No description",
                  color: Colors.white.withOpacity(0.05),
                  shadow: true,
                  onTap: () {
                    // Optional: navigate to job details
                  },
                  extraWidget: Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: app["status"] == "Accepted"
                                ? Colors.green
                                : app["status"] == "Rejected"
                                    ? Colors.red
                                    : Colors.orange,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            app["status"] ?? "Pending",
                            style: const TextStyle(
                                color: Colors.white, fontSize: 12),
                          ),
                        ),
                        Text(
                          app["assessed_date"] != null
                              ? app["assessed_date"].substring(0, 10)
                              : "",
                          style: TextStyle(
                              color: Colors.white.withOpacity(0.6),
                              fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
