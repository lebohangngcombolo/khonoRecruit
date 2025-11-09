import 'dart:convert';
import 'package:http/http.dart' as http;
import 'auth_service.dart';

class TeamService {
  static const String baseUrl = 'http://127.0.0.1:5000/api/admin/team';
  
  static final headers = {
    'Content-Type': 'application/json',
  };

  // Team Members
  static Future<List<dynamic>> getTeamMembers() async {
    final token = await AuthService.getAccessToken();
    final response = await http.get(
      Uri.parse('$baseUrl/members'),
      headers: {...headers, 'Authorization': 'Bearer $token'},
    );
    
    if (response.statusCode == 200) {
      return json.decode(response.body) as List;
    }
    throw Exception('Failed to load team members: ${response.body}');
  }

  // Team Notes
  static Future<List<dynamic>> getTeamNotes() async {
    final token = await AuthService.getAccessToken();
    final response = await http.get(
      Uri.parse('$baseUrl/notes'),
      headers: {...headers, 'Authorization': 'Bearer $token'},
    );
    
    if (response.statusCode == 200) {
      return json.decode(response.body) as List;
    }
    throw Exception('Failed to load team notes: ${response.body}');
  }

  static Future<Map<String, dynamic>> createTeamNote(String title, String content) async {
    final token = await AuthService.getAccessToken();
    final response = await http.post(
      Uri.parse('$baseUrl/notes'),
      headers: {...headers, 'Authorization': 'Bearer $token'},
      body: json.encode({
        'title': title,
        'content': content,
        'is_shared': true,
      }),
    );
    
    if (response.statusCode == 201) {
      return json.decode(response.body) as Map<String, dynamic>;
    }
    throw Exception('Failed to create note: ${response.body}');
  }

  static Future<Map<String, dynamic>> updateTeamNote(int noteId, String title, String content) async {
    final token = await AuthService.getAccessToken();
    final response = await http.put(
      Uri.parse('$baseUrl/notes/$noteId'),
      headers: {...headers, 'Authorization': 'Bearer $token'},
      body: json.encode({
        'title': title,
        'content': content,
      }),
    );
    
    if (response.statusCode == 200) {
      return json.decode(response.body) as Map<String, dynamic>;
    }
    throw Exception('Failed to update note: ${response.body}');
  }

  static Future<void> deleteTeamNote(int noteId) async {
    final token = await AuthService.getAccessToken();
    final response = await http.delete(
      Uri.parse('$baseUrl/notes/$noteId'),
      headers: {...headers, 'Authorization': 'Bearer $token'},
    );
    
    if (response.statusCode != 200) {
      throw Exception('Failed to delete note: ${response.body}');
    }
  }

  // Team Messages
  static Future<List<dynamic>> getTeamMessages() async {
    final token = await AuthService.getAccessToken();
    final response = await http.get(
      Uri.parse('$baseUrl/messages'),
      headers: {...headers, 'Authorization': 'Bearer $token'},
    );
    
    if (response.statusCode == 200) {
      return json.decode(response.body) as List;
    }
    throw Exception('Failed to load messages: ${response.body}');
  }

  static Future<Map<String, dynamic>> sendTeamMessage(String message) async {
    final token = await AuthService.getAccessToken();
    final response = await http.post(
      Uri.parse('$baseUrl/messages'),
      headers: {...headers, 'Authorization': 'Bearer $token'},
      body: json.encode({
        'message': message,
      }),
    );
    
    if (response.statusCode == 201) {
      return json.decode(response.body) as Map<String, dynamic>;
    }
    throw Exception('Failed to send message: ${response.body}');
  }

  // Team Activities
  static Future<List<dynamic>> getTeamActivities() async {
    final token = await AuthService.getAccessToken();
    final response = await http.get(
      Uri.parse('$baseUrl/activities'),
      headers: {...headers, 'Authorization': 'Bearer $token'},
    );
    
    if (response.statusCode == 200) {
      return json.decode(response.body) as List;
    }
    throw Exception('Failed to load activities: ${response.body}');
  }

  // Update Activity
  static Future<void> updateUserActivity() async {
    try {
      final token = await AuthService.getAccessToken();
      await http.post(
        Uri.parse('$baseUrl/update-activity'),
        headers: {...headers, 'Authorization': 'Bearer $token'},
      );
    } catch (e) {
      // Silently fail - this is a background task
      print('Failed to update activity: $e');
    }
  }
}
