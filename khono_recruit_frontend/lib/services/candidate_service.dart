import 'dart:convert';
import 'package:http/http.dart' as http;
import '../utils/api_endpoints.dart';

class CandidateService {
  // ---------- SUBMIT ENROLLMENT ----------
  static Future<Map<String, dynamic>> submitEnrollment(
      Map<String, dynamic> data, String token) async {
    final response = await http.post(
      Uri.parse(ApiEndpoints.enrollment),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token'
      },
      body: jsonEncode(data),
    );
    return jsonDecode(response.body);
  }

  // ----------------- GET AVAILABLE JOBS -----------------
  static Future<List<Map<String, dynamic>>> getAvailableJobs(
      String token) async {
    final response = await http.get(
      Uri.parse("http://127.0.0.1:5000/api/candidate/jobs"),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      // Cast each item to Map<String, dynamic>
      return data
          .map<Map<String, dynamic>>((item) => Map<String, dynamic>.from(item))
          .toList();
    } else {
      throw Exception('Failed to fetch jobs: ${response.statusCode}');
    }
  }

  // ---------- UPLOAD RESUME ----------
  static Future<Map<String, dynamic>> uploadResume(
      int applicationId, String token, String filePath,
      {String? resumeText}) async {
    final uri =
        Uri.parse('${ApiEndpoints.candidateBase}/upload_resume/$applicationId');
    var request = http.MultipartRequest('POST', uri);
    request.headers['Authorization'] = 'Bearer $token';
    request.files.add(await http.MultipartFile.fromPath('resume', filePath));
    if (resumeText != null) {
      request.fields['resume_text'] = resumeText;
    }

    final streamedResponse = await request.send();
    final responseString = await streamedResponse.stream.bytesToString();
    return jsonDecode(responseString);
  }

  // ---------- GET CANDIDATE APPLICATIONS ----------
  static Future<List<dynamic>> getApplications(String token) async {
    final response = await http.get(
      Uri.parse('${ApiEndpoints.candidateBase}/applications'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token'
      },
    );
    return jsonDecode(response.body);
  }

  // ---------- GET ASSESSMENT FOR APPLICATION ----------
  static Future<Map<String, dynamic>> getAssessment(
      int applicationId, String token) async {
    final response = await http.get(
      Uri.parse(
          '${ApiEndpoints.candidateBase}/applications/$applicationId/assessment'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token'
      },
    );
    return jsonDecode(response.body);
  }

  // ---------- SUBMIT ASSESSMENT ----------
  static Future<Map<String, dynamic>> submitAssessment(
      int applicationId, Map<String, dynamic> answers, String token) async {
    final response = await http.post(
      Uri.parse(
          '${ApiEndpoints.candidateBase}/applications/$applicationId/assessment'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token'
      },
      body: jsonEncode({'answers': answers}),
    );
    return jsonDecode(response.body);
  }
}
