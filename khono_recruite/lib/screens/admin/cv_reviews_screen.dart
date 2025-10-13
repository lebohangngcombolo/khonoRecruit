import 'package:flutter/material.dart';
import 'package:percent_indicator/percent_indicator.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../services/admin_service.dart';

class CVReviewsScreen extends StatefulWidget {
  const CVReviewsScreen({super.key});

  @override
  State<CVReviewsScreen> createState() => _CVReviewsScreenState();
}

class _CVReviewsScreenState extends State<CVReviewsScreen> {
  final AdminService admin = AdminService();
  List<Map<String, dynamic>> cvReviews = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    fetchCVReviews();
  }

  Future<void> fetchCVReviews() async {
    setState(() => loading = true);
    try {
      final data = await admin.listCVReviews();
      setState(() {
        cvReviews = List<Map<String, dynamic>>.from(data);
      });
    } catch (e) {
      debugPrint("Error fetching CV reviews: $e");
    } finally {
      setState(() => loading = false);
    }
  }

  Color getScoreColor(double score) {
    if (score >= 70) return Colors.greenAccent;
    if (score >= 50) return Colors.orangeAccent;
    return Colors.redAccent;
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final crossAxisCount = screenWidth > 1000
        ? 3
        : screenWidth > 600
            ? 2
            : 1;

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text("CV Reviews"),
        backgroundColor: Colors.redAccent,
        elevation: 0,
      ),
      body: loading
          ? const Center(
              child: CircularProgressIndicator(color: Colors.redAccent))
          : Padding(
              padding: const EdgeInsets.all(16),
              child: cvReviews.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Icon(Icons.folder_open, size: 80, color: Colors.grey),
                          SizedBox(height: 16),
                          Text(
                            "No CV reviews found",
                            style: TextStyle(color: Colors.grey, fontSize: 16),
                          ),
                        ],
                      ),
                    )
                  : GridView.builder(
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: crossAxisCount,
                        mainAxisSpacing: 16,
                        crossAxisSpacing: 16,
                        childAspectRatio: 0.75,
                      ),
                      itemCount: cvReviews.length,
                      itemBuilder: (_, index) {
                        final review = cvReviews[index];
                        final score = (review['cv_score'] ?? 0).toDouble();
                        final topColor = getScoreColor(score);

                        final cvParser = review['cv_parser_result'] ?? {};
                        final skills = cvParser['skills'] ?? [];
                        final education = cvParser['education'] ?? [];
                        final workExp = cvParser['work_experience'] ?? [];

                        return Card(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 4,
                          child: Column(
                            children: [
                              // Top color indicator
                              Container(
                                height: 6,
                                decoration: BoxDecoration(
                                  color: topColor,
                                  borderRadius: const BorderRadius.vertical(
                                      top: Radius.circular(16)),
                                ),
                              ),
                              Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      // Candidate & Score
                                      Row(
                                        children: [
                                          CircularPercentIndicator(
                                            radius: 28,
                                            lineWidth: 5,
                                            percent:
                                                (score / 100).clamp(0.0, 1.0),
                                            center: Text(
                                              "${score.toStringAsFixed(0)}%",
                                              style: const TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 12),
                                            ),
                                            progressColor: topColor,
                                            backgroundColor: Colors.grey[300]!,
                                            circularStrokeCap:
                                                CircularStrokeCap.round,
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Text(
                                              review['full_name'] ??
                                                  "Unknown Candidate",
                                              style: const TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.bold),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 12),

                                      // CV Fit Linear Progress
                                      Text(
                                        "CV Fit Score",
                                        style: const TextStyle(
                                            fontWeight: FontWeight.bold),
                                      ),
                                      const SizedBox(height: 6),
                                      LinearPercentIndicator(
                                        lineHeight: 8,
                                        percent: (score / 100).clamp(0.0, 1.0),
                                        backgroundColor: Colors.grey[300]!,
                                        progressColor: topColor,
                                      ),
                                      const SizedBox(height: 12),

                                      // Skills
                                      if (skills.isNotEmpty)
                                        Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            const Text(
                                              "Skills",
                                              style: TextStyle(
                                                  fontWeight: FontWeight.bold),
                                            ),
                                            const SizedBox(height: 4),
                                            Wrap(
                                              spacing: 6,
                                              runSpacing: 4,
                                              children: skills
                                                  .map<Widget>((s) => Chip(
                                                        label: Text(
                                                          s.toString(),
                                                          style:
                                                              const TextStyle(
                                                                  fontSize: 10),
                                                        ),
                                                        backgroundColor:
                                                            topColor
                                                                .withOpacity(
                                                                    0.2),
                                                        visualDensity:
                                                            VisualDensity
                                                                .compact,
                                                      ))
                                                  .toList(),
                                            ),
                                            const SizedBox(height: 8),
                                          ],
                                        ),

                                      // Education
                                      if (education.isNotEmpty)
                                        Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            const Text(
                                              "Education",
                                              style: TextStyle(
                                                  fontWeight: FontWeight.bold),
                                            ),
                                            const SizedBox(height: 4),
                                            ...education
                                                .map<Widget>((edu) => Text(
                                                      "${edu['degree'] ?? ''} - ${edu['institution'] ?? ''} (${edu['year'] ?? ''})",
                                                      style: const TextStyle(
                                                          fontSize: 11),
                                                    )),
                                            const SizedBox(height: 8),
                                          ],
                                        ),

                                      // Work Experience
                                      if (workExp.isNotEmpty)
                                        Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            const Text(
                                              "Work Experience",
                                              style: TextStyle(
                                                  fontWeight: FontWeight.bold),
                                            ),
                                            const SizedBox(height: 4),
                                            ...workExp
                                                .map<Widget>((exp) => Text(
                                                      "${exp['role'] ?? ''} at ${exp['company'] ?? ''} (${exp['years'] ?? ''})",
                                                      style: const TextStyle(
                                                          fontSize: 11),
                                                    )),
                                            const SizedBox(height: 8),
                                          ],
                                        ),

                                      // Download CV
                                      if (review['cv_url'] != null)
                                        Align(
                                          alignment: Alignment.centerRight,
                                          child: ElevatedButton.icon(
                                            icon: const Icon(Icons.download,
                                                size: 16),
                                            label: const Text("Download CV",
                                                style: TextStyle(fontSize: 11)),
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: Colors.redAccent,
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                              ),
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      horizontal: 12,
                                                      vertical: 6),
                                            ),
                                            onPressed: () async {
                                              final url =
                                                  Uri.parse(review['cv_url']);
                                              if (await canLaunchUrl(url)) {
                                                await launchUrl(url,
                                                    mode: LaunchMode
                                                        .externalApplication);
                                              }
                                            },
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
    );
  }
}
