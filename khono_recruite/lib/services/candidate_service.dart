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

  // ---------- GET NOTIFICATIONS ----------
  static Future<List<Map<String, dynamic>>> getNotifications(
      String token) async {
    final response = await http.get(
      Uri.parse("${ApiEndpoints.candidateBase}/notifications"),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data
          .map<Map<String, dynamic>>((item) => Map<String, dynamic>.from(item))
          .toList();
    } else {
      throw Exception('Failed to fetch notifications: ${response.statusCode}');
    }
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

  static Future<Map<String, dynamic>> getProfile(String token) async {
    final response = await http.get(
      Uri.parse('${ApiEndpoints.candidateBase}/profile'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body)['data'];

      final user = data['user'] ?? {};
      final candidate = data['candidate'] ?? {};

      // Merge user and candidate into a single map if needed
      return {
        'user': user,
        'candidate': candidate,
      };
    } else {
      throw Exception('Failed to fetch profile: ${response.statusCode}');
    }
  }

  /// Save or update a draft for a specific job application
  static Future<Map<String, dynamic>> saveDraft(
      int jobId, Map<String, dynamic> draftData, String token) async {
    final response = await http.post(
      Uri.parse('${ApiEndpoints.candidateBase}/apply/save_draft/$jobId'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({'draft_data': draftData}),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to save draft: ${response.body}');
    }
  }

  /// Retrieve all saved drafts for the logged-in candidate
  static Future<List<Map<String, dynamic>>> getDrafts(String token) async {
    final response = await http.get(
      Uri.parse('${ApiEndpoints.candidateBase}/applications/drafts'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data
          .map<Map<String, dynamic>>((item) => Map<String, dynamic>.from(item))
          .toList();
    } else {
      throw Exception('Failed to fetch drafts: ${response.statusCode}');
    }
  }

  /// Submit a saved draft as a finalized application
  static Future<Map<String, dynamic>> submitDraft(
      int draftId, String token) async {
    final response = await http.put(
      Uri.parse(
          '${ApiEndpoints.candidateBase}/applications/submit_draft/$draftId'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to submit draft: ${response.body}');
    }
  }
}
