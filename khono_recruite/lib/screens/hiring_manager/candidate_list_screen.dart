import 'dart:convert';
import 'dart:ui';
import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../../utils/api_endpoints.dart';

class CandidateListScreen extends StatefulWidget {
  const CandidateListScreen({super.key});

  @override
  State<CandidateListScreen> createState() => _CandidateListScreenState();
}

class _CandidateListScreenState extends State<CandidateListScreen> {
  List<dynamic> candidates = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    fetchCandidates();
  }

  Future<void> fetchCandidates() async {
    try {
      final response = await AuthService.authorizedGet(
        "${ApiEndpoints.adminBase}/candidates/all",
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          candidates = data['candidates'];
          loading = false;
        });
      } else {
        setState(() => loading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to load candidates')),
        );
      }
    } catch (e) {
      setState(() => loading = false);
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final cardBgColor =
        isDark ? Colors.white.withOpacity(0.08) : Colors.white.withOpacity(0.4);

    return Scaffold(
      appBar: AppBar(
        title: const Text("All Candidates"),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : candidates.isEmpty
              ? const Center(child: Text("No candidates found"))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Wrap(
                    spacing: 16,
                    runSpacing: 16,
                    children: candidates.map((c) {
                      return ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                          child: Container(
                            width: 350,
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: cardBgColor,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                  color: Colors.white.withOpacity(0.15)),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.15),
                                  blurRadius: 10,
                                  offset: const Offset(2, 4),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                CircleAvatar(
                                  radius: 40,
                                  backgroundImage: c['profile_picture'] != null
                                      ? NetworkImage(c['profile_picture'])
                                      : null,
                                  child: c['profile_picture'] == null
                                      ? const Icon(Icons.person, size: 40)
                                      : null,
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  c['full_name'] ?? 'Unknown',
                                  style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 4),
                                Text("Email: ${c['email'] ?? 'N/A'}"),
                                Text("Phone: ${c['phone'] ?? 'N/A'}"),
                                Text("Address: ${c['address'] ?? 'N/A'}"),
                                Text("Location: ${c['location'] ?? 'N/A'}"),
                                Text("Gender: ${c['gender'] ?? 'N/A'}"),
                                Text("ID: ${c['id_number'] ?? 'N/A'}"),
                              ],
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
    );
  }
}
