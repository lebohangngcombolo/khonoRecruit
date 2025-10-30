import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../../providers/theme_provider.dart';

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
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);

    String role = "";
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: (themeProvider.isDarkMode
                  ? const Color(0xFF14131E)
                  : Colors.white)
              .withOpacity(0.95),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(
            "Add New Role",
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.w600,
              color: themeProvider.isDarkMode ? Colors.white : Colors.black87,
            ),
          ),
          content: TextField(
            decoration: InputDecoration(
              hintText: "Enter role name",
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Colors.redAccent, width: 2),
              ),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              fillColor: (themeProvider.isDarkMode
                      ? const Color(0xFF14131E)
                      : Colors.white)
                  .withOpacity(0.9),
              filled: true,
              hintStyle: TextStyle(
                color: themeProvider.isDarkMode
                    ? Colors.grey.shade400
                    : Colors.grey.shade600,
              ),
            ),
            onChanged: (val) => role = val,
            style: GoogleFonts.inter(
              color: themeProvider.isDarkMode ? Colors.white : Colors.black87,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(
                "Cancel",
                style: GoogleFonts.inter(
                  color: themeProvider.isDarkMode
                      ? Colors.grey.shade400
                      : Colors.grey.shade600,
                ),
              ),
            ),
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.blue.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ElevatedButton(
                onPressed: () {
                  if (role.isNotEmpty) {
                    setState(() => roles.add(role));
                    Navigator.pop(ctx);
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  "Add Role",
                  style: GoogleFonts.inter(fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _addMemberDialog() {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);

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
              backgroundColor: (themeProvider.isDarkMode
                      ? const Color(0xFF14131E)
                      : Colors.white)
                  .withOpacity(0.95),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20)),
              title: Text(
                "Add Team Member",
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w600,
                  color:
                      themeProvider.isDarkMode ? Colors.white : Colors.black87,
                ),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (errorMessage != null)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: Colors.red.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.red.shade200),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.error_outline,
                                color: Colors.red, size: 16),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                errorMessage!,
                                style: GoogleFonts.inter(
                                  color: Colors.red,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    TextField(
                      decoration: InputDecoration(
                        labelText: "Full Name",
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                              color: Colors.redAccent, width: 2),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                        fillColor: (themeProvider.isDarkMode
                                ? const Color(0xFF14131E)
                                : Colors.white)
                            .withOpacity(0.9),
                        filled: true,
                        labelStyle: TextStyle(
                          color: themeProvider.isDarkMode
                              ? Colors.grey.shade400
                              : Colors.grey.shade600,
                        ),
                      ),
                      onChanged: (val) => name = val,
                      style: GoogleFonts.inter(
                        color: themeProvider.isDarkMode
                            ? Colors.white
                            : Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      decoration: InputDecoration(
                        labelText: "Email Address",
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                              color: Colors.redAccent, width: 2),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                        fillColor: (themeProvider.isDarkMode
                                ? const Color(0xFF14131E)
                                : Colors.white)
                            .withOpacity(0.9),
                        filled: true,
                        labelStyle: TextStyle(
                          color: themeProvider.isDarkMode
                              ? Colors.grey.shade400
                              : Colors.grey.shade600,
                        ),
                      ),
                      onChanged: (val) => email = val,
                      style: GoogleFonts.inter(
                        color: themeProvider.isDarkMode
                            ? Colors.white
                            : Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: role.isNotEmpty ? role : null,
                      items: roles
                          .map((r) => DropdownMenuItem(
                                value: r,
                                child: Text(
                                  r,
                                  style: GoogleFonts.inter(
                                    color: themeProvider.isDarkMode
                                        ? Colors.white
                                        : Colors.black87,
                                  ),
                                ),
                              ))
                          .toList(),
                      onChanged: (val) {
                        if (val != null) role = val;
                      },
                      decoration: InputDecoration(
                        labelText: "Select Role",
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                              color: Colors.redAccent, width: 2),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                        fillColor: (themeProvider.isDarkMode
                                ? const Color(0xFF14131E)
                                : Colors.white)
                            .withOpacity(0.9),
                        filled: true,
                        labelStyle: TextStyle(
                          color: themeProvider.isDarkMode
                              ? Colors.grey.shade400
                              : Colors.grey.shade600,
                        ),
                      ),
                      dropdownColor: (themeProvider.isDarkMode
                              ? const Color(0xFF1E1E1E)
                              : Colors.white)
                          .withOpacity(0.95),
                      style: GoogleFonts.inter(
                        color: themeProvider.isDarkMode
                            ? Colors.white
                            : Colors.black87,
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: Text(
                    "Cancel",
                    style: GoogleFonts.inter(
                      color: themeProvider.isDarkMode
                          ? Colors.grey.shade400
                          : Colors.grey.shade600,
                    ),
                  ),
                ),
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.blue.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ElevatedButton(
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
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : Text(
                            "Add Member",
                            style:
                                GoogleFonts.inter(fontWeight: FontWeight.w600),
                          ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _editRoleDialog(int index) {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);

    String role = users[index]["role"]!;
    bool isLoading = false;
    String? errorMessage;

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              backgroundColor: (themeProvider.isDarkMode
                      ? const Color(0xFF14131E)
                      : Colors.white)
                  .withOpacity(0.95),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20)),
              title: Text(
                "Edit User Role",
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w600,
                  color:
                      themeProvider.isDarkMode ? Colors.white : Colors.black87,
                ),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (errorMessage != null)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.red.shade200),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.error_outline,
                              color: Colors.red, size: 16),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              errorMessage!,
                              style: GoogleFonts.inter(
                                color: Colors.red,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  Text(
                    users[index]["name"] ?? "",
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.w500,
                      color: themeProvider.isDarkMode
                          ? Colors.white
                          : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value: role,
                    items: roles
                        .map((r) => DropdownMenuItem(
                              value: r,
                              child: Text(
                                r,
                                style: GoogleFonts.inter(
                                  color: themeProvider.isDarkMode
                                      ? Colors.white
                                      : Colors.black87,
                                ),
                              ),
                            ))
                        .toList(),
                    onChanged: (val) {
                      if (val != null) role = val;
                    },
                    decoration: InputDecoration(
                      labelText: "Select Role",
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide:
                            const BorderSide(color: Colors.redAccent, width: 2),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      fillColor: (themeProvider.isDarkMode
                              ? const Color(0xFF14131E)
                              : Colors.white)
                          .withOpacity(0.9),
                      filled: true,
                      labelStyle: TextStyle(
                        color: themeProvider.isDarkMode
                            ? Colors.grey.shade400
                            : Colors.grey.shade600,
                      ),
                    ),
                    dropdownColor: (themeProvider.isDarkMode
                            ? const Color(0xFF14131E)
                            : Colors.white)
                        .withOpacity(0.95),
                    style: GoogleFonts.inter(
                      color: themeProvider.isDarkMode
                          ? Colors.white
                          : Colors.black87,
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: Text(
                    "Cancel",
                    style: GoogleFonts.inter(
                      color: themeProvider.isDarkMode
                          ? Colors.grey.shade400
                          : Colors.grey.shade600,
                    ),
                  ),
                ),
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.blue.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ElevatedButton(
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
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : Text(
                            "Save Changes",
                            style:
                                GoogleFonts.inter(fontWeight: FontWeight.w600),
                          ),
                  ),
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
    final themeProvider = Provider.of<ThemeProvider>(context);
    final user = users[index];
    final role = user["role"] ?? "";

    Color getRoleColor(String role) {
      switch (role.toLowerCase()) {
        case 'admin':
          return Colors.redAccent;
        case 'hr':
          return Colors.blue;
        case 'manager':
          return Colors.green;
        case 'recruiter':
          return Colors.orange;
        default:
          return Colors.grey;
      }
    }

    return Container(
      padding: const EdgeInsets.all(20),
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color:
            (themeProvider.isDarkMode ? const Color(0xFF14131E) : Colors.white)
                .withOpacity(0.9),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 15,
            offset: const Offset(0, 6),
          ),
        ],
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              ClipOval(
                child: user["profile_image"] != null &&
                        user["profile_image"].toString().isNotEmpty
                    ? Image.network(
                        user["profile_image"],
                        width: 48,
                        height: 48,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            width: 48,
                            height: 48,
                            color: getRoleColor(role).withOpacity(0.1),
                            child: Icon(Icons.person,
                                color: getRoleColor(role), size: 24),
                          );
                        },
                      )
                    : Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: getRoleColor(role).withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.person,
                            color: getRoleColor(role), size: 24),
                      ),
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user["name"] ?? "",
                    style: GoogleFonts.inter(
                      color: themeProvider.isDarkMode
                          ? Colors.white
                          : Colors.black87,
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    user["email"] ?? "",
                    style: GoogleFonts.inter(
                      color: themeProvider.isDarkMode
                          ? Colors.grey.shade400
                          : Colors.grey.shade600,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: getRoleColor(role).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      role,
                      style: GoogleFonts.inter(
                        color: getRoleColor(role),
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          Row(
            children: [
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.blue.withOpacity(0.2),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: IconButton(
                  onPressed: () => _editRoleDialog(index),
                  icon: Icon(Icons.edit, color: Colors.blue, size: 20),
                  style: IconButton.styleFrom(
                    backgroundColor: (themeProvider.isDarkMode
                            ? const Color(0xFF14131E)
                            : Colors.white)
                        .withOpacity(0.9),
                    padding: const EdgeInsets.all(8),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.red.withOpacity(0.2),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: IconButton(
                  onPressed: () {
                    setState(() {
                      users.removeAt(index);
                    });
                  },
                  icon: Icon(Icons.delete, color: Colors.red, size: 20),
                  style: IconButton.styleFrom(
                    backgroundColor: (themeProvider.isDarkMode
                            ? const Color(0xFF2D2D2D)
                            : Colors.white)
                        .withOpacity(0.9),
                    padding: const EdgeInsets.all(8),
                  ),
                ),
              ),
            ],
          ),
        ],
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
          appBar: AppBar(
            title: Text(
              "User Management",
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w600,
                color: themeProvider.isDarkMode ? Colors.white : Colors.black87,
              ),
            ),
            backgroundColor: (themeProvider.isDarkMode
                    ? const Color(0xFF14131E)
                    : Colors.white)
                .withOpacity(0.9),
            elevation: 0,
            iconTheme: IconThemeData(
              color: themeProvider.isDarkMode ? Colors.white : Colors.black87,
            ),
            actions: [
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.blue.withOpacity(0.2),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: IconButton(
                  onPressed: _addRoleDialog,
                  icon: const Icon(Icons.add_moderator, color: Colors.blue),
                  style: IconButton.styleFrom(
                    backgroundColor: (themeProvider.isDarkMode
                            ? const Color(0xFF14131E)
                            : Colors.white)
                        .withOpacity(0.9),
                    padding: const EdgeInsets.all(8),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.blue.withOpacity(0.2),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: IconButton(
                  onPressed: _addMemberDialog,
                  icon: const Icon(Icons.person_add, color: Colors.blue),
                  style: IconButton.styleFrom(
                    backgroundColor: (themeProvider.isDarkMode
                            ? const Color(0xFF14131E)
                            : Colors.white)
                        .withOpacity(0.9),
                    padding: const EdgeInsets.all(8),
                  ),
                ),
              ),
              const SizedBox(width: 16),
            ],
          ),
          body: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Stats
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
                        color: Colors.black.withOpacity(0.05),
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
                          Icons.people_alt,
                          color: Colors.redAccent,
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Team Members",
                            style: GoogleFonts.poppins(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: themeProvider.isDarkMode
                                  ? Colors.white
                                  : Colors.black87,
                            ),
                          ),
                          Text(
                            "${users.length} active users",
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
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.redAccent.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          "${roles.length} roles",
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

                // Users List
                Expanded(
                  child: users.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.people_outline,
                                size: 80,
                                color: themeProvider.isDarkMode
                                    ? Colors.grey.shade600
                                    : Colors.grey.shade300,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                "No Team Members",
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
                                "Add your first team member to get started",
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
                      : ListView.builder(
                          itemCount: users.length,
                          itemBuilder: (ctx, index) => buildUserCard(index),
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
