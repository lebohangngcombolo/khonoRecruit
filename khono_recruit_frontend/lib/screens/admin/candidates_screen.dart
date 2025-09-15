import 'package:flutter/material.dart';
import '../../services/admin_service.dart';
import '../../models/user_model.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/custom_button.dart';

class CandidatesScreen extends StatefulWidget {
  final int jobId;
  const CandidatesScreen({super.key, required this.jobId});

  @override
  _CandidatesScreenState createState() => _CandidatesScreenState();
}

class _CandidatesScreenState extends State<CandidatesScreen> {
  bool _loading = true;
  List<User> _candidates = [];

  @override
  void initState() {
    super.initState();
    _fetchCandidates();
  }

  Future<void> _fetchCandidates() async {
    try {
      final list = await AdminService.getCandidates(widget.jobId);
      setState(() {
        _candidates = list;
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error fetching candidates: $e')));
    }
  }

  Future<void> _shortlistCandidate(int candidateId) async {
    try {
      await AdminService.shortlistCandidate(widget.jobId, candidateId);
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Candidate shortlisted')));
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Error shortlisting: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Candidates')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: _candidates.length,
              itemBuilder: (_, index) {
                final candidate = _candidates[index];
                return GlassCard(
                  child: ListTile(
                    title: Text(candidate.name,
                        style: const TextStyle(color: Colors.white)),
                    subtitle: Text(candidate.email,
                        style: const TextStyle(color: Colors.white70)),
                    trailing: CustomButton(
                      text: 'Shortlist',
                      onPressed: () => _shortlistCandidate(candidate.id),
                    ),
                  ),
                );
              },
            ),
    );
  }
}
