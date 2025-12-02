import 'dart:convert';
import 'package:http/http.dart' as http;
import '../utils/api_endpoints.dart';
import 'auth_service.dart';

class AdminService {
  final Map<String, String> headers = {'Content-Type': 'application/json'};

  // ---------- JOBS ----------
  Future<List<dynamic>> listJobs() async {
    final token = await AuthService.getAccessToken();
    final res = await http.get(
      Uri.parse(ApiEndpoints.adminJobs),
      headers: {...headers, 'Authorization': 'Bearer $token'},
    );
    if (res.statusCode == 200) return json.decode(res.body);
    throw Exception('Failed to load jobs: ${res.body}');
  }

  Future<Map<String, dynamic>> createJob(Map<String, dynamic> data) async {
    final token = await AuthService.getAccessToken();
    final res = await http.post(
      Uri.parse(ApiEndpoints.adminJobs),
      headers: {...headers, 'Authorization': 'Bearer $token'},
      body: json.encode(data),
    );
    if (res.statusCode == 201) return json.decode(res.body);
    throw Exception('Failed to create job: ${res.body}');
  }

  Future<Map<String, dynamic>> updateJob(
      int jobId, Map<String, dynamic> data) async {
    final token = await AuthService.getAccessToken();
    final res = await http.put(
      Uri.parse('${ApiEndpoints.adminJobs}/$jobId'),
      headers: {...headers, 'Authorization': 'Bearer $token'},
      body: json.encode(data),
    );
    if (res.statusCode == 200) return json.decode(res.body);
    throw Exception('Failed to update job: ${res.body}');
  }

  Future<void> deleteJob(int jobId) async {
    final token = await AuthService.getAccessToken();
    final res = await http.delete(
      Uri.parse('${ApiEndpoints.adminJobs}/$jobId'),
      headers: {...headers, 'Authorization': 'Bearer $token'},
    );
    if (res.statusCode != 200)
      throw Exception('Failed to delete job: ${res.body}');
  }

  // ---------- CANDIDATES ----------
  Future<List<dynamic>> listCandidates() async {
    final token = await AuthService.getAccessToken();
    final res = await http.get(
      Uri.parse('${ApiEndpoints.adminBase}/candidates'),
      headers: {...headers, 'Authorization': 'Bearer $token'},
    );
    if (res.statusCode == 200) return json.decode(res.body);
    throw Exception('Failed to fetch candidates: ${res.body}');
  }

  Future<Map<String, dynamic>> getApplication(int applicationId) async {
    final token = await AuthService.getAccessToken();
    final res = await http.get(
      Uri.parse('${ApiEndpoints.adminBase}/applications/$applicationId'),
      headers: {...headers, 'Authorization': 'Bearer $token'},
    );
    if (res.statusCode == 200) return json.decode(res.body);
    throw Exception('Failed to fetch application: ${res.body}');
  }

  Future<List<dynamic>> shortlistCandidates(int jobId) async {
    final token = await AuthService.getAccessToken();
    final res = await http.get(
      Uri.parse('${ApiEndpoints.adminJobs}/$jobId/shortlist'),
      headers: {...headers, 'Authorization': 'Bearer $token'},
    );
    if (res.statusCode == 200) return json.decode(res.body);
    throw Exception('Failed to fetch shortlisted candidates: ${res.body}');
  }

  // ---------- INTERVIEWS ----------
  Future<Map<String, dynamic>> scheduleInterview(
      Map<String, dynamic> data) async {
    final token = await AuthService.getAccessToken();
    final res = await http.post(
      Uri.parse('${ApiEndpoints.adminJobs}/interviews'),
      headers: {...headers, 'Authorization': 'Bearer $token'},
      body: json.encode(data),
    );
    if (res.statusCode == 201) return json.decode(res.body);
    throw Exception('Failed to schedule interview: ${res.body}');
  }

  Future<List<Map<String, dynamic>>> getAllInterviews() async {
    final token = await AuthService.getAccessToken();
    final res = await http.get(
      Uri.parse("${ApiEndpoints.adminBase}/interviews"),
      headers: {...headers, 'Authorization': 'Bearer $token'},
    );
    if (res.statusCode == 200) {
      return List<Map<String, dynamic>>.from(jsonDecode(res.body));
    } else {
      throw Exception("Failed to fetch interviews: ${res.body}");
    }
  }

