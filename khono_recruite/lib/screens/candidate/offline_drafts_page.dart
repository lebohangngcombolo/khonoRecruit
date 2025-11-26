import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import '../../services/drafts_service.dart';
import '../../services/auth_service.dart';
import 'job_details_page.dart';

class OfflineDraftsPage extends StatefulWidget {
  final String token;
  const OfflineDraftsPage({super.key, required this.token});

  @override
  State<OfflineDraftsPage> createState() => _OfflineDraftsPageState();
}

class _OfflineDraftsPageState extends State<OfflineDraftsPage> {
  List<Map<String, dynamic>> drafts = [];
  bool loading = true;
  bool syncing = false;

  @override
  void initState() {
    super.initState();
    _loadDrafts();
  }

  Future<void> _loadDrafts() async {
    setState(() => loading = true);
    final list = await DraftsService.getDrafts();
    setState(() {
      drafts = list;
      loading = false;
    });
  }

  Future<void> _deleteDraft(String id) async {
    await DraftsService.deleteDraft(id);
    await _loadDrafts();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Draft deleted')),
      );
    }
  }

  Future<void> _syncSingle(Map<String, dynamic> draft) async {
    final job = draft['job'] as Map<String, dynamic>?;
    final form = draft['form'] as Map<String, dynamic>?;
    if (job == null || form == null || job['id'] == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Missing job info in draft')),
      );
      return;
    }
    setState(() => syncing = true);
    try {
      final token = await AuthService.getAccessToken();
      final res = await http.post(
        Uri.parse('http://127.0.0.1:5000/api/candidate/apply/${job['id']}'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({
          'full_name': form['full_name'] ?? '',
          'phone': form['phone'] ?? '',
          'portfolio': form['portfolio'] ?? '',
          'cover_letter': form['cover_letter'] ?? '',
        }),
      );
      if (res.statusCode == 201 || res.statusCode == 200) {
        await DraftsService.deleteDraft(draft['id']);
        await _loadDrafts();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Draft synced successfully')),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Sync failed: ${res.statusCode}')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Sync error: $e')),
      );
    } finally {
      if (mounted) setState(() => syncing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Offline Drafts',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        backgroundColor: const Color(0xFFC10D00),
      ),
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/Frame 1.jpg'),
            fit: BoxFit.cover,
          ),
        ),
        child: loading
            ? const Center(
                child: CircularProgressIndicator(color: Color(0xFFC10D00)))
            : drafts.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.save_outlined,
                            size: 72, color: Colors.white70),
                        const SizedBox(height: 12),
                        Text('No offline drafts found',
                            style: GoogleFonts.poppins(
                                color: Colors.white,
                                fontWeight: FontWeight.w600)),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: drafts.length,
                    itemBuilder: (context, index) {
                      final d = drafts[index];
                      final job = (d['job'] ?? {}) as Map<String, dynamic>;
                      final form = (d['form'] ?? {}) as Map<String, dynamic>;
                      return Card(
                        color: Colors.black.withOpacity(0.25),
                        elevation: 3,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: const BorderSide(
                              color: Color(0xFFC10D00), width: 1),
                        ),
                        margin: const EdgeInsets.only(bottom: 12),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(job['title'] ?? 'Job draft',
                                  style: GoogleFonts.poppins(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white)),
                              const SizedBox(height: 4),
                              Text(
                                  '${job['company'] ?? ''} • ${job['location'] ?? ''}',
                                  style: GoogleFonts.poppins(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600)),
                              const SizedBox(height: 8),
                              Text('Saved: ${d['saved_at'] ?? ''}',
                                  style: GoogleFonts.poppins(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600)),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  ElevatedButton(
                                    onPressed:
                                        syncing ? null : () => _syncSingle(d),
                                    style: ElevatedButton.styleFrom(
                                        backgroundColor:
                                            const Color(0xFFC10D00)),
                                    child: Text('Sync Now',
                                        style: GoogleFonts.poppins(
                                            fontWeight: FontWeight.w600,
                                            color: Colors.white)),
                                  ),
                                  const SizedBox(width: 8),
                                  OutlinedButton(
                                    onPressed: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => JobDetailsPage(
                                            job: job,
                                            draftForm: form,
                                          ),
                                        ),
                                      );
                                    },
                                    style: OutlinedButton.styleFrom(
                                      side: const BorderSide(
                                          color: Color(0xFFC10D00)),
                                    ),
                                    child: Text('Continue',
                                        style: GoogleFonts.poppins(
                                            fontWeight: FontWeight.w600,
                                            color: Colors.white)),
                                  ),
                                  const SizedBox(width: 8),
                                  TextButton(
                                    onPressed: () => _deleteDraft(d['id']),
                                    style: TextButton.styleFrom(
                                        foregroundColor: Colors.white),
                                    child: Text('Delete',
                                        style: GoogleFonts.poppins(
                                            fontWeight: FontWeight.w600,
                                            color: Colors.white)),
                                  ),
                                ],
                              )
                            ],
                          ),
                        ),
                      );
                    },
                  ),
      ),
    );
  }
}
