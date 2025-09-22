import 'package:flutter/material.dart';
import '../../services/admin_service.dart';
import '../../models/user_model.dart';
import '../../models/assessment_model.dart';
import '../../screens/admin/candidates_profile_screen.dart';

class CandidatesScreen extends StatefulWidget {
  final int jobId;
  const CandidatesScreen({super.key, required this.jobId});

  @override
  _CandidatesScreenState createState() => _CandidatesScreenState();
}

class _CandidatesScreenState extends State<CandidatesScreen> {
  bool _loading = true;
  List<User> _candidates = [];
  List<User> _filteredCandidates = [];
  Map<int, Assessment> _assessmentResults = {};
  final TextEditingController _searchController = TextEditingController();
  bool _isSidebarOpen = true;

  @override
  void initState() {
    super.initState();
    _fetchCandidatesAndAssessments();
    _searchController.addListener(_filterCandidates);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _filterCandidates() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredCandidates = _candidates.where((c) {
        return c.name.toLowerCase().contains(query) ||
            c.email.toLowerCase().contains(query);
      }).toList();
    });
  }

  Future<void> _fetchCandidatesAndAssessments() async {
    setState(() => _loading = true);
    try {
      final candidates = await AdminService.getCandidates(widget.jobId);

      for (var candidate in candidates) {
        if (candidate.applicationId != null) {
          try {
            final assessment =
                await AdminService.getAssessment(candidate.applicationId!);
            _assessmentResults[candidate.id] = assessment ??
                Assessment(
                  id: 0,
                  applicationId: candidate.applicationId!,
                  score: 0,
                  recommendation: "Assessment not available",
                  assessedAt: DateTime.now(),
                  answers: {},
                );
          } catch (_) {
            _assessmentResults[candidate.id] = Assessment(
              id: 0,
              applicationId: candidate.applicationId!,
              score: 0,
              recommendation: "Assessment not available",
              assessedAt: DateTime.now(),
              answers: {},
            );
          }
        } else {
          _assessmentResults[candidate.id] = Assessment(
            id: 0,
            applicationId: 0,
            score: 0,
            recommendation: "No application found",
            assessedAt: DateTime.now(),
            answers: {},
          );
        }
      }

      setState(() {
        _candidates = candidates;
        _filteredCandidates = candidates;
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error fetching candidates: $e')));
    }
  }

  Future<void> _shortlistCandidate(User candidate) async {
    try {
      await AdminService.shortlistCandidate(widget.jobId, candidate.id);
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Candidate shortlisted')));
      _fetchCandidatesAndAssessments();
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Error shortlisting: $e')));
    }
  }

  void _viewProfile(User candidate) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CandidateProfileScreen(candidate: candidate),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Row(
        children: [
          // ----------------- Sidebar ----------------- //
          AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            width: _isSidebarOpen ? 220 : 60,
            decoration: BoxDecoration(
              color: Colors.redAccent.shade700,
              boxShadow: const [
                BoxShadow(
                  color: Colors.black45,
                  blurRadius: 6,
                  offset: Offset(2, 0),
                ),
              ],
            ),
            child: Column(
              children: [
                const SizedBox(height: 40),
                IconButton(
                  icon: Icon(
                    _isSidebarOpen ? Icons.arrow_back : Icons.menu,
                    color: Colors.white,
                  ),
                  onPressed: () =>
                      setState(() => _isSidebarOpen = !_isSidebarOpen),
                ),
                const SizedBox(height: 20),
                _sidebarItem(Icons.home, "Home", () {}),
                _sidebarItem(Icons.person, "Profile", () {}),
                _sidebarItem(Icons.work, "Jobs", () {}),
                _sidebarItem(Icons.assignment, "Applications", () {}),
                const Spacer(),
                _sidebarItem(Icons.logout, "Logout", () {}),
                const SizedBox(height: 20),
              ],
            ),
          ),

          // ----------------- Main Content ----------------- //
          Expanded(
            child: Container(
              color: Colors.white, // white background
              child: Column(
                children: [
                  // -------- Top Navbar -------- //
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 16),
                    color: Colors.redAccent.withOpacity(0.9),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _searchController,
                            decoration: InputDecoration(
                              hintText: 'Search candidates...',
                              prefixIcon: const Icon(Icons.search),
                              filled: true,
                              fillColor: Colors.white70,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(20),
                                borderSide: BorderSide.none,
                              ),
                            ),
                            style: const TextStyle(color: Colors.black87),
                          ),
                        ),
                        const SizedBox(width: 16),
                        IconButton(
                          icon: const Icon(Icons.notifications,
                              color: Colors.white),
                          onPressed: () {},
                        ),
                        const SizedBox(width: 16),
                        GestureDetector(
                          onTap: () {},
                          child: CircleAvatar(
                            backgroundColor: Colors.redAccent.shade100,
                            child:
                                const Icon(Icons.person, color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // -------- Candidates List -------- //
                  Expanded(
                    child: _loading
                        ? const Center(
                            child: CircularProgressIndicator(
                                color: Colors.redAccent))
                        : _filteredCandidates.isEmpty
                            ? const Center(
                                child: Text(
                                  'No candidates found',
                                  style: TextStyle(
                                      color: Colors.black54, fontSize: 18),
                                ),
                              )
                            : Padding(
                                padding: const EdgeInsets.all(16),
                                child: LayoutBuilder(
                                  builder: (context, constraints) {
                                    return SingleChildScrollView(
                                      child: ConstrainedBox(
                                        constraints: BoxConstraints(
                                            minHeight: constraints.maxHeight),
                                        child: Column(
                                          children: _filteredCandidates.map(
                                            (candidate) {
                                              final assessment =
                                                  _assessmentResults[
                                                      candidate.id];
                                              return Container(
                                                margin: const EdgeInsets.only(
                                                    bottom: 16),
                                                padding:
                                                    const EdgeInsets.all(20),
                                                decoration: BoxDecoration(
                                                  color: Colors.redAccent
                                                      .withOpacity(0.1),
                                                  borderRadius:
                                                      BorderRadius.circular(20),
                                                  boxShadow: const [
                                                    BoxShadow(
                                                      color: Colors.black12,
                                                      blurRadius: 6,
                                                      offset: Offset(0, 3),
                                                    ),
                                                  ],
                                                ),
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Text(candidate.name,
                                                        style: const TextStyle(
                                                            color: Colors
                                                                .redAccent,
                                                            fontSize: 20,
                                                            fontWeight:
                                                                FontWeight
                                                                    .bold)),
                                                    const SizedBox(height: 4),
                                                    Text(candidate.email,
                                                        style: const TextStyle(
                                                            color:
                                                                Colors.black87,
                                                            fontSize: 16)),
                                                    if (assessment != null) ...[
                                                      const SizedBox(height: 8),
                                                      Container(
                                                        padding:
                                                            const EdgeInsets
                                                                .all(12),
                                                        decoration:
                                                            BoxDecoration(
                                                          color:
                                                              Colors.grey[200],
                                                          borderRadius:
                                                              BorderRadius
                                                                  .circular(12),
                                                        ),
                                                        child: Text(
                                                          'Score: ${assessment.score} | Recommendation: ${assessment.recommendation}',
                                                          style:
                                                              const TextStyle(
                                                                  color: Colors
                                                                      .black87,
                                                                  fontSize: 16),
                                                        ),
                                                      ),
                                                    ],
                                                    const SizedBox(height: 12),
                                                    Row(
                                                      children: [
                                                        Expanded(
                                                          child: ElevatedButton(
                                                            style:
                                                                ElevatedButton
                                                                    .styleFrom(
                                                              backgroundColor:
                                                                  Colors.green,
                                                              shape: RoundedRectangleBorder(
                                                                  borderRadius:
                                                                      BorderRadius
                                                                          .circular(
                                                                              12)),
                                                            ),
                                                            onPressed: () =>
                                                                _shortlistCandidate(
                                                                    candidate),
                                                            child: const Text(
                                                                'Shortlist'),
                                                          ),
                                                        ),
                                                        const SizedBox(
                                                            width: 12),
                                                        Expanded(
                                                          child: ElevatedButton(
                                                            style:
                                                                ElevatedButton
                                                                    .styleFrom(
                                                              backgroundColor:
                                                                  Colors
                                                                      .blueAccent,
                                                              shape: RoundedRectangleBorder(
                                                                  borderRadius:
                                                                      BorderRadius
                                                                          .circular(
                                                                              12)),
                                                            ),
                                                            onPressed: () =>
                                                                _viewProfile(
                                                                    candidate),
                                                            child: const Text(
                                                                'View Profile'),
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ],
                                                ),
                                              );
                                            },
                                          ).toList(),
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
        ],
      ),
    );
  }

  Widget _sidebarItem(IconData icon, String label, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
        child: Row(
          children: [
            Icon(icon, color: Colors.white, size: 24),
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
}
