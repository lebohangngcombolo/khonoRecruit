import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_textfield.dart';
import '../../providers/theme_provider.dart';
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
  final TextEditingController dobController =
      TextEditingController(); // New field
  final TextEditingController linkedinController =
      TextEditingController(); // New field

  // ------------------- Education -------------------
  final TextEditingController educationController = TextEditingController();
  final TextEditingController universityController =
      TextEditingController(); // New field
  final TextEditingController graduationYearController =
      TextEditingController(); // New field

  // ------------------- Skills -------------------
  final TextEditingController skillsController = TextEditingController();
  final TextEditingController certificationsController =
      TextEditingController(); // New field
  final TextEditingController languagesController =
      TextEditingController(); // New field

  // ------------------- Experience -------------------
  final TextEditingController experienceController = TextEditingController();
  final TextEditingController previousCompaniesController =
      TextEditingController(); // New field
  final TextEditingController positionController =
      TextEditingController(); // New field

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
            builder: (_) => const CandidateDashboard(
                  token: '',
                )),
      );
    }
  }

  Widget stepIndicator(int step) {
    return CircleAvatar(
      radius: 15,
      backgroundColor: currentStep >= step ? Colors.red : Colors.grey.shade400,
      child: Text(
        "${step + 1}",
        style:
            const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Enrollment"),
        actions: [
          IconButton(
            icon: Icon(
                themeProvider.isDarkMode ? Icons.light_mode : Icons.dark_mode),
            onPressed: () => themeProvider.toggleTheme(),
          )
        ],
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator(color: Colors.red))
          : Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // ------------------- Timeline -------------------
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: List.generate(4, (index) => stepIndicator(index)),
                  ),
                  const SizedBox(height: 24),

                  // ------------------- TabBarView -------------------
                  Expanded(
                    child: TabBarView(
                      controller: _tabController,
                      physics: const NeverScrollableScrollPhysics(),
                      children: [
                        // Step 1: Personal Details
                        ListView(
                          children: [
                            CustomTextField(
                                label: "Full Name", controller: nameController),
                            const SizedBox(height: 16),
                            CustomTextField(
                                label: "Phone",
                                controller: phoneController,
                                inputType: TextInputType.phone),
                            const SizedBox(height: 16),
                            CustomTextField(
                                label: "Address",
                                controller: addressController),
                            const SizedBox(height: 16),
                            CustomTextField(
                                label: "Date of Birth",
                                controller: dobController),
                            const SizedBox(height: 16),
                            CustomTextField(
                                label: "LinkedIn Profile",
                                controller: linkedinController,
                                inputType: TextInputType.url),
                          ],
                        ),
                        // Step 2: Education
                        ListView(
                          children: [
                            CustomTextField(
                                label: "Highest Education",
                                controller: educationController),
                            const SizedBox(height: 16),
                            CustomTextField(
                                label: "University / Institution",
                                controller: universityController),
                            const SizedBox(height: 16),
                            CustomTextField(
                                label: "Graduation Year",
                                controller: graduationYearController,
                                inputType: TextInputType.number),
                          ],
                        ),
                        // Step 3: Skills
                        ListView(
                          children: [
                            CustomTextField(
                                label: "Skills (comma separated)",
                                controller: skillsController),
                            const SizedBox(height: 16),
                            CustomTextField(
                                label: "Certifications (comma separated)",
                                controller: certificationsController),
                            const SizedBox(height: 16),
                            CustomTextField(
                                label: "Languages Known (comma separated)",
                                controller: languagesController),
                          ],
                        ),
                        // Step 4: Experience
                        ListView(
                          children: [
                            CustomTextField(
                                label: "Work Experience Description",
                                controller: experienceController,
                                maxLines: 5),
                            const SizedBox(height: 16),
                            CustomTextField(
                                label: "Previous Companies (comma separated)",
                                controller: previousCompaniesController),
                            const SizedBox(height: 16),
                            CustomTextField(
                                label: "Positions Held",
                                controller: positionController),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // ------------------- Navigation Buttons -------------------
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      if (currentStep > 0)
                        CustomButton(
                            text: "Back",
                            onPressed: previousStep,
                            color: Colors.grey),
                      CustomButton(
                          text: currentStep == 3 ? "Submit" : "Next",
                          onPressed: nextStep),
                    ],
                  )
                ],
              ),
            ),
    );
  }
}
