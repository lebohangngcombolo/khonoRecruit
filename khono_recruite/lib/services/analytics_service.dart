import 'dart:convert';
import 'package:http/http.dart' as http;

class AnalyticsService {
  final String baseUrl;
  final Map<String, String> headers;

  AnalyticsService({required this.baseUrl, Map<String, String>? headers})
      : headers = headers ?? {'Content-Type': 'application/json'};

  Future<List<dynamic>> getList(String path) async {
    final resp = await http.get(Uri.parse('$baseUrl$path'), headers: headers);
    if (resp.statusCode == 200) return jsonDecode(resp.body) as List<dynamic>;
    throw Exception('Failed GET $path (${resp.statusCode})');
  }

  Future<Map<String, dynamic>> getMap(String path) async {
    final resp = await http.get(Uri.parse('$baseUrl$path'), headers: headers);
    if (resp.statusCode == 200)
      return jsonDecode(resp.body) as Map<String, dynamic>;
    throw Exception('Failed GET $path (${resp.statusCode})');
  }

  // Typed methods
  Future<List<dynamic>> applicationsPerRequisition() =>
      getList('/api/analytics/applications-per-requisition');
  Future<Map<String, dynamic>> pipelineConversion() =>
      getMap('/api/analytics/pipeline-conversion');
  Future<Map<String, dynamic>> avgTimePerStage() =>
      getMap('/api/analytics/avg-time-per-stage');
  Future<List<dynamic>> monthlyApplications() =>
      getList('/api/analytics/applications/monthly');
  Future<List<dynamic>> cvScreeningDrop() =>
      getList('/api/analytics/cv-screening-drop');
  Future<List<dynamic>> assessmentPassRate() =>
      getList('/api/analytics/assessments/pass-rate');
  Future<List<dynamic>> interviewsScheduled() =>
      getList('/api/analytics/interviews/scheduled');
  Future<List<dynamic>> offersByCategory() =>
      getList('/api/analytics/offers-by-category');
  Future<Map<String, dynamic>> avgCvScore() =>
      getMap('/api/analytics/candidate/avg-cv-score');
  Future<Map<String, dynamic>> avgAssessmentScore() =>
      getMap('/api/analytics/candidate/avg-assessment-score');
  Future<Map<String, dynamic>> skillsFrequency() =>
      getMap('/api/analytics/candidate/skills-frequency');
  Future<Map<String, dynamic>> experienceDistribution() =>
      getMap('/api/analytics/candidate/experience-distribution');
}
