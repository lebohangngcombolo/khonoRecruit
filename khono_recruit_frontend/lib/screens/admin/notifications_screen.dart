import 'package:flutter/material.dart';
import '../../services/admin_service.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  _NotificationsScreenState createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final AdminService admin = AdminService();
  List<dynamic> notifications = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    fetchNotifications();
  }

  Future<void> fetchNotifications() async {
    setState(() => loading = true);
    try {
      final data = await admin.getNotifications(0); // 0 = admin
      setState(() => notifications = data);
    } catch (e) {
      debugPrint("Error fetching notifications: $e");
    } finally {
      setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return loading
        ? const Center(child: CircularProgressIndicator(color: Colors.red))
        : Padding(
            padding: const EdgeInsets.all(16),
            child: notifications.isEmpty
                ? const Center(child: Text("No notifications"))
                : ListView.builder(
                    itemCount: notifications.length,
                    itemBuilder: (_, index) {
                      final n = notifications[index];
                      return Card(
                        margin: const EdgeInsets.symmetric(vertical: 8),
                        child: ListTile(
                          title: Text(n['title']),
                          subtitle: Text(n['message']),
                        ),
                      );
                    },
                  ),
          );
  }
}
