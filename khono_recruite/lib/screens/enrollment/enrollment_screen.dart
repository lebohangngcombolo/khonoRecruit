import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../candidate/candidate_dashboard.dart';

class EnrollmentScreen extends StatefulWidget {
  final String token;
  const EnrollmentScreen({super.key, required this.token});

  @override
  _EnrollmentScreenState createState() => _EnrollmentScreenState();
}

class _EnrollmentScreenState extends State<EnrollmentScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int currentStep = 0;
  bool loading = false;
  bool profileLoading = true;
  String? userName;

  // Scroll controller for detecting scroll position
  final ScrollController _scrollController = ScrollController();
  bool _isProgressCollapsed = false;

  // ------------------- Personal Details -------------------
  final TextEditingController nameController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController addressController = TextEditingController();
  final TextEditingController dobController = TextEditingController();
  final TextEditingController linkedinController = TextEditingController();

  // ------------------- Education -------------------
  final TextEditingController educationController = TextEditingController();
  final TextEditingController universityController = TextEditingController();
  final TextEditingController graduationYearController =
      TextEditingController();

  // ------------------- Skills -------------------
  final TextEditingController skillsController = TextEditingController();
  final TextEditingController certificationsController =
      TextEditingController();
  final TextEditingController languagesController = TextEditingController();

  // ------------------- Experience -------------------
  final TextEditingController experienceController = TextEditingController();
  final TextEditingController previousCompaniesController =
      TextEditingController();
  final TextEditingController positionController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _fetchUserProfile();

    // Listen to scroll events
    _scrollController.addListener(_handleScroll);
  }

  void _handleScroll() {
    final scrollOffset = _scrollController.offset;
    final shouldCollapse = scrollOffset > 50; // Collapse when scrolled 50px

    if (shouldCollapse != _isProgressCollapsed) {
      setState(() {
        _isProgressCollapsed = shouldCollapse;
      });
    }
  }

  void _fetchUserProfile() async {
    try {
      final profile = await AuthService.getCurrentUser(token: widget.token);
      setState(() {
        userName = profile['full_name'] ??
            profile['name'] ??
            profile['email']?.split('@').first;
        if (userName != null && userName!.isNotEmpty) {
          nameController.text = userName!;
        }
        profileLoading = false;
      });
    } catch (e) {
      debugPrint("Error fetching user profile: $e");
      try {
        final localUser = await AuthService.getUserInfo();
        if (localUser != null) {
          setState(() {
            userName = localUser['full_name'] ??
                localUser['name'] ??
                localUser['email']?.split('@').first;
            if (userName != null && userName!.isNotEmpty) {
              nameController.text = userName!;
            }
          });
        }
      } catch (e) {
        debugPrint("Error fetching local user info: $e");
      }
      setState(() => profileLoading = false);
    }
  }

  void nextStep() {
    if (currentStep < 3) {
      setState(() => currentStep++);
      _tabController.animateTo(currentStep);
    } else {
      submitEnrollment();
    }
  }

  void previousStep() {
    if (currentStep > 0) {
      setState(() => currentStep--);
      _tabController.animateTo(currentStep);
    }
  }

  void submitEnrollment() async {
    setState(() => loading = true);

    final data = {
      "name": nameController.text.trim(),
      "phone": phoneController.text.trim(),
      "address": addressController.text.trim(),
      "dob": dobController.text.trim(),
      "linkedin": linkedinController.text.trim(),
      "education": educationController.text.trim().split(','),
      "university": universityController.text.trim(),
      "graduation_year": graduationYearController.text.trim(),
      "skills": skillsController.text.trim().split(','),
      "certifications": certificationsController.text.trim().split(','),
      "languages": languagesController.text.trim().split(','),
      "experience": experienceController.text.trim(),
      "previous_companies": previousCompaniesController.text.trim().split(','),
      "position": positionController.text.trim(),
    };

    final response = await AuthService.completeEnrollment(widget.token, data);
    setState(() => loading = false);

    if (response.containsKey('error')) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(response['error'])),
      );
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
            builder: (_) => CandidateDashboard(token: widget.token)),
      );
    }
  }

  Widget _buildStepIndicator(String label, int index, IconData icon) {
    final isActive = currentStep == index;
    final isCompleted = currentStep > index;

    return Expanded(
      child: Column(
        children: [
          Container(
            width: _isProgressCollapsed ? 28 : 36,
            height: _isProgressCollapsed ? 28 : 36,
            decoration: BoxDecoration(
              color: isActive
                  ? const Color(0xFFDC2626).withOpacity(0.9)
                  : isCompleted
                      ? const Color(0xFF16A34A).withOpacity(0.9)
                      : Colors.white.withOpacity(0.2),
              shape: BoxShape.circle,
              border: Border.all(
                color: isActive
                    ? Colors.white.withOpacity(0.8)
                    : isCompleted
                        ? const Color(0xFF16A34A).withOpacity(0.8)
                        : Colors.white.withOpacity(0.4),
                width: 1.5,
              ),
            ),
            child: Icon(
              icon,
              color: isActive || isCompleted
                  ? Colors.white
                  : Colors.white.withOpacity(0.7),
              size: _isProgressCollapsed ? 14 : 16,
            ),
          ),
          if (!_isProgressCollapsed) ...[
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: Colors.white.withOpacity(0.9),
              ),
            ),
            const SizedBox(height: 4),
          ],
          if (index < 3)
            Container(
              height: 2,
              color: isCompleted
                  ? const Color(0xFF16A34A).withOpacity(0.8)
                  : Colors.white.withOpacity(0.3),
            ),
        ],
      ),
    );
  }

  Widget _buildGlassCard(Widget child, {String? title, String? subtitle}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: const Color(0xFFDC2626).withOpacity(0.15),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.2), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 15,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: const ColorFilter.matrix([
            1,
            0,
            0,
            0,
            0,
            0,
            1,
            0,
            0,
            0,
            0,
            0,
            1,
            0,
            0,
            0,
            0,
            0,
            18,
            -7,
          ]),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (title != null) ...[
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.white.withOpacity(0.8),
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),
                  Container(
                    height: 1,
                    color: Colors.white.withOpacity(0.2),
                  ),
                  const SizedBox(height: 16),
                ],
                child,
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label,
      {TextInputType keyboardType = TextInputType.text,
      int maxLines = 1,
      IconData? prefixIcon,
      bool readOnly = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Colors.white.withOpacity(0.9),
          ),
        ),
        const SizedBox(height: 6),
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: TextField(
            controller: controller,
            keyboardType: keyboardType,
            maxLines: maxLines,
            readOnly: readOnly,
            style: const TextStyle(fontSize: 15, color: Colors.white),
            decoration: InputDecoration(
              filled: true,
              fillColor: Colors.white.withOpacity(0.1),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: Colors.white, width: 1.5),
              ),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              prefixIcon: prefixIcon != null
                  ? Icon(prefixIcon,
                      color: Colors.white.withOpacity(0.7), size: 20)
                  : null,
            ),
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildProgressHeader() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      height: _isProgressCollapsed ? 80 : 160,
      padding: _isProgressCollapsed
          ? const EdgeInsets.symmetric(vertical: 16, horizontal: 24)
          : const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFFDC2626).withOpacity(0.15),
        borderRadius: const BorderRadius.vertical(
          bottom: Radius.circular(25),
        ),
        border: Border.all(color: Colors.white.withOpacity(0.2)),
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(
          bottom: Radius.circular(25),
        ),
        child: BackdropFilter(
          filter: const ColorFilter.matrix([
            1,
            0,
            0,
            0,
            0,
            0,
            1,
            0,
            0,
            0,
            0,
            0,
            1,
            0,
            0,
            0,
            0,
            0,
            18,
            -7,
          ]),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (!_isProgressCollapsed) ...[
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    "Step ${currentStep + 1} of 4",
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  _getStepTitle(currentStep),
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 6),
                Text(
                  _getStepSubtitle(currentStep),
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.white.withOpacity(0.8),
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
              ],
              // Step Indicators - Adjusted spacing for collapsed state
              Row(
                children: [
                  _buildStepIndicator(
                      "Personal", 0, Icons.person_outline_rounded),
                  _buildStepIndicator("Education", 1, Icons.school_rounded),
                  _buildStepIndicator(
                      "Skills", 2, Icons.workspace_premium_rounded),
                  _buildStepIndicator(
                      "Experience", 3, Icons.work_history_rounded),
                ],
              ),
              // Add some bottom spacing when collapsed
              if (_isProgressCollapsed) const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/dark.png'),
            fit: BoxFit.cover,
          ),
        ),
        child: Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(
            title: const Text(
              "Complete Your Profile",
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 18,
                color: Colors.white,
              ),
            ),
            backgroundColor: const Color(0xFFDC2626).withOpacity(0.2),
            elevation: 0,
            centerTitle: true,
            leading: IconButton(
              icon: Icon(Icons.arrow_back_ios_new_rounded,
                  color: Colors.white.withOpacity(0.9), size: 20),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),
          body: loading || profileLoading
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          color: const Color(0xFFDC2626).withOpacity(0.3),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.3),
                              blurRadius: 15,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: const CircularProgressIndicator(
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.white),
                          strokeWidth: 2.5,
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        "Preparing Your Profile",
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        "Please wait while we set up your account",
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.white.withOpacity(0.8),
                        ),
                      ),
                    ],
                  ),
                )
              : Column(
                  children: [
                    // Progress Header - Now animated
                    _buildProgressHeader(),

                    // Form Content
                    Expanded(
                      child: Container(
                        color: Colors.transparent,
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: TabBarView(
                            controller: _tabController,
                            physics: const NeverScrollableScrollPhysics(),
                            children: [
                              // Step 1: Personal Details
                              _buildScrollableStep([
                                if (userName != null)
                                  _buildGlassCard(
                                    Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(5),
                                          decoration: const BoxDecoration(
                                            color: Color(0xFF16A34A),
                                            shape: BoxShape.circle,
                                          ),
                                          child: const Icon(
                                              Icons.check_circle_rounded,
                                              color: Colors.white,
                                              size: 16),
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            "Welcome, $userName! Your profile has been detected.",
                                            style: const TextStyle(
                                              fontSize: 13,
                                              fontWeight: FontWeight.w600,
                                              color: Color(0xFF16A34A),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    title: "Profile Detected",
                                    subtitle:
                                        "We found your existing information",
                                  ),
                                _buildGlassCard(
                                  _buildTextField(
                                    nameController,
                                    "Full Name",
                                    prefixIcon: Icons.person_rounded,
                                    readOnly: userName != null &&
                                        userName!.isNotEmpty,
                                  ),
                                  title: "Personal Information",
                                  subtitle: "Your basic identification details",
                                ),
                                _buildGlassCard(
                                  Column(
                                    children: [
                                      _buildTextField(
                                          phoneController, "Phone Number",
                                          keyboardType: TextInputType.phone,
                                          prefixIcon: Icons.phone_rounded),
                                      _buildTextField(
                                          addressController, "Address",
                                          maxLines: 2,
                                          prefixIcon:
                                              Icons.location_on_rounded),
                                      _buildTextField(
                                          dobController, "Date of Birth",
                                          prefixIcon:
                                              Icons.calendar_today_rounded),
                                      _buildTextField(linkedinController,
                                          "LinkedIn Profile",
                                          keyboardType: TextInputType.url,
                                          prefixIcon: Icons.link_rounded),
                                    ],
                                  ),
                                  title: "Contact Details",
                                  subtitle: "How we can reach you",
                                ),
                              ]),
                              // Step 2: Education
                              _buildScrollableStep([
                                _buildGlassCard(
                                  Column(
                                    children: [
                                      _buildTextField(educationController,
                                          "Highest Education",
                                          prefixIcon: Icons.school_rounded),
                                      _buildTextField(universityController,
                                          "University / Institution",
                                          prefixIcon:
                                              Icons.account_balance_rounded),
                                      _buildTextField(graduationYearController,
                                          "Graduation Year",
                                          keyboardType: TextInputType.number,
                                          prefixIcon: Icons.date_range_rounded),
                                    ],
                                  ),
                                  title: "Educational Background",
                                  subtitle: "Your academic qualifications",
                                ),
                              ]),
                              // Step 3: Skills
                              _buildScrollableStep([
                                _buildGlassCard(
                                  Column(
                                    children: [
                                      _buildTextField(skillsController,
                                          "Skills (comma separated)",
                                          maxLines: 3,
                                          prefixIcon: Icons.code_rounded),
                                      _buildTextField(certificationsController,
                                          "Certifications (comma separated)",
                                          maxLines: 3,
                                          prefixIcon: Icons.verified_rounded),
                                      _buildTextField(languagesController,
                                          "Languages Known (comma separated)",
                                          maxLines: 2,
                                          prefixIcon: Icons.language_rounded),
                                    ],
                                  ),
                                  title: "Skills & Certifications",
                                  subtitle: "Your professional capabilities",
                                ),
                              ]),
                              // Step 4: Experience
                              _buildScrollableStep([
                                _buildGlassCard(
                                  Column(
                                    children: [
                                      _buildTextField(experienceController,
                                          "Work Experience Description",
                                          maxLines: 5,
                                          prefixIcon:
                                              Icons.description_rounded),
                                      _buildTextField(
                                          previousCompaniesController,
                                          "Previous Companies (comma separated)",
                                          maxLines: 3,
                                          prefixIcon: Icons.business_rounded),
                                      _buildTextField(
                                          positionController, "Positions Held",
                                          prefixIcon: Icons.work_rounded),
                                    ],
                                  ),
                                  title: "Professional Experience",
                                  subtitle: "Your career journey",
                                ),
                              ]),
                            ],
                          ),
                        ),
                      ),
                    ),

                    // Navigation Buttons
                    Container(
                      height: 80,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFDC2626).withOpacity(0.15),
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(25),
                        ),
                        border:
                            Border.all(color: Colors.white.withOpacity(0.2)),
                      ),
                      child: ClipRRect(
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(25),
                        ),
                        child: BackdropFilter(
                          filter: const ColorFilter.matrix([
                            1,
                            0,
                            0,
                            0,
                            0,
                            0,
                            1,
                            0,
                            0,
                            0,
                            0,
                            0,
                            1,
                            0,
                            0,
                            0,
                            0,
                            0,
                            18,
                            -7,
                          ]),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              if (currentStep > 0)
                                Container(
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(10),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.1),
                                        blurRadius: 8,
                                        offset: const Offset(0, 3),
                                      ),
                                    ],
                                  ),
                                  child: ElevatedButton.icon(
                                    onPressed: previousStep,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor:
                                          Colors.white.withOpacity(0.2),
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 16, vertical: 12),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(10),
                                        side: BorderSide(
                                            color:
                                                Colors.white.withOpacity(0.3)),
                                      ),
                                      elevation: 0,
                                    ),
                                    icon: const Icon(Icons.arrow_back_rounded,
                                        size: 16),
                                    label: const Text(
                                      "Back",
                                      style: TextStyle(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 13),
                                    ),
                                  ),
                                ),
                              Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(10),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.white.withOpacity(0.3),
                                      blurRadius: 12,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: ElevatedButton.icon(
                                  onPressed: nextStep,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor:
                                        Colors.white.withOpacity(0.9),
                                    foregroundColor: const Color(0xFFDC2626),
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 20, vertical: 12),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    elevation: 0,
                                  ),
                                  icon: Icon(
                                    currentStep == 3
                                        ? Icons.check_circle_rounded
                                        : Icons.arrow_forward_rounded,
                                    size: 16,
                                  ),
                                  label: Text(
                                    currentStep == 3
                                        ? "Complete Profile"
                                        : "Continue",
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 13),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _buildScrollableStep(List<Widget> children) {
    return SingleChildScrollView(
      controller: _scrollController,
      physics: const BouncingScrollPhysics(),
      child: Column(
        children: [
          ...children,
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  String _getStepTitle(int step) {
    switch (step) {
      case 0:
        return "Personal Information";
      case 1:
        return "Education Background";
      case 2:
        return "Skills & Languages";
      case 3:
        return "Work Experience";
      default:
        return "Complete Profile";
    }
  }

  String _getStepSubtitle(int step) {
    switch (step) {
      case 0:
        return "Tell us about yourself and how to reach you";
      case 1:
        return "Share your educational qualifications and achievements";
      case 2:
        return "Highlight your skills, certifications, and languages";
      case 3:
        return "Describe your professional journey and experience";
      default:
        return "Complete your professional profile";
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _scrollController.dispose();
    nameController.dispose();
    phoneController.dispose();
    addressController.dispose();
    dobController.dispose();
    linkedinController.dispose();
    educationController.dispose();
    universityController.dispose();
    graduationYearController.dispose();
    skillsController.dispose();
    certificationsController.dispose();
    languagesController.dispose();
    experienceController.dispose();
    previousCompaniesController.dispose();
    positionController.dispose();
    super.dispose();
  }
}
