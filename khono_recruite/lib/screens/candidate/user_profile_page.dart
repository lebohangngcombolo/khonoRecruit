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

  Widget _outlineSwitch(
      {required bool value, required ValueChanged<bool> onChanged}) {
    return GestureDetector(
      onTap: () => onChanged(!value),
      child: SizedBox(
        width: 56,
        height: 32,
        child: Stack(
          alignment: Alignment.center,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 56,
              height: 28,
              decoration: BoxDecoration(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: const Color(0xFFC10D00),
                  width: 2,
                ),
              ),
            ),
            AnimatedAlign(
              duration: const Duration(milliseconds: 200),
              alignment: value ? Alignment.centerRight : Alignment.centerLeft,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 3),
                child: Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: const Color(0xFFC10D00),
                    shape: BoxShape.circle,
                    border:
                        Border.all(color: const Color(0xFFC10D00), width: 2),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _toggleRow(String title, bool value, ValueChanged<bool> onChanged) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: GoogleFonts.poppins(
                  color: Colors.white, fontWeight: FontWeight.w600),
            ),
          ),
          _outlineSwitch(value: value, onChanged: onChanged),
        ],
      ),
    );
  }

  Widget _bannerCard(String title, Widget child) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: Colors.black.withOpacity(0.10),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFC10D00).withOpacity(0.1),
            blurRadius: 3,
            offset: const Offset(0, 6),
          )
        ],
        border: Border.all(
          color: const Color(0xFFC10D00).withAlpha((255 * 0.2).round()),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: DefaultTextStyle.merge(
          style: const TextStyle(color: Colors.white),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 12),
              child,
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    if (loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Theme(
      data: themeProvider.themeData,
      child: Scaffold(
        backgroundColor: Colors
            .transparent, // Set to transparent to show the background image
        body: Container(
          decoration: const BoxDecoration(
            image: DecorationImage(
              image: AssetImage('assets/images/Frame 1.jpg'),
              fit: BoxFit.cover,
            ),
          ),
          child: Row(
            children: [
              // Sidebar
              ClipRRect(
                borderRadius: BorderRadius.circular(0),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: Container(
                    width: 250,
                    decoration: BoxDecoration(
                      color: const Color(0xFF2A2A2A),
                      border: Border(
                        right: BorderSide(
                            color: Colors.grey.shade200.withOpacity(0.1),
                            width: 1),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withAlpha((255 * 0.02).round()),
                          blurRadius: 8,
                          offset: const Offset(2, 0),
                        )
                      ],
                    ),
                    child: Column(
                      children: [
                        SizedBox(
                          height: 72,
                          child: Padding(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 8.0),
                            child: Align(
                              alignment: Alignment.centerLeft,
                              child: Image.asset(
                                'assets/icons/khono.png',
                                height: 40,
                                fit: BoxFit.contain,
                              ),
                            ),
                          ),
                        ),
                        _sidebarButton("Profile"),
                        _sidebarButton("Settings"),
                        _sidebarButton("2FA"),
                        _sidebarButton("Reset Password"),
                      ],
                    ),
                  ),
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
      ),
    );
  }

  Widget _sidebarButton(String title) {
    final isSelected = selectedSidebar == title;
    final iconPath = _iconForTitle(title);
    return SizedBox(
      height: 48,
      child: ListTile(
        leading: iconPath != null
            ? Image.asset(
                iconPath,
                width: 32,
                height: 32,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) {
                  IconData fallback;
                  switch (title) {
                    case "Profile":
                      fallback = Icons.person_outline;
                      break;
                    case "Settings":
                      fallback = Icons.settings_outlined;
                      break;
                    case "2FA":
                      fallback = Icons.lock_outline;
                      break;
                    case "Reset Password":
                      fallback = Icons.password_outlined;
                      break;
                    default:
                      fallback = Icons.circle_outlined;
                  }
                  return Icon(fallback, color: Colors.white, size: 20);
                },
              )
            : null,
        title: Text(
          title,
          style: GoogleFonts.poppins(
              color: Colors.white, fontWeight: FontWeight.w600),
        ),
        selected: isSelected,
        hoverColor: const Color(0xFFC10D00).withOpacity(0.4),
        focusColor: const Color(0xFFC10D00).withOpacity(0.4),
        selectedTileColor: const Color(0xFFC10D00).withOpacity(0.4),
        onTap: () {
          setState(() {
            selectedSidebar = title;
            if (title == "Profile") showProfileSummary = true;
          });
        },
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
          _bannerCard(
            "Profile",
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Image.asset(
                    'assets/icons/Account_User Profile/User Profile_White Badge_Red.png',
                    width: 100,
                    height: 100,
                    fit: BoxFit.contain,
                  ),
                ),
                const SizedBox(height: 12),
                Center(
                  child: Text(
                    fullNameController.text,
                    style: GoogleFonts.poppins(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
                Center(
                  child: Text(emailController.text,
                      style: GoogleFonts.poppins(
                        color: Colors.white70,
                        fontWeight: FontWeight.w500,
                        fontSize: 12,
                      )),
                ),
                const SizedBox(height: 12),
                Center(
                  child: ElevatedButton(
                    onPressed: () => setState(() => showProfileSummary = false),
                    style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFC10D00)),
                    child: const Text("Edit Profile"),
                  ),
                ),
                const Divider(height: 30),
                Text(
                  "Title: ${titleController.text}",
                  style: GoogleFonts.poppins(fontSize: 16, color: Colors.white),
                ),
                const SizedBox(height: 6),
                Text(
                  "Nationality: ${nationalityController.text}",
                  style: GoogleFonts.poppins(fontSize: 16, color: Colors.white),
                ),
                const SizedBox(height: 6),
                Text(
                  "Bio: ${bioController.text}",
                  style: GoogleFonts.poppins(fontSize: 16, color: Colors.white),
                ),
                const SizedBox(height: 6),
                Text(
                  "Location: ${locationController.text}",
                  style: GoogleFonts.poppins(fontSize: 16, color: Colors.white),
                ),
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
          _bannerCard(
            "Personal Info",
            Column(
              children: [
                GestureDetector(
                  onTap: _pickProfileImage,
                  child: Image.asset(
                    'assets/icons/Account_User Profile/User Profile_White Badge_Red.png',
                    width: 100,
                    height: 100,
                    fit: BoxFit.contain,
                  ),
                ),
                const SizedBox(height: 12),
                CustomTextField(
                  label: "Full Name",
                  controller: fullNameController,
                  textColor: Colors.white,
                  backgroundColor: Colors.black.withOpacity(0.10),
                ),
                CustomTextField(
                  label: "Email",
                  controller: emailController,
                  textColor: Colors.white,
                  backgroundColor: Colors.black.withOpacity(0.10),
                ),
                CustomTextField(
                  label: "Phone",
                  controller: phoneController,
                  textColor: Colors.white,
                  backgroundColor: Colors.black.withOpacity(0.10),
                ),
                CustomTextField(
                  label: "Gender",
                  controller: genderController,
                  textColor: Colors.white,
                  backgroundColor: Colors.black.withOpacity(0.10),
                ),
                CustomTextField(
                  label: "Date of Birth",
                  controller: dobController,
                  textColor: Colors.white,
                  backgroundColor: Colors.black.withOpacity(0.10),
                ),
                CustomTextField(
                  label: "Nationality",
                  controller: nationalityController,
                  textColor: Colors.white,
                  backgroundColor: Colors.black.withOpacity(0.10),
                ),
                CustomTextField(
                  label: "ID Number",
                  controller: idNumberController,
                  textColor: Colors.white,
                  backgroundColor: Colors.black.withOpacity(0.10),
                ),
                CustomTextField(
                  label: "Bio",
                  controller: bioController,
                  textColor: Colors.white,
                  backgroundColor: Colors.black.withOpacity(0.10),
                ),
                CustomTextField(
                  label: "Location",
                  controller: locationController,
                  textColor: Colors.white,
                  backgroundColor: Colors.black.withOpacity(0.10),
                ),
                CustomTextField(
                  label: "Title",
                  controller: titleController,
                  textColor: Colors.white,
                  backgroundColor: Colors.black.withOpacity(0.10),
                ),
              ],
            ),
          ),
          _bannerCard(
            "Education & Skills",
            Column(
              children: [
                CustomTextField(
                  label: "Degree",
                  controller: degreeController,
                  textColor: Colors.white,
                  backgroundColor: Colors.black.withOpacity(0.10),
                ),
                CustomTextField(
                  label: "Institution",
                  controller: institutionController,
                  textColor: Colors.white,
                  backgroundColor: Colors.black.withOpacity(0.10),
                ),
                CustomTextField(
                  label: "Graduation Year",
                  controller: graduationYearController,
                  textColor: Colors.white,
                  backgroundColor: Colors.black.withOpacity(0.10),
                ),
                CustomTextField(
                  label: "Skills (comma separated)",
                  controller: skillsController,
                  textColor: Colors.white,
                  backgroundColor: Colors.black.withOpacity(0.10),
                ),
              ],
            ),
          ),
          _bannerCard(
            "Work Experience",
            Column(
              children: [
                CustomTextField(
                  label: "Job Title",
                  controller: jobTitleController,
                  textColor: Colors.white,
                  backgroundColor: Colors.black.withOpacity(0.10),
                ),
                CustomTextField(
                  label: "Company",
                  controller: companyController,
                  textColor: Colors.white,
                  backgroundColor: Colors.black.withOpacity(0.10),
                ),
                CustomTextField(
                  label: "Years of Experience",
                  controller: yearsOfExpController,
                  textColor: Colors.white,
                  backgroundColor: Colors.black.withOpacity(0.10),
                ),
                CustomTextField(
                  label: "Work Experience Details",
                  controller: workExpController,
                  textColor: Colors.white,
                  backgroundColor: Colors.black.withOpacity(0.10),
                ),
              ],
            ),
          ),
          _bannerCard(
            "Online Profiles & CV",
            Column(
              children: [
                CustomTextField(
                  label: "LinkedIn",
                  controller: linkedinController,
                  textColor: Colors.white,
                  backgroundColor: Colors.black.withOpacity(0.10),
                ),
                CustomTextField(
                  label: "GitHub",
                  controller: githubController,
                  textColor: Colors.white,
                  backgroundColor: Colors.black.withOpacity(0.10),
                ),
                CustomTextField(
                  label: "Portfolio",
                  controller: portfolioController,
                  textColor: Colors.white,
                  backgroundColor: Colors.black.withOpacity(0.10),
                ),
                CustomTextField(
                  label: "CV Text",
                  controller: cvTextController,
                  textColor: Colors.white,
                  backgroundColor: Colors.black.withOpacity(0.10),
                ),
                CustomTextField(
                  label: "CV URL",
                  controller: cvUrlController,
                  textColor: Colors.white,
                  backgroundColor: Colors.black.withOpacity(0.10),
                ),
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: updateProfile,
                  style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFC10D00)),
                  child: const Text("Save Changes"),
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
      child: _bannerCard(
        "Settings",
        Column(
          children: [
            _toggleRow(
                "Dark Mode", darkMode, (v) => setState(() => darkMode = v)),
            _toggleRow("Notifications", notificationsEnabled,
                (v) => setState(() => notificationsEnabled = v)),
            _toggleRow("Job Alerts", jobAlertsEnabled,
                (v) => setState(() => jobAlertsEnabled = v)),
            _toggleRow("Profile Visible", profileVisible,
                (v) => setState(() => profileVisible = v)),
            _toggleRow("Enrollment Completed", enrollmentCompleted,
                (v) => setState(() => enrollmentCompleted = v)),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: updateSettings,
              style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFC10D00)),
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
      child: _bannerCard(
        "Two-Factor Authentication",
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Enable 2FA to add an extra layer of security to your account.",
              style: GoogleFonts.poppins(color: Colors.white70),
            ),
            const SizedBox(height: 16),
            _toggleRow("Enable Two-Factor Authentication", twoFactorEnabled,
                (v) => setState(() => twoFactorEnabled = v)),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: updateSettings,
              style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFC10D00)),
              child: const Text("Save 2FA Settings"),
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
      child: _bannerCard(
        "Reset Password",
        Column(
          children: [
            CustomTextField(
              label: "Current Password",
              controller: currentPassword,
              obscureText: true,
              textColor: Colors.white,
              backgroundColor: Colors.black.withOpacity(0.10),
            ),
            const SizedBox(height: 10),
            CustomTextField(
              label: "New Password",
              controller: newPassword,
              obscureText: true,
              textColor: Colors.white,
              backgroundColor: Colors.black.withOpacity(0.10),
            ),
            const SizedBox(height: 10),
            CustomTextField(
              label: "Confirm New Password",
              controller: confirmPassword,
              obscureText: true,
              textColor: Colors.white,
              backgroundColor: Colors.black.withOpacity(0.10),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: isLoading ? null : changePassword,
              style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFC10D00)),
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
