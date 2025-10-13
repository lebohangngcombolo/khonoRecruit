import 'dart:convert';
import 'package:flutter/material.dart';
import '../../services/admin_service.dart';
import '../../services/auth_service.dart';
import 'package:http/http.dart' as http;
import '../../utils/api_endpoints.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  _NotificationsScreenState createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final AdminService admin = AdminService();
  List<Map<String, dynamic>> notifications = [];
  bool loading = true;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    fetchNotifications();
  }

  Future<void> fetchNotifications() async {
    setState(() {
      loading = true;
      errorMessage = null;
    });

    try {
      final userId = await AuthService.getUserId();
      final data = await getNotifications(userId);
      setState(() => notifications = List<Map<String, dynamic>>.from(data));
    } catch (e) {
      debugPrint("Error fetching notifications: $e");
      setState(() => errorMessage = "Failed to load notifications");
    } finally {
      setState(() => loading = false);
    }
  }

  Future<List<Map<String, dynamic>>> getNotifications(int userId) async {
    final token = await AuthService.getAccessToken();
    final res = await http.get(
      Uri.parse("${ApiEndpoints.getNotifications}/$userId"),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (res.statusCode == 200) {
      final body = jsonDecode(res.body);

      if (body is List) {
        return body.map((e) => Map<String, dynamic>.from(e)).toList();
      }

      if (body is Map && body.containsKey('notifications')) {
        final list = body['notifications'];
        if (list is List) {
          return list.map((e) => Map<String, dynamic>.from(e)).toList();
        }
      }

      if (body is Map && body.containsKey('data')) {
        final list = body['data'];
        if (list is List) {
          return list.map((e) => Map<String, dynamic>.from(e)).toList();
        }
      }

      if (body is Map<String, dynamic>) {
        return [body];
      }

      throw Exception("Unexpected notifications format: ${body.runtimeType}");
    } else {
      throw Exception("Failed to load notifications: ${res.body}");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          "Notifications",
          style: TextStyle(color: Colors.black),
        ),
        backgroundColor: Colors.white,
        elevation: 1,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: loading
          ? const Center(
              child: CircularProgressIndicator(color: Colors.blue),
            )
          : errorMessage != null
              ? Center(child: Text(errorMessage!))
              : notifications.isEmpty
                  ? const Center(child: Text("No notifications"))
                  : RefreshIndicator(
                      onRefresh: fetchNotifications,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: notifications.length,
                        itemBuilder: (_, index) {
                          final n = notifications[index];
                          final createdAt = n['created_at'] != null
                              ? DateTime.parse(n['created_at'])
                              : null;

                          return TweenAnimationBuilder<double>(
                            tween: Tween(begin: 0, end: 1),
                            duration:
                                Duration(milliseconds: 500 + (index * 100)),
                            builder: (context, opacity, child) {
                              return Opacity(
                                opacity: opacity,
                                child: Transform.translate(
                                  offset: Offset(0, (1 - opacity) * 20),
                                  child: child,
                                ),
                              );
                            },
                            child: Container(
                              margin: const EdgeInsets.symmetric(vertical: 8),
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.grey[100],
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: Colors.grey[300]!),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.05),
                                    blurRadius: 6,
                                    offset: const Offset(0, 3),
                                  ),
                                ],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    n['title'] ?? "Notification",
                                    style: const TextStyle(
                                      color: Colors.black,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    n['message'] ?? "",
                                    style: const TextStyle(
                                        color: Colors.black87, fontSize: 14),
                                  ),
                                  if (createdAt != null)
                                    Align(
                                      alignment: Alignment.bottomRight,
                                      child: Text(
                                        "${createdAt.year}-${createdAt.month.toString().padLeft(2, '0')}-${createdAt.day.toString().padLeft(2, '0')} "
                                        "${createdAt.hour.toString().padLeft(2, '0')}:${createdAt.minute.toString().padLeft(2, '0')}",
                                        style: const TextStyle(
                                            fontSize: 12, color: Colors.grey),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
    );
  }
}
