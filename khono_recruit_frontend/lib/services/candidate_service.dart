import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:http/http.dart' as http;
import 'package:khono_recruit_frontend/models/application_model.dart';
import '../constants/api_endpoints.dart';
import '../models/job_model.dart';
import '../models/user_model.dart';
import '../models/api_response.dart';

class CandidateService {
  static final Dio _dio = Dio(
    BaseOptions(baseUrl: ApiEndpoints.baseUrl),
  );

  /// 🔹 Fetch all available jobs
  static Future<ApiResponse<List<Job>>> getJobs(String token) async {
    try {
      final res = await http.get(
        Uri.parse(ApiEndpoints.baseUrl + ApiEndpoints.jobs),
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
        },
      );

      final decoded = jsonDecode(res.body);

      final jobsList =
          (decoded['jobs'] as List).map((e) => Job.fromJson(e)).toList();

      return ApiResponse<List<Job>>(
        success: res.statusCode >= 200 && res.statusCode < 300,
        message: decoded['message'] ?? 'Jobs fetched successfully',
        code: res.statusCode,
        data: jobsList,
      );
    } catch (e) {
      return ApiResponse<List<Job>>(
        success: false,
        message: e.toString(),
        code: 500,
        data: [],
      );
    }
  }

  /// 🔹 Fetch jobs the candidate has applied for
  static Future<ApiResponse<List<Application>>> getAppliedJobs(
      String token) async {
    try {
      final res = await http.get(
        Uri.parse(ApiEndpoints.baseUrl + ApiEndpoints.appliedJobs),
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
        },
      );

      final decoded = jsonDecode(res.body);

      final applications = (decoded['applications'] as List)
          .map((e) => Application.fromJson(e))
          .toList();

      return ApiResponse<List<Application>>(
        success: res.statusCode >= 200 && res.statusCode < 300,
        message: decoded['message'] ?? 'Applied jobs fetched successfully',
        code: res.statusCode,
        data: applications,
      );
    } catch (e) {
      return ApiResponse<List<Application>>(
        success: false,
        message: e.toString(),
        code: 500,
        data: [],
      );
    }
  }

  /// 🔹 Upload candidate CV
  static Future<ApiResponse<Map<String, dynamic>>> uploadCV(
      String token, String filePath) async {
    try {
      FormData formData = FormData.fromMap({
        'cv': await MultipartFile.fromFile(filePath,
            filename: filePath.split('/').last),
      });

      final response = await _dio.post(
        ApiEndpoints.uploadCV,
        data: formData,
        options: Options(
          headers: {"Authorization": "Bearer $token"},
        ),
      );

      return ApiResponse<Map<String, dynamic>>(
        success: response.statusCode! >= 200 && response.statusCode! < 300,
        message: response.data['message'] ?? 'CV uploaded successfully',
        code: response.statusCode ?? 200,
        data: response.data,
      );
    } on DioError catch (e) {
      return ApiResponse<Map<String, dynamic>>(
        success: false,
        message:
            e.response?.data['error'] ?? e.message ?? 'Failed to upload CV',
        code: e.response?.statusCode ?? 500,
        data: e.response?.data,
      );
    } catch (e) {
      return ApiResponse<Map<String, dynamic>>(
        success: false,
        message: e.toString(),
        code: 500,
        data: null,
      );
    }
  }

  /// 🔹 Update candidate profile
  static Future<ApiResponse<void>> updateProfile(
      String token, Map<String, dynamic> data) async {
    try {
      final res = await http.put(
        Uri.parse(ApiEndpoints.baseUrl + ApiEndpoints.updateCandidateProfile),
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json"
        },
        body: jsonEncode(data),
      );

      return ApiResponse<void>(
        success: res.statusCode >= 200 && res.statusCode < 300,
        message: jsonDecode(res.body)['message'] ?? 'Profile updated',
        code: res.statusCode,
      );
    } catch (e) {
      return ApiResponse<void>(
        success: false,
        message: e.toString(),
        code: 500,
      );
    }
  }

  /// 🔹 Apply for a job
  static Future<ApiResponse<void>> applyJob(String token, int jobId) async {
    try {
      final res = await http.post(
        Uri.parse("${ApiEndpoints.baseUrl}${ApiEndpoints.jobs}/$jobId/apply"),
        headers: {"Authorization": "Bearer $token"},
      );

      return ApiResponse<void>(
        success: res.statusCode >= 200 && res.statusCode < 300,
        message: jsonDecode(res.body)['message'] ?? 'Applied successfully',
        code: res.statusCode,
      );
    } catch (e) {
      return ApiResponse<void>(
        success: false,
        message: e.toString(),
        code: 500,
      );
    }
  }

  /// 🔹 Submit assessment answers
  static Future<ApiResponse<void>> submitAssessment(
      String token, int applicationId, Map<String, dynamic> answers) async {
    try {
      final res = await http.post(
        Uri.parse(
            "${ApiEndpoints.baseUrl}${ApiEndpoints.applicationAssessment}/$applicationId/assessment"),
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json"
        },
        body: jsonEncode(answers),
      );

      return ApiResponse<void>(
        success: res.statusCode >= 200 && res.statusCode < 300,
        message: jsonDecode(res.body)['message'] ?? 'Assessment submitted',
        code: res.statusCode,
      );
    } catch (e) {
      return ApiResponse<void>(
        success: false,
        message: e.toString(),
        code: 500,
      );
    }
  }

  static Future<User?> getProfile(String token) async {
    try {
      final res = await http.get(
        Uri.parse(ApiEndpoints.baseUrl + ApiEndpoints.getProfile),
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
        },
      );

      if (res.statusCode >= 200 && res.statusCode < 300) {
        final decoded = jsonDecode(res.body);
        return User.fromJson(decoded['profile']); // ✅ return User directly
      } else {
        throw Exception("Failed to fetch profile: ${res.body}");
      }
    } catch (e) {
      print("Error: $e");
      return null;
    }
  }

  /// 🔹 Fetch assessment questions for a candidate
  static Future<ApiResponse<List<Map<String, dynamic>>>> getAssessmentQuestions(
      String token, int jobId) async {
    try {
      final res = await http.get(
        Uri.parse(
            '${ApiEndpoints.baseUrl}${ApiEndpoints.jobs}/$jobId/assessment/candidate'),
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
        },
      );

      final decoded = jsonDecode(res.body);
      final questionsRaw = decoded['assessment']['questions'] as List? ?? [];

      // Ensure each question Map has proper types
      final questions = questionsRaw.map((q) {
        final map = Map<String, dynamic>.from(q);
        // If the 'id' comes as String, convert to int
        if (map['id'] is String) {
          map['id'] = int.tryParse(map['id']) ?? 0;
        }
        return map;
      }).toList();

      return ApiResponse<List<Map<String, dynamic>>>(
        success: res.statusCode >= 200 && res.statusCode < 300,
        message: decoded['message'] ?? 'Assessment questions fetched',
        code: res.statusCode,
        data: questions,
      );
    } catch (e) {
      return ApiResponse<List<Map<String, dynamic>>>(
        success: false,
        message: e.toString(),
        code: 500,
        data: [],
      );
    }
  }
}
