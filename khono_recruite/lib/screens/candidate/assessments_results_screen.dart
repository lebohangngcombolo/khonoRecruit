import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:go_router/go_router.dart';

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
  bool hasError = false;
  String errorMessage = '';
  List<dynamic> applications = [];
  late String token;
  final GlobalKey<RefreshIndicatorState> _refreshIndicatorKey =
      GlobalKey<RefreshIndicatorState>();

  @override
  void initState() {
    super.initState();
    token = widget.token;
    _fetchResults();
  }

  Future<void> _fetchResults() async {
    if (!loading) {
      setState(() {
        loading = true;
        hasError = false;
        errorMessage = '';
      });
    }

    try {
      final res = await http.get(
        Uri.parse('http://127.0.0.1:5000/api/candidate/applications'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token'
        },
      );

      if (res.statusCode == 200) {
        final data = json.decode(res.body);
        List<dynamic> filteredData = [];

        if (data is List) {
          filteredData = widget.applicationId != null
              ? data
                  .where((a) => a['application_id'] == widget.applicationId)
                  .toList()
              : List<dynamic>.from(data);
        }

        setState(() {
          applications = filteredData;
          hasError = false;
        });
      } else {
        throw Exception(
            'Failed to load applications. Status code: ${res.statusCode}');
      }
    } catch (e) {
      setState(() {
        hasError = true;
        errorMessage = e.toString().replaceAll('Exception: ', '');
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:
                Text('Error: ${e.toString().replaceAll('Exception: ', '')}'),
            backgroundColor: const Color(0xFFC10D00),
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.all(10),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => loading = false);
      }
    }
  }

  Widget scoreDonutChart(double score, Color color) {
    return SizedBox(
      height: 100,
      width: 100,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SfCircularChart(
            margin: EdgeInsets.zero,
            annotations: <CircularChartAnnotation>[
              CircularChartAnnotation(
                widget: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${score.toInt()}%',
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      'Score',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ],
            series: <CircularSeries>[
              DoughnutSeries<_ChartData, String>(
                dataSource: [
                  _ChartData('Score', score),
                  _ChartData('Remaining', 100 - score)
                ],
                xValueMapper: (_ChartData data, _) => data.label,
                yValueMapper: (_ChartData data, _) => data.value,
                pointColorMapper: (_ChartData data, _) =>
                    data.label == 'Score' ? color : Colors.grey[200],
                dataLabelMapper: (_ChartData data, _) => '',
                radius: '100%',
                innerRadius: '75%',
                cornerStyle: CornerStyle.bothCurve,
                strokeColor: Colors.transparent,
                strokeWidth: 0,
                animationDuration: 1500,
              ),
            ],
          ),
          // Outer ring for better visual effect
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: color.withOpacity(0.2),
                width: 1,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget chipsList(List<String> items,
      {Color color = const Color(0xFFC10D00)}) {
    if (items.isEmpty) {
      return const SizedBox.shrink();
    }

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: items.map((item) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: color.withOpacity(0.3)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                color == Colors.blue ? Icons.lightbulb_outline : Icons.close,
                size: 14,
                color: color,
              ),
              const SizedBox(width: 4),
              Text(
                item,
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  // Helper method to get status color
  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'accepted':
        return Colors.green;
      case 'rejected':
        return const Color(0xFFC10D00);
      case 'pending':
        return Colors.orange;
      case 'shortlisted':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  // Helper method to format date
  String _formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      return '${_getMonthName(date.month)} ${date.day}, ${date.year}';
    } catch (e) {
      return 'N/A';
    }
  }

  String _getMonthName(int month) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];
    return months[month - 1];
  }

  Widget _buildStatusBadge(String status, String passFail) {
    Color statusColor = Colors.blue;
    if (status.toLowerCase() == 'approved') statusColor = Colors.green;
    if (status.toLowerCase() == 'rejected') statusColor = Colors.red;

    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: statusColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            status,
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: statusColor,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: passFail == "Pass"
                ? Colors.green.withOpacity(0.1)
                : Colors.red.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            passFail,
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: passFail == "Pass" ? Colors.green : Colors.red,
            ),
          ),
        ),
      ],
    );
  }

  Widget applicationCard(dynamic app) {
    final assessmentScore = (app['assessment_score'] ?? 0).toDouble();
    final cvScore = (app['cv_score'] ?? 0).toDouble();
    final status = app['status']?.toString().toLowerCase() ?? "applied";
    final passFail = assessmentScore >= 60 ? "Pass" : "Fail";
    final missingSkills = List<String>.from(
      app['cv_parser_result']?['missing_skills']?.map((e) => e.toString()) ??
          [],
    );
    final suggestions = List<String>.from(
      app['cv_parser_result']?['suggestions']?.map((e) => e.toString()) ?? [],
    );

    // Format status for display
    final statusText = status.isNotEmpty
        ? '${status[0].toUpperCase()}${status.substring(1)}'
        : 'Applied';

    // Get status color
    final statusColor = _getStatusColor(status);

    return Card(
      color: Colors.black.withOpacity(0.25),
      margin: const EdgeInsets.symmetric(vertical: 12),
      elevation: 3,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: Color(0xFFC10D00), width: 1)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(app['job_title'] ?? "Unknown Job",
                style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.white)),
            const SizedBox(height: 8),
            Row(
              children: [
                Text("Status: ",
                    style: GoogleFonts.poppins(
                        color: Colors.white, fontWeight: FontWeight.w600)),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: statusColor.withOpacity(0.3)),
                  ),
                  child: Text(
                    statusText,
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                const Spacer(),
                Text(
                  'Applied on: ${_formatDate(app['applied_date'] ?? DateTime.now().toString())}',
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  children: [
                    Text("Assessment",
                        style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w600, color: Colors.white)),
                    const SizedBox(height: 8),
                    scoreDonutChart(assessmentScore, const Color(0xFFC10D00)),
                    const SizedBox(height: 4),
                    Text(passFail,
                        style: GoogleFonts.poppins(
                            color: Colors.white, fontWeight: FontWeight.w600))
                  ],
                ),
                const SizedBox(height: 16),
              ],
            ],

            // Application Date
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.green.shade100),
              ),
              child: Row(
                children: [
                  Icon(Icons.calendar_today,
                      color: Colors.green.shade600, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      "Applied on: ${app['applied_on'] ?? 'Unknown date'}",
                      style: GoogleFonts.inter(
                        color: Colors.green.shade800,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage("assets/images/dark.png"),
            fit: BoxFit.cover,
          ),
        ),
        child: Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(
            title: Text(
              "Assessment Results",
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
            backgroundColor: Colors.transparent,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () {
                // Redirect to dashboard using GoRouter
                GoRouter.of(context).go('/candidate-dashboard');
              },
            ),
            iconTheme: const IconThemeData(color: Colors.white),
          ),
          body: loading
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        "Loading Assessment Results...",
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                )
              : applications.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.assessment_outlined,
                            size: 80,
                            color: Colors.white.withOpacity(0.5),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            "No Assessment Results Found",
                            style: GoogleFonts.inter(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            "Your assessment results will appear here",
                            style: GoogleFonts.inter(
                              color: Colors.white.withOpacity(0.7),
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView(
                      padding: const EdgeInsets.all(24),
                      children: [
                        // Summary Card
                        Container(
                          padding: const EdgeInsets.all(20),
                          margin: const EdgeInsets.only(bottom: 24),
                          decoration: BoxDecoration(
                            color: const Color(0xFFDC2626).withOpacity(0.2),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.2),
                              width: 1,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Performance Overview",
                                style: GoogleFonts.poppins(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                "Track your assessment scores and improvement areas",
                                style: GoogleFonts.inter(
                                  fontSize: 14,
                                  color: Colors.white.withOpacity(0.9),
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Applications List
                        ...applications
                            .map((app) => applicationCard(app))
                            .toList(),
                      ],
                    ),
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
