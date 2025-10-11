import 'package:flutter/material.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_textfield.dart';
import '../../services/admin_service.dart';

class JobModal extends StatefulWidget {
  final String token;
  final Map<String, dynamic>? job;
  final VoidCallback onSaved;

  const JobModal(
      {super.key, required this.token, this.job, required this.onSaved});

  @override
  State<JobModal> createState() => _JobModalState();
}

class _JobModalState extends State<JobModal> {
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  final _skillsController = TextEditingController();
  bool loading = false;

  @override
  void initState() {
    super.initState();
    if (widget.job != null) {
      _titleController.text = widget.job!['title'] ?? '';
      _descController.text = widget.job!['description'] ?? '';
      _skillsController.text =
          (widget.job!['required_skills'] ?? []).join(", ");
    }
  }

  void saveJob() async {
    setState(() => loading = true);
    final service = AdminService();
    final data = {
      "title": _titleController.text,
      "description": _descController.text,
      "required_skills":
          _skillsController.text.split(",").map((e) => e.trim()).toList(),
    };

    try {
      if (widget.job == null) {
        await service.createJob(data); // no token needed
      } else {
        await service.updateJob(widget.job!['id'], data); // no token needed
      }
      widget.onSaved();
      Navigator.pop(context);
    } catch (e) {
      setState(() => loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.job == null ? "Create Job" : "Update Job"),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CustomTextField(label: "Title", controller: _titleController),
          const SizedBox(height: 8),
          CustomTextField(label: "Description", controller: _descController),
          const SizedBox(height: 8),
          CustomTextField(
              label: "Skills (comma-separated)", controller: _skillsController),
        ],
      ),
      actions: [
        CustomButton(
          text: loading ? "Saving..." : "Save",
          onPressed: loading ? null : saveJob,
        ),
      ],
    );
  }
}
