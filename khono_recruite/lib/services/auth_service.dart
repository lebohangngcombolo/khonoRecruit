import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_web_auth/flutter_web_auth.dart';
import 'package:khono_recruite/utils/api_endpoints.dart';

class AuthService {
  static const _storage = FlutterSecureStorage();

  // ----------------- REGISTER -----------------
  static Future<Map<String, dynamic>> register(
    Map<String, dynamic> data,
  ) async {
    final response = await http.post(
      Uri.parse(ApiEndpoints.register),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode(data),
    );

    final body = jsonDecode(response.body);

    return {
      "status": response.statusCode, // HTTP status code
      "body": body, // decoded response
    };
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

    if (decoded.containsKey('access_token')) {
      await saveToken(decoded['access_token']);
    }
    return decoded;
  }

  // Example: fetch stored user info from shared preferences
  static Future<int> getUserId() async {
    final user = await getUserInfo();
    if (user != null) {
      return user['id'] as int;
    }
    throw Exception('User not logged in');
  }

  // ----------------- LOGIN (UPDATED WITH MFA) -----------------
  static Future<Map<String, dynamic>> login(
    String email,
    String password,
  ) async {
    final response = await http.post(
      Uri.parse(ApiEndpoints.login),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'password': password}),
    );

    final data = jsonDecode(response.body);

    if (response.statusCode == 200) {
      // 🆕 Check if MFA is required
      if (data['mfa_required'] == true) {
        // 🆕 FIX: Convert user_id to string to prevent type errors
        final userId = data['user_id']?.toString() ?? '';

        return {
          'success': true,
          'mfa_required': true,
          'mfa_session_token': data['mfa_session_token'],
          'user_id': userId, // 🆕 Now guaranteed to be string
          'message': data['message'],
        };
      }

      // 🆕 Normal login without MFA
      await saveToken(data['access_token']);
      await saveUserInfo(data['user']);

      return {
        'success': true,
        'access_token': data['access_token'],
        'refresh_token': data['refresh_token'],
        'role': data['user']['role'],
        'dashboard': data['dashboard'],
      };
    } else {
      return {'success': false, 'message': data['error'] ?? 'Login failed'};
    }
  }

  static Future<Map<String, dynamic>> verifyMfaLogin(
      String mfaSessionToken, String token) async {
    final response = await http.post(
      Uri.parse(ApiEndpoints.mfaLogin), // <-- fixed
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'mfa_session_token': mfaSessionToken,
        'token': token,
      }),
    );

    final data = jsonDecode(response.body);

    if (response.statusCode == 200) {
      await saveToken(data['access_token']);
      await saveUserInfo(data['user']);

      return {
        'success': true,
        'access_token': data['access_token'],
        'refresh_token': data['refresh_token'],
        'user': data['user'],
        'dashboard': data['dashboard'],
        'used_backup_code': data['used_backup_code'] ?? false,
        'message': data['message'],
      };
    } else {
      return {
        'success': false,
        'message': data['error'] ?? 'MFA verification failed'
      };
    }
  }

  // ----------------- LOGOUT -----------------
  static Future<bool> logout() async {
    try {
      final response = await http.post(
        Uri.parse(ApiEndpoints.logout),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${await getAccessToken()}',
        },
      );

      if (response.statusCode == 200) {
        await deleteTokens();
        return true;
      }
      return false;
    } catch (_) {
      return false;
    }
  }

// ---------- SOCIAL LOGIN URL GETTERS ----------
  static String get googleOAuthUrl => ApiEndpoints.googleOAuth;
  static String get githubOAuthUrl => ApiEndpoints.githubOAuth;

  static Future<Map<String, dynamic>> loginWithGoogle() async {
    // Launch Google OAuth in a new tab or popup
    final result = await FlutterWebAuth.authenticate(
      url: ApiEndpoints.googleOAuth,
      callbackUrlScheme: "myapp", // match your URL scheme
    );

    // Parse the redirected URL with tokens
    final uri = Uri.parse(result);
    final accessToken = uri.queryParameters['access_token'];
    final refreshToken = uri.queryParameters['refresh_token'];
    final role = uri.queryParameters['role'];

    // Store tokens and role for future API calls
    if (accessToken != null && role != null) {
      await AuthService.storeTokens(accessToken, refreshToken, role);
    }

    // Return success status and info
    return {
      'success': accessToken != null,
      'access_token': accessToken,
      'refresh_token': refreshToken,
      'role': role,
    };
  }

  static Future<Map<String, dynamic>> loginWithGithub() async {
    final result = await FlutterWebAuth.authenticate(
      url: ApiEndpoints.githubOAuth,
      callbackUrlScheme: "myapp",
    );

    final uri = Uri.parse(result);
    final accessToken = uri.queryParameters['access_token'];
    final refreshToken = uri.queryParameters['refresh_token'];
    final role = uri.queryParameters['role'];
    final dashboard = uri.queryParameters['dashboard'];

    if (accessToken != null) {
      await saveTokens(accessToken, refreshToken);
    }

    return {
      'success': accessToken != null,
      'access_token': accessToken,
      'refresh_token': refreshToken,
      'role': role,
      'dashboard': dashboard,
    };
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
    token ??= await getAccessToken();

    final response = await http.get(
      Uri.parse(ApiEndpoints.currentUser),
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

  // ----------------- ADMIN ENROLL USER -----------------
  static Future<Map<String, dynamic>> enrollUser(
      String token, Map<String, dynamic> data) async {
    final response = await http.post(
      Uri.parse(ApiEndpoints.adminEnroll),
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      },
      body: jsonEncode(data),
    );
    return jsonDecode(response.body);
  }

  // ----------------- CHANGE PASSWORD (FIRST LOGIN) -----------------
  static Future<Map<String, dynamic>> changePassword({
    required String tempPassword,
    required String newPassword,
    required String confirmPassword,
  }) async {
    final token = await getAccessToken();

    final response = await http.post(
      Uri.parse(ApiEndpoints.changePassword),
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      },
      body: jsonEncode({
        "temporary_password": tempPassword,
        "new_password": newPassword,
        "confirm_password": confirmPassword,
      }),
    );

    return jsonDecode(response.body);
  }

  // ----------------- TOKEN HELPERS -----------------
  static Future<void> saveTokens(
      String accessToken, String? refreshToken) async {
    await _storage.write(key: 'access_token', value: accessToken);
    if (refreshToken != null) {
      await _storage.write(key: 'refresh_token', value: refreshToken);
    }
  }

  static Future<String?> getAccessToken() async {
    return await _storage.read(key: 'access_token');
  }

  static Future<String?> getRefreshToken() async {
    return await _storage.read(key: 'refresh_token');
  }

  static Future<void> deleteTokens() async {
    await _storage.delete(key: 'access_token');
    await _storage.delete(key: 'refresh_token');
  }

