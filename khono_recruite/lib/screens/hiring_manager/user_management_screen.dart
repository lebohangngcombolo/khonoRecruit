import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../services/auth_service.dart';

class UserManagementScreen extends StatefulWidget {
  const UserManagementScreen({Key? key}) : super(key: key);

  @override
  State<UserManagementScreen> createState() => _UserManagementScreenState();
}

class _UserManagementScreenState extends State<UserManagementScreen> {
  List<Map<String, dynamic>> users = [];
  List<String> roles = ["Admin", "HR", "Recruiter", "Viewer"];

  @override
  void initState() {
    super.initState();
    _fetchRolesFromBackend();
    _fetchUsersFromBackend();
  }

  Future<void> _fetchRolesFromBackend() async {
    await Future.delayed(const Duration(seconds: 1));
    setState(() {
      roles = ["Admin", "HR", "Recruiter", "Viewer", "Manager"];
    });
  }

  Future<void> _fetchUsersFromBackend() async {
    try {
      final token = await AuthService.getAccessToken();
      if (token == null) return;

      final response = await http.get(
        Uri.parse("http://127.0.0.1:5000/api/admin/users"),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          users = List<Map<String, dynamic>>.from(data);
        });
      }
    } catch (e) {
      debugPrint("Error fetching users: $e");
    }
  }

  void _addRoleDialog() {
    String role = "";
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text("Add New Role",
              style:
                  TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
          content: TextField(
            decoration: const InputDecoration(
              hintText: "Enter role name",
            ),
            onChanged: (val) => role = val,
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text("Cancel")),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
              onPressed: () {
                if (role.isNotEmpty) {
                  setState(() => roles.add(role));
                  Navigator.pop(ctx);
                }
              },
              child: const Text("Add"),
            ),
          ],
        );
      },
    );
  }

  void _addMemberDialog() {
    String name = "";
    String email = "";
    String role = roles.isNotEmpty ? roles[0] : "";
    bool isLoading = false;
    String? errorMessage;

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              title: const Text("Add Member",
                  style: TextStyle(
                      color: Colors.black, fontWeight: FontWeight.bold)),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (errorMessage != null)
                    Text(errorMessage!,
                        style: const TextStyle(color: Colors.red)),
                  TextField(
                    decoration:
                        const InputDecoration(hintText: "Enter full name"),
                    onChanged: (val) => name = val,
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    decoration: const InputDecoration(hintText: "Enter email"),
                    onChanged: (val) => email = val,
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: role.isNotEmpty ? role : null,
                    items: roles
                        .map((r) => DropdownMenuItem(value: r, child: Text(r)))
                        .toList(),
                    onChanged: (val) {
                      if (val != null) role = val;
                    },
                    decoration: const InputDecoration(labelText: "Select Role"),
                  ),
                ],
              ),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text("Cancel")),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
                  onPressed: isLoading
                      ? null
                      : () async {
                          if (name.isEmpty || email.isEmpty || role.isEmpty)
                            return;
                          setState(() {
                            isLoading = true;
                            errorMessage = null;
                          });

                          try {
                            final token = await AuthService.getAccessToken();
                            if (token == null)
                              throw Exception("Token not found");

                            final response = await http.post(
                              Uri.parse(
                                  "http://127.0.0.1:5000/api/auth/admin-enroll"),
                              headers: {
                                "Content-Type": "application/json",
                                "Authorization": "Bearer $token",
                              },
                              body: jsonEncode({
                                "email": email.trim(),
                                "first_name": name.split(" ").first,
                                "last_name": name.split(" ").length > 1
                                    ? name.split(" ").sublist(1).join(" ")
                                    : "",
                                "role": role.toLowerCase()
                              }),
                            );

                            if (response.statusCode == 200 ||
                                response.statusCode == 201) {
                              final data = jsonDecode(response.body);
                              setState(() {
                                users.add({
                                  "user_id": data["user_id"],
                                  "name": name,
                                  "email": email,
                                  "role": role,
                                });
                              });
                              Navigator.pop(ctx);
                            } else {
                              final data = jsonDecode(response.body);
                              setState(() {
                                errorMessage =
                                    data["error"] ?? "Failed to add member";
                              });
                            }
                          } catch (e) {
                            setState(() {
                              errorMessage = "Error: $e";
                            });
                          } finally {
                            setState(() {
                              isLoading = false;
                            });
                          }
                        },
                  child: isLoading
                      ? const CircularProgressIndicator()
                      : const Text("Add"),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _editRoleDialog(int index) {
    String role = users[index]["role"]!;
    bool isLoading = false;
    String? errorMessage;

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              title: const Text("Edit Role",
                  style: TextStyle(
                      color: Colors.black, fontWeight: FontWeight.bold)),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (errorMessage != null)
                    Text(errorMessage!,
                        style: const TextStyle(color: Colors.red)),
                  DropdownButtonFormField<String>(
                    value: role,
                    items: roles
                        .map((r) => DropdownMenuItem(value: r, child: Text(r)))
                        .toList(),
                    onChanged: (val) {
                      if (val != null) role = val;
                    },
                    decoration: const InputDecoration(labelText: "Select Role"),
                  ),
                ],
              ),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text("Cancel")),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
                  onPressed: isLoading
                      ? null
                      : () async {
                          setState(() {
                            isLoading = true;
                            errorMessage = null;
                          });

                          try {
                            final token = await AuthService.getAccessToken();
                            if (token == null)
                              throw Exception("Token not found");

                            final userId = users[index]["user_id"];
                            if (userId == null)
                              throw Exception("User ID not found");

                            final response = await http.put(
                              Uri.parse(
                                  "http://127.0.0.1:5000/api/admin/users/$userId"),
                              headers: {
                                "Content-Type": "application/json",
                                "Authorization": "Bearer $token",
                              },
                              body: jsonEncode({"role": role.toLowerCase()}),
                            );

                            if (response.statusCode == 200) {
                              setState(() {
                                users[index]["role"] = role;
                              });
                              Navigator.pop(ctx);
                            } else {
                              final data = jsonDecode(response.body);
                              setState(() {
                                errorMessage =
                                    data["error"] ?? "Failed to update role";
                              });
                            }
                          } catch (e) {
                            setState(() {
                              errorMessage = "Error: $e";
                            });
                          } finally {
                            setState(() {
                              isLoading = false;
                            });
                          }
                        },
                  child: isLoading
                      ? const CircularProgressIndicator()
                      : const Text("Save"),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // ------------------ UI ------------------
  Widget buildUserCard(int index) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(children: [
            const Icon(Icons.person, color: Colors.blue, size: 28),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(users[index]["name"] ?? "",
                    style: const TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                        fontSize: 16)),
                Text(users[index]["role"] ?? "",
                    style:
                        const TextStyle(color: Colors.black54, fontSize: 14)),
              ],
            ),
          ]),
          Row(
            children: [
              IconButton(
                  onPressed: () => _editRoleDialog(index),
                  icon: const Icon(Icons.edit, color: Colors.black54)),
              IconButton(
                  onPressed: () {
                    setState(() {
                      users.removeAt(index);
                    });
                  },
                  icon: const Icon(Icons.delete, color: Colors.red)),
            ],
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("User Management",
            style: TextStyle(color: Colors.black)),
        backgroundColor: Colors.white,
        elevation: 1,
        iconTheme: const IconThemeData(color: Colors.black),
        actions: [
          IconButton(
              onPressed: _addRoleDialog,
              icon: const Icon(Icons.add_moderator, color: Colors.blue)),
          IconButton(
              onPressed: _addMemberDialog,
              icon: const Icon(Icons.person_add, color: Colors.blue)),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView.separated(
          itemCount: users.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (ctx, index) => buildUserCard(index),
        ),
      ),
    );
  }
}
