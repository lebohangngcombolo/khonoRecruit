import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/admin_service.dart';
import '../../widgets/custom_button.dart';
import 'candidate_detail_screen.dart';
import '../../providers/theme_provider.dart';

class CandidateManagementScreen extends StatefulWidget {
  final int jobId;

  const CandidateManagementScreen({super.key, required this.jobId});

  @override
  _CandidateManagementScreenState createState() =>
      _CandidateManagementScreenState();
}

class _CandidateManagementScreenState extends State<CandidateManagementScreen> {
  final AdminService admin = AdminService();
  List<Map<String, dynamic>> candidates = [];
  bool loading = true;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    fetchShortlist();
  }

  Future<void> fetchShortlist() async {
    setState(() {
      loading = true;
      errorMessage = null;
    });

    try {
      final data = await admin.shortlistCandidates(widget.jobId);
      final List<Map<String, dynamic>> fetched =
          List<Map<String, dynamic>>.from(data);

      fetched.sort((a, b) {
        final aScore = a['overall_score'] ?? 0;
        final bScore = b['overall_score'] ?? 0;
        return bScore.compareTo(aScore);
      });

      setState(() => candidates = fetched);
    } catch (e) {
      debugPrint("Error fetching shortlist: $e");
      setState(() => errorMessage = "Failed to load candidates: $e");
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Error: $e")));
    } finally {
      setState(() => loading = false);
    }
  }

  void openCandidateDetails(Map<String, dynamic> candidate) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CandidateDetailScreen(
          candidateId: candidate['candidate_id'],
          applicationId: candidate['application_id'],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

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
          body: SafeArea(
            child: Column(
              children: [
                // Sticky header
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  color: (themeProvider.isDarkMode
                          ? const Color(0xFF14131E)
                          : Colors.white)
                      .withOpacity(0.9),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Shortlisted Candidates",
                        style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: themeProvider.isDarkMode
                                ? Colors.white
                                : Colors.black87),
                      ),
                      CustomButton(
                        text: "Refresh",
                        onPressed: fetchShortlist,
                      ),
                    ],
                  ),
                ),
                Divider(
                    height: 1,
                    color: themeProvider.isDarkMode
                        ? Colors.grey.shade800
                        : Colors.grey),

                // Loading / Error / Candidate List
                Expanded(
                  child: loading
                      ? const Center(
                          child: CircularProgressIndicator(
                              color: Colors.redAccent),
                        )
                      : errorMessage != null
                          ? Center(
                              child: Text(
                                errorMessage!,
                                style: TextStyle(
                                    color: Colors.redAccent, fontSize: 16),
                              ),
                            )
                          : candidates.isEmpty
                              ? Center(
                                  child: Text(
                                    "No shortlisted candidates found",
                                    style: TextStyle(
                                        color: themeProvider.isDarkMode
                                            ? Colors.grey.shade400
                                            : Colors.black54,
                                        fontSize: 16),
                                  ),
                                )
                              : RefreshIndicator(
                                  onRefresh: fetchShortlist,
                                  color: Colors.redAccent,
                                  child: ListView.builder(
                                    padding: const EdgeInsets.all(16),
                                    itemCount: candidates.length,
                                    itemBuilder: (_, index) {
                                      final c = candidates[index];
                                      final overallScore =
                                          c['overall_score']?.toDouble() ?? 0.0;

                                      return GestureDetector(
                                        onTap: () => openCandidateDetails(c),
                                        child: Container(
                                          margin: const EdgeInsets.symmetric(
                                              vertical: 8),
                                          padding: const EdgeInsets.all(16),
                                          decoration: BoxDecoration(
                                            color: (themeProvider.isDarkMode
                                                    ? const Color(0xFF14131E)
                                                    : Colors.white)
                                                .withOpacity(0.9),
                                            borderRadius:
                                                BorderRadius.circular(12),
                                            border: Border.all(
                                                color: themeProvider.isDarkMode
                                                    ? Colors.grey.shade800
                                                    : Colors.grey.shade200),
                                            boxShadow: [
                                              BoxShadow(
                                                color: Colors.black
                                                    .withOpacity(0.03),
                                                blurRadius: 6,
                                                offset: const Offset(0, 3),
                                              )
                                            ],
                                          ),
                                          child: Row(
                                            children: [
                                              CircleAvatar(
                                                radius: 26,
                                                backgroundColor:
                                                    Colors.red.shade50,
                                                child: Text(
                                                  c['full_name']
                                                          ?.substring(0, 1) ??
                                                      "?",
                                                  style: const TextStyle(
                                                      color: Colors.redAccent,
                                                      fontWeight:
                                                          FontWeight.bold),
                                                ),
                                              ),
                                              const SizedBox(width: 16),
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      c['full_name'] ??
                                                          'Unnamed Candidate',
                                                      style: TextStyle(
                                                          fontWeight:
                                                              FontWeight.w600,
                                                          fontSize: 16,
                                                          color: themeProvider
                                                                  .isDarkMode
                                                              ? Colors.white
                                                              : Colors.black87),
                                                    ),
                                                    const SizedBox(height: 4),
                                                    Text(
                                                      "CV: ${c['cv_score'] ?? 'N/A'} | "
                                                      "Assessment: ${c['assessment_score'] ?? 'N/A'} | "
                                                      "Overall: ${overallScore.toStringAsFixed(1)}",
                                                      style: TextStyle(
                                                          fontSize: 14,
                                                          color: themeProvider
                                                                  .isDarkMode
                                                              ? Colors
                                                                  .grey.shade400
                                                              : Colors.black87),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                        vertical: 6,
                                                        horizontal: 12),
                                                decoration: BoxDecoration(
                                                  color: c['status'] == "hired"
                                                      ? Colors.green.shade50
                                                      : Colors.orange.shade50,
                                                  borderRadius:
                                                      BorderRadius.circular(20),
                                                ),
                                                child: Text(
                                                  c['status'] ?? "Pending",
                                                  style: TextStyle(
                                                    color:
                                                        c['status'] == "hired"
                                                            ? Colors.green
                                                            : Colors.orange,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      );
                                    },
                                  ),
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
