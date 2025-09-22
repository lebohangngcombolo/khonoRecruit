import 'package:flutter/material.dart';
import '../../services/candidate_service.dart';
import '../../models/job_model.dart';
import '../../models/api_response.dart';

class JobsScreen extends StatefulWidget {
  final String token;

  const JobsScreen({super.key, required this.token});

  @override
  _JobsScreenState createState() => _JobsScreenState();
}

class _JobsScreenState extends State<JobsScreen> {
  bool _loading = true;
  List<Job> _jobs = [];

  @override
  void initState() {
    super.initState();
    _loadJobs();
  }

  /// Load jobs from API
  Future<void> _loadJobs() async {
    setState(() => _loading = true);

    try {
      final apiRes = await CandidateService.getJobs(widget.token);

      if (apiRes.success) {
        setState(() {
          _jobs = apiRes.data ?? [];
          _loading = false;
        });
      } else {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load jobs: ${apiRes.message}')),
        );
      }
    } catch (e) {
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading jobs: $e')),
      );
    }
  }

  /// Apply for a job
  Future<void> _applyJob(Job job) async {
    setState(() => _loading = true);
    try {
      final ApiResponse<void> response =
          await CandidateService.applyJob(widget.token, job.id);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            response.success
                ? 'Applied to ${job.title} successfully!'
                : 'Failed to apply: ${response.message}',
          ),
          behavior: SnackBarBehavior.floating,
          backgroundColor: response.success ? Colors.green : Colors.redAccent,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error applying: $e'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.redAccent,
        ),
      );
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.redAccent,
        title: const Text("Available Jobs"),
        centerTitle: true,
      ),
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage("assets/images/landing_bg.jpg"),
            fit: BoxFit.cover,
          ),
        ),
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _jobs.isEmpty
                ? const Center(
                    child: Text(
                      "No jobs available",
                      style: TextStyle(color: Colors.white70, fontSize: 18),
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: _jobs.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final job = _jobs[index];
                      return Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          gradient: const LinearGradient(
                            colors: [Colors.redAccent, Colors.deepOrange],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: ListTile(
                          title: Text(
                            job.title,
                            style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text(
                            job.description,
                            style: const TextStyle(color: Colors.white70),
                          ),
                          trailing: ElevatedButton(
                            onPressed: _loading ? null : () => _applyJob(job),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: Colors.redAccent,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12)),
                            ),
                            child: const Text("Apply"),
                          ),
                        ),
                      );
                    },
                  ),
      ),
    );
  }
}
