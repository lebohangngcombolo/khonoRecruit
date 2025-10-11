import 'package:flutter/material.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_textfield.dart';
import '../../services/admin_service.dart';

class JobManagement extends StatefulWidget {
  final Function(int jobId)? onJobSelected; // Callback when a job is selected

  const JobManagement({super.key, this.onJobSelected});

  @override
  _JobManagementState createState() => _JobManagementState();
}

class _JobManagementState extends State<JobManagement> {
  final AdminService admin = AdminService();
  List<Map<String, dynamic>> jobs = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    fetchJobs();
  }

  Future<void> fetchJobs() async {
    setState(() => loading = true);
    try {
      final data = await admin.listJobs();
      jobs = List<Map<String, dynamic>>.from(data);
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Error fetching jobs: $e")));
    }
    setState(() => loading = false);
  }

  void openJobForm({Map<String, dynamic>? job}) {
    showDialog(
      context: context,
      builder: (_) => JobFormDialog(job: job, onSaved: fetchJobs),
    );
  }

  @override
  Widget build(BuildContext context) {
    return loading
        ? const Center(child: CircularProgressIndicator(color: Colors.red))
        : Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      "Job Management",
                      style:
                          TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                    CustomButton(
                        text: "Add Job", onPressed: () => openJobForm()),
                  ],
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: jobs.isEmpty
                      ? const Center(child: Text("No jobs available"))
                      : ListView.builder(
                          itemCount: jobs.length,
                          itemBuilder: (_, index) {
                            final job = jobs[index];
                            return Card(
                              elevation: 3,
                              margin: const EdgeInsets.symmetric(vertical: 8),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10)),
                              child: ListTile(
                                title: Text(job['title'] ?? '',
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold)),
                                subtitle: Text(job['description'] ?? ''),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.edit,
                                          color: Colors.red),
                                      onPressed: () => openJobForm(job: job),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete,
                                          color: Colors.red),
                                      onPressed: () async {
                                        try {
                                          await admin
                                              .deleteJob(job['id'] as int);
                                          fetchJobs();
                                        } catch (e) {
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(SnackBar(
                                                  content: Text(
                                                      "Error deleting job: $e")));
                                        }
                                      },
                                    ),
                                    if (widget.onJobSelected != null)
                                      IconButton(
                                        icon: const Icon(Icons.check_circle,
                                            color: Colors.green),
                                        onPressed: () => widget
                                            .onJobSelected!(job['id'] as int),
                                        tooltip: "Select Job",
                                      ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
          );
  }
}

// ---------------- Job + Assessment Form Dialog ----------------
class JobFormDialog extends StatefulWidget {
  final Map<String, dynamic>? job;
  final VoidCallback onSaved;
  const JobFormDialog({super.key, this.job, required this.onSaved});

  @override
  _JobFormDialogState createState() => _JobFormDialogState();
}

