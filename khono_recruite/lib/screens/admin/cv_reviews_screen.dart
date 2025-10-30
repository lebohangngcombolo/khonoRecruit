import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:percent_indicator/percent_indicator.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/admin_service.dart';
import '../../providers/theme_provider.dart';

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
    if (score >= 70) return Colors.green;
    if (score >= 50) return Colors.orange;
    return Colors.redAccent;
  }

  String getScoreLabel(double score) {
    if (score >= 70) return 'Excellent';
    if (score >= 50) return 'Good';
    return 'Needs Review';
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final screenWidth = MediaQuery.of(context).size.width;
    final crossAxisCount = screenWidth > 1000
        ? 3
        : screenWidth > 600
            ? 2
            : 1;

    return Scaffold(
      // 🌆 Dynamic background implementation
      body: Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage(themeProvider.backgroundImage),
            fit: BoxFit.cover,
          ),
        ),
        child: Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(
            title: Text(
              "CV Reviews Dashboard",
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w600,
              ),
            ),
            backgroundColor: (themeProvider.isDarkMode
                    ? const Color(0xFF14131E)
                    : Colors.white)
                .withOpacity(0.9),
            elevation: 0,
            foregroundColor:
                themeProvider.isDarkMode ? Colors.white : Colors.black87,
            iconTheme: IconThemeData(
                color:
                    themeProvider.isDarkMode ? Colors.white : Colors.black87),
          ),
          body: loading
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const CircularProgressIndicator(
                        valueColor:
                            AlwaysStoppedAnimation<Color>(Colors.redAccent),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        "Loading CV Reviews...",
                        style: GoogleFonts.inter(
                          color: themeProvider.isDarkMode
                              ? Colors.grey.shade400
                              : Colors.grey.shade600,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                )
              : Padding(
                  padding: const EdgeInsets.all(20),
                  child: cvReviews.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.assignment_outlined,
                                size: 80,
                                color: themeProvider.isDarkMode
                                    ? Colors.grey.shade600
                                    : Colors.grey.shade300,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                "No CV Reviews Found",
                                style: GoogleFonts.inter(
                                  color: themeProvider.isDarkMode
                                      ? Colors.grey.shade400
                                      : Colors.grey.shade600,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                "CV reviews will appear here once available",
                                style: GoogleFonts.inter(
                                  color: themeProvider.isDarkMode
                                      ? Colors.grey.shade500
                                      : Colors.grey.shade500,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        )
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Header with stats
                            Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: (themeProvider.isDarkMode
                                        ? const Color(0xFF14131E)
                                        : Colors.white)
                                    .withOpacity(0.9),
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.1),
                                    blurRadius: 15,
                                    offset: const Offset(0, 6),
                                  ),
                                ],
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: Colors.redAccent.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Icon(
                                      Icons.assignment_outlined,
                                      color: Colors.redAccent,
                                      size: 28,
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        "CV Reviews",
                                        style: GoogleFonts.poppins(
                                          fontSize: 20,
                                          fontWeight: FontWeight.w600,
                                          color: themeProvider.isDarkMode
                                              ? Colors.white
                                              : Colors.black87,
                                        ),
                                      ),
                                      Text(
                                        "${cvReviews.length} candidates reviewed",
                                        style: GoogleFonts.inter(
                                          color: themeProvider.isDarkMode
                                              ? Colors.grey.shade400
                                              : Colors.grey.shade600,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const Spacer(),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 16, vertical: 8),
                                    decoration: BoxDecoration(
                                      color: Colors.redAccent.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      "Active Reviews",
                                      style: GoogleFonts.inter(
                                        color: Colors.redAccent,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 20),

                            // Grid of CV reviews
                            Expanded(
                              child: GridView.builder(
                                gridDelegate:
                                    SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: crossAxisCount,
                                  mainAxisSpacing: 20,
                                  crossAxisSpacing: 20,
                                  childAspectRatio: 0.75,
                                ),
                                itemCount: cvReviews.length,
                                itemBuilder: (_, index) {
                                  final review = cvReviews[index];
                                  final score =
                                      (review['cv_score'] ?? 0).toDouble();
                                  final scoreColor = getScoreColor(score);
                                  final scoreLabel = getScoreLabel(score);

                                  final cvParser =
                                      review['cv_parser_result'] ?? {};
                                  final skills = cvParser['skills'] ?? [];
                                  final education = cvParser['education'] ?? [];
                                  final workExp =
                                      cvParser['work_experience'] ?? [];

                                  return Container(
                                    decoration: BoxDecoration(
                                      color: (themeProvider.isDarkMode
                                              ? const Color(0xFF14131E)
                                              : Colors.white)
                                          .withOpacity(0.9),
                                      borderRadius: BorderRadius.circular(20),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.1),
                                          blurRadius: 15,
                                          offset: const Offset(0, 6),
                                        ),
                                      ],
                                    ),
                                    child: Column(
                                      children: [
                                        // Header with score
                                        Container(
                                          padding: const EdgeInsets.all(20),
                                          decoration: BoxDecoration(
                                            color: scoreColor.withOpacity(0.1),
                                            borderRadius:
                                                const BorderRadius.only(
                                              topLeft: Radius.circular(20),
                                              topRight: Radius.circular(20),
                                            ),
                                          ),
                                          child: Row(
                                            children: [
                                              Stack(
                                                alignment: Alignment.center,
                                                children: [
                                                  CircularPercentIndicator(
                                                    radius: 30,
                                                    lineWidth: 6,
                                                    percent: (score / 100)
                                                        .clamp(0.0, 1.0),
                                                    center: Text(
                                                      "${score.toStringAsFixed(0)}%",
                                                      style: GoogleFonts.inter(
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        fontSize: 14,
                                                        color: scoreColor,
                                                      ),
                                                    ),
                                                    progressColor: scoreColor,
                                                    backgroundColor:
                                                        themeProvider.isDarkMode
                                                            ? Colors
                                                                .grey.shade800
                                                            : Colors
                                                                .grey.shade200,
                                                    circularStrokeCap:
                                                        CircularStrokeCap.round,
                                                  ),
                                                ],
                                              ),
                                              const SizedBox(width: 16),
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      review['full_name'] ??
                                                          "Unknown Candidate",
                                                      style: GoogleFonts.inter(
                                                        fontSize: 16,
                                                        fontWeight:
                                                            FontWeight.w600,
                                                        color: themeProvider
                                                                .isDarkMode
                                                            ? Colors.white
                                                            : Colors.black87,
                                                      ),
                                                      maxLines: 1,
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                    ),
                                                    const SizedBox(height: 4),
                                                    Container(
                                                      padding: const EdgeInsets
                                                          .symmetric(
                                                          horizontal: 8,
                                                          vertical: 4),
                                                      decoration: BoxDecoration(
                                                        color: scoreColor
                                                            .withOpacity(0.2),
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(6),
                                                      ),
                                                      child: Text(
                                                        scoreLabel,
                                                        style:
                                                            GoogleFonts.inter(
                                                          color: scoreColor,
                                                          fontSize: 10,
                                                          fontWeight:
                                                              FontWeight.w600,
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),

                                        Expanded(
                                          child: Padding(
                                            padding: const EdgeInsets.all(20),
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                // CV Fit Score
                                                Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Row(
                                                      mainAxisAlignment:
                                                          MainAxisAlignment
                                                              .spaceBetween,
                                                      children: [
                                                        Text(
                                                          "CV Fit Score",
                                                          style:
                                                              GoogleFonts.inter(
                                                            fontWeight:
                                                                FontWeight.w600,
                                                            fontSize: 12,
                                                            color: themeProvider
                                                                    .isDarkMode
                                                                ? Colors.grey
                                                                    .shade400
                                                                : Colors.grey
                                                                    .shade700,
                                                          ),
                                                        ),
                                                        Text(
                                                          "${score.toStringAsFixed(1)}%",
                                                          style:
                                                              GoogleFonts.inter(
                                                            fontWeight:
                                                                FontWeight.w600,
                                                            fontSize: 12,
                                                            color: scoreColor,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                    const SizedBox(height: 8),
                                                    LinearPercentIndicator(
                                                      lineHeight: 6,
                                                      percent: (score / 100)
                                                          .clamp(0.0, 1.0),
                                                      backgroundColor:
                                                          themeProvider
                                                                  .isDarkMode
                                                              ? Colors
                                                                  .grey.shade800
                                                              : Colors.grey
                                                                  .shade200,
                                                      progressColor: scoreColor,
                                                      barRadius:
                                                          const Radius.circular(
                                                              3),
                                                    ),
                                                  ],
                                                ),
                                                const SizedBox(height: 16),

                                                // Skills
                                                if (skills.isNotEmpty)
                                                  Column(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
                                                    children: [
                                                      Text(
                                                        "Skills",
                                                        style:
                                                            GoogleFonts.inter(
                                                          fontWeight:
                                                              FontWeight.w600,
                                                          fontSize: 12,
                                                          color: themeProvider
                                                                  .isDarkMode
                                                              ? Colors
                                                                  .grey.shade400
                                                              : Colors.grey
                                                                  .shade700,
                                                        ),
                                                      ),
                                                      const SizedBox(height: 8),
                                                      Wrap(
                                                        spacing: 6,
                                                        runSpacing: 6,
                                                        children: skills
                                                            .take(4)
                                                            .map<Widget>(
                                                                (s) =>
                                                                    Container(
                                                                      padding: const EdgeInsets
                                                                          .symmetric(
                                                                          horizontal:
                                                                              8,
                                                                          vertical:
                                                                              4),
                                                                      decoration:
                                                                          BoxDecoration(
                                                                        color: Colors
                                                                            .redAccent
                                                                            .withOpacity(0.1),
                                                                        borderRadius:
                                                                            BorderRadius.circular(12),
                                                                      ),
                                                                      child:
                                                                          Text(
                                                                        s.toString(),
                                                                        style: GoogleFonts
                                                                            .inter(
                                                                          fontSize:
                                                                              10,
                                                                          color:
                                                                              Colors.redAccent,
                                                                          fontWeight:
                                                                              FontWeight.w500,
                                                                        ),
                                                                      ),
                                                                    ))
                                                            .toList(),
                                                      ),
                                                      if (skills.length > 4)
                                                        Padding(
                                                          padding:
                                                              const EdgeInsets
                                                                  .only(top: 4),
                                                          child: Text(
                                                            "+${skills.length - 4} more",
                                                            style: GoogleFonts
                                                                .inter(
                                                              fontSize: 10,
                                                              color: themeProvider
                                                                      .isDarkMode
                                                                  ? Colors.grey
                                                                      .shade500
                                                                  : Colors.grey
                                                                      .shade500,
                                                            ),
                                                          ),
                                                        ),
                                                      const SizedBox(
                                                          height: 12),
                                                    ],
                                                  ),

                                                // Education
                                                if (education.isNotEmpty)
                                                  Column(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
                                                    children: [
                                                      Text(
                                                        "Education",
                                                        style:
                                                            GoogleFonts.inter(
                                                          fontWeight:
                                                              FontWeight.w600,
                                                          fontSize: 12,
                                                          color: themeProvider
                                                                  .isDarkMode
                                                              ? Colors
                                                                  .grey.shade400
                                                              : Colors.grey
                                                                  .shade700,
                                                        ),
                                                      ),
                                                      const SizedBox(height: 6),
                                                      ...education
                                                          .take(2)
                                                          .map<Widget>(
                                                              (edu) => Padding(
                                                                    padding: const EdgeInsets
                                                                        .only(
                                                                        bottom:
                                                                            4),
                                                                    child: Text(
                                                                      "• ${edu['degree'] ?? ''} - ${edu['institution'] ?? ''}",
                                                                      style: GoogleFonts
                                                                          .inter(
                                                                        fontSize:
                                                                            10,
                                                                        color: themeProvider.isDarkMode
                                                                            ? Colors.grey.shade500
                                                                            : Colors.grey.shade600,
                                                                      ),
                                                                      maxLines:
                                                                          1,
                                                                      overflow:
                                                                          TextOverflow
                                                                              .ellipsis,
                                                                    ),
                                                                  )),
                                                      const SizedBox(
                                                          height: 12),
                                                    ],
                                                  ),

                                                // Work Experience
                                                if (workExp.isNotEmpty)
                                                  Expanded(
                                                    child: Column(
                                                      crossAxisAlignment:
                                                          CrossAxisAlignment
                                                              .start,
                                                      children: [
                                                        Text(
                                                          "Experience",
                                                          style:
                                                              GoogleFonts.inter(
                                                            fontWeight:
                                                                FontWeight.w600,
                                                            fontSize: 12,
                                                            color: themeProvider
                                                                    .isDarkMode
                                                                ? Colors.grey
                                                                    .shade400
                                                                : Colors.grey
                                                                    .shade700,
                                                          ),
                                                        ),
                                                        const SizedBox(
                                                            height: 6),
                                                        ...workExp
                                                            .take(2)
                                                            .map<Widget>(
                                                                (exp) =>
                                                                    Padding(
                                                                      padding: const EdgeInsets
                                                                          .only(
                                                                          bottom:
                                                                              4),
                                                                      child:
                                                                          Text(
                                                                        "• ${exp['role'] ?? ''} at ${exp['company'] ?? ''}",
                                                                        style: GoogleFonts
                                                                            .inter(
                                                                          fontSize:
                                                                              10,
                                                                          color: themeProvider.isDarkMode
                                                                              ? Colors.grey.shade500
                                                                              : Colors.grey.shade600,
                                                                        ),
                                                                        maxLines:
                                                                            1,
                                                                        overflow:
                                                                            TextOverflow.ellipsis,
                                                                      ),
                                                                    )),
                                                      ],
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
                          ],
                        ),
                ),
        ),
      ),
    );
  }
}
