import 'dart:convert';
import 'package:flutter/material.dart';
import '../../services/admin_service.dart';
import '../../services/auth_service.dart';
import 'package:http/http.dart' as http;
import '../../utils/api_endpoints.dart';
import '../../constants/app_colors.dart';
import '../../widgets/widgets1/glass_card.dart';

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

  Future<void> _markAsRead(int notificationId) async {
    try {
      final token = await AuthService.getAccessToken();
      final res = await http.patch(
        Uri.parse("${ApiEndpoints.adminBase}/notifications/$notificationId/read"),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (res.statusCode == 200) {
        setState(() {
          final idx = notifications.indexWhere((n) => n['id'] == notificationId);
          if (idx != -1) {
            notifications[idx]['is_read'] = true;
          }
        });
      } else {
        throw Exception('Failed to mark as read');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Failed to mark as read: $e')));
      }
    }
  }

  Future<void> _markAllAsRead() async {
    try {
      final token = await AuthService.getAccessToken();
      final res = await http.post(
        Uri.parse("${ApiEndpoints.adminBase}/notifications/mark-all-read"),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (res.statusCode == 200) {
        setState(() {
          for (final n in notifications) {
            n['is_read'] = true;
          }
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('All notifications marked as read')));
        }
      } else {
        throw Exception('Failed to mark all as read');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Failed to mark all as read: $e')));
      }
    }
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
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "Notifications",
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  shadows: [
                    Shadow(
                      color: Colors.black54,
                      blurRadius: 8,
                      offset: Offset(0, 2),
                    )
                  ],
                ),
              ),
              TextButton.icon(
                onPressed: notifications.isEmpty ? null : _markAllAsRead,
                icon: const Icon(Icons.mark_email_read, color: Colors.white70),
                label: const Text('Mark all as read',
                    style: TextStyle(color: Colors.white70)),
              )
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: loading
                ? const Center(
                    child: CircularProgressIndicator(color: Colors.redAccent),
                  )
                : errorMessage != null
                    ? Center(
                        child: Text(
                          errorMessage!,
                          style: const TextStyle(color: Colors.white70),
                        ))
                    : notifications.isEmpty
                        ? const Center(
                            child: Text(
                              "No notifications",
                              style: TextStyle(color: Colors.white70, fontSize: 16),
                            ))
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
                              child: GlassCard(
                                blur: 8,
                                opacity: 0.1,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(8),
                                          decoration: BoxDecoration(
                                            color: AppColors.primaryRed.withValues(alpha: 0.1),
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: Icon(
                                            Icons.notifications_active,
                                            color: AppColors.primaryRed,
                                            size: 20,
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Text(
                                            n['title'] ?? "Notification",
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 12),
                                    Text(
                                      n['message'] ?? "",
                                      style: const TextStyle(
                                          color: Colors.white70, fontSize: 14),
                                    ),
                                  const SizedBox(height: 8),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      if (createdAt != null)
                                        Text(
                                          "${createdAt.year}-${createdAt.month.toString().padLeft(2, '0')}-${createdAt.day.toString().padLeft(2, '0')} "
                                          "${createdAt.hour.toString().padLeft(2, '0')}:${createdAt.minute.toString().padLeft(2, '0')}",
                                          style: const TextStyle(fontSize: 12, color: Colors.white60),
                                        ),
                                      Row(
                                        children: [
                                          if (!(n['is_read'] == true))
                                            TextButton(
                                              onPressed: () => _markAsRead(n['id'] as int),
                                              style: TextButton.styleFrom(
                                                foregroundColor: AppColors.primaryRed,
                                              ),
                                              child: const Text('Mark as read'),
                                            ),
                                          Container(
                                            width: 10,
                                            height: 10,
                                            decoration: BoxDecoration(
                                              shape: BoxShape.circle,
                                              color: (n['is_read'] == true)
                                                  ? AppColors.statusSuccess
                                                  : AppColors.primaryRed,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
          ),
        ],
      ),
    );
  }
}