class _JobFormDialogState extends State<JobFormDialog>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  late String title;
  late String description;
  final skillsController = TextEditingController();
  final minExpController = TextEditingController();

  List<Map<String, dynamic>> questions = [];

  late TabController _tabController;
  final AdminService admin = AdminService();

  @override
  void initState() {
    super.initState();
    title = widget.job?['title'] ?? '';
    description = widget.job?['description'] ?? '';
    skillsController.text = (widget.job?['required_skills'] ?? []).join(", ");
    minExpController.text = (widget.job?['min_experience'] ?? 0).toString();

    if (widget.job != null &&
        widget.job!['assessment_pack'] != null &&
        widget.job!['assessment_pack']['questions'] != null) {
      questions = List<Map<String, dynamic>>.from(
          widget.job!['assessment_pack']['questions']);
    }

    _tabController = TabController(length: 2, vsync: this);
  }

  void addQuestion() {
    setState(() {
      questions.add({
        "question": "",
        "options": ["", "", "", ""],
        "answer": 0,
        "weight": 1,
      });
    });
  }

  Future<void> saveJob() async {
    if (!_formKey.currentState!.validate()) return;

    final skills = skillsController.text
        .split(",")
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();

    final jobData = {
      'title': title,
      'description': description,
      'required_skills': skills,
      'min_experience': double.tryParse(minExpController.text) ?? 0,
      'weightings': {'cv': 60, 'assessment': 40},
      'assessment_pack': {
        'questions': questions.map((q) {
          return {
            "question": q["question"],
            "options": q["options"],
            "correct_answer": q["answer"],
            "weight": q["weight"] ?? 1
          };
        }).toList()
      },
    };

    try {
      if (widget.job == null) {
        await admin.createJob(jobData);
      } else {
        await admin.updateJob(widget.job!['id'] as int, jobData);
      }
      widget.onSaved();
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Error saving job: $e")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      contentPadding: const EdgeInsets.all(0),
      content: SizedBox(
        width: 600,
        height: 500,
        child: Column(
          children: [
            TabBar(
              controller: _tabController,
              tabs: const [
                Tab(text: "Job Details"),
                Tab(text: "Assessment"),
              ],
              labelColor: Colors.red,
              unselectedLabelColor: Colors.black54,
              indicatorColor: Colors.red,
            ),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Form(
                      key: _formKey,
                      child: SingleChildScrollView(
                        child: Column(
                          children: [
                            CustomTextField(
                              label: "Title",
                              initialValue: title,
                              hintText: "Enter job title",
                              onChanged: (v) => title = v,
                              validator: (v) =>
                                  v == null || v.isEmpty ? "Enter title" : null,
                            ),
                            const SizedBox(height: 16),
                            CustomTextField(
                              label: "Description",
                              initialValue: description,
                              hintText: "Enter job description",
                              maxLines: 4,
                              onChanged: (v) => description = v,
                              validator: (v) => v == null || v.isEmpty
                                  ? "Enter description"
                                  : null,
                            ),
                            const SizedBox(height: 16),
                            CustomTextField(
                              label: "Required Skills (comma separated)",
                              hintText: "Flutter, Dart, Firebase",
                              controller: skillsController,
                              validator: (v) => v == null || v.isEmpty
                                  ? "Enter skills"
                                  : null,
                            ),
                            const SizedBox(height: 16),
                            CustomTextField(
                              label: "Minimum Experience (years)",
                              hintText: "0",
                              controller: minExpController,
                              inputType: TextInputType.number,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        Expanded(
                          child: ListView.builder(
                            itemCount: questions.length,
                            itemBuilder: (_, index) {
                              final q = questions[index];
                              return Card(
                                margin: const EdgeInsets.symmetric(vertical: 8),
                                child: Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Column(
                                    children: [
                                      TextFormField(
                                        decoration: const InputDecoration(
                                            labelText: "Question"),
                                        initialValue: q["question"],
                                        onChanged: (v) => q["question"] = v,
                                      ),
                                      ...List.generate(4, (i) {
                                        return TextFormField(
                                          decoration: InputDecoration(
                                              labelText: "Option ${i + 1}"),
                                          initialValue: q["options"][i],
                                          onChanged: (v) => q["options"][i] = v,
                                        );
                                      }),
                                      DropdownButton<int>(
                                        value: q["answer"],
                                        items: List.generate(
                                          4,
                                          (i) => DropdownMenuItem(
                                            value: i,
                                            child: Text(
                                                "Correct: Option ${i + 1}"),
                                          ),
                                        ),
                                        onChanged: (v) =>
                                            setState(() => q["answer"] = v!),
                                      ),
                                      TextFormField(
                                        decoration: const InputDecoration(
                                            labelText: "Weight"),
                                        initialValue: q["weight"].toString(),
                                        keyboardType: TextInputType.number,
                                        onChanged: (v) => q["weight"] =
                                            double.tryParse(v) ?? 1,
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 8),
                        CustomButton(
                            text: "Add Question", onPressed: addQuestion),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text("Cancel")),
                  const SizedBox(width: 8),
                  CustomButton(text: "Save Job", onPressed: saveJob),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
