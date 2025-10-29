import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class AssessmentResultsPage extends StatefulWidget {
  final int? applicationId;
  final String token;
  const AssessmentResultsPage(
      {super.key, this.applicationId, required this.token});

  @override
  State<AssessmentResultsPage> createState() => _AssessmentResultsPageState();
}

class _AssessmentResultsPageState extends State<AssessmentResultsPage> {
  bool loading = true;
  List<dynamic> applications = [];
  late String token;

  @override
  void initState() {
    super.initState();
    token = widget.token;
    _fetchResults();
  }

  Future<void> _fetchResults() async {
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
                data.label == 'Score' ? color : Colors.grey[300],
            dataLabelMapper: (_ChartData data, _) =>
                data.label == 'Score' ? '${score.toInt()}%' : '',
            dataLabelSettings: const DataLabelSettings(
                isVisible: true,
                textStyle: TextStyle(
                    color: Colors.black, fontWeight: FontWeight.bold)),
            radius: '100%',
            innerRadius: '60%',
          )
        ],
      ),
    );
  }

  Widget chipsList(List<String> items, {Color color = Colors.red}) {
    return Wrap(
      spacing: 6,
      runSpacing: 4,
      children: items
          .map((item) => Chip(
                label: Text(item),
                backgroundColor: color.withAlpha((255 * 0.2).round()), // Use withAlpha
                labelStyle:
                    TextStyle(color: color, fontWeight: FontWeight.bold),
              ))
          .toList(),
    );
  }

  Widget sidebar() {
    return Container(
      width: 200,
      color: Colors.white,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          Text("Menu",
              style: TextStyle(
                  color: Colors.red,
                  fontSize: 20,
                  fontWeight: FontWeight.bold)),
          SizedBox(height: 24),
          Text("Dashboard", style: TextStyle(color: Colors.black87)),
          SizedBox(height: 12),
          Text("My Applications", style: TextStyle(color: Colors.black87)),
        ],
      ),
    );
  }

  Widget applicationCard(dynamic app) {
    final assessmentScore = (app['assessment_score'] ?? 0).toDouble();
    final cvScore = (app['cv_score'] ?? 0).toDouble();
    final status = app['status'] ?? "Applied";
    final passFail = assessmentScore >= 60 ? "Pass" : "Fail";
    final missingSkills =
        List<String>.from(app['cv_parser_result']?['missing_skills'] ?? []);
    final suggestions =
        List<String>.from(app['cv_parser_result']?['suggestions'] ?? []);

    return Card(
      color: Colors.white,
      margin: const EdgeInsets.symmetric(vertical: 12),
      elevation: 3,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: Colors.red, width: 1)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(app['job_title'] ?? "Unknown Job",
                style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.red)),
            const SizedBox(height: 8),
            Text("Application Status: $status",
                style: const TextStyle(color: Colors.black87)),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Column(
                  children: [
                    const Text("Assessment",
                        style: TextStyle(
                            fontWeight: FontWeight.bold, color: Colors.black)),
                    const SizedBox(height: 8),
                    scoreDonutChart(assessmentScore, Colors.red),
                    const SizedBox(height: 4),
                    Text(passFail,
                        style: TextStyle(
                            color:
                                passFail == "Pass" ? Colors.green : Colors.red,
                            fontWeight: FontWeight.bold))
                  ],
                ),
                Column(
                  children: [
                    const Text("Resume Score",
                        style: TextStyle(
                            fontWeight: FontWeight.bold, color: Colors.black)),
                    const SizedBox(height: 8),
                    scoreDonutChart(cvScore, Colors.blue),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (missingSkills.isNotEmpty) ...[
              const Text("Missing Skills:",
                  style: TextStyle(
                      fontWeight: FontWeight.bold, color: Colors.red)),
              const SizedBox(height: 4),
              chipsList(missingSkills, color: Colors.red),
              const SizedBox(height: 12),
            ],
            if (suggestions.isNotEmpty) ...[
              const Text("Suggestions:",
                  style: TextStyle(
                      fontWeight: FontWeight.bold, color: Colors.black)),
              const SizedBox(height: 4),
              chipsList(suggestions, color: Colors.blue),
            ],
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent, // Ensure Scaffold is transparent to show background
      appBar: applications.isEmpty && !loading
          ? AppBar(
              title: Text("My Applications", style: GoogleFonts.poppins(fontWeight: FontWeight.w600, color: Colors.white)),
              backgroundColor: Colors.red,
              elevation: 0,
            )
          : null, // Only show AppBar if no applications and not loading
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('Khono_Assets2/images/frame_1.jpg'),
            fit: BoxFit.cover,
          ),
        ),
        child: loading
            ? const Center(
                child: CircularProgressIndicator(color: Colors.red),
              )
            : applications.isEmpty
                ? const Center(
                    child: Text(
                      "No applications found",
                      style: TextStyle(color: Colors.black87),
                    ),
                  )
                : Row(
                    children: [
                      sidebar(),
                      Expanded(
                        child: ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: applications.length,
                          itemBuilder: (context, index) {
                            return applicationCard(applications[index]);
                          },
                        ),
                      ),
                    ],
                  ),
      ),
    );
  }
}

class _ChartData {
  final String label;
  final double value;
  _ChartData(this.label, this.value);
}
