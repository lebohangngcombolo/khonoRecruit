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

  // ---------- INTERVIEWS (PAGINATED) ----------
  Future<Map<String, dynamic>> getInterviewsPaginated({
    int page = 1,
    int perPage = 10,
    String? status,
    String? interviewType,
  }) async {
    final token = await AuthService.getAccessToken();
    final query = <String, String>{
      'page': page.toString(),
      'per_page': perPage.toString(),
    };
    if (status != null && status.isNotEmpty) query['status'] = status;
    if (interviewType != null && interviewType.isNotEmpty) {
      query['interview_type'] = interviewType;
    }

    final uri = Uri.parse("${ApiEndpoints.adminBase}/interviews/all").replace(
      queryParameters: query,
    );

    final res = await http.get(
      uri,
      headers: {...headers, 'Authorization': 'Bearer $token'},
    );
    if (res.statusCode == 200) {
      return Map<String, dynamic>.from(json.decode(res.body));
    }
    throw Exception('Failed to load interviews: ${res.body}');
  }

  // ---------- ANALYTICS (AGGREGATED) ----------
  Future<Map<String, dynamic>> getAnalytics({String? timeRange}) async {
    final token = await AuthService.getAccessToken();
    final authHeaders = {...headers, 'Authorization': 'Bearer $token'};

    // Map time range to days for users-growth endpoint
    int days = 30;
    switch (timeRange) {
      case '1m':
        days = 30;
        break;
      case '3m':
        days = 90;
        break;
      case '6m':
        days = 180;
        break;
      case '1y':
        days = 365;
        break;
      default:
        days = 30;
    }

    // Fetch multiple analytics endpoints in parallel
    final responses = await Future.wait([
      http.get(
        Uri.parse('${ApiEndpoints.adminBase}/analytics/dashboard'),
        headers: authHeaders,
      ),
      http.get(
        Uri.parse('${ApiEndpoints.adminBase}/analytics/users-growth?days=$days'),
        headers: authHeaders,
      ),
      http.get(
        Uri.parse('${ApiEndpoints.adminBase}/analytics/applications-analysis'),
        headers: authHeaders,
      ),
      http.get(
        Uri.parse('${ApiEndpoints.adminBase}/analytics/interviews-analysis'),
        headers: authHeaders,
      ),
      http.get(
        Uri.parse('${ApiEndpoints.adminBase}/analytics/assessments-analysis'),
        headers: authHeaders,
      ),
    ]);

    // Check for errors
    if (responses.any((r) => r.statusCode != 200)) {
      final failedIndex = responses.indexWhere((r) => r.statusCode != 200);
      throw Exception('Failed to fetch analytics data from endpoint $failedIndex: ${responses[failedIndex].body}');
    }

    // Parse responses
    final dashboard = json.decode(responses[0].body) as Map<String, dynamic>;
    final usersGrowth = json.decode(responses[1].body) as Map<String, dynamic>;
    final appsAnalysis = json.decode(responses[2].body) as Map<String, dynamic>;
    final interviewsAnalysis = json.decode(responses[3].body) as Map<String, dynamic>;
    final assessmentsAnalysis = json.decode(responses[4].body) as Map<String, dynamic>;

    // Calculate interviewed count from monthly interviews
    final interviewedCount = (interviewsAnalysis['monthly_interviews'] is List)
        ? (interviewsAnalysis['monthly_interviews'] as List)
            .fold<int>(0, (sum, e) => sum + ((e['count'] ?? 0) as int))
        : 0;

    // Map to HMAnalyticsPage expected structure
    final summary = {
      'total_applications': dashboard['total_applications'] ?? 0,
      'total_hires': (dashboard['application_status_breakdown'] ?? const {})['hired'] ?? 0,
      'avg_time_to_fill': 0, // Placeholder until backend supports
      'cost_per_hire': 0, // Placeholder until backend supports
      'quality_score': (dashboard['average_scores']?['assessment_score'] ?? 0).toStringAsFixed(1),
    };

    final statusBreakdown = Map<String, dynamic>.from(
      dashboard['application_status_breakdown'] ?? const {},
    );

    final timeline = List<Map<String, dynamic>>.from(
      usersGrowth['user_growth'] ?? const [],
    );

    final topJobs = List<Map<String, dynamic>>.from(
      appsAnalysis['applications_by_requisition'] ?? const [],
    );

    final conversionFunnel = {
      'applied': dashboard['total_applications'] ?? 0,
      'shortlisted': 0, // Placeholder until backend supports
      'interviewed': interviewedCount,
      'hired': summary['total_hires'] ?? 0,
    };

    // New data mappings for additional charts
    final monthlyApplications = List<Map<String, dynamic>>.from(
      appsAnalysis['monthly_applications'] ?? const [],
    );

    final cvScoreDistribution = List<Map<String, dynamic>>.from(
      appsAnalysis['cv_score_distribution'] ?? const [],
    );

    // Convert interview status breakdown from list to map
    final interviewStatusList = interviewsAnalysis['interview_status_breakdown'] ?? [];
    final interviewStatusBreakdown = <String, dynamic>{};
    if (interviewStatusList is List) {
      for (var item in interviewStatusList) {
        if (item is Map && item.containsKey('status') && item.containsKey('count')) {
          interviewStatusBreakdown[item['status'].toString()] = item['count'];
        }
      }
    }

    // Convert interviews by type from list to map
    final interviewsByTypeList = interviewsAnalysis['interviews_by_type'] ?? [];
    final interviewsByType = <String, dynamic>{};
    if (interviewsByTypeList is List) {
      for (var item in interviewsByTypeList) {
        if (item is Map && item.containsKey('type') && item.containsKey('count')) {
          interviewsByType[item['type'].toString()] = item['count'];
        }
      }
    }

    final assessmentScoreDistribution = List<Map<String, dynamic>>.from(
      assessmentsAnalysis['assessment_score_distribution'] ?? const [],
    );

    final averageScoresByRequisition = List<Map<String, dynamic>>.from(
      assessmentsAnalysis['average_scores_by_requisition'] ?? const [],
    );

    return {
      'summary': summary,
      'status_breakdown': statusBreakdown,
      'timeline': timeline,
      'top_jobs': topJobs,
      'conversion_funnel': conversionFunnel,
      'monthly_applications': monthlyApplications,
      'cv_score_distribution': cvScoreDistribution,
      'interview_status_breakdown': interviewStatusBreakdown,
      'interviews_by_type': interviewsByType,
      'assessment_score_distribution': assessmentScoreDistribution,
      'average_scores_by_requisition': averageScoresByRequisition,
    };
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
    if (jobId <= 0) {
      throw Exception('Invalid job ID: $jobId');
    }
    
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
      Uri.parse("${ApiEndpoints.adminBase}/interviews/cancel/$interviewId"),
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
}
