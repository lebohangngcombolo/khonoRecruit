import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import '../../constants/app_colors.dart';
import '../../services/auth_service.dart';
import '../../utils/api_endpoints.dart';
import '../../widgets/widgets1/glass_card.dart';

class HmProfilePage extends StatefulWidget {
  const HmProfilePage({super.key});

  @override
  State<HmProfilePage> createState() => _HmProfilePageState();
}

class _HmProfilePageState extends State<HmProfilePage> {
  Map<String, dynamic> _userData = {};
  bool _isLoading = true;
  String _error = '';
  File? _imageFile;
  bool _isEditing = false;

  final ImagePicker _picker = ImagePicker();
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _emailController = TextEditingController();
    _phoneController = TextEditingController();
    _loadUserData();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    setState(() {
      _isLoading = true;
      _error = '';
    });
    try {
      final user = await AuthService.getUserInfo();
      if (user != null) {
        setState(() {
          _userData = {
            'name': user['name'] ?? user['email']?.split('@')[0] ?? 'Hiring Manager',
            'email': user['email'] ?? 'hiring.manager@khonology.com',
            'role': user['role'] ?? 'hiring_manager',
            'phone': user['phone'] ?? '+27 12 345 6789',
          };
          _nameController.text = _userData['name'] ?? '';
          _emailController.text = _userData['email'] ?? '';
          _phoneController.text = _userData['phone'] ?? '';
        });
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 85,
      );
      if (image != null) {
        setState(() {
          _imageFile = File(image.path);
        });
        await _uploadProfilePicture(_imageFile!);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to pick image: $e'),
          backgroundColor: AppColors.statusError,
        ),
      );
    }
  }

  Future<void> _uploadProfilePicture(File file) async {
    try {
      final token = await AuthService.getAccessToken();
      final uri = Uri.parse("${ApiEndpoints.adminBase}/profile/upload_profile_picture");
      final request = http.MultipartRequest('POST', uri);
      request.headers['Authorization'] = 'Bearer $token';
      request.files.add(await http.MultipartFile.fromPath('image', file.path));

      final response = await request.send();
      final respStr = await response.stream.bytesToString();
      final respJson = json.decode(respStr);

      if (response.statusCode == 200 && (respJson['success'] == true || respJson['data'] != null)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile picture updated'),
            backgroundColor: AppColors.statusSuccess,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to upload image: ${response.statusCode}'),
            backgroundColor: AppColors.statusError,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to upload image: $e'),
          backgroundColor: AppColors.statusError,
        ),
      );
    }
  }

  Future<void> _saveProfile() async {
    setState(() {
      _isLoading = true;
    });
    try {
      final token = await AuthService.getAccessToken();
      final uri = Uri.parse("${ApiEndpoints.adminBase}/profile");
      final res = await http.put(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'name': _nameController.text,
          'email': _emailController.text,
          'phone': _phoneController.text,
        }),
      );

      if (res.statusCode == 200) {
        setState(() {
          _userData['name'] = _nameController.text;
          _userData['email'] = _emailController.text;
          _userData['phone'] = _phoneController.text;
          _isEditing = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile updated successfully'),
            backgroundColor: AppColors.statusSuccess,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update profile: ${res.body}'),
            backgroundColor: AppColors.statusError,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to update profile: $e'),
          backgroundColor: AppColors.statusError,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return _isLoading
        ? const Center(
            child: CircularProgressIndicator(color: AppColors.primaryRed))
        : _error.isNotEmpty
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline,
                        size: 64, color: AppColors.statusError),
                    const SizedBox(height: 16),
                    Text('Error: $_error',
                        style: const TextStyle(color: Colors.white)),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _loadUserData,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryRed,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              )
            : SingleChildScrollView(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'My Profile',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            shadows: [
                              Shadow(
                                color: Colors.black54,
                                blurRadius: 8,
                                offset: Offset(0, 2),
                              )
                            ],
                          ),
                        ),
                        if (!_isEditing)
                          ElevatedButton.icon(
                            onPressed: () {
                              setState(() {
                                _isEditing = true;
                              });
                            },
                            icon: const Icon(Icons.edit, size: 18),
                            label: const Text('Edit'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primaryRed,
                              foregroundColor: Colors.white,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Profile Card
                    GlassCard(
                      blur: 8,
                      opacity: 0.1,
                      child: Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Column(
                          children: [
                            // Profile Picture Section
                            Stack(
                              children: [
                                CircleAvatar(
                                  radius: 60,
                                  backgroundColor: AppColors.primaryRed.withValues(alpha: 0.2),
                                  backgroundImage: _imageFile != null
                                      ? FileImage(_imageFile!)
                                      : null,
                                  child: _imageFile == null
                                      ? Text(
                                          _userData['name']
                                                  ?.substring(0, 2)
                                                  .toUpperCase() ??
                                              'HM',
                                          style: const TextStyle(
                                            fontSize: 36,
                                            fontWeight: FontWeight.bold,
                                            color: AppColors.primaryRed,
                                          ),
                                        )
                                      : null,
                                ),
                                Positioned(
                                  bottom: 0,
                                  right: 0,
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: AppColors.primaryRed,
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                          color: Colors.white, width: 3),
                                    ),
                                    child: IconButton(
                                      icon: const Icon(Icons.camera_alt,
                                          color: Colors.white, size: 20),
                                      onPressed: _pickImage,
                                      tooltip: 'Change profile picture',
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 32),

                            // Profile Fields
                            if (_isEditing) ...[
                              _buildEditableField(
                                label: 'Full Name',
                                controller: _nameController,
                                icon: Icons.person,
                              ),
                              const SizedBox(height: 16),
                              _buildEditableField(
                                label: 'Email',
                                controller: _emailController,
                                icon: Icons.email,
                                enabled: false, // Email usually can't be changed
                              ),
                              const SizedBox(height: 16),
                              _buildReadOnlyField(
                                label: 'Role',
                                value: _userData['role']
                                        ?.toString()
                                        .replaceAll('_', ' ')
                                        .toUpperCase() ??
                                    'HIRING MANAGER',
                                icon: Icons.badge,
                              ),
                              const SizedBox(height: 16),
                              _buildEditableField(
                                label: 'Phone',
                                controller: _phoneController,
                                icon: Icons.phone,
                              ),
                              const SizedBox(height: 24),
                              Row(
                                children: [
                                  Expanded(
                                    child: ElevatedButton(
                                      onPressed: () {
                                        setState(() {
                                          _isEditing = false;
                                          // Reset controllers
                                          _nameController.text =
                                              _userData['name'] ?? '';
                                          _emailController.text =
                                              _userData['email'] ?? '';
                                          _phoneController.text =
                                              _userData['phone'] ?? '';
                                        });
                                      },
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.grey[700],
                                        foregroundColor: Colors.white,
                                        padding: const EdgeInsets.symmetric(
                                            vertical: 16),
                                      ),
                                      child: const Text('Cancel'),
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: ElevatedButton(
                                      onPressed: _saveProfile,
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: AppColors.primaryRed,
                                        foregroundColor: Colors.white,
                                        padding: const EdgeInsets.symmetric(
                                            vertical: 16),
                                      ),
                                      child: const Text('Save Changes'),
                                    ),
                                  ),
                                ],
                              ),
                            ] else ...[
                              _buildReadOnlyField(
                                label: 'Full Name',
                                value: _userData['name'] ?? 'N/A',
                                icon: Icons.person,
                              ),
                              const SizedBox(height: 16),
                              _buildReadOnlyField(
                                label: 'Email',
                                value: _userData['email'] ?? 'N/A',
                                icon: Icons.email,
                              ),
                              const SizedBox(height: 16),
                              _buildReadOnlyField(
                                label: 'Role',
                                value: _userData['role']
                                        ?.toString()
                                        .replaceAll('_', ' ')
                                        .toUpperCase() ??
                                    'HIRING MANAGER',
                                icon: Icons.badge,
                              ),
                              const SizedBox(height: 16),
                              _buildReadOnlyField(
                                label: 'Phone',
                                value: _userData['phone'] ?? 'N/A',
                                icon: Icons.phone,
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              );
  }

  Widget _buildEditableField({
    required String label,
    required TextEditingController controller,
    required IconData icon,
    bool enabled = true,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.white70,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          enabled: enabled,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            filled: true,
            fillColor: enabled
                ? Colors.white.withValues(alpha: 0.1)
                : Colors.white.withValues(alpha: 0.05),
            prefixIcon: Icon(icon, color: AppColors.primaryRed),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide:
                  BorderSide(color: AppColors.primaryRed.withValues(alpha: 0.3)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide:
                  BorderSide(color: AppColors.primaryRed.withValues(alpha: 0.3)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.primaryRed, width: 2),
            ),
            disabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildReadOnlyField({
    required String label,
    required String value,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.primaryRed.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.primaryRed.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: AppColors.primaryRed, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.white60,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
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