  Future<void> cancelInterview(int interviewId) async {
    final token = await AuthService.getAccessToken();
    final res = await http.delete(
      Uri.parse("${ApiEndpoints.adminBase}/interviews/$interviewId"),
      headers: {...headers, 'Authorization': 'Bearer $token'},
    );
    if (res.statusCode != 200)
      throw Exception("Failed to cancel interview: ${res.body}");
  }

  // ---------- CANDIDATE INTERVIEWS ----------
  /// Get all interviews for a specific candidate
  Future<List<Map<String, dynamic>>> getCandidateInterviews(
      int candidateId) async {
    final token = await AuthService.getAccessToken();
    final res = await http.get(
      Uri.parse(
          "${ApiEndpoints.adminBase}/interviews?candidate_id=$candidateId"),
      headers: {...headers, 'Authorization': 'Bearer $token'},
    );
    if (res.statusCode == 200) {
      return List<Map<String, dynamic>>.from(json.decode(res.body));
    } else {
      throw Exception("Failed to fetch candidate interviews: ${res.body}");
    }
  }

  Future<Map<String, dynamic>> getDashboardCounts() async {
    final token = await AuthService.getAccessToken();
    final res = await http.get(
      Uri.parse("${ApiEndpoints.adminBase}/dashboard-counts"),
      headers: {...headers, 'Authorization': 'Bearer $token'},
    );

    if (res.statusCode == 200) {
      return Map<String, dynamic>.from(json.decode(res.body));
    } else {
      throw Exception("Failed to fetch dashboard counts: ${res.body}");
    }
  }

  /// Schedule a new interview for a candidate
  Future<Map<String, dynamic>> scheduleInterviewForCandidate({
    required int candidateId,
    required int applicationId,
    required DateTime scheduledTime,
  }) async {
    final token = await AuthService.getAccessToken();
    final data = {
      "candidate_id": candidateId,
      "application_id": applicationId,
      "scheduled_time": scheduledTime.toIso8601String(),
    };
    final res = await http.post(
      Uri.parse("${ApiEndpoints.adminJobs}/interviews"),
      headers: {...headers, 'Authorization': 'Bearer $token'},
      body: json.encode(data),
    );
    if (res.statusCode == 201) return json.decode(res.body);
    throw Exception("Failed to schedule interview: ${res.body}");
  }

  // ---------- NOTIFICATIONS ----------
  Future<List<Map<String, dynamic>>> getNotifications(int userId) async {
    // Get the saved access token
    final token = await AuthService.getAccessToken();
    if (token == null) {
      throw Exception('User not authenticated');
    }

    // Define headers
    final Map<String, String> requestHeaders = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };

    // Make GET request
    final res = await http.get(
      Uri.parse("${ApiEndpoints.adminBase}/notifications/$userId"),
      headers: requestHeaders,
    );

    if (res.statusCode == 200) {
      final Map<String, dynamic> data = jsonDecode(res.body);

      // Extract the list from 'notifications' key
      final List<dynamic> notificationsList = data['notifications'] ?? [];

      return notificationsList
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
    } else {
      throw Exception('Failed to fetch notifications: ${res.body}');
    }
  }

  // ---------- CV REVIEWS ----------
  Future<List<Map<String, dynamic>>> listCVReviews() async {
    final token = await AuthService.getAccessToken();
    final res = await http.get(
      Uri.parse('${ApiEndpoints.adminBase}/cv-reviews'),
      headers: {...headers, 'Authorization': 'Bearer $token'},
    );

    if (res.statusCode == 200) {
      return List<Map<String, dynamic>>.from(json.decode(res.body));
    }
    throw Exception('Failed to fetch CV reviews: ${res.body}');
  }

