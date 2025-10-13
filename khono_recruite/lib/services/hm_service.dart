import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/hm_models.dart';
import '../services/auth_service.dart';

class HMService {
  static const String baseUrl = 'http://127.0.0.1:5000/api/admin';

  Future<HMDashboardData> getDashboardData(String token) async {
    final response = await http.get(
      Uri.parse('$baseUrl/dashboard'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return HMDashboardData.fromJson(data);
    } else {
      throw Exception('Failed to load dashboard data: ${response.statusCode}');
    }
  }

  Future<List<CandidateData>> getCandidates(String token) async {
    final response = await http.get(
      Uri.parse('$baseUrl/candidates'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => CandidateData.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load candidates: ${response.statusCode}');
    }
  }

  Future<List<RequisitionData>> getRequisitions(String token) async {
    final response = await http.get(
      Uri.parse('$baseUrl/requisitions'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => RequisitionData.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load requisitions: ${response.statusCode}');
    }
  }

  Future<List<Map<String, dynamic>>> getInterviews(String token) async {
    final response = await http.get(
      Uri.parse('$baseUrl/interviews'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      return List<Map<String, dynamic>>.from(jsonDecode(response.body));
    } else {
      throw Exception('Failed to load interviews: ${response.statusCode}');
    }
  }

  Future<Map<String, dynamic>> scheduleInterview(
      String token, Map<String, dynamic> data) async {
    final response = await http.post(
      Uri.parse('$baseUrl/interviews'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(data),
    );

    if (response.statusCode == 201) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to schedule interview: ${response.statusCode}');
    }
  }

  // Static wrapper methods for requisition management
  static Future<void> createRequisition(
      Map<String, dynamic> requisitionData) async {
    final token = await AuthService.getAccessToken();
    final response = await http.post(
      Uri.parse('$baseUrl/requisitions'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(requisitionData),
    );

    if (response.statusCode != 201) {
      throw Exception('Failed to create requisition: ${response.statusCode}');
    }
  }

  static Future<void> updateRequisition(
      int id, Map<String, dynamic> requisitionData) async {
    final token = await AuthService.getAccessToken();
    final response = await http.put(
      Uri.parse('$baseUrl/requisitions/$id'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(requisitionData),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to update requisition: ${response.statusCode}');
    }
  }

  static Future<void> deleteRequisition(int id) async {
    final token = await AuthService.getAccessToken();
    final response = await http.delete(
      Uri.parse('$baseUrl/requisitions/$id'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to delete requisition: ${response.statusCode}');
    }
  }

  // Assessment methods
  static Future<List<Map<String, dynamic>>> getAssessments(String token) async {
    final response = await http.get(
      Uri.parse('$baseUrl/assessments'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      return List<Map<String, dynamic>>.from(jsonDecode(response.body));
    } else {
      throw Exception('Failed to load assessments: ${response.statusCode}');
    }
  }

  static Future<void> createAssessment(
      String token, Map<String, dynamic> assessmentData) async {
    final response = await http.post(
      Uri.parse('$baseUrl/assessments'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(assessmentData),
    );

    if (response.statusCode != 201) {
      throw Exception('Failed to create assessment: ${response.statusCode}');
    }
  }

  // Analytics methods
  static Future<Map<String, dynamic>> getAnalytics(String token) async {
    final response = await http.get(
      Uri.parse('$baseUrl/analytics'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load analytics: ${response.statusCode}');
    }
  }

  static Future<void> exportCSV(String token, String reportType) async {
    final response = await http.get(
      Uri.parse('$baseUrl/analytics/export?type=$reportType'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to export CSV: ${response.statusCode}');
    }
  }
}
