import 'dart:typed_data';
import 'dart:io' show File;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'dart:convert';

import '../../providers/theme_provider.dart';
import '../../widgets/custom_textfield.dart';

class UserAccountPage extends StatefulWidget {
  final String token;
  const UserAccountPage({super.key, required this.token});

  @override
  _UserAccountPageState createState() => _UserAccountPageState();
}

class _UserAccountPageState extends State<UserAccountPage> {
  // Controllers
  final TextEditingController fullNameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController genderController = TextEditingController();
  final TextEditingController educationController = TextEditingController();
  final TextEditingController dobController = TextEditingController();
  final TextEditingController nationalityController = TextEditingController();
  final TextEditingController idNumberController = TextEditingController();

  final TextEditingController degreeController = TextEditingController();
  final TextEditingController institutionController = TextEditingController();
  final TextEditingController graduationYearController =
      TextEditingController();

  final TextEditingController skillsController = TextEditingController();
  final TextEditingController workExpController = TextEditingController();
  final TextEditingController jobTitleController = TextEditingController();
  final TextEditingController companyController = TextEditingController();
  final TextEditingController yearsOfExpController = TextEditingController();

  final TextEditingController linkedinController = TextEditingController();
  final TextEditingController githubController = TextEditingController();
  final TextEditingController portfolioController = TextEditingController();

  final TextEditingController cvTextController = TextEditingController();
  final TextEditingController cvUrlController = TextEditingController();

  // Image picker
  XFile? _profileImage;
  Uint8List? _profileImageBytes;
  final ImagePicker _picker = ImagePicker();

  bool loadingProfile = true;
  bool darkMode = false;
  bool notificationsEnabled = true;
  bool enrollmentCompleted = false;
  bool jobAlertsEnabled = true;
  bool profileVisible = true;
  List<dynamic> documents = [];

  int _selectedTab = 0;
  final String apiBase = "http://127.0.0.1:5000/api/candidate";

  @override
  void initState() {
    super.initState();
    fetchProfileAndSettings();
  }

  Future<void> fetchProfileAndSettings() async {
    try {
      final profileRes = await http.get(
        Uri.parse("$apiBase/profile"),
        headers: {
          'Authorization': 'Bearer ${widget.token}',
          'Content-Type': 'application/json',
        },
      );

      if (profileRes.statusCode == 200) {
        final data = Map<String, dynamic>.from(json.decode(profileRes.body));
        final user = data['user'] ?? {};
        final candidate = data['candidate'] ?? {};

        fullNameController.text = candidate['full_name'] ?? "";
        emailController.text = user['profile']['email'] ?? "";
        phoneController.text = candidate['phone'] ?? "";
        genderController.text = candidate['gender'] ?? "";
        dobController.text = candidate['dob'] ?? "";
        nationalityController.text = candidate['nationality'] ?? "";
        idNumberController.text = candidate['id_number'] ?? "";

        degreeController.text = candidate['degree'] ?? "";
        institutionController.text = candidate['institution'] ?? "";
        graduationYearController.text = candidate['graduation_year'] ?? "";

        jobTitleController.text = candidate['job_title'] ?? "";
        companyController.text = candidate['company'] ?? "";
        yearsOfExpController.text = candidate['years_of_experience'] ?? "";

        educationController.text = candidate['education'] ?? "";
        skillsController.text = candidate['skills'] ?? "";
        workExpController.text = candidate['work_experience'] ?? "";
        linkedinController.text = candidate['linkedin'] ?? "";
        githubController.text = candidate['github'] ?? "";
        portfolioController.text = candidate['portfolio'] ?? "";
        cvTextController.text = candidate['cv_text'] ?? "";
        cvUrlController.text = candidate['cv_url'] ?? "";
        documents = candidate['documents'] ?? [];
      }

      final settingsRes = await http.get(
        Uri.parse("$apiBase/settings"),
        headers: {
          'Authorization': 'Bearer ${widget.token}',
          'Content-Type': 'application/json',
        },
      );

      if (settingsRes.statusCode == 200) {
        final data = Map<String, dynamic>.from(json.decode(settingsRes.body));
        darkMode = data['dark_mode'] ?? false;
        notificationsEnabled = data['notifications_enabled'] ?? true;
        enrollmentCompleted = data['enrollment_completed'] ?? false;
        jobAlertsEnabled = data['job_alerts_enabled'] ?? true;
        profileVisible = data['profile_visible'] ?? true;
      }
    } catch (e) {
      debugPrint("Error fetching profile/settings: $e");
    } finally {
      setState(() {
        loadingProfile = false;
      });
    }
  }

