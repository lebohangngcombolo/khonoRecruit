import 'dart:convert';
import 'dart:typed_data';
import 'dart:io' show File;
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';
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
  bool twoFactorEnabled = false;

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
        twoFactorEnabled = data['two_factor_enabled'] ?? false;
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
        "two_factor_enabled": twoFactorEnabled,
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

  Widget _modernCard(String title, Widget child, {Color? headerColor}) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        color:
            themeProvider.isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: headerColor ?? Colors.redAccent.withOpacity(0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
            child: Text(
              title,
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: themeProvider.isDarkMode
                    ? Colors.white
                    : Colors.grey.shade800,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: child,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    if (loading) {
      return Scaffold(
        backgroundColor: themeProvider.isDarkMode
            ? const Color(0xFF14131E)
            : Colors.grey.shade50,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.redAccent),
              ),
              const SizedBox(height: 16),
              Text(
                "Loading Profile...",
                style: GoogleFonts.inter(
                  fontSize: 16,
                  color: themeProvider.isDarkMode
                      ? Colors.grey.shade400
                      : Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Theme(
      data: themeProvider.themeData,
      child: Scaffold(
        backgroundColor: themeProvider.isDarkMode
            ? const Color(0xFF14131E)
            : Colors.grey.shade50,
        body: Row(
          children: [
            // Enhanced Sidebar
            Container(
              width: 280,
              decoration: BoxDecoration(
                color: themeProvider.isDarkMode
                    ? const Color(0xFF14131E)
                    : Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 8,
                    offset: const Offset(2, 0),
                  ),
                ],
              ),
              child: Column(
                children: [
                  const SizedBox(height: 40),
                  // Profile Summary in Sidebar
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      children: [
                        Stack(
                          children: [
                            CircleAvatar(
                              radius: 40,
                              backgroundImage: _getProfileImageProvider(),
                            ),
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: Colors.redAccent,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: Colors.white,
                                    width: 2,
                                  ),
                                ),
                                child: const Icon(
                                  Icons.camera_alt,
                                  color: Colors.white,
                                  size: 16,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          fullNameController.text.isNotEmpty
                              ? fullNameController.text
                              : "Your Name",
                          style: GoogleFonts.poppins(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: themeProvider.isDarkMode
                                ? Colors.white
                                : Colors.grey.shade900,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        Text(
                          titleController.text.isNotEmpty
                              ? titleController.text
                              : "Administrator",
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            color: themeProvider.isDarkMode
                                ? Colors.grey.shade400
                                : Colors.grey.shade600,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                  _sidebarButton("Profile", Icons.person_outline),
                  _sidebarButton("Settings", Icons.settings_outlined),
                  _sidebarButton("2FA", Icons.security_outlined),
                  _sidebarButton("Reset Password", Icons.lock_reset_outlined),
                ],
              ),
            ),

            // Main Content
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

  Widget _sidebarButton(String title, IconData icon) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isSelected = selectedSidebar == title;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Material(
        color:
            isSelected ? Colors.redAccent.withOpacity(0.1) : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: () {
            setState(() {
              selectedSidebar = title;
              if (title == "Profile") showProfileSummary = true;
            });
          },
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Icon(
                  icon,
                  color: isSelected
                      ? Colors.redAccent
                      : (themeProvider.isDarkMode
                          ? Colors.grey.shade400
                          : Colors.grey.shade600),
                  size: 20,
                ),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: isSelected
                        ? Colors.redAccent
                        : (themeProvider.isDarkMode
                            ? Colors.grey.shade400
                            : Colors.grey.shade700),
                  ),
                ),
                const Spacer(),
                if (isSelected)
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: Colors.redAccent,
                      shape: BoxShape.circle,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String? _iconForTitle(String title) {
    switch (title) {
      case "Profile":
        return 'assets/icons/Account_User Profile/red_user_profile.png';
      case "Settings":
        return 'assets/icons/RED_Settings icon badge.png';
      case "2FA":
        return 'assets/icons/Login_Lock/Lock_Red Badge_White.png';
      case "Reset Password":
        return 'assets/icons/Red_chnage password_badge.png';
      default:
        return null;
    }
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
    final themeProvider = Provider.of<ThemeProvider>(context);

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
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: themeProvider.isDarkMode
                        ? const Color(0xFF14131E)
                        : Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 8,
                      ),
                    ],
                  ),
                  child: const Icon(Icons.arrow_back, color: Colors.redAccent),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                "Profile Overview",
                style: GoogleFonts.poppins(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: themeProvider.isDarkMode
                      ? Colors.white
                      : Colors.grey.shade900,
                ),
              ),
              const Spacer(),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.redAccent.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(Icons.edit, color: Colors.redAccent, size: 16),
                    const SizedBox(width: 6),
                    GestureDetector(
                      onTap: () => setState(() => showProfileSummary = false),
                      child: Text(
                        "Edit Profile",
                        style: GoogleFonts.inter(
                          color: Colors.redAccent,
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Personal Information Card
          _modernCard(
            "Personal Information",
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _infoRow("Full Name", fullNameController.text),
                _infoRow("Email", emailController.text),
                _infoRow("Phone", phoneController.text),
                _infoRow("Location", locationController.text),
                _infoRow("Nationality", nationalityController.text),
                _infoRow("Title", titleController.text),
                if (bioController.text.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Text(
                    "Bio",
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: themeProvider.isDarkMode
                          ? Colors.white
                          : Colors.grey.shade700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    bioController.text,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: themeProvider.isDarkMode
                          ? Colors.grey.shade400
                          : Colors.grey.shade600,
                    ),
                  ),
                ],
              ],
            ),
            headerColor: Colors.blue.withOpacity(0.1),
          ),

          // Education & Skills Card
          _modernCard(
            "Education & Skills",
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (degreeController.text.isNotEmpty)
                  _infoRow("Degree", degreeController.text),
                if (institutionController.text.isNotEmpty)
                  _infoRow("Institution", institutionController.text),
                if (graduationYearController.text.isNotEmpty)
                  _infoRow("Graduation Year", graduationYearController.text),
                if (skillsController.text.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Text(
                    "Skills",
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: themeProvider.isDarkMode
                          ? Colors.white
                          : Colors.grey.shade700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: skillsController.text.split(',').map((skill) {
                      final trimmedSkill = skill.trim();
                      if (trimmedSkill.isEmpty) return const SizedBox.shrink();
                      return Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.redAccent.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(
                          trimmedSkill,
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: Colors.redAccent,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ],
            ),
            headerColor: Colors.green.withOpacity(0.1),
          ),

          // Online Profiles Card
          if (linkedinController.text.isNotEmpty ||
              githubController.text.isNotEmpty ||
              portfolioController.text.isNotEmpty)
            _modernCard(
              "Online Profiles",
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (linkedinController.text.isNotEmpty)
                    _linkRow("LinkedIn", linkedinController.text,
                        Icons.work_outline),
                  if (githubController.text.isNotEmpty)
                    _linkRow("GitHub", githubController.text, Icons.code),
                  if (portfolioController.text.isNotEmpty)
                    _linkRow(
                        "Portfolio", portfolioController.text, Icons.public),
                ],
              ),
              headerColor: Colors.purple.withOpacity(0.1),
            ),
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    if (value.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: themeProvider.isDarkMode
                    ? Colors.white
                    : Colors.grey.shade700,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.inter(
                fontSize: 14,
                color: themeProvider.isDarkMode
                    ? Colors.grey.shade400
                    : Colors.grey.shade600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _linkRow(String label, String value, IconData icon) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, color: Colors.redAccent, size: 18),
          const SizedBox(width: 12),
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: themeProvider.isDarkMode
                    ? Colors.white
                    : Colors.grey.shade700,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: GestureDetector(
              onTap: () {
                final uri = Uri.tryParse(value) ?? Uri();
                launchUrl(uri, mode: LaunchMode.externalApplication);
              },
              child: Text(
                value,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: Colors.blue.shade600,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ----- Profile Form -----
  Widget _buildProfileForm() {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          // Header
          Row(
            children: [
              IconButton(
                onPressed: () => setState(() => showProfileSummary = true),
                icon: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: themeProvider.isDarkMode
                        ? const Color(0xFF14131E)
                        : Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 8,
                      ),
                    ],
                  ),
                  child: const Icon(Icons.arrow_back, color: Colors.redAccent),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                "Edit Profile",
                style: GoogleFonts.poppins(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: themeProvider.isDarkMode
                      ? Colors.white
                      : Colors.grey.shade900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          _modernCard(
            "Personal Information",
            Column(
              children: [
                GestureDetector(
                  onTap: _pickProfileImage,
                  child: Stack(
                    children: [
                      CircleAvatar(
                        radius: 50,
                        backgroundImage: _getProfileImageProvider(),
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.redAccent,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.white,
                              width: 2,
                            ),
                          ),
                          child: const Icon(
                            Icons.camera_alt,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                CustomTextField(
                    label: "Full Name", controller: fullNameController),
                const SizedBox(height: 12),
                CustomTextField(label: "Email", controller: emailController),
                const SizedBox(height: 12),
                CustomTextField(label: "Phone", controller: phoneController),
                const SizedBox(height: 12),
                CustomTextField(label: "Gender", controller: genderController),
                const SizedBox(height: 12),
                CustomTextField(
                    label: "Date of Birth", controller: dobController),
                const SizedBox(height: 12),
                CustomTextField(
                    label: "Nationality", controller: nationalityController),
                const SizedBox(height: 12),
                CustomTextField(
                    label: "ID Number", controller: idNumberController),
                const SizedBox(height: 12),
                CustomTextField(label: "Bio", controller: bioController),
                const SizedBox(height: 12),
                CustomTextField(
                    label: "Location", controller: locationController),
                const SizedBox(height: 12),
                CustomTextField(label: "Title", controller: titleController),
              ],
            ),
          ),

          _modernCard(
            "Education & Skills",
            Column(
              children: [
                CustomTextField(label: "Degree", controller: degreeController),
                const SizedBox(height: 12),
                CustomTextField(
                    label: "Institution", controller: institutionController),
                const SizedBox(height: 12),
                CustomTextField(
                    label: "Graduation Year",
                    controller: graduationYearController),
                const SizedBox(height: 12),
                CustomTextField(
                  label: "Skills (comma separated)",
                  controller: skillsController,
                  textColor: Colors.white,
                  backgroundColor: Colors.black.withOpacity(0.10),
                ),
              ],
            ),
          ),

          _modernCard(
            "Work Experience",
            Column(
              children: [
                CustomTextField(
                    label: "Job Title", controller: jobTitleController),
                const SizedBox(height: 12),
                CustomTextField(
                    label: "Company", controller: companyController),
                const SizedBox(height: 12),
                CustomTextField(
                    label: "Years of Experience",
                    controller: yearsOfExpController),
                const SizedBox(height: 12),
                CustomTextField(
                    label: "Work Experience Details",
                    controller: workExpController,
                    maxLines: 4),
              ],
            ),
          ),

          _modernCard(
            "Online Profiles & CV",
            Column(
              children: [
                CustomTextField(
                    label: "LinkedIn", controller: linkedinController),
                const SizedBox(height: 12),
                CustomTextField(label: "GitHub", controller: githubController),
                const SizedBox(height: 12),
                CustomTextField(
                    label: "Portfolio", controller: portfolioController),
                const SizedBox(height: 12),
                CustomTextField(
                    label: "CV Text",
                    controller: cvTextController,
                    maxLines: 4),
                const SizedBox(height: 12),
                CustomTextField(label: "CV URL", controller: cvUrlController),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: updateProfile,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.redAccent,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      "Save Profile",
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
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
    final themeProvider = Provider.of<ThemeProvider>(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Settings",
            style: GoogleFonts.poppins(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: themeProvider.isDarkMode
                  ? Colors.white
                  : Colors.grey.shade900,
            ),
          ),
          const SizedBox(height: 24),
          _modernCard(
            "Preferences",
            Column(
              children: [
                _settingsSwitch(
                  "Dark Mode",
                  "Enable dark theme",
                  Icons.dark_mode_outlined,
                  darkMode,
                  (v) => setState(() => darkMode = v),
                ),
                _settingsSwitch(
                  "Notifications",
                  "Receive push notifications",
                  Icons.notifications_outlined,
                  notificationsEnabled,
                  (v) => setState(() => notificationsEnabled = v),
                ),
                _settingsSwitch(
                  "Job Alerts",
                  "Get notified about new jobs",
                  Icons.work_outline,
                  jobAlertsEnabled,
                  (v) => setState(() => jobAlertsEnabled = v),
                ),
                _settingsSwitch(
                  "Profile Visibility",
                  "Make your profile visible to employers",
                  Icons.visibility_outlined,
                  profileVisible,
                  (v) => setState(() => profileVisible = v),
                ),
                _settingsSwitch(
                  "Enrollment Completed",
                  "Mark enrollment as completed",
                  Icons.check_circle_outline,
                  enrollmentCompleted,
                  (v) => setState(() => enrollmentCompleted = v),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: updateSettings,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.redAccent,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      "Save Settings",
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _settingsSwitch(String title, String subtitle, IconData icon,
      bool value, Function(bool) onChanged) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.redAccent.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: Colors.redAccent, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: themeProvider.isDarkMode
                        ? Colors.white
                        : Colors.grey.shade800,
                  ),
                ),
                Text(
                  subtitle,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: themeProvider.isDarkMode
                        ? Colors.grey.shade400
                        : Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: Colors.redAccent,
          ),
        ],
      ),
    );
  }

  Widget _build2FATab() {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Two-Factor Authentication",
            style: GoogleFonts.poppins(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: themeProvider.isDarkMode
                  ? Colors.white
                  : Colors.grey.shade900,
            ),
          ),
          const SizedBox(height: 24),
          _modernCard(
            "Security",
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.orange.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.security, color: Colors.orange),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        "Add an extra layer of security to your account",
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: themeProvider.isDarkMode
                              ? Colors.white
                              : Colors.grey.shade800,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Text(
                  "Two-factor authentication adds an additional layer of security to your account by requiring more than just a password to sign in.",
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: themeProvider.isDarkMode
                        ? Colors.grey.shade400
                        : Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      // TODO: Implement 2FA enable logic
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.redAccent,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      "Enable 2FA",
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResetPasswordTab() {
    final themeProvider = Provider.of<ThemeProvider>(context);
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
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Reset Password",
            style: GoogleFonts.poppins(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: themeProvider.isDarkMode
                  ? Colors.white
                  : Colors.grey.shade900,
            ),
          ),
          const SizedBox(height: 24),
          _modernCard(
            "Change Password",
            Column(
              children: [
                CustomTextField(
                  label: "Current Password",
                  controller: currentPassword,
                  obscureText: true,
                ),
                const SizedBox(height: 16),
                CustomTextField(
                  label: "New Password",
                  controller: newPassword,
                  obscureText: true,
                ),
                const SizedBox(height: 16),
                CustomTextField(
                  label: "Confirm New Password",
                  controller: confirmPassword,
                  obscureText: true,
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: isLoading ? null : changePassword,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.redAccent,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : Text(
                            "Reset Password",
                            style: GoogleFonts.inter(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
