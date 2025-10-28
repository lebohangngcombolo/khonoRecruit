import 'dart:convert';
import 'dart:typed_data';
import 'dart:io' show File;
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/theme_provider.dart';
import '../../widgets/custom_textfield.dart';

// ------------------- API Base URL -------------------
const String candidateBase = "http://127.0.0.1:5000/api/candidate";

class ProfilePage extends StatefulWidget {
  final String token;
  const ProfilePage({super.key, required this.token});

  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage>
    with TickerProviderStateMixin {
  bool loading = true;
  bool showProfileSummary = true;

  String selectedSidebar = "Profile";

  // Profile Controllers
  final TextEditingController fullNameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController genderController = TextEditingController();
  final TextEditingController dobController = TextEditingController();
  final TextEditingController nationalityController = TextEditingController();
  final TextEditingController idNumberController = TextEditingController();
  final TextEditingController bioController = TextEditingController();
  final TextEditingController locationController = TextEditingController();
  final TextEditingController titleController = TextEditingController();

  // Candidate fields
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

  // Profile Image
  XFile? _profileImage;
  Uint8List? _profileImageBytes;
  String _profileImageUrl = "";
  final ImagePicker _picker = ImagePicker();

  // Settings
  bool darkMode = false;
  bool notificationsEnabled = true;
  bool jobAlertsEnabled = true;
  bool profileVisible = true;
  bool enrollmentCompleted = false;

  List<dynamic> documents = [];

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
          'Content-Type': 'application/json'
        },
      );

      if (profileRes.statusCode == 200) {
        final data = json.decode(profileRes.body)['data'];
        final user = data['user'] ?? {};
        final candidate = data['candidate'] ?? {};

        fullNameController.text = candidate['full_name'] ?? "";
        emailController.text = user['profile']['email'] ?? "";
        phoneController.text = candidate['phone'] ?? "";
        genderController.text = candidate['gender'] ?? "";
        dobController.text = candidate['dob'] ?? "";
        nationalityController.text = candidate['nationality'] ?? "";
        idNumberController.text = candidate['id_number'] ?? "";
        bioController.text = candidate['bio'] ?? "";
        locationController.text = candidate['location'] ?? "";
        titleController.text = candidate['title'] ?? "";

        degreeController.text = candidate['degree'] ?? "";
        institutionController.text = candidate['institution'] ?? "";
        graduationYearController.text = candidate['graduation_year'] ?? "";
        skillsController.text = (candidate['skills'] ?? []).join(", ");
        workExpController.text =
            (candidate['work_experience'] ?? []).join("\n");
        jobTitleController.text = candidate['job_title'] ?? "";
        companyController.text = candidate['company'] ?? "";
        yearsOfExpController.text = candidate['years_of_experience'] ?? "";
        linkedinController.text = candidate['linkedin'] ?? "";
        githubController.text = candidate['github'] ?? "";
        portfolioController.text = candidate['portfolio'] ?? "";
        cvTextController.text = candidate['cv_text'] ?? "";
        cvUrlController.text = candidate['cv_url'] ?? "";
        documents = candidate['documents'] ?? [];
        _profileImageUrl = candidate['profile_picture'] ?? "";
      }

      final settingsRes = await http.get(
        Uri.parse("$apiBase/settings"),
        headers: {
          'Authorization': 'Bearer ${widget.token}',
          'Content-Type': 'application/json'
        },
      );

      if (settingsRes.statusCode == 200) {
        final data = json.decode(settingsRes.body);
        darkMode = data['dark_mode'] ?? false;
        notificationsEnabled = data['notifications_enabled'] ?? true;
        enrollmentCompleted = data['enrollment_completed'] ?? false;
        jobAlertsEnabled = data['job_alerts_enabled'] ?? true;
        profileVisible = data['profile_visible'] ?? true;
      }
    } catch (e) {
      debugPrint("Error fetching profile/settings: $e");
    } finally {
      setState(() => loading = false);
    }
  }

  Future<void> _pickProfileImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      if (kIsWeb) _profileImageBytes = await pickedFile.readAsBytes();
      setState(() => _profileImage = pickedFile);
      await uploadProfileImage();
    }
  }

  Future<void> uploadProfileImage() async {
    if (_profileImage == null) return;
    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse("$apiBase/upload_profile_picture"),
      );
      request.headers['Authorization'] = 'Bearer ${widget.token}';
      request.files.add(
        http.MultipartFile.fromBytes(
          'image',
          kIsWeb
              ? _profileImageBytes!
              : File(_profileImage!.path).readAsBytesSync(),
          filename: _profileImage!.name,
        ),
      );

      var response = await request.send();
      final respStr = await response.stream.bytesToString();
      final respJson = json.decode(respStr);

      if (response.statusCode == 200 && respJson['success'] == true) {
        setState(() {
          _profileImageUrl = respJson['data']['profile_picture'];
          _profileImage = null;
          _profileImageBytes = null;
        });
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Profile picture updated")));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Upload failed: ${response.statusCode}")));
      }
    } catch (e) {
      debugPrint("Profile image upload error: $e");
    }
  }

  Future<void> uploadDocument(String type) async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile == null) return;

    var fileBytes = kIsWeb
        ? await pickedFile.readAsBytes()
        : File(pickedFile.path).readAsBytesSync();
    var request = http.MultipartRequest(
      'POST',
      Uri.parse("$apiBase/upload_document"),
    );
    request.headers['Authorization'] = 'Bearer ${widget.token}';
    request.fields['type'] = type;
    request.files.add(
      http.MultipartFile.fromBytes(
        'file',
        fileBytes,
        filename: pickedFile.name,
      ),
    );

    var response = await request.send();
    final respStr = await response.stream.bytesToString();
    final respJson = json.decode(respStr);

    if (response.statusCode == 200 && respJson['success'] == true) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("$type uploaded successfully")));
      fetchProfileAndSettings();
    } else {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Failed to upload $type")));
    }
  }

  Future<void> updateProfile() async {
    try {
      final payload = {
        "full_name": fullNameController.text,
        "phone": phoneController.text,
        "gender": genderController.text,
        "dob": dobController.text.isNotEmpty
            ? DateFormat('yyyy-MM-dd')
                .format(DateTime.parse(dobController.text))
            : null,
        "nationality": nationalityController.text,
        "id_number": idNumberController.text,
        "bio": bioController.text,
        "location": locationController.text,
        "title": titleController.text,
        "degree": degreeController.text,
        "institution": institutionController.text,
        "graduation_year": graduationYearController.text,
        "skills":
            skillsController.text.split(",").map((e) => e.trim()).toList(),
        "work_experience":
            workExpController.text.split("\n").map((e) => e.trim()).toList(),
        "job_title": jobTitleController.text,
        "company": companyController.text,
        "years_of_experience": yearsOfExpController.text,
        "linkedin": linkedinController.text,
        "github": githubController.text,
        "portfolio": portfolioController.text,
        "cv_text": cvTextController.text,
        "cv_url": cvUrlController.text,
        "user_profile": {"email": emailController.text},
      };

      final res = await http.put(
        Uri.parse("$apiBase/profile"),
        headers: {
          'Authorization': 'Bearer ${widget.token}',
          'Content-Type': 'application/json'
        },
        body: json.encode(payload),
      );

      if (res.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Profile updated successfully")));
        setState(() => showProfileSummary = true);
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
        "job_alerts_enabled": jobAlertsEnabled,
        "profile_visible": profileVisible,
        "enrollment_completed": enrollmentCompleted,
      };

      final res = await http.put(
        Uri.parse("$apiBase/settings"),
        headers: {
          'Authorization': 'Bearer ${widget.token}',
          'Content-Type': 'application/json'
        },
        body: json.encode(payload),
      );

      if (res.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Settings updated successfully")));
      }
    } catch (e) {
      debugPrint("Error updating settings: $e");
    }
  }

  ImageProvider<Object> _getProfileImageProvider() {
    if (_profileImage != null) {
      if (kIsWeb) return MemoryImage(_profileImageBytes!);
      return FileImage(File(_profileImage!.path));
    }
    if (_profileImageUrl.isNotEmpty) return NetworkImage(_profileImageUrl);
    return const AssetImage("assets/images/profile_placeholder.png");
  }

  Widget _modernCard(String title, Widget child) {
    return Card(
      color: Colors.white,
      elevation: 4,
      margin: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title,
              style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.redAccent)),
          const SizedBox(height: 12),
          child,
        ]),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDarkMode;

    if (loading)
      return const Scaffold(body: Center(child: CircularProgressIndicator()));

    return Theme(
      data: themeProvider.themeData,
      child: Scaffold(
        backgroundColor: isDark ? Colors.grey[900] : Colors.grey[100],
        body: Row(
          children: [
            // Sidebar
            Container(
              width: 200,
              color: Colors.redAccent,
              child: Column(
                children: [
                  const SizedBox(height: 50),
                  _sidebarButton("Profile"),
                  _sidebarButton("Settings"),
                  _sidebarButton("2FA"),
                  _sidebarButton("Reset Password"),
                ],
              ),
            ),
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: _buildSelectedTab(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sidebarButton(String title) {
    return GestureDetector(
      onTap: () {
        setState(() {
          selectedSidebar = title;
          if (title == "Profile") showProfileSummary = true;
        });
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 20),
        color: selectedSidebar == title ? Colors.red[700] : Colors.redAccent,
        child: Center(
            child: Text(title,
                style: const TextStyle(
                    color: Colors.white, fontWeight: FontWeight.bold))),
      ),
    );
  }

  Widget _buildSelectedTab() {
    switch (selectedSidebar) {
      case "Profile":
        return showProfileSummary
            ? _buildProfileSummary()
            : _buildProfileForm();
      case "Settings":
        return _buildSettingsTab();
      case "2FA":
        return _build2FATab();
      case "Reset Password":
        return _buildResetPasswordTab();
      default:
        return _buildProfileSummary();
    }
  }

// ----- Profile Summary -----
  Widget _buildProfileSummary() {
    Future<void> _launchUrl(String url) async {
      final uri = Uri.tryParse(url) ?? Uri();
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Could not launch URL")),
        );
      }
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Back button
          IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.redAccent),
            onPressed: () {
              Navigator.pop(context); // navigate to dashboard
            },
          ),
          _modernCard(
            "Profile",
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: CircleAvatar(
                    radius: 50,
                    backgroundImage: _getProfileImageProvider(),
                  ),
                ),
                const SizedBox(height: 12),
                Center(
                  child: Text(fullNameController.text,
                      style: const TextStyle(
                          fontSize: 20, fontWeight: FontWeight.bold)),
                ),
                Center(
                  child: Text(emailController.text,
                      style: const TextStyle(color: Colors.grey)),
                ),
                const SizedBox(height: 12),
                Center(
                  child: ElevatedButton(
                    onPressed: () => setState(() => showProfileSummary = false),
                    style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.redAccent),
                    child: const Text("Edit Profile"),
                  ),
                ),
                const Divider(height: 30),
                Text("Title: ${titleController.text}",
                    style: const TextStyle(fontSize: 16)),
                const SizedBox(height: 6),
                Text("Nationality: ${nationalityController.text}",
                    style: const TextStyle(fontSize: 16)),
                const SizedBox(height: 6),
                Text("Bio: ${bioController.text}",
                    style: const TextStyle(fontSize: 16)),
                const SizedBox(height: 6),
                Text("Location: ${locationController.text}",
                    style: const TextStyle(fontSize: 16)),
                const SizedBox(height: 6),
                InkWell(
                  onTap: () => _launchUrl(portfolioController.text),
                  child: Text("Portfolio: ${portfolioController.text}",
                      style: const TextStyle(
                          fontSize: 16,
                          color: Colors.blue,
                          decoration: TextDecoration.underline)),
                ),
                const SizedBox(height: 6),
                InkWell(
                  onTap: () => _launchUrl(githubController.text),
                  child: Text("GitHub: ${githubController.text}",
                      style: const TextStyle(
                          fontSize: 16,
                          color: Colors.blue,
                          decoration: TextDecoration.underline)),
                ),
                const SizedBox(height: 6),
                InkWell(
                  onTap: () => _launchUrl(linkedinController.text),
                  child: Text("LinkedIn: ${linkedinController.text}",
                      style: const TextStyle(
                          fontSize: 16,
                          color: Colors.blue,
                          decoration: TextDecoration.underline)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ----- Profile Form -----
  Widget _buildProfileForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _modernCard(
            "Personal Info",
            Column(
              children: [
                GestureDetector(
                  onTap: _pickProfileImage,
                  child: CircleAvatar(
                    radius: 50,
                    backgroundImage: _getProfileImageProvider(),
                  ),
                ),
                const SizedBox(height: 12),
                CustomTextField(
                    label: "Full Name", controller: fullNameController),
                CustomTextField(label: "Email", controller: emailController),
                CustomTextField(label: "Phone", controller: phoneController),
                CustomTextField(label: "Gender", controller: genderController),
                CustomTextField(
                    label: "Date of Birth", controller: dobController),
                CustomTextField(
                    label: "Nationality", controller: nationalityController),
                CustomTextField(
                    label: "ID Number", controller: idNumberController),
                CustomTextField(label: "Bio", controller: bioController),
                CustomTextField(
                    label: "Location", controller: locationController),
                CustomTextField(label: "Title", controller: titleController),
              ],
            ),
          ),
          _modernCard(
            "Education & Skills",
            Column(
              children: [
                CustomTextField(label: "Degree", controller: degreeController),
                CustomTextField(
                    label: "Institution", controller: institutionController),
                CustomTextField(
                    label: "Graduation Year",
                    controller: graduationYearController),
                CustomTextField(
                    label: "Skills (comma separated)",
                    controller: skillsController),
              ],
            ),
          ),
          _modernCard(
            "Work Experience",
            Column(
              children: [
                CustomTextField(
                    label: "Job Title", controller: jobTitleController),
                CustomTextField(
                    label: "Company", controller: companyController),
                CustomTextField(
                    label: "Years of Experience",
                    controller: yearsOfExpController),
                CustomTextField(
                    label: "Work Experience Details",
                    controller: workExpController),
              ],
            ),
          ),
          _modernCard(
            "Online Profiles & CV",
            Column(
              children: [
                CustomTextField(
                    label: "LinkedIn", controller: linkedinController),
                CustomTextField(label: "GitHub", controller: githubController),
                CustomTextField(
                    label: "Portfolio", controller: portfolioController),
                CustomTextField(label: "CV Text", controller: cvTextController),
                CustomTextField(label: "CV URL", controller: cvUrlController),
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: updateProfile,
                  style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.redAccent),
                  child: const Text("Save Profile"),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ----- Settings Tab -----
  Widget _buildSettingsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: _modernCard(
        "Settings",
        Column(
          children: [
            SwitchListTile(
              title: const Text("Dark Mode"),
              value: darkMode,
              onChanged: (v) => setState(() => darkMode = v),
            ),
            SwitchListTile(
              title: const Text("Notifications"),
              value: notificationsEnabled,
              onChanged: (v) => setState(() => notificationsEnabled = v),
            ),
            SwitchListTile(
              title: const Text("Job Alerts"),
              value: jobAlertsEnabled,
              onChanged: (v) => setState(() => jobAlertsEnabled = v),
            ),
            SwitchListTile(
              title: const Text("Profile Visible"),
              value: profileVisible,
              onChanged: (v) => setState(() => profileVisible = v),
            ),
            SwitchListTile(
              title: const Text("Enrollment Completed"),
              value: enrollmentCompleted,
              onChanged: (v) => setState(() => enrollmentCompleted = v),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: updateSettings,
              style:
                  ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
              child: const Text("Save Settings"),
            ),
          ],
        ),
      ),
    );
  }

  Widget _build2FATab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: _modernCard(
        "Two-Factor Authentication",
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
                "Enable 2FA to add an extra layer of security to your account."),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                // TODO: Implement 2FA enable logic
              },
              style:
                  ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
              child: const Text("Enable 2FA"),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResetPasswordTab() {
    final TextEditingController currentPassword = TextEditingController();
    final TextEditingController newPassword = TextEditingController();
    final TextEditingController confirmPassword = TextEditingController();
    bool isLoading = false;

    Future<void> changePassword() async {
      if (newPassword.text != confirmPassword.text) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("New passwords do not match")),
        );
        return;
      }

      setState(() => isLoading = true);

      try {
        final response = await http.post(
          Uri.parse("$candidateBase/settings/change_password"),
          headers: {
            "Authorization": "Bearer ${widget.token}",
            "Content-Type": "application/json",
          },
          body: jsonEncode({
            "current_password": currentPassword.text,
            "new_password": newPassword.text,
          }),
        );

        final data = jsonDecode(response.body);

        if (response.statusCode == 200 && data["success"] == true) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Password updated successfully")),
          );
          currentPassword.clear();
          newPassword.clear();
          confirmPassword.clear();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text(data["message"] ?? "Failed to update password")),
          );
        }
      } catch (e) {
        debugPrint("Password change error: $e");
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text("Error changing password. Please try again.")),
        );
      } finally {
        setState(() => isLoading = false);
      }
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: _modernCard(
        "Reset Password",
        Column(
          children: [
            CustomTextField(
              label: "Current Password",
              controller: currentPassword,
              obscureText: true,
            ),
            const SizedBox(height: 10),
            CustomTextField(
              label: "New Password",
              controller: newPassword,
              obscureText: true,
            ),
            const SizedBox(height: 10),
            CustomTextField(
              label: "Confirm New Password",
              controller: confirmPassword,
              obscureText: true,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: isLoading ? null : changePassword,
              style:
                  ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
              child: isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Text("Reset Password"),
            ),
          ],
        ),
      ),
    );
  }
}
