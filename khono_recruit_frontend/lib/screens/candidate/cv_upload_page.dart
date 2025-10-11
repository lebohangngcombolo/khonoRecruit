import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../services/auth_service.dart';
import 'assessments_results_screen.dart';

class CVUploadScreen extends StatefulWidget {
  final int applicationId;
  const CVUploadScreen({super.key, required this.applicationId});

  @override
  State<CVUploadScreen> createState() => _CVUploadScreenState();
}

class _CVUploadScreenState extends State<CVUploadScreen> {
  Uint8List? selectedFileBytes;
  String? selectedFileName;
  TextEditingController resumeTextController = TextEditingController();
  bool uploading = false;
  String? token;

  @override
  void initState() {
    super.initState();
    _loadToken();
  }

  Future<void> _loadToken() async {
    final t = await AuthService.getAccessToken();
    setState(() {
      token = t;
    });
  }

  Future<void> _pickFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        allowMultiple: false,
        type: FileType.any,
        withData: true,
      );

      if (result != null && result.files.isNotEmpty) {
        final f = result.files.single;
        setState(() {
          selectedFileBytes = f.bytes;
          selectedFileName = f.name;
        });
      } else {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text("No file selected")));
      }
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Error picking file: $e")));
    }
  }

  Future<void> _uploadCV() async {
    if ((selectedFileBytes == null || selectedFileName == null) ||
        token == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text("Please select a file and ensure you're logged in.")));
      return;
    }

    setState(() => uploading = true);

    try {
      final uri = Uri.parse(
          'http://127.0.0.1:5000/api/candidate/upload_resume/${widget.applicationId}');

      final request = http.MultipartRequest('POST', uri);
      request.headers['Authorization'] = 'Bearer $token';
      request.files.add(
        http.MultipartFile.fromBytes(
          'resume',
          selectedFileBytes!,
          filename: selectedFileName!,
        ),
      );
      request.fields['resume_text'] = resumeTextController.text;

      final streamedResponse = await request.send();
      final responseString = await streamedResponse.stream.bytesToString();
      final resp = json.decode(responseString);

      if (streamedResponse.statusCode == 200 ||
          streamedResponse.statusCode == 201) {
        final matchScore = resp['parser_result']?['match_score'] ??
            resp['parser_result']?['score'] ??
            'N/A';
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Resume uploaded! CV Score: $matchScore")));

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => AssessmentResultsPage(
              token: token!,
              applicationId: widget.applicationId,
            ),
          ),
        );
      } else {
        final err = resp['error'] ?? resp['message'] ?? 'Upload failed';
        throw Exception(err);
      }
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Error uploading CV: $e")));
    } finally {
      setState(() => uploading = false);
    }
  }

  @override
  void dispose() {
    resumeTextController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final fileLabel = selectedFileName ?? 'No file selected';

    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 700),
            child: Card(
              color: Colors.white,
              elevation: 4,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: const BorderSide(color: Colors.red, width: 1)),
              margin: const EdgeInsets.all(16),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.upload_file, size: 60, color: Colors.red),
                    const SizedBox(height: 12),
                    const Text(
                      "Upload Your Resume",
                      style:
                          TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      "Select your CV file and optionally paste the text content for analysis.",
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.black87),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _pickFile,
                            icon: const Icon(Icons.folder_open,
                                color: Colors.red),
                            label: const Text("Select File",
                                style: TextStyle(color: Colors.red)),
                            style: OutlinedButton.styleFrom(
                              side: BorderSide(color: Colors.red.shade700),
                              padding: const EdgeInsets.symmetric(
                                  vertical: 14, horizontal: 16),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            fileLabel,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                fontStyle: FontStyle.italic,
                                color: Colors.black87),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: resumeTextController,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12)),
                        labelText: "Paste your CV text (optional)",
                        labelStyle: const TextStyle(color: Colors.black54),
                        contentPadding: const EdgeInsets.all(12),
                        filled: true,
                        fillColor: Colors.grey[200],
                      ),
                      style: const TextStyle(color: Colors.black87),
                      maxLines: 5,
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: uploading ? null : _uploadCV,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                        child: uploading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                    color: Colors.white, strokeWidth: 2))
                            : const Text("Upload CV & Continue",
                                style: TextStyle(fontSize: 16)),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Supported: PDF/DOC/DOCX/TXT. Max file size depends on server config.',
                      style: TextStyle(color: Colors.black54, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
