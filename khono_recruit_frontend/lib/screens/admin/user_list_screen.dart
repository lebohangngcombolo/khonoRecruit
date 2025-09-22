import 'package:flutter/material.dart';
import '../../services/admin_service.dart';
import '../../models/user_model.dart';
import '../../screens/admin/job_list_screen.dart';
import '../../screens/admin/applications_screen.dart';
import '../../screens/admin/candidates_screen.dart';
import '../../screens/admin/assessment_screen.dart';

class UserListScreen extends StatefulWidget {
  final int jobId;
  const UserListScreen({super.key, required this.jobId});

  @override
  _UserListScreenState createState() => _UserListScreenState();
}

class _UserListScreenState extends State<UserListScreen> {
  bool _loading = true;
  bool _submitting = false;
  List<User> _users = [];
  List<User> _filteredUsers = [];
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchUsers();
    _searchController.addListener(_filterUsers);
  }

  void _filterUsers() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredUsers = _users
          .where((user) =>
              user.name.toLowerCase().contains(query) ||
              user.email.toLowerCase().contains(query))
          .toList();
    });
  }

  Future<void> _fetchUsers() async {
    setState(() => _loading = true);
    try {
      final users = await AdminService.getUsers();
      setState(() {
        _users = users;
        _filteredUsers = users;
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Error fetching users: $e')));
    }
  }

  Future<void> _updateRole(int userId, String newRole) async {
    setState(() => _submitting = true);
    try {
      await AdminService.updateUserRole(userId, newRole);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Role updated successfully'),
          backgroundColor: Colors.green,
        ),
      );
      _fetchUsers();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error updating role: $e'),
          backgroundColor: Colors.redAccent,
        ),
      );
    } finally {
      setState(() => _submitting = false);
    }
  }

  void _navigateTo(Widget page) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => page));
  }

  Widget _sidebarItem(IconData icon, String label, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        child: Row(
          children: [
            Icon(icon, color: Colors.white, size: 26),
            const SizedBox(width: 16),
            Text(label,
                style: const TextStyle(color: Colors.white, fontSize: 16)),
          ],
        ),
      ),
    );
  }

  Widget _buildSidebar() {
    return Container(
      width: 220,
      decoration: BoxDecoration(
        color: const Color(0xFFD50000),
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
          const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.work, color: Colors.white, size: 28),
              SizedBox(width: 10),
              Text(
                "iDraft",
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 30),
          _sidebarItem(Icons.people, "Users", () {}),
          _sidebarItem(Icons.person_search, "Candidates",
              () => _navigateTo(CandidatesScreen(jobId: widget.jobId))),
          _sidebarItem(
              Icons.work, "Jobs", () => _navigateTo(const JobListScreen())),
          _sidebarItem(Icons.assignment, "Applications",
              () => _navigateTo(const ApplicationsScreen())),
          _sidebarItem(Icons.fact_check, "Assessments",
              () => _navigateTo(AssessmentScreen(jobId: widget.jobId))),
          const Spacer(),
          _sidebarItem(Icons.logout, "Logout", () {}),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _metricCard(String label, int count, Color color) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 8),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.15),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          children: [
            Text(
              count.toString(),
              style: TextStyle(
                  fontSize: 24, fontWeight: FontWeight.bold, color: color),
            ),
            const SizedBox(height: 6),
            Text(label, style: TextStyle(color: color.withOpacity(0.9))),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricsBar() {
    final totalUsers = _users.length;
    final totalAdmins =
        _users.where((u) => u.role.toLowerCase() == 'admin').length;
    final totalCandidates =
        _users.where((u) => u.role.toLowerCase() == 'candidate').length;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      child: Row(
        children: [
          _metricCard("Total Users", totalUsers, Colors.redAccent),
          _metricCard("Admins", totalAdmins, Colors.orangeAccent),
          _metricCard("Candidates", totalCandidates, Colors.greenAccent),
        ],
      ),
    );
  }

  Widget _buildUserCard(User user) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            color: Colors.grey,
            blurRadius: 12,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                user.name,
                style: const TextStyle(
                    color: Color(0xFFD50000),
                    fontSize: 18,
                    fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 6),
              Text(user.email, style: const TextStyle(color: Colors.black87)),
            ],
          ),
          DropdownButton<String>(
            value: user.role,
            dropdownColor: Colors.white,
            style: const TextStyle(color: Colors.black87),
            items: const [
              DropdownMenuItem(value: 'admin', child: Text('Admin')),
              DropdownMenuItem(
                  value: 'hiring_manager', child: Text('Hiring Manager')),
              DropdownMenuItem(value: 'candidate', child: Text('Candidate')),
            ],
            onChanged: (val) {
              if (!_submitting && val != null && val != user.role) {
                _updateRole(user.id, val);
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildUserList() {
    if (_loading) {
      return const Center(
          child: CircularProgressIndicator(color: Color(0xFFD50000)));
    } else if (_filteredUsers.isEmpty) {
      return const Center(
        child: Text(
          'No users found',
          style: TextStyle(color: Colors.black54, fontSize: 18),
        ),
      );
    } else {
      return GridView.builder(
        padding: const EdgeInsets.all(24),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 16,
          crossAxisSpacing: 16,
          childAspectRatio: 3,
        ),
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: _filteredUsers.length,
        itemBuilder: (_, index) => _buildUserCard(_filteredUsers[index]),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          _buildSidebar(),
          Expanded(
            child: Container(
              color: Colors.white,
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildMetricsBar(),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: TextField(
                        controller: _searchController,
                        style: const TextStyle(color: Colors.black87),
                        decoration: InputDecoration(
                          hintText: "Search users...",
                          hintStyle: const TextStyle(color: Colors.black45),
                          prefixIcon:
                              const Icon(Icons.search, color: Colors.black45),
                          filled: true,
                          fillColor: Colors.grey.withOpacity(0.1),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildUserList(),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
