import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/user_model.dart';

class CandidateProfileScreen extends StatefulWidget {
  final User candidate;
  const CandidateProfileScreen({super.key, required this.candidate});

  @override
  _CandidateProfileScreenState createState() => _CandidateProfileScreenState();
}

class _CandidateProfileScreenState extends State<CandidateProfileScreen> {
  bool _isSidebarOpen = true;
  bool _skillsExpanded = true;
  bool _experienceExpanded = true;
  bool _educationExpanded = true;

  void _toggleSidebar() => setState(() => _isSidebarOpen = !_isSidebarOpen);

  @override
  Widget build(BuildContext context) {
    final candidate = widget.candidate;
    final profile = candidate.profile ?? {};

    return Scaffold(
      backgroundColor: Colors.white,
      body: Row(
        children: [
          // ----------------- Sidebar ----------------- //
          AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            width: _isSidebarOpen ? 220 : 60,
            decoration: BoxDecoration(
              color: Colors.red.shade700,
              boxShadow: const [
                BoxShadow(
                  color: Colors.black26,
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
                  onPressed: _toggleSidebar,
                ),
                const SizedBox(height: 20),
                _sidebarItem(Icons.people, "Users", () {}),
                _sidebarItem(Icons.person_search, "Candidates", () {}),
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
              padding: const EdgeInsets.all(16),
              color: Colors.grey[100],
              child: Column(
                children: [
                  // -------- Top Navbar -------- //
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: const BorderRadius.vertical(
                        bottom: Radius.circular(20),
                      ),
                      boxShadow: [
                        BoxShadow(
                            color: Colors.black12,
                            blurRadius: 6,
                            offset: Offset(0, 2))
                      ],
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(candidate.name,
                              style: const TextStyle(
                                  color: Colors.redAccent,
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold)),
                        ),
                        const SizedBox(width: 20),
                        IconButton(
                          icon: const Icon(Icons.notifications,
                              color: Colors.redAccent),
                          onPressed: () {},
                        ),
                        const SizedBox(width: 16),
                        const CircleAvatar(
                          backgroundColor: Colors.redAccent,
                          child: Icon(Icons.person, color: Colors.white),
                        ),
                      ],
                    ),
                  ),

                  // -------- Metrics Bar -------- //
                  Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 0, vertical: 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _metricCard("Skills", profile['skills']?.length ?? 0),
                        _metricCard("Experience", profile['experience'] ?? 0),
                        _metricCard(
                          "Education",
                          profile['education'] is List
                              ? (profile['education'] as List).length
                              : profile['education'] != null
                                  ? 1
                                  : 0,
                        ),
                      ],
                    ),
                  ),

                  // -------- Profile Info -------- //
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(16),
                            margin: const EdgeInsets.symmetric(vertical: 8),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: const [
                                BoxShadow(
                                    color: Colors.black12,
                                    blurRadius: 8,
                                    offset: Offset(0, 4)),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                _buildInfoTile("Name", candidate.name),
                                _buildInfoTile("Email", candidate.email),
                                _buildInfoTile("Phone", candidate.phone),
                                const SizedBox(height: 12),
                                if (profile['skills'] != null)
                                  _collapsibleSection(
                                    title: "Skills",
                                    isExpanded: _skillsExpanded,
                                    onToggle: () => setState(() =>
                                        _skillsExpanded = !_skillsExpanded),
                                    content:
                                        (profile['skills'] as List<dynamic>)
                                            .join(', '),
                                  ),
                                if (profile['experience'] != null)
                                  _collapsibleSection(
                                    title: "Experience",
                                    isExpanded: _experienceExpanded,
                                    onToggle: () => setState(() =>
                                        _experienceExpanded =
                                            !_experienceExpanded),
                                    content: "${profile['experience']} years",
                                  ),
                                if (profile['education'] != null)
                                  _collapsibleSection(
                                    title: "Education",
                                    isExpanded: _educationExpanded,
                                    onToggle: () => setState(() =>
                                        _educationExpanded =
                                            !_educationExpanded),
                                    content: profile['education'] is List
                                        ? (profile['education']
                                                as List<dynamic>)
                                            .join(', ')
                                        : profile['education'].toString(),
                                  ),
                                const SizedBox(height: 20),
                                if (candidate.cvUrl != null &&
                                    candidate.cvUrl!.isNotEmpty)
                                  Center(
                                    child: ElevatedButton.icon(
                                      style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.redAccent),
                                      onPressed: () =>
                                          _openCV(candidate.cvUrl!),
                                      icon: const Icon(Icons.picture_as_pdf),
                                      label: const Text("View CV"),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ],
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

  Widget _collapsibleSection({
    required String title,
    required bool isExpanded,
    required VoidCallback onToggle,
    required String content,
  }) {
    return Column(
      children: [
        InkWell(
          onTap: onToggle,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
            decoration: BoxDecoration(
              color: Colors.redAccent.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(title,
                      style: const TextStyle(
                          color: Colors.redAccent,
                          fontWeight: FontWeight.bold)),
                ),
                Icon(isExpanded ? Icons.expand_less : Icons.expand_more,
                    color: Colors.redAccent),
              ],
            ),
          ),
        ),
        if (isExpanded)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: Colors.redAccent.withOpacity(0.05),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(content,
                style: const TextStyle(color: Colors.redAccent, height: 1.4)),
          ),
      ],
    );
  }

  Widget _metricCard(String label, int count) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 6),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.redAccent.withOpacity(0.15),
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [
            BoxShadow(
                color: Colors.black12, blurRadius: 4, offset: Offset(0, 2))
          ],
        ),
        child: Column(
          children: [
            Text(count.toString(),
                style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.redAccent)),
            const SizedBox(height: 4),
            Text(label,
                style: TextStyle(color: Colors.redAccent.withOpacity(0.8))),
          ],
        ),
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

  Widget _buildInfoTile(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("$label: ",
              style: const TextStyle(
                  fontWeight: FontWeight.bold, color: Colors.redAccent)),
          Expanded(
              child:
                  Text(value, style: const TextStyle(color: Colors.black87))),
        ],
      ),
    );
  }

  void _openCV(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      debugPrint("Could not launch CV URL: $url");
    }
  }
}
