import 'package:flutter/material.dart';
import '../../services/admin_service.dart';
import '../../models/application_model.dart';
import '../../widgets/glass_card.dart';
import 'assessment_screen.dart';

class ApplicationsScreen extends StatefulWidget {
  const ApplicationsScreen({super.key});

  @override
  _ApplicationsScreenState createState() => _ApplicationsScreenState();
}

class _ApplicationsScreenState extends State<ApplicationsScreen> {
  bool _loading = true;
  List<Application> _applications = [];

  @override
  void initState() {
    super.initState();
    _fetchApplications();
  }

  Future<void> _fetchApplications() async {
    try {
      final apps = await AdminService.getApplications();
      setState(() {
        _applications = apps;
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error fetching applications: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Applications')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: _applications.length,
              itemBuilder: (_, index) {
                final app = _applications[index];
                return GlassCard(
                  child: ListTile(
                    title: Text(app.candidateName,
                        style: const TextStyle(color: Colors.white)),
                    subtitle: Text(app.jobTitle,
                        style: const TextStyle(color: Colors.white70)),
                    trailing: IconButton(
                      icon:
                          const Icon(Icons.remove_red_eye, color: Colors.white),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                AssessmentScreen(applicationId: app.id),
                          ),
                        );
                      },
                    ),
                  ),
                );
              },
            ),
    );
  }
}
