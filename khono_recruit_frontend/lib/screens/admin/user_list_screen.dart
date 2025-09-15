import 'package:flutter/material.dart';
import '../../services/admin_service.dart';
import '../../models/user_model.dart';
import '../../widgets/glass_card.dart';

class UserListScreen extends StatefulWidget {
  const UserListScreen({super.key});

  @override
  _UserListScreenState createState() => _UserListScreenState();
}

class _UserListScreenState extends State<UserListScreen> {
  bool _loading = true;
  List<User> _users = [];

  @override
  void initState() {
    super.initState();
    _fetchUsers();
  }

  Future<void> _fetchUsers() async {
    try {
      final users = await AdminService.getUsers();
      setState(() {
        _users = users;
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching users: $e')),
      );
    }
  }

  Future<void> _updateRole(int userId, String newRole) async {
    try {
      await AdminService.updateUserRole(userId, newRole);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Role updated successfully')),
      );
      _fetchUsers();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating role: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Users')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: _users.length,
              itemBuilder: (_, index) {
                final user = _users[index];
                return GlassCard(
                  child: ListTile(
                    title: Text(user.name,
                        style: const TextStyle(color: Colors.white)),
                    subtitle: Text(user.email,
                        style: const TextStyle(color: Colors.white70)),
                    trailing: DropdownButton<String>(
                      value: user.role,
                      items: const [
                        DropdownMenuItem(value: 'admin', child: Text('Admin')),
                        DropdownMenuItem(
                            value: 'hiring_manager',
                            child: Text('Hiring Manager')),
                        DropdownMenuItem(
                            value: 'candidate', child: Text('Candidate')),
                      ],
                      onChanged: (val) {
                        if (val != null && val != user.role) {
                          _updateRole(user.id, val);
                        }
                      },
                    ),
                  ),
                );
              },
            ),
    );
  }
}
