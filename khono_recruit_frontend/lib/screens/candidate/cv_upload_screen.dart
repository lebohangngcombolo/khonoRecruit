import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../../services/candidate_service.dart';
import '../../models/api_response.dart';
import '../../constants/api_endpoints.dart';
import 'package:http/http.dart' as http;

class CVUploadScreen extends StatefulWidget {
  final String token;

  const CVUploadScreen({super.key, required this.token});

  @override
  _CVUploadScreenState createState() => _CVUploadScreenState();
}

class _CVUploadScreenState extends State<CVUploadScreen> {
  bool _loading = false;
  double _progress = 0.0;
  String? _fileName;

  Future<void> _pickAndUploadCV() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'doc', 'docx'],
      withData: true, // Important for web
    );

    if (result != null && result.files.single.bytes != null) {
      if (result.files.single.size > 5 * 1024 * 1024) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("File too large (max 5MB)")),
        );
        return;
      }

      setState(() {
        _fileName = result.files.single.name;
        _loading = true;
      });

      try {
        final fileBytes = result.files.single.bytes!;
        final fileName = result.files.single.name;

        // Multipart request
        var request = http.MultipartRequest(
          'POST',
          Uri.parse(ApiEndpoints.baseUrl + ApiEndpoints.uploadCV),
        );
        request.headers["Authorization"] = "Bearer ${widget.token}";
        request.files.add(http.MultipartFile.fromBytes(
          'cv',
          fileBytes,
          filename: fileName,
        ));

        final streamedResponse = await request.send();
        final res = await http.Response.fromStream(streamedResponse);

        // ✅ Use fromHttp instead of fromMap
        final apiRes = ApiResponse.fromHttp(res, (data) => data);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(apiRes.message),
            backgroundColor: apiRes.success ? Colors.green : Colors.red,
          ),
        );

        if (!apiRes.success && apiRes.code == 401) {
          Navigator.of(context).pushReplacementNamed('/login');
        }
      } catch (e) {
        String message = e.toString().contains("SocketException")
            ? "No internet connection. Please check your network."
            : "Something went wrong. Please try again.";
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message), backgroundColor: Colors.red),
        );
      } finally {
        setState(() => _loading = false);
      }
    }
  }

  Widget _buildProgressIndicator() {
    if (!_loading) return const SizedBox.shrink();
    return Column(
      children: [
        const SizedBox(height: 12),
        LinearProgressIndicator(
          value: _progress,
          color: Colors.redAccent,
          backgroundColor: Colors.red[100],
        ),
        const SizedBox(height: 12),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Upload CV"),
        backgroundColor: Colors.redAccent,
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.redAccent, Colors.deepOrange],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
              child: Card(
                elevation: 8,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                color: Colors.white,
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.upload_file,
                          size: 50, color: Colors.redAccent),
                      const SizedBox(height: 15),
                      Text(
                        _fileName ?? "No file selected",
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      _buildProgressIndicator(),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _loading ? null : _pickAndUploadCV,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.redAccent,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: _loading
                              ? Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: const [
                                    SizedBox(
                                      height: 20,
                                      width: 20,
                                      child: CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 2,
                                      ),
                                    ),
                                    SizedBox(width: 12),
                                    Text("Uploading CV..."),
                                  ],
                                )
                              : Text(
                                  _fileName == null
                                      ? "Pick & Upload CV"
                                      : "Upload Another CV",
                                  style: const TextStyle(fontSize: 16),
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
