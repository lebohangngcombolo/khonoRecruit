import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/candidate_service.dart';
import '../../models/job_model.dart';
import '../../models/api_response.dart';
import '../../models/application_model.dart';
import '../../utils/theme_utils.dart';

class CandidateDashboard extends StatefulWidget {
  final String token;

  const CandidateDashboard({super.key, required this.token});

  @override
  _CandidateDashboardState createState() => _CandidateDashboardState();
}

class _CandidateDashboardState extends State<CandidateDashboard> {
  bool _loading = true;
  List<Job> _jobs = [];

  @override
  void initState() {
    super.initState();
    _fetchJobs();
  }

  Future<void> _fetchJobs() async {
    setState(() => _loading = true);
    try {
      final apiRes = await CandidateService.getJobs(widget.token);
      if (apiRes.success && apiRes.data != null) {
        setState(() {
          _jobs = apiRes.data!;
          _loading = false;
        });
      } else {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed: ${apiRes.message}")),
        );
      }
    } catch (e) {
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    }
  }

  Future<void> _applyJob(Job job) async {
    setState(() => _loading = true);
    try {
      final ApiResponse<void> response =
          await CandidateService.applyJob(widget.token, job.id);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(response.success
              ? 'Applied to ${job.title} successfully!'
              : 'Failed to apply: ${response.message}'),
          backgroundColor: response.success ? Colors.green : Colors.redAccent,
        ),
      );

      if (response.success) {
        _fetchJobs();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error applying: $e'),
          backgroundColor: Colors.redAccent,
        ),
      );
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<List<Application>> _fetchAppliedJobs() async {
    try {
      final ApiResponse<List<Application>> response =
          await CandidateService.getAppliedJobs(widget.token);
      if (response.success && response.data != null) {
        return response.data!;
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed: ${response.message}')),
        );
        return [];
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching applied jobs: $e')),
      );
      return [];
    }
  }

  Widget _sidebarItem(IconData icon, String label, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
        child: Row(
          children: [
            Icon(icon, color: Colors.white, size: 24),
            const SizedBox(width: 16),
            Text(label,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }

  Widget _buildSidebar() {
    return Container(
      width: 220,
      color: const Color(0xFFD50000),
      child: Column(
        children: [
          const SizedBox(height: 40),
          const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.person, color: Colors.white, size: 28),
              SizedBox(width: 10),
              Text(
                "Candidate",
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 30),
          _sidebarItem(Icons.upload_file, "Upload CV", () {
            Navigator.pushNamed(context, '/candidate/cv_upload');
          }),
          _sidebarItem(Icons.work, "Jobs", () {
            Navigator.pushNamed(context, '/candidate/jobs');
          }),
          _sidebarItem(Icons.assignment, "Assessments", () async {
            final appliedJobs = await _fetchAppliedJobs();
            if (appliedJobs.isNotEmpty) {
              showDialog(
                  context: context,
                  builder: (_) => AlertDialog(
                        title: const Text('Select Assessment'),
                        content: SizedBox(
                          width: double.maxFinite,
                          child: ListView.builder(
                            shrinkWrap: true,
                            itemCount: appliedJobs.length,
                            itemBuilder: (_, index) {
                              final app = appliedJobs[index];
                              return ListTile(
                                title: Text(app.jobTitle),
                                subtitle: Text(app.candidateName),
                                onTap: () {
                                  Navigator.pop(context);
                                  Navigator.pushNamed(
                                    context,
                                    '/candidate/assessment',
                                    arguments: {
                                      'applicationId': app.id,
                                      'jobId': app.jobId,
                                      'token': widget.token,
                                    },
                                  );
                                },
                              );
                            },
                          ),
                        ),
                      ));
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("No assessments available.")),
              );
            }
          }),
          const Spacer(),
          _sidebarItem(Icons.logout, "Logout", () {
            Navigator.pushReplacementNamed(context, '/login');
          }),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildJobCard(Job job) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: Colors.white.withOpacity(0.1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ListTile(
        title: Text(
          job.title,
          style: const TextStyle(
              color: Colors.redAccent, fontWeight: FontWeight.bold),
        ),
        subtitle: Text(job.description,
            style: const TextStyle(color: Colors.white70)),
        trailing: ElevatedButton(
          onPressed: () => _applyJob(job),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.redAccent,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          child: const Text("Apply"),
        ),
        onTap: () {
          Navigator.pushNamed(
            context,
            '/candidate/job_detail',
            arguments: {'job': job, 'token': widget.token},
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return Scaffold(
      body: Row(
        children: [
          _buildSidebar(),
          Expanded(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF1C1C1C), Color(0xFF2C2C2C)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Available Jobs",
                        style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Colors.white),
                      ),
                      const SizedBox(height: 12),
                      Expanded(
                        child: _loading
                            ? const Center(
                                child: CircularProgressIndicator(
                                color: Colors.redAccent,
                              ))
                            : _jobs.isEmpty
                                ? const Center(
                                    child: Text(
                                    "No jobs available",
                                    style: TextStyle(
                                        color: Colors.white70, fontSize: 18),
                                  ))
                                : ListView.separated(
                                    itemCount: _jobs.length,
                                    separatorBuilder: (_, __) =>
                                        const SizedBox(height: 12),
                                    itemBuilder: (_, index) =>
                                        _buildJobCard(_jobs[index]),
                                  ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
