import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import '../../services/auth_service.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class AssessmentResultsPage extends StatefulWidget {
  final int? applicationId; // null = all applications, set = single app
  final String token; // <-- Add this
  const AssessmentResultsPage(
      {super.key, this.applicationId, required this.token});

  @override
  State<AssessmentResultsPage> createState() => _AssessmentResultsPageState();
}

class _AssessmentResultsPageState extends State<AssessmentResultsPage> {
  bool loading = true;
  List<dynamic> applications = [];
  String? token;

  @override
  void initState() {
    super.initState();
    _loadTokenAndFetch();
  }

  Future<void> _loadTokenAndFetch() async {
    final t = await AuthService.getToken();
    setState(() => token = t);
    _fetchResults();
  }

  Future<void> _fetchResults() async {
    if (token == null) return;
    setState(() => loading = true);

    try {
      final res = await http.get(
        Uri.parse('http://127.0.0.1:5000/api/candidate/applications'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token'
        },
      );

      if (res.statusCode == 200) {
        List<dynamic> data = json.decode(res.body);

        if (widget.applicationId != null) {
          data = data
              .where((a) => a['application_id'] == widget.applicationId)
              .toList();
        }

        setState(() => applications = data);
      } else {
        throw Exception('Failed to load results');
      }
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Error: $e")));
    } finally {
      setState(() => loading = false);
    }
  }

  // Donut chart widget using Syncfusion
  Widget scoreDonutChart(double score, Color color) {
    return SizedBox(
      height: 100,
      width: 100,
      child: SfCircularChart(
        series: <CircularSeries>[
          DoughnutSeries<_ChartData, String>(
            dataSource: [
              _ChartData('Score', score),
              _ChartData('Remaining', 100 - score)
            ],
            xValueMapper: (_ChartData data, _) => data.label,
            yValueMapper: (_ChartData data, _) => data.value,
            pointColorMapper: (_ChartData data, _) =>
                data.label == 'Score' ? color : Colors.grey.shade300,
            dataLabelMapper: (_ChartData data, _) =>
                data.label == 'Score' ? '${score.toInt()}%' : '',
            dataLabelSettings: const DataLabelSettings(
                isVisible: true, textStyle: TextStyle(color: Colors.white)),
            radius: '100%',
            innerRadius: '60%',
          )
        ],
      ),
    );
  }

  Widget chipsList(List<String> items, {Color color = Colors.redAccent}) {
    return Wrap(
      spacing: 6,
      runSpacing: 4,
      children: items
          .map((item) => Chip(
                label: Text(item),
                backgroundColor: color.withOpacity(0.2),
                labelStyle: TextStyle(color: color),
              ))
          .toList(),
    );
  }

  // Glassmorphism sidebar
  Widget glassSidebar() {
    return Container(
      width: 200,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: const BorderRadius.only(
          topRight: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
        border: Border.all(color: Colors.white.withOpacity(0.2)),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          Text("Menu",
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold)),
          SizedBox(height: 20),
          Text("Dashboard", style: TextStyle(color: Colors.white)),
          SizedBox(height: 10),
          Text("My Applications", style: TextStyle(color: Colors.white)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Scaffold(
        backgroundColor: Colors.red,
        body: Center(child: CircularProgressIndicator(color: Colors.white)),
      );
    }

    if (applications.isEmpty) {
      return Scaffold(
        backgroundColor: Colors.red.shade50,
        appBar: AppBar(
            title: const Text("My Applications"), backgroundColor: Colors.red),
        body: const Center(child: Text("No applications found")),
      );
    }

    return Scaffold(
      backgroundColor: Colors.red.shade50,
      body: Row(
        children: [
          glassSidebar(),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: applications.length,
              itemBuilder: (context, index) {
                final app = applications[index];
                final assessmentScore =
                    (app['assessment_score'] ?? 0).toDouble();
                final cvScore = (app['cv_score'] ?? 0).toDouble();
                final status = app['status'] ?? "Applied";
                final passFail = assessmentScore >= 60 ? "Pass" : "Fail";

                final missingSkills = List<String>.from(
                    app['cv_parser_result']?['missing_skills'] ?? []);
                final suggestions = List<String>.from(
                    app['cv_parser_result']?['suggestions'] ?? []);

                return Card(
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                  elevation: 6,
                  margin: const EdgeInsets.only(bottom: 16),
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(app['job_title'] ?? "Unknown Job",
                            style: const TextStyle(
                                fontSize: 18, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        Text("Application Status: $status"),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            Column(
                              children: [
                                const Text("Assessment",
                                    style:
                                        TextStyle(fontWeight: FontWeight.bold)),
                                scoreDonutChart(
                                    assessmentScore, Colors.redAccent),
                                const SizedBox(height: 4),
                                Text(passFail,
                                    style: TextStyle(
                                        color: passFail == "Pass"
                                            ? Colors.green
                                            : Colors.red,
                                        fontWeight: FontWeight.bold))
                              ],
                            ),
                            Column(
                              children: [
                                const Text("Resume Score",
                                    style:
                                        TextStyle(fontWeight: FontWeight.bold)),
                                scoreDonutChart(cvScore, Colors.blueAccent),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        if (missingSkills.isNotEmpty) ...[
                          const Text("Missing Skills:",
                              style: TextStyle(fontWeight: FontWeight.bold)),
                          const SizedBox(height: 4),
                          chipsList(missingSkills, color: Colors.redAccent),
                          const SizedBox(height: 12),
                        ],
                        if (suggestions.isNotEmpty) ...[
                          const Text("Suggestions:",
                              style: TextStyle(fontWeight: FontWeight.bold)),
                          const SizedBox(height: 4),
                          chipsList(suggestions, color: Colors.blueAccent),
                        ],
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _ChartData {
  final String label;
  final double value;
  _ChartData(this.label, this.value);
}
