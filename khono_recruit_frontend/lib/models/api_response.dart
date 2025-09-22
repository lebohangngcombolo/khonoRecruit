import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiResponse<T> {
  final bool success;
  final String message;
  final int code;
  T? data; // generic and mutable

  ApiResponse({
    required this.success,
    required this.message,
    required this.code,
    this.data,
  });

  // Create from HTTP response
  factory ApiResponse.fromHttp(
      http.Response res, T Function(dynamic)? fromJsonT) {
    try {
      final decoded = jsonDecode(res.body);

      // Detect correct payload
      final payload = decoded['data'] ?? decoded['jobs'] ?? decoded['profile'];

      return ApiResponse<T>(
        success: res.statusCode >= 200 && res.statusCode < 300,
        message: decoded['message'] ?? res.reasonPhrase ?? 'Unknown error',
        code: res.statusCode,
        data: fromJsonT != null && payload != null
            ? fromJsonT(payload)
            : payload as T?,
      );
    } catch (_) {
      return ApiResponse<T>(
        success: res.statusCode >= 200 && res.statusCode < 300,
        message: res.reasonPhrase ?? 'Unknown error',
        code: res.statusCode,
        data: null,
      );
    }
  }

  // ✅ Safe isNotEmpty for nullable types
  bool get isNotEmpty {
    if (data == null) return false;
    if (data is String) return (data as String).isNotEmpty;
    if (data is List) return (data as List).isNotEmpty;
    if (data is Map) return (data as Map).isNotEmpty;
    return true; // fallback
  }

  // ✅ Safe first element if data is a List
  dynamic get first {
    if (data is List && (data as List).isNotEmpty) {
      return (data as List).first;
    }
    return null;
  }

  // Convert to Map
  Map<String, dynamic> toMap() {
    return {
      'success': success,
      'message': message,
      'code': code,
      'data': data,
    };
  }
}
