import 'package:flutter/material.dart';
import '../../services/admin_service.dart';
import '../../models/job_model.dart';
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

  final _formKey = GlobalKey<FormState>();
  String _newJobTitle = '';
  String _newJobDescription = '';
  List<String> _newJobSkills = [];
  int _newJobMinExp = 0;

  bool _isSidebarOpen = true;

  @override
  void initState() {
    super.initState();
    _fetchJobs();
  }

  Future<void> _fetchJobs() async {
    setState(() => _loading = true);
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

  Future<void> _addJob() async {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();
    Navigator.pop(context);

    await Future.delayed(const Duration(milliseconds: 50));

    setState(() => _loading = true);
    try {
      await AdminService.createJob(
        _newJobTitle,
        _newJobDescription,
        _newJobSkills,
        _newJobMinExp,
      );
      await _fetchJobs();
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Job added successfully')));
    } catch (e) {
      setState(() => _loading = false);
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Error adding job: $e')));
    }
  }

  void _showAddJobDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Add Job'),
        content: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  decoration: const InputDecoration(labelText: 'Title'),
                  validator: (value) =>
                      value == null || value.isEmpty ? 'Enter title' : null,
                  onSaved: (value) => _newJobTitle = value!.trim(),
                ),
                TextFormField(
                  decoration: const InputDecoration(labelText: 'Description'),
                  validator: (value) => value == null || value.isEmpty
                      ? 'Enter description'
                      : null,
                  onSaved: (value) => _newJobDescription = value!.trim(),
                ),
                TextFormField(
                  decoration: const InputDecoration(
                      labelText: 'Required Skills (comma-separated)'),
                  validator: (value) =>
                      value == null || value.isEmpty ? 'Enter skills' : null,
                  onSaved: (value) => _newJobSkills =
                      value!.split(',').map((e) => e.trim()).toList(),
                ),
                TextFormField(
                  decoration: const InputDecoration(
                      labelText: 'Min Experience (years)'),
                  keyboardType: TextInputType.number,
                  validator: (value) => value == null || value.isEmpty
                      ? 'Enter min experience'
                      : null,
                  onSaved: (value) =>
                      _newJobMinExp = int.tryParse(value!.trim()) ?? 0,
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
            ),
            onPressed: _addJob,
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  Widget _buildJobTile(Job job) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.redAccent.shade100),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 8,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: ListTile(
        title: Text(job.title,
            style: const TextStyle(color: Colors.redAccent, fontSize: 18)),
        subtitle: Text(job.description,
            style: const TextStyle(color: Colors.black87, fontSize: 14)),
        trailing: SizedBox(
          width: 120,
          child: CustomButton(
            text: 'Candidates',
            color: Colors.redAccent,
            textColor: Colors.white,
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
      ),
    );
  }

  Widget _sidebarItem(IconData icon, String label, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 20),
        child: Row(
          children: [
            Icon(icon, color: Colors.white, size: 28),
            if (_isSidebarOpen)
              Padding(
                padding: const EdgeInsets.only(left: 16.0),
                child: Text(label,
                    style: const TextStyle(color: Colors.white, fontSize: 16)),
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Row(
        children: [
          // Sidebar
          AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            width: _isSidebarOpen ? 220 : 60,
            decoration: BoxDecoration(
              color: Colors.redAccent.shade700,
              boxShadow: const [
                BoxShadow(
                  color: Colors.black26,
                  blurRadius: 6,
                  offset: Offset(2, 0),
                ),
              ],
            ),
            child: Column(
              children: [
                const SizedBox(height: 40),
                IconButton(
                  icon: Icon(_isSidebarOpen ? Icons.arrow_back : Icons.menu,
                      color: Colors.white),
                  onPressed: () =>
                      setState(() => _isSidebarOpen = !_isSidebarOpen),
                ),
                const SizedBox(height: 20),
                _sidebarItem(Icons.dashboard, "Dashboard", () {}),
                _sidebarItem(Icons.work, "Jobs", () {}),
                _sidebarItem(Icons.people, "Candidates", () {}),
                const Spacer(),
                _sidebarItem(Icons.logout, "Logout", () {}),
                const SizedBox(height: 20),
              ],
            ),
          ),

          // Main Content
          Expanded(
            child: Container(
              color: Colors.white,
              child: Column(
                children: [
                  // Top Navbar
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: const BorderRadius.vertical(
                        bottom: Radius.circular(20),
                      ),
                      boxShadow: const [
                        BoxShadow(
                            color: Colors.black12,
                            blurRadius: 6,
                            offset: Offset(0, 2)),
                      ],
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Job Listings',
                            style: const TextStyle(
                                color: Colors.redAccent,
                                fontSize: 20,
                                fontWeight: FontWeight.bold),
                          ),
                        ),
                        const SizedBox(width: 16),
                        IconButton(
                          icon: const Icon(Icons.notifications,
                              color: Colors.redAccent),
                          onPressed: () {},
                        ),
                        const SizedBox(width: 16),
                        GestureDetector(
                          onTap: () {},
                          child: const CircleAvatar(
                            backgroundColor: Colors.redAccent,
                            child: Icon(Icons.person, color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Job List
                  Expanded(
                    child: _loading
                        ? const Center(
                            child: CircularProgressIndicator(
                                color: Colors.redAccent))
                        : _jobs.isEmpty
                            ? Center(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Text('No jobs available',
                                        style: TextStyle(
                                            color: Colors.redAccent,
                                            fontSize: 18)),
                                    const SizedBox(height: 12),
                                    ElevatedButton(
                                      onPressed: _fetchJobs,
                                      style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.redAccent),
                                      child: const Text('Retry'),
                                    ),
                                  ],
                                ),
                              )
                            : RefreshIndicator(
                                onRefresh: _fetchJobs,
                                color: Colors.redAccent,
                                child: ListView.builder(
                                  padding: const EdgeInsets.all(16),
                                  itemCount: _jobs.length,
                                  itemBuilder: (_, index) =>
                                      _buildJobTile(_jobs[index]),
                                ),
                              ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.redAccent,
        onPressed: _showAddJobDialog,
        child: const Icon(Icons.add),
      ),
    );
  }
}
