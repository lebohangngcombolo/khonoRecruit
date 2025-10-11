import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:khono_recruite/utils/api_endpoints.dart';

class AuthService {
  // Secure storage instance
  static const _storage = FlutterSecureStorage();

  // ----------------- REGISTER -----------------
  static Future<Map<String, dynamic>> register(
      Map<String, dynamic> data) async {
    final response = await http.post(
      Uri.parse(ApiEndpoints.register),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode(data),
    );
    return jsonDecode(response.body);
  }

  // ----------------- VERIFY EMAIL -----------------
  static Future<Map<String, dynamic>> verifyEmail(
      Map<String, dynamic> data) async {
    final response = await http.post(
      Uri.parse(ApiEndpoints.verify),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode(data),
    );

    final decoded = jsonDecode(response.body);

    // Save access token if returned
    if (decoded.containsKey('access_token')) {
      await saveToken(decoded['access_token']);
    }

    return decoded;
  }

  // ----------------- LOGIN -----------------
  Future<Map<String, dynamic>> login(String email, String password) async {
    final response = await http.post(
      Uri.parse(ApiEndpoints.login),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'password': password}),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);

      // Save token locally
      await saveToken(data['access_token']);

      return {
        'success': true,
        'access_token': data['access_token'],
        'refresh_token': data['refresh_token'],
        'role': data['user']['role'],
        'dashboard': data['dashboard'],
      };
    } else {
      final err = jsonDecode(response.body);
      return {'success': false, 'message': err['error'] ?? 'Login failed'};
    }
  }

  // ----------------- GET TOKEN -----------------
  static Future<String> getToken() async {
    final token = await _storage.read(key: 'access_token');
    if (token == null) {
      throw Exception("No token found. User may not be logged in.");
    }
    return token;
  }

  // ----------------- FORGOT PASSWORD -----------------
  static Future<Map<String, dynamic>> forgotPassword(String email) async {
    final response = await http.post(
      Uri.parse(ApiEndpoints.forgotPassword),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"email": email}),
    );
    return jsonDecode(response.body);
  }

  // ----------------- RESET PASSWORD -----------------
  static Future<Map<String, dynamic>> resetPassword(
      String token, String newPassword) async {
    final response = await http.post(
      Uri.parse(ApiEndpoints.resetPassword),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"token": token, "new_password": newPassword}),
    );
    return jsonDecode(response.body);
  }

  // ----------------- GET CURRENT USER -----------------
  static Future<Map<String, dynamic>> getCurrentUser({String? token}) async {
    token ??= await getToken();

    final response = await http.get(
      Uri.parse("${ApiEndpoints.baseUrl}/me"),
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      },
    );

    return jsonDecode(response.body);
  }

  // ----------------- COMPLETE ENROLLMENT -----------------
  static Future<Map<String, dynamic>> completeEnrollment(
      String token, Map<String, dynamic> data) async {
    final response = await http.post(
      Uri.parse(ApiEndpoints.enrollment),
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      },
      body: jsonEncode(data),
    );
    return jsonDecode(response.body);
  }

  // ----------------- SAVE TOKEN -----------------
  static Future<void> saveToken(String token) async {
    await _storage.write(key: 'access_token', value: token);
  }

  // ----------------- DELETE TOKEN -----------------
  static Future<void> deleteToken() async {
    await _storage.delete(key: 'access_token');
  }

  // ----------------- AUTHORIZED GET -----------------
  static Future<http.Response> authorizedGet(String url) async {
    final token = await getToken();
    return http.get(
      Uri.parse(url),
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      },
    );
  }

// ----------------- AUTHORIZED POST -----------------
  static Future<http.Response> authorizedPost(
      String url, Map<String, dynamic> body) async {
    final token = await getToken();
    return http.post(
      Uri.parse(url),
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      },
      body: jsonEncode(body),
    );
  }

// ----------------- AUTHORIZED PUT -----------------
  static Future<http.Response> authorizedPut(
      String url, Map<String, dynamic> data) async {
    final token = await getToken();
    return http.put(
      Uri.parse(url),
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      },
      body: jsonEncode(data),
    );
  }

// ----------------- AUTHORIZED DELETE -----------------
  static Future<http.Response> authorizedDelete(String url) async {
    final token = await getToken();
    return http.delete(
      Uri.parse(url),
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      },
    );
  }
}
