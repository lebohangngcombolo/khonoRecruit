import 'package:dio/dio.dart';
import '../models/user_model.dart';
import '../models/job_model.dart';
import '../models/application_model.dart';
import '../models/assessment_model.dart';
import '../constants/api_endpoints.dart';
import 'auth_service.dart';

class AdminService {
  static final Dio _dio = Dio(
    BaseOptions(
      baseUrl: ApiEndpoints.baseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
      headers: {'Content-Type': 'application/json'},
    ),
  );

  // -------------------- USERS --------------------
  static Future<List<User>> getUsers() async {
    final token = await AuthService.getToken();
    final res = await _dio.get(
      ApiEndpoints.adminUsers,
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );

    final List usersList =
        res.data is Map ? res.data['users'] as List : res.data as List;
    return usersList.map((e) => User.fromJson(e)).toList();
  }

  static Future<void> updateUserRole(int userId, String newRole) async {
    final token = await AuthService.getToken();
    await _dio.put(
      '${ApiEndpoints.updateRole}/$userId',
      data: {'role': newRole},
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );
  }

  // -------------------- JOBS --------------------
  static Future<List<Job>> getJobs() async {
    final token = await AuthService.getToken();
    final res = await _dio.get(
      ApiEndpoints.adminJobs,
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );

    final List jobsList =
        res.data is Map ? res.data['jobs'] as List : res.data as List;
    return jobsList.map((e) => Job.fromJson(e)).toList();
  }

  static Future<void> createJob(String title, String description,
      List<String> requiredSkills, int minExperience,
      {List<String>? knockoutRules, Map<String, int>? weightings}) async {
    final token = await AuthService.getToken();
    await _dio.post(
      ApiEndpoints.jobs,
      data: {
        'title': title,
        'description': description,
        'required_skills': requiredSkills,
        'min_experience': minExperience,
        'knockout_rules': knockoutRules ?? [],
        'weightings': weightings ?? {'cv': 60, 'assessment': 40},
      },
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );
  }

  // -------------------- APPLICATIONS --------------------
  static Future<List<Application>> getApplications() async {
    final token = await AuthService.getToken();
    final res = await _dio.get(
      ApiEndpoints.adminApplications,
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );

    final List appsList =
        res.data is Map ? res.data['applications'] as List : res.data as List;
    return appsList.map((e) => Application.fromJson(e)).toList();
  }

  // -------------------- CANDIDATES --------------------
  static Future<List<User>> getCandidates(int jobId) async {
    final token = await AuthService.getToken();
    final res = await _dio.get(
      ApiEndpoints.jobCandidates(jobId),
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );

    final List candidatesList =
        res.data is Map ? res.data['candidates'] as List : res.data as List;
    return candidatesList.map((e) => User.fromJson(e)).toList();
  }

  static Future<void> shortlistCandidate(int jobId, int id) async {
    try {
      final token = await AuthService.getToken();
      final res = await _dio.post(
        '/admin/jobs/$jobId/shortlist',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      if (res.statusCode != 200) {
        throw Exception('Failed to shortlist candidates');
      }
    } catch (e) {
      throw Exception('Shortlist request failed: $e');
    }
  }

  // -------------------- ASSESSMENTS (Candidate-level) --------------------
  static Future<Assessment?> getAssessment(int applicationId) async {
    try {
      final token = await AuthService.getToken();
      final res = await _dio.get(
        '${ApiEndpoints.applicationAssessment}/$applicationId/assessment',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      if (res.data == null || res.data['error'] != null) return null;

      final data = res.data;
      return Assessment(
        id: data['id'],
        applicationId: data['application_id'],
        score: (data['total_score'] ?? 0).toDouble(),
        recommendation: data['recommendation'] ?? 'Not assessed',
        assessedAt:
            DateTime.tryParse(data['assessed_at'] ?? '') ?? DateTime.now(),
        answers: Map<String, dynamic>.from(data['scores'] ?? {}),
      );
    } catch (e) {
      print('Error fetching assessment: $e');
      return null;
    }
  }

  // -------------------- ASSESSMENTS (Job-level, Admin) --------------------
  static Future<Assessment?> getJobAssessment(int jobId) async {
    try {
      final token = await AuthService.getToken();
      final res = await _dio.get(
        '/jobs/$jobId/assessment',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      if (res.data == null) return Assessment(questions: []);
      return Assessment.fromJson(res.data);
    } catch (e) {
      print('Error fetching job assessment: $e');
      return Assessment(questions: []);
    }
  }

  static Future<void> createAssessment(int jobId, Assessment assessment) async {
    final token = await AuthService.getToken();
    await _dio.post(
      '/jobs/$jobId/assessment',
      data: assessment.toJson(),
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );
  }

  static Future<void> updateAssessment(int jobId, Assessment assessment) async {
    final token = await AuthService.getToken();
    await _dio.put(
      '/jobs/$jobId/assessment',
      data: assessment.toJson(),
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );
  }

  static Future<void> deleteAssessment(int jobId) async {
    final token = await AuthService.getToken();
    await _dio.delete(
      '/jobs/$jobId/assessment',
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );
  }
}
