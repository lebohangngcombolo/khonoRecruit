import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_svg/flutter_svg.dart';

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
                Column(
                  children: [
                    Text("Resume Score",
                        style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w600, color: Colors.white)),
                    const SizedBox(height: 8),
                    scoreDonutChart(cvScore, Colors.blue),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (missingSkills.isNotEmpty) ...[
              Text("Missing Skills:",
                  style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w600, color: Colors.white)),
              const SizedBox(height: 4),
              chipsList(missingSkills, color: const Color(0xFFC10D00)),
              const SizedBox(height: 12),
            ],
            if (suggestions.isNotEmpty) ...[
              Text("Suggestions:",
                  style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w600, color: Colors.white)),
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
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: Text(
          "My Applications",
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        backgroundColor: const Color(0xFFC10D00),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _fetchResults,
          ),
        ],
      ),
      body: RefreshIndicator(
        key: _refreshIndicatorKey,
        onRefresh: _fetchResults,
        color: const Color(0xFFC10D00),
        child: Container(
          decoration: const BoxDecoration(
            image: DecorationImage(
              image: AssetImage('assets/images/Frame 1.jpg'),
              fit: BoxFit.cover,
            ),
          ),
          child: _buildBody(),
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (loading && applications.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 40,
              height: 40,
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFC10D00)),
                strokeWidth: 3,
              ),
            ),
            SizedBox(height: 16),
            Text(
              'Loading your applications...',
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      );
    }

    if (hasError) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 64,
                color: Color(0xFFC10D00),
              ),
              const SizedBox(height: 16),
              Text(
                'Oops! Something went wrong',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                errorMessage.isNotEmpty
                    ? errorMessage
                    : 'Unable to load applications. Please try again.',
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _fetchResults,
                icon: const Icon(Icons.refresh, size: 18),
                label: Text('Try Again',
                    style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFC10D00),
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (applications.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.assignment_outlined,
              size: 100,
              color: Colors.grey,
            ),
            const SizedBox(height: 24),
            Text(
              'No Applications Yet',
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40.0),
              child: Text(
                "You haven't applied to any jobs yet. Browse jobs and apply to see your applications here.",
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                // Navigate to jobs list
                Navigator.pushReplacementNamed(context, '/jobs');
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFC10D00),
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                elevation: 2,
              ),
              child: Text('Browse Jobs',
                  style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: applications.length,
      itemBuilder: (context, index) {
        return applicationCard(applications[index]);
      },
    );
  }
}

class _ChartData {
  final String label;
  final double value;
  _ChartData(this.label, this.value);
}
