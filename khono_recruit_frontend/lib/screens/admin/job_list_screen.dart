import 'package:flutter/material.dart';
import '../../services/admin_service.dart';
import '../../models/job_model.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/custom_button.dart';
import 'candidates_screen.dart';

class JobListScreen extends StatefulWidget {
  const JobListScreen({super.key});

  @override
  _JobListScreenState createState() => _JobListScreenState();
}

class _JobListScreenState extends State<JobListScreen> {
  bool _loading = true;
  List<Job> _jobs = [];

  @override
  void initState() {
    super.initState();
    _fetchJobs();
  }

  Future<void> _fetchJobs() async {
    try {
      final jobs = await AdminService.getJobs();
      setState(() {
        _jobs = jobs;
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Error fetching jobs: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Jobs')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: _jobs.length,
              itemBuilder: (_, index) {
                final job = _jobs[index];
                return GlassCard(
                  child: ListTile(
                    title: Text(job.title,
                        style: const TextStyle(color: Colors.white)),
                    subtitle: Text(job.description,
                        style: const TextStyle(color: Colors.white70)),
                    trailing: CustomButton(
                      text: 'Candidates',
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => CandidatesScreen(jobId: job.id),
                          ),
                        );
                      },
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.redAccent,
        onPressed: () {
          // TODO: Add job creation dialog
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
