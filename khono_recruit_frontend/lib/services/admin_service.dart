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

  /// ---------- USERS ----------
  static Future<List<User>> getUsers() async {
    final token = await AuthService.getToken();
    final res = await _dio.get(
      ApiEndpoints.adminUsers,
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );
    return (res.data as List).map((e) => User.fromJson(e)).toList();
  }

  static Future<void> updateUserRole(int userId, String newRole) async {
    final token = await AuthService.getToken();
    await _dio.put(
      '${ApiEndpoints.updateRole}/$userId',
      data: {'role': newRole},
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );
  }

  /// ---------- JOBS ----------
  static Future<List<Job>> getJobs() async {
    final token = await AuthService.getToken();
    final res = await _dio.get(
      ApiEndpoints.adminJobs,
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );
    return (res.data as List).map((e) => Job.fromJson(e)).toList();
  }

  static Future<void> createJob(String title, String description) async {
    final token = await AuthService.getToken();
    await _dio.post(
      ApiEndpoints.jobs,
      data: {'title': title, 'description': description},
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );
  }

  /// ---------- APPLICATIONS ----------
  static Future<List<Application>> getApplications() async {
    final token = await AuthService.getToken();
    final res = await _dio.get(
      ApiEndpoints.adminApplications,
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );
    return (res.data as List).map((e) => Application.fromJson(e)).toList();
  }

  /// ---------- CANDIDATES ----------
  static Future<List<User>> getCandidates(int jobId) async {
    final token = await AuthService.getToken();
    final res = await _dio.get(
      '${ApiEndpoints.jobCandidates}/$jobId/candidates',
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );
    return (res.data as List).map((e) => User.fromJson(e)).toList();
  }

  static Future<void> shortlistCandidate(int jobId, int candidateId) async {
    final token = await AuthService.getToken();
    await _dio.post(
      '${ApiEndpoints.jobCandidates}/$jobId/shortlist',
      data: {'candidate_id': candidateId},
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );
  }

  /// ---------- ASSESSMENTS ----------
  static Future<Assessment> getAssessment(int applicationId) async {
    final token = await AuthService.getToken();
    final res = await _dio.get(
      '${ApiEndpoints.applicationAssessment}/$applicationId/assessment',
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );
    return Assessment.fromJson(res.data);
  }
}