// ---------- ASSESSMENTS ----------
  Future<Map<String, dynamic>> updateAssessment(
      int jobId, Map<String, dynamic> data) async {
    final token = await AuthService.getAccessToken();
    final res = await http.put(
      Uri.parse('${ApiEndpoints.adminJobs}/$jobId/assessment'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: json.encode(data),
    );

    if (res.statusCode == 200) return json.decode(res.body);
    throw Exception('Failed to update assessment: ${res.body}');
  }

  // ---------- ANALYTICS ----------
  Future<Map<String, dynamic>> getDashboardStats() async {
    final token = await AuthService.getAccessToken();
    final res = await http.get(
      Uri.parse('${ApiEndpoints.adminBase}/analytics/dashboard'),
      headers: {...headers, 'Authorization': 'Bearer $token'},
    );
    if (res.statusCode == 200) return json.decode(res.body);
    throw Exception('Failed to load dashboard stats: ${res.body}');
  }

  Future<Map<String, dynamic>> getUsersGrowth({int days = 30}) async {
    final token = await AuthService.getAccessToken();
    final res = await http.get(
      Uri.parse('${ApiEndpoints.adminBase}/analytics/users-growth?days=$days'),
      headers: {...headers, 'Authorization': 'Bearer $token'},
    );
    if (res.statusCode == 200) return json.decode(res.body);
    throw Exception('Failed to load users growth data: ${res.body}');
  }

  Future<Map<String, dynamic>> getApplicationsAnalysis() async {
    final token = await AuthService.getAccessToken();
    final res = await http.get(
      Uri.parse('${ApiEndpoints.adminBase}/analytics/applications-analysis'),
      headers: {...headers, 'Authorization': 'Bearer $token'},
    );
    if (res.statusCode == 200) return json.decode(res.body);
    throw Exception('Failed to load applications analysis: ${res.body}');
  }

  Future<Map<String, dynamic>> getInterviewsAnalysis() async {
    final token = await AuthService.getAccessToken();
    final res = await http.get(
      Uri.parse('${ApiEndpoints.adminBase}/analytics/interviews-analysis'),
      headers: {...headers, 'Authorization': 'Bearer $token'},
    );
    if (res.statusCode == 200) return json.decode(res.body);
    throw Exception('Failed to load interviews analysis: ${res.body}');
  }

  Future<Map<String, dynamic>> getAssessmentsAnalysis() async {
    final token = await AuthService.getAccessToken();
    final res = await http.get(
      Uri.parse('${ApiEndpoints.adminBase}/analytics/assessments-analysis'),
      headers: {...headers, 'Authorization': 'Bearer $token'},
    );
    if (res.statusCode == 200) return json.decode(res.body);
    throw Exception('Failed to load assessments analysis: ${res.body}');
  }

  // ---------- SHARED NOTES ----------
  Future<Map<String, dynamic>> createNote(Map<String, dynamic> data) async {
    final token = await AuthService.getAccessToken();
    final res = await http.post(
      Uri.parse(ApiEndpoints.createNote),
      headers: {...headers, 'Authorization': 'Bearer $token'},
      body: json.encode(data),
    );
    if (res.statusCode == 201) return json.decode(res.body);
    throw Exception('Failed to create note: ${res.body}');
  }

  Future<Map<String, dynamic>> getNotes({
    int page = 1,
    int perPage = 20,
    String? search,
    int? authorId,
  }) async {
    final token = await AuthService.getAccessToken();

    // Build query parameters
    final params = {
      'page': page.toString(),
      'per_page': perPage.toString(),
      if (search != null && search.isNotEmpty) 'search': search,
      if (authorId != null) 'author_id': authorId.toString(),
    };

    final uri =
        Uri.parse(ApiEndpoints.getNotes).replace(queryParameters: params);
    final res = await http.get(
      uri,
      headers: {...headers, 'Authorization': 'Bearer $token'},
    );
    if (res.statusCode == 200) return json.decode(res.body);
    throw Exception('Failed to fetch notes: ${res.body}');
  }

  Future<Map<String, dynamic>> getNoteById(int noteId) async {
    final token = await AuthService.getAccessToken();
    final res = await http.get(
      Uri.parse('${ApiEndpoints.getNoteById}/$noteId'),
      headers: {...headers, 'Authorization': 'Bearer $token'},
    );
    if (res.statusCode == 200) return json.decode(res.body);
    throw Exception('Failed to fetch note: ${res.body}');
  }

  Future<Map<String, dynamic>> updateNote(
      int noteId, Map<String, dynamic> data) async {
    final token = await AuthService.getAccessToken();
    final res = await http.put(
      Uri.parse('${ApiEndpoints.updateNote}/$noteId'),
      headers: {...headers, 'Authorization': 'Bearer $token'},
      body: json.encode(data),
    );
    if (res.statusCode == 200) return json.decode(res.body);
    throw Exception('Failed to update note: ${res.body}');
  }

  Future<void> deleteNote(int noteId) async {
    final token = await AuthService.getAccessToken();
    final res = await http.delete(
      Uri.parse('${ApiEndpoints.deleteNote}/$noteId'),
      headers: {...headers, 'Authorization': 'Bearer $token'},
    );
    if (res.statusCode != 200) {
      throw Exception('Failed to delete note: ${res.body}');
    }
  }

// Note: The shareNote endpoint was removed as sharing is handled via participants in the backend
// If you need sharing functionality, you'll need to update the backend or handle it differently

// ---------- MEETINGS ----------
  Future<Map<String, dynamic>> createMeeting(Map<String, dynamic> data) async {
    final token = await AuthService.getAccessToken();
    final res = await http.post(
      Uri.parse(ApiEndpoints.createMeeting),
      headers: {...headers, 'Authorization': 'Bearer $token'},
      body: json.encode(data),
    );

    if (res.statusCode == 201) {
      return json.decode(res.body);
    } else {
      // Try to parse error message from response
      try {
        final errorBody = json.decode(res.body);
        throw Exception(
            errorBody['error'] ?? 'Failed to create meeting: ${res.body}');
      } catch (e) {
        throw Exception('Failed to create meeting: ${res.body}');
      }
    }
  }

  Future<Map<String, dynamic>> getMeetings({
    int page = 1,
    int perPage = 20,
    String? status,
    String? search,
  }) async {
    final token = await AuthService.getAccessToken();

    final params = {
      'page': page.toString(),
      'per_page': perPage.toString(),
      if (status != null && status.isNotEmpty) 'status': status,
      if (search != null && search.isNotEmpty) 'search': search,
    };

    final uri =
        Uri.parse(ApiEndpoints.getMeetings).replace(queryParameters: params);
    final res = await http.get(
      uri,
      headers: {...headers, 'Authorization': 'Bearer $token'},
    );

    if (res.statusCode == 200) {
      final body = json.decode(res.body);
      return {
        "meetings": body["meetings"] ?? [],
        "total": body["total"] ?? 0,
        "pages": body["pages"] ?? 0,
        "current_page": body["current_page"] ?? page,
        "per_page": body["per_page"] ?? perPage,
      };
    } else {
      throw Exception('Failed to fetch meetings: ${res.body}');
    }
  }

  Future<Map<String, dynamic>> getMeetingById(int meetingId) async {
    final token = await AuthService.getAccessToken();
    final res = await http.get(
      Uri.parse('${ApiEndpoints.getMeetingById}/$meetingId'),
      headers: {...headers, 'Authorization': 'Bearer $token'},
    );
    return _handleResponse(res);
  }

  Future<Map<String, dynamic>> updateMeeting(
      int meetingId, Map<String, dynamic> data) async {
    final token = await AuthService.getAccessToken();
    final res = await http.put(
      Uri.parse('${ApiEndpoints.updateMeeting}/$meetingId'),
      headers: {...headers, 'Authorization': 'Bearer $token'},
      body: json.encode(data),
    );
    return _handleResponse(res);
  }

  Future<void> cancelMeeting(int meetingId) async {
    final token = await AuthService.getAccessToken();
    final res = await http.post(
      Uri.parse('${ApiEndpoints.cancelMeeting}/$meetingId'),
      headers: {...headers, 'Authorization': 'Bearer $token'},
    );
    if (res.statusCode != 200) {
      throw Exception('Failed to cancel meeting: ${res.body}');
    }
  }

  Future<void> deleteMeeting(int meetingId) async {
    final token = await AuthService.getAccessToken();
    final res = await http.delete(
      Uri.parse('${ApiEndpoints.deleteMeeting}/$meetingId'),
      headers: {...headers, 'Authorization': 'Bearer $token'},
    );
    if (res.statusCode != 200) {
      throw Exception('Failed to delete meeting: ${res.body}');
    }
  }

  Future<Map<String, dynamic>> getUpcomingMeetings({int limit = 5}) async {
    final token = await AuthService.getAccessToken();
    final uri = Uri.parse(ApiEndpoints.getUpcomingMeetings).replace(
      queryParameters: {'limit': limit.toString()},
    );
    final res = await http.get(
      uri,
      headers: {...headers, 'Authorization': 'Bearer $token'},
    );
    final body = _handleResponse(res);
    return {"meetings": body["data"] ?? []};
  }

// ---------- PRIVATE HELPER ----------
  Map<String, dynamic> _handleResponse(http.Response res,
      {int expectedStatusCode = 200}) {
    try {
      final decoded = json.decode(res.body);
      if (res.statusCode == expectedStatusCode) {
        if (decoded is Map<String, dynamic>) return decoded;
        return {"data": decoded};
      } else {
        throw Exception('Request failed: ${res.body}');
      }
    } catch (e) {
      throw Exception('Invalid JSON response: ${res.body}');
    }
  }

// Note: inviteToMeeting was removed as participants are now handled in create/update meeting
// If you need separate invite functionality, you'll need to add it to the backend
}
