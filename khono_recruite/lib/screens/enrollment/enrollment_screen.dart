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

  Widget _tabButton(String label, int index) {
    return GestureDetector(
      onTap: () => setState(() => currentStep = index),
      child: CircleAvatar(
        radius: 20,
        backgroundColor:
            currentStep == index ? Colors.redAccent : Colors.grey.shade400,
        child: Text(
          "${index + 1}",
          style:
              const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Widget _buildPlainCard(Widget child) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: child,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Complete Your Profile"),
        backgroundColor: Colors.redAccent,
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // Tabs
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: List.generate(
                        4, (index) => _tabButton("Step ${index + 1}", index)),
                  ),
                  const SizedBox(height: 16),

                  // Form Fields
                  Expanded(
                    child: TabBarView(
                      controller: _tabController,
                      physics: const NeverScrollableScrollPhysics(),
                      children: [
                        // Step 1: Personal Details
                        ListView(
                          children: [
                            _buildPlainCard(TextField(
                                controller: nameController,
                                decoration: const InputDecoration(
                                    labelText: "Full Name"))),
                            _buildPlainCard(TextField(
                                controller: phoneController,
                                decoration:
                                    const InputDecoration(labelText: "Phone"),
                                keyboardType: TextInputType.phone)),
                            _buildPlainCard(TextField(
                                controller: addressController,
                                decoration: const InputDecoration(
                                    labelText: "Address"))),
                            _buildPlainCard(TextField(
                                controller: dobController,
                                decoration: const InputDecoration(
                                    labelText: "Date of Birth"))),
                            _buildPlainCard(TextField(
                                controller: linkedinController,
                                decoration: const InputDecoration(
                                    labelText: "LinkedIn Profile"),
                                keyboardType: TextInputType.url)),
                          ],
                        ),
                        // Step 2: Education
                        ListView(
                          children: [
                            _buildPlainCard(TextField(
                                controller: educationController,
                                decoration: const InputDecoration(
                                    labelText: "Highest Education"))),
                            _buildPlainCard(TextField(
                                controller: universityController,
                                decoration: const InputDecoration(
                                    labelText: "University / Institution"))),
                            _buildPlainCard(TextField(
                                controller: graduationYearController,
                                decoration: const InputDecoration(
                                    labelText: "Graduation Year"),
                                keyboardType: TextInputType.number)),
                          ],
                        ),
                        // Step 3: Skills
                        ListView(
                          children: [
                            _buildPlainCard(TextField(
                                controller: skillsController,
                                decoration: const InputDecoration(
                                    labelText: "Skills (comma separated)"))),
                            _buildPlainCard(TextField(
                                controller: certificationsController,
                                decoration: const InputDecoration(
                                    labelText:
                                        "Certifications (comma separated)"))),
                            _buildPlainCard(TextField(
                                controller: languagesController,
                                decoration: const InputDecoration(
                                    labelText:
                                        "Languages Known (comma separated)"))),
                          ],
                        ),
                        // Step 4: Experience
                        ListView(
                          children: [
                            _buildPlainCard(TextField(
                                controller: experienceController,
                                decoration: const InputDecoration(
                                    labelText: "Work Experience Description"),
                                maxLines: 5)),
                            _buildPlainCard(TextField(
                                controller: previousCompaniesController,
                                decoration: const InputDecoration(
                                    labelText:
                                        "Previous Companies (comma separated)"))),
                            _buildPlainCard(TextField(
                                controller: positionController,
                                decoration: const InputDecoration(
                                    labelText: "Positions Held"))),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Navigation Buttons
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      if (currentStep > 0)
                        ElevatedButton(
                          onPressed: previousStep,
                          style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.grey),
                          child: const Text("Back"),
                        ),
                      ElevatedButton(
                        onPressed: nextStep,
                        style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.redAccent),
                        child: Text(currentStep == 3 ? "Submit" : "Next"),
                      ),
                    ],
                  ),
                ],
              ),
            ),
    );
  }
}