  Future<void> deleteDocument(int index) async {
    try {
      final res = await http.delete(
        Uri.parse("$apiBase/profile/documents/$index"),
        headers: {
          'Authorization': 'Bearer ${widget.token}',
          'Content-Type': 'application/json',
        },
      );
      if (res.statusCode == 200) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text("Document deleted")));
        fetchProfileAndSettings();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text("Failed to delete document: ${res.statusCode}")),
        );
      }
    } catch (e) {
      debugPrint("Error deleting document: $e");
    }
  }

  Future<void> updateProfile() async {
    try {
      final payload = {
        "full_name": fullNameController.text,
        "phone": phoneController.text,
        "gender": genderController.text,
        "dob": dobController.text,
        "nationality": nationalityController.text,
        "id_number": idNumberController.text,
        "degree": degreeController.text,
        "institution": institutionController.text,
        "graduation_year": graduationYearController.text,
        "job_title": jobTitleController.text,
        "company": companyController.text,
        "years_of_experience": yearsOfExpController.text,
        "linkedin": linkedinController.text,
        "github": githubController.text,
        "portfolio": portfolioController.text,
        "candidate_profile": {
          "education": educationController.text,
          "skills": skillsController.text,
          "work_experience": workExpController.text,
          "cv_text": cvTextController.text,
          "cv_url": cvUrlController.text,
        },
        "user_profile": {"email": emailController.text},
      };

      final res = await http.put(
        Uri.parse("$apiBase/profile"),
        headers: {
          'Authorization': 'Bearer ${widget.token}',
          'Content-Type': 'application/json',
        },
        body: json.encode(payload),
      );

      if (res.statusCode == 200) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text("Profile updated")));
      }
    } catch (e) {
      debugPrint("Error updating profile: $e");
    }
  }

  Future<void> updateSettings() async {
    try {
      final payload = {
        "dark_mode": darkMode,
        "notifications_enabled": notificationsEnabled,
        "enrollment_completed": enrollmentCompleted,
        "job_alerts_enabled": jobAlertsEnabled,
        "profile_visible": profileVisible,
      };

      final res = await http.put(
        Uri.parse("$apiBase/settings"),
        headers: {
          'Authorization': 'Bearer ${widget.token}',
          'Content-Type': 'application/json',
        },
        body: json.encode(payload),
      );

      if (res.statusCode == 200) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text("Settings updated")));
      }
    } catch (e) {
      debugPrint("Error updating settings: $e");
    }
  }

  Future<void> _pickProfileImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      if (kIsWeb) {
        _profileImageBytes = await pickedFile.readAsBytes();
      }
      setState(() {
        _profileImage = pickedFile;
      });
    }
  }

  ImageProvider<Object> _getProfileImageProvider() {
    if (_profileImage != null) {
      if (kIsWeb) {
        return MemoryImage(_profileImageBytes!);
      } else {
        return FileImage(File(_profileImage!.path));
      }
    } else {
      return const AssetImage("assets/images/profile_placeholder.png");
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDarkMode;

    if (loadingProfile) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Theme(
      data: themeProvider.themeData.copyWith(
        textSelectionTheme: const TextSelectionThemeData(
          cursorColor: Colors.grey,
          selectionColor: Colors.grey,
          selectionHandleColor: Colors.grey,
        ),
      ),
      child: Scaffold(
        backgroundColor: isDark ? Colors.grey[900] : Colors.grey[100],
        body: Row(
          children: [
            _buildSidebar(isDark),
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: _selectedTab == 0
                    ? _buildProfileTab()
                    : _buildSettingsTab(themeProvider),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSidebar(bool isDark) {
    return Container(
      width: 200,
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[850] : Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 2),
          )
        ],
      ),
      child: Column(
        children: [
          const SizedBox(height: 50),
          GestureDetector(
            onTap: _pickProfileImage,
            child: CircleAvatar(
              radius: 45,
              backgroundColor: Colors.redAccent.withOpacity(0.15),
              backgroundImage: _getProfileImageProvider(),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            fullNameController.text,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isDark ? Colors.white : Colors.black87,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 30),
          _sidebarItem("Profile", Icons.person, 0),
          _sidebarItem("Settings", Icons.settings, 1),
          const Spacer(),
          const Padding(
            padding: EdgeInsets.only(bottom: 20),
            child: Text("Recruitment Dashboard",
                style: TextStyle(fontSize: 12, color: Colors.grey)),
          ),
        ],
      ),
    );
  }

  Widget _sidebarItem(String label, IconData icon, int index) {
    final isActive = _selectedTab == index;
    return InkWell(
      onTap: () => setState(() => _selectedTab = index),
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color:
              isActive ? Colors.redAccent.withOpacity(0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(icon,
                color: isActive ? Colors.redAccent : Colors.grey, size: 20),
            const SizedBox(width: 10),
            Text(label,
                style: TextStyle(
                    color: isActive ? Colors.redAccent : Colors.grey,
                    fontWeight:
                        isActive ? FontWeight.bold : FontWeight.normal)),
          ],
        ),
      ),
    );
  }

  Widget _modernCard(String title, Widget child) {
    return Card(
      elevation: 5,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title,
                style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            child,
          ],
        ),
      ),
    );
  }

  Widget _buildProfileTab() {
    Widget _withPadding(CustomTextField field, {bool isLast = false}) {
      return Padding(
        padding: EdgeInsets.only(bottom: isLast ? 0 : 12),
        child: field,
      );
    }

    return SingleChildScrollView(
      key: const ValueKey("profile"),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _modernCard(
            "Personal Information",
            Column(
              children: [
                _withPadding(CustomTextField(
                    label: "Full Name", controller: fullNameController)),
                _withPadding(CustomTextField(
                    label: "Email", controller: emailController)),
                _withPadding(CustomTextField(
                    label: "Phone", controller: phoneController)),
                _withPadding(CustomTextField(
                    label: "Gender", controller: genderController)),
                _withPadding(CustomTextField(
                    label: "Date of Birth", controller: dobController)),
                _withPadding(CustomTextField(
                    label: "Nationality", controller: nationalityController)),
                CustomTextField(
                    label: "ID/Passport No", controller: idNumberController),
              ],
            ),
          ),
          _modernCard(
            "Education & Skills",
            Column(
              children: [
                _withPadding(CustomTextField(
                    label: "Degree", controller: degreeController)),
                _withPadding(CustomTextField(
                    label: "Institution", controller: institutionController)),
                _withPadding(CustomTextField(
                    label: "Graduation Year",
                    controller: graduationYearController)),
                CustomTextField(label: "Skills", controller: skillsController),
              ],
            ),
          ),
          _modernCard(
            "Work Experience",
            Column(
              children: [
                _withPadding(CustomTextField(
                    label: "Job Title", controller: jobTitleController)),
                _withPadding(CustomTextField(
                    label: "Company", controller: companyController)),
                _withPadding(CustomTextField(
                    label: "Years of Experience",
                    controller: yearsOfExpController)),
                CustomTextField(
                    label: "Experience Summary", controller: workExpController),
              ],
            ),
          ),
          _modernCard(
            "Online Presence",
            Column(
              children: [
                _withPadding(CustomTextField(
                    label: "LinkedIn", controller: linkedinController)),
                _withPadding(CustomTextField(
                    label: "GitHub", controller: githubController)),
                CustomTextField(
                    label: "Portfolio URL", controller: portfolioController),
              ],
            ),
          ),
          _modernCard(
            "Documents",
            Column(
              children: [
                ...documents.asMap().entries.map((entry) {
                  int idx = entry.key;
                  var doc = entry.value;
                  return ListTile(
                    title: Text(doc['name'] ?? ""),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete, color: Colors.redAccent),
                      onPressed: () => deleteDocument(idx),
                    ),
                  );
                }).toList(),
                const SizedBox(height: 8),
                ElevatedButton.icon(
                  onPressed: _pickProfileImage,
                  icon: const Icon(Icons.upload),
                  label: const Text("Upload Document"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.redAccent,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Align(
            alignment: Alignment.centerRight,
            child: ElevatedButton(
              onPressed: updateProfile,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                padding:
                    const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
              ),
              child: const Text("Save Profile",
                  style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsTab(ThemeProvider themeProvider) {
    return SingleChildScrollView(
      key: const ValueKey("settings"),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _modernCard(
            "Account Settings",
            Column(
              children: [
                SwitchListTile(
                  value: darkMode,
                  onChanged: (v) {
                    setState(() {
                      darkMode = v;
                      themeProvider.toggleTheme();
                    });
                  },
                  title: const Text("Dark Mode"),
                ),
                SwitchListTile(
                  value: notificationsEnabled,
                  onChanged: (v) => setState(() => notificationsEnabled = v),
                  title: const Text("Enable Notifications"),
                ),
                SwitchListTile(
                  value: jobAlertsEnabled,
                  onChanged: (v) => setState(() => jobAlertsEnabled = v),
                  title: const Text("Job Alerts"),
                ),
                SwitchListTile(
                  value: profileVisible,
                  onChanged: (v) => setState(() => profileVisible = v),
                  title: const Text("Make Profile Public"),
                ),
                SwitchListTile(
                  value: enrollmentCompleted,
                  onChanged: (v) => setState(() => enrollmentCompleted = v),
                  title: const Text("Enrollment Completed"),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Align(
            alignment: Alignment.centerRight,
            child: ElevatedButton(
              onPressed: updateSettings,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                padding:
                    const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
              ),
              child: const Text("Save Settings",
                  style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }
}