// ----------------- SAVE TOKEN -----------------
  static Future<void> saveToken(String token) async {
    await _storage.write(key: 'access_token', value: token);
  }

  // ----------------- AUTHORIZED REQUEST HELPERS -----------------
  static Future<http.Response> authorizedGet(String url) async {
    final token = await getAccessToken();
    return http.get(
      Uri.parse(url),
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      },
    );
  }

  static Future<http.Response> authorizedPost(
      String url, Map<String, dynamic> body) async {
    final token = await getAccessToken();
    return http.post(
      Uri.parse(url),
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      },
      body: jsonEncode(body),
    );
  }

  static Future<http.Response> authorizedPut(
      String url, Map<String, dynamic> data) async {
    final token = await getAccessToken();
    return http.put(
      Uri.parse(url),
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      },
      body: jsonEncode(data),
    );
  }

  static Future<http.Response> authorizedDelete(String url) async {
    final token = await getAccessToken();
    return http.delete(
      Uri.parse(url),
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      },
    );
  }

  // Save user info (JSON string) in SharedPreferences
  static Future<void> saveUserInfo(Map<String, dynamic> user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user', jsonEncode(user));
  }

// Retrieve saved user info
  static Future<Map<String, dynamic>?> getUserInfo() async {
    final prefs = await SharedPreferences.getInstance();
    final userStr = prefs.getString('user');
    if (userStr != null) {
      return jsonDecode(userStr) as Map<String, dynamic>;
    }
    return null;
  }

  // ----------------- GET USER PROFILE -----------------
  static Future<Map<String, dynamic>> getUserProfile(String token) async {
    try {
      final response = await http.get(
        Uri.parse(ApiEndpoints.currentUser), // Using existing endpoint
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data;
      } else {
        throw Exception('Failed to load profile: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching profile: $e');
    }
  }

  // ----------------- STORE TOKENS WITH ROLE -----------------
  static Future<void> storeTokens(
      String accessToken, String? refreshToken, String role) async {
    await saveTokens(accessToken, refreshToken);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('role', role);
  }

// Retrieve stored role
  static Future<String?> getRole() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('role');
  }

  // 🆕 MFA MANAGEMENT METHODS
  static Future<Map<String, dynamic>> enableMfa() async {
    final token = await getAccessToken();
    final response = await http.post(
      Uri.parse(ApiEndpoints.enableMfa),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );
    return jsonDecode(response.body);
  }

  static Future<Map<String, dynamic>> verifyMfaSetup(String token) async {
    final authToken = await getAccessToken();
    final response = await http.post(
      Uri.parse(ApiEndpoints.verifyMfaSetup),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $authToken',
      },
      body: jsonEncode({'token': token}),
    );
    return jsonDecode(response.body);
  }

  static Future<Map<String, dynamic>> disableMfa(String password) async {
    final authToken = await getAccessToken();
    final response = await http.post(
      Uri.parse(ApiEndpoints.disableMfa),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $authToken',
      },
      body: jsonEncode({'password': password}),
    );
    return jsonDecode(response.body);
  }

  static Future<Map<String, dynamic>> getMfaStatus() async {
    final token = await getAccessToken();
    final response = await http.get(
      Uri.parse(ApiEndpoints.mfaStatus),
      headers: {
        'Authorization': 'Bearer $token',
      },
    );
    return jsonDecode(response.body);
  }

  static Future<Map<String, dynamic>> getBackupCodes() async {
    final token = await getAccessToken();
    final response = await http.get(
      Uri.parse(ApiEndpoints.backupCodes),
      headers: {
        'Authorization': 'Bearer $token',
      },
    );
    return jsonDecode(response.body);
  }

  static Future<Map<String, dynamic>> regenerateBackupCodes() async {
    final token = await getAccessToken();
    final response = await http.post(
      Uri.parse(ApiEndpoints.regenerateBackupCodes),
      headers: {
        'Authorization': 'Bearer $token',
      },
    );
    return jsonDecode(response.body);
  }
}
