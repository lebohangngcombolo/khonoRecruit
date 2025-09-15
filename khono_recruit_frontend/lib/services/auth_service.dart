import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/api_endpoints.dart';

class AuthService {
  static final Dio _dio = Dio(
    BaseOptions(
      baseUrl: ApiEndpoints.baseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
      headers: {'Content-Type': 'application/json'},
    ),
  );

  /// Login
  static Future<String> login(String email, String password) async {
    final res = await _dio.post(ApiEndpoints.login, data: {
      'email': email,
      'password': password,
    });
    final token = res.data['access_token'];
    await saveToken(token);
    return token;
  }

  /// Register
  static Future<void> register(
      String firstName, String lastName, String email, String password,
      {String role = "candidate"}) async {
    try {
      final res = await _dio.post(ApiEndpoints.register, data: {
        'first_name': firstName,
        'last_name': lastName,
        'email': email,
        'password': password,
        'role': role,
      });

      // Optionally, you can return something if needed
      if (res.statusCode != 201) {
        throw Exception('Registration failed');
      }
    } on DioError catch (e) {
      String message = 'Registration failed';
      if (e.response != null && e.response!.data != null) {
        final data = e.response!.data;
        if (data is Map<String, dynamic> && data.containsKey('error')) {
          message = data['error'] ?? message;
        } else {
          message = data.toString();
        }
      } else {
        message = e.message ?? message; // null-safe
      }
      throw Exception(message);
    }
  }

  /// Verify email
  static Future<void> verifyEmail(String email, String code) async {
    try {
      await _dio.post(ApiEndpoints.verifyEmail, data: {
        'email': email,
        'code': code,
      });
    } on DioError catch (e) {
      throw Exception(e.message ?? 'Verification failed');
    }
  }

  /// Forgot password
  static Future<void> forgotPassword(String email) async {
    try {
      await _dio.post(ApiEndpoints.forgotPassword, data: {'email': email});
    } on DioError catch (e) {
      throw Exception(e.message ?? 'Forgot password failed');
    }
  }

  /// Reset password
  static Future<void> resetPassword(String token, String newPassword) async {
    try {
      await _dio.post(ApiEndpoints.resetPassword, data: {
        'token': token,
        'new_password': newPassword,
      });
    } on DioError catch (e) {
      throw Exception(e.message ?? 'Reset password failed');
    }
  }

  /// Refresh JWT
  static Future<String> refreshToken() async {
    final token = await getToken();
    final res = await _dio.post(
      ApiEndpoints.refresh,
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );
    final newToken = res.data['access_token'];
    await saveToken(newToken);
    return newToken;
  }

  /// Get current user
  static Future<Map<String, dynamic>> getMe() async {
    final token = await getToken();
    final res = await _dio.get(
      ApiEndpoints.me,
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );
    return res.data;
  }

  /// Save token
  static Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('jwt_token', token);
  }

  /// Get token
  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('jwt_token');
  }

  /// Logout
  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('jwt_token');
  }
}
