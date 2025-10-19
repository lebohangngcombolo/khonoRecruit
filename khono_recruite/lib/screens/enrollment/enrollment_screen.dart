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
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: isActive
                  ? Colors.redAccent
                  : isCompleted
                      ? Colors.green
                      : Colors.grey.shade300,
              shape: BoxShape.circle,
              boxShadow: [
                if (isActive || isCompleted)
                  BoxShadow(
                    color: (isActive ? Colors.redAccent : Colors.green)
                        .withOpacity(0.3),
                    blurRadius: 8,
                    spreadRadius: 2,
                  ),
              ],
            ),
            child: Icon(
              icon,
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
              color: isActive ? Colors.redAccent : Colors.grey.shade600,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Container(
            height: 3,
            margin: const EdgeInsets.symmetric(horizontal: 8),
            decoration: BoxDecoration(
              color: isCompleted ? Colors.green : Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEnhancedCard(Widget child, {IconData? icon}) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: Colors.grey.shade100, width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (icon != null) ...[
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.redAccent.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: Colors.redAccent, size: 20),
              ),
              const SizedBox(width: 16),
            ],
            Expanded(child: child),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label,
      {TextInputType keyboardType = TextInputType.text,
      int maxLines = 1,
      IconData? icon}) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      style: const TextStyle(fontSize: 16),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: Colors.grey.shade600),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.redAccent, width: 2),
        ),
        filled: true,
        fillColor: Colors.grey.shade50,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text(
          "Complete Your Profile",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black,
        centerTitle: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            bottom: Radius.circular(20),
          ),
        ),
      ),
      body: loading
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: Colors.redAccent),
                  SizedBox(height: 16),
                  Text(
                    "Setting up your profile...",
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                ],
              ),
            )
          : Column(
              children: [
                // Progress Header
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.vertical(
                      bottom: Radius.circular(20),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 10,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Text(
                        "Step ${currentStep + 1} of 4",
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _getStepTitle(currentStep),
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 24),
                      // Step Indicators
                      Row(
                        children: [
                          _buildStepIndicator(
                              "Personal", 0, Icons.person_outline),
                          _buildStepIndicator(
                              "Education", 1, Icons.school_outlined),
                          _buildStepIndicator(
                              "Skills", 2, Icons.workspace_premium_outlined),
                          _buildStepIndicator(
                              "Experience", 3, Icons.work_outline),
                        ],
                      ),
                    ],
                  ),
                ),

                // Form Content
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: TabBarView(
                      controller: _tabController,
                      physics: const NeverScrollableScrollPhysics(),
                      children: [
                        // Step 1: Personal Details
                        ListView(
                          children: [
                            _buildEnhancedCard(
                              _buildTextField(nameController, "Full Name",
                                  icon: Icons.person),
                              icon: Icons.person,
                            ),
                            _buildEnhancedCard(
                              _buildTextField(phoneController, "Phone Number",
                                  keyboardType: TextInputType.phone),
                              icon: Icons.phone,
                            ),
                            _buildEnhancedCard(
                              _buildTextField(addressController, "Address",
                                  maxLines: 2),
                              icon: Icons.location_on,
                            ),
                            _buildEnhancedCard(
                              _buildTextField(dobController, "Date of Birth"),
                              icon: Icons.calendar_today,
                            ),
                            _buildEnhancedCard(
                              _buildTextField(
                                  linkedinController, "LinkedIn Profile",
                                  keyboardType: TextInputType.url),
                              icon: Icons.link,
                            ),
                          ],
                        ),
                        // Step 2: Education
                        ListView(
                          children: [
                            _buildEnhancedCard(
                              _buildTextField(
                                  educationController, "Highest Education"),
                              icon: Icons.school,
                            ),
                            _buildEnhancedCard(
                              _buildTextField(universityController,
                                  "University / Institution"),
                              icon: Icons.account_balance,
                            ),
                            _buildEnhancedCard(
                              _buildTextField(
                                  graduationYearController, "Graduation Year",
                                  keyboardType: TextInputType.number),
                              icon: Icons.date_range,
                            ),
                          ],
                        ),
                        // Step 3: Skills
                        ListView(
                          children: [
                            _buildEnhancedCard(
                              _buildTextField(
                                  skillsController, "Skills (comma separated)",
                                  maxLines: 3),
                              icon: Icons.code,
                            ),
                            _buildEnhancedCard(
                              _buildTextField(certificationsController,
                                  "Certifications (comma separated)",
                                  maxLines: 3),
                              icon: Icons.verified,
                            ),
                            _buildEnhancedCard(
                              _buildTextField(languagesController,
                                  "Languages Known (comma separated)",
                                  maxLines: 2),
                              icon: Icons.language,
                            ),
                          ],
                        ),
                        // Step 4: Experience
                        ListView(
                          children: [
                            _buildEnhancedCard(
                              _buildTextField(experienceController,
                                  "Work Experience Description",
                                  maxLines: 5),
                              icon: Icons.description,
                            ),
                            _buildEnhancedCard(
                              _buildTextField(previousCompaniesController,
                                  "Previous Companies (comma separated)",
                                  maxLines: 3),
                              icon: Icons.business,
                            ),
                            _buildEnhancedCard(
                              _buildTextField(
                                  positionController, "Positions Held"),
                              icon: Icons.work,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                // Navigation Buttons
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, -2),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      if (currentStep > 0)
                        ElevatedButton.icon(
                          onPressed: previousStep,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.grey.shade100,
                            foregroundColor: Colors.grey.shade700,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 24, vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 0,
                          ),
                          icon: const Icon(Icons.arrow_back, size: 18),
                          label: const Text("Back"),
                        ),
                      ElevatedButton.icon(
                        onPressed: nextStep,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.redAccent,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 32, vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 2,
                          shadowColor: Colors.redAccent.withOpacity(0.3),
                        ),
                        icon: Icon(
                          currentStep == 3 ? Icons.check : Icons.arrow_forward,
                          size: 18,
                        ),
                        label: Text(
                            currentStep == 3 ? "Complete Profile" : "Continue"),
                      ),
                    ],
                  ),
                ),
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

  @override
  void dispose() {
    _tabController.dispose();
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
