import 'package:flutter/material.dart';
import '../../services/candidate_service.dart';
import '../../models/user_model.dart';

class ProfileScreen extends StatefulWidget {
  final String token;

  const ProfileScreen({super.key, required this.token});

  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _loading = true;
  User? _profile;
  final _formKey = GlobalKey<FormState>();
  final Map<String, dynamic> _formData = {};

  // Skills tag input controller
  final TextEditingController _skillController = TextEditingController();
  List<String> _skills = [];

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  /// Fetch candidate profile
  Future<void> _loadProfile() async {
    setState(() => _loading = true);
    try {
      final profile = await CandidateService.getProfile(widget.token);

      if (profile != null) {
        setState(() {
          _profile = profile;
          _formData.addAll(_profile!.toMap());

          // Populate skills list if available
          if (_formData['skills'] != null && _formData['skills'] is String) {
            _skills = (_formData['skills'] as String)
                .split(',')
                .map((s) => s.trim())
                .toList();
          }
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Failed to load profile: Unknown error')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load profile: $e')),
      );
    } finally {
      setState(() => _loading = false);
    }
  }

  /// Update candidate profile
  Future<void> _updateProfile() async {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();

    // Convert skills list to comma-separated string
    _formData['skills'] = _skills.join(', ');

    setState(() => _loading = true);

    try {
      final response =
          await CandidateService.updateProfile(widget.token, _formData);

      if (response.success) {
        await _loadProfile();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated!')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Update failed: ${response.message}')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Update failed: $e')),
      );
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.redAccent,
        title: const Text("Profile"),
        centerTitle: true,
      ),
      drawer: _buildDrawer(),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _profile == null
              ? const Center(child: Text('Profile not found'))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      _buildHeader(),
                      const SizedBox(height: 24),
                      _buildProfileForm(),
                    ],
                  ),
                ),
    );
  }

  /// Gradient header
  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 32),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Colors.redAccent, Colors.deepOrangeAccent],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          const CircleAvatar(
            radius: 50,
            backgroundColor: Colors.white,
            child: Icon(Icons.person, size: 50, color: Colors.redAccent),
          ),
          const SizedBox(height: 12),
          Text(
            _profile?.name ?? '',
            style: const TextStyle(
                color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            _profile?.email ?? '',
            style: const TextStyle(color: Colors.white70),
          ),
        ],
      ),
    );
  }

  /// Profile form with extended fields
  Widget _buildProfileForm() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              _buildTextField("Name", _profile?.name ?? '',
                  (val) => _formData['name'] = val),
              const SizedBox(height: 16),
              _buildTextField("Email", _profile?.email ?? '',
                  (val) => _formData['email'] = val),
              const SizedBox(height: 16),
              _buildTextField("Phone", _profile?.phone ?? '',
                  (val) => _formData['phone'] = val),
              const SizedBox(height: 16),
              _buildTextField("Education", _formData['education'] ?? '',
                  (val) => _formData['education'] = val,
                  maxLines: 3),
              const SizedBox(height: 16),
              _buildTextField("Experience", _formData['experience'] ?? '',
                  (val) => _formData['experience'] = val,
                  maxLines: 4),
              const SizedBox(height: 16),
              _buildSkillsField(),
              const SizedBox(height: 16),
              _buildDynamicListField(
                  "Certificates",
                  _formData['certificates'] ?? [],
                  (list) => _formData['certificates'] = list),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _updateProfile,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.redAccent,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _loading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text("Update Profile",
                          style: TextStyle(fontSize: 16)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Skills input as tags
  Widget _buildSkillsField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Skills", style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: _skills
              .map((skill) => Chip(
                    label: Text(skill),
                    onDeleted: () {
                      setState(() {
                        _skills.remove(skill);
                      });
                    },
                  ))
              .toList(),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _skillController,
                decoration: const InputDecoration(
                  hintText: "Add a skill",
                  border: OutlineInputBorder(),
                ),
              ),
            ),
            const SizedBox(width: 8),
            ElevatedButton(
              onPressed: () {
                if (_skillController.text.isNotEmpty) {
                  setState(() {
                    _skills.add(_skillController.text.trim());
                    _skillController.clear();
                  });
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text("Add"),
            ),
          ],
        ),
      ],
    );
  }

  /// Dynamic list input (Certificates)
  Widget _buildDynamicListField(
      String label, List<dynamic> items, Function(List<dynamic>) onSaved) {
    final controller = TextEditingController();
    List<String> itemList = List<String>.from(items);

    return StatefulBuilder(builder: (context, setState) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: itemList
                .map((item) => Chip(
                      label: Text(item),
                      onDeleted: () {
                        setState(() {
                          itemList.remove(item);
                          onSaved(itemList);
                        });
                      },
                    ))
                .toList(),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: controller,
                  decoration: InputDecoration(
                    hintText: "Add a certificate",
                    border: const OutlineInputBorder(),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: () {
                  if (controller.text.isNotEmpty) {
                    setState(() {
                      itemList.add(controller.text);
                      onSaved(itemList);
                      controller.clear();
                    });
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.redAccent,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text("Add"),
              ),
            ],
          ),
        ],
      );
    });
  }

  /// Drawer
  Drawer _buildDrawer() {
    return Drawer(
      child: Column(
        children: [
          DrawerHeader(
            decoration: const BoxDecoration(color: Colors.redAccent),
            child: Align(
              alignment: Alignment.bottomLeft,
              child: Text(
                "Hello, ${_profile?.name ?? 'Candidate'}!",
                style: const TextStyle(
                    fontSize: 22,
                    color: Colors.white,
                    fontWeight: FontWeight.bold),
              ),
            ),
          ),
          _buildDrawerItem(Icons.person, "Profile", '/candidate/profile'),
          _buildDrawerItem(
              Icons.upload_file, "Upload CV", '/candidate/cv_upload'),
          _buildDrawerItem(Icons.work, "Jobs", '/candidate/jobs'),
          _buildDrawerItem(
              Icons.assignment, "Assessments", '/candidate/assessment'),
          const Spacer(),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.redAccent),
            title: const Text("Logout"),
            onTap: () {
              Navigator.pushReplacementNamed(context, '/login');
            },
          ),
        ],
      ),
    );
  }

  ListTile _buildDrawerItem(IconData icon, String title, String route) {
    return ListTile(
      leading: Icon(icon, color: Colors.redAccent),
      title: Text(title),
      onTap: () {
        Navigator.pushNamed(context, route, arguments: widget.token);
      },
    );
  }

  /// Multi-line text field helper
  Widget _buildTextField(
      String label, String initialValue, Function(String) onSaved,
      {int maxLines = 1}) {
    return TextFormField(
      initialValue: initialValue,
      maxLines: maxLines,
      decoration:
          InputDecoration(labelText: label, border: const OutlineInputBorder()),
      validator: (val) => val == null || val.isEmpty ? 'Enter $label' : null,
      onSaved: (val) => onSaved(val!),
    );
  }
}
