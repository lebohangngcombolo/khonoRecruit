import 'package:flutter/material.dart';
import '../../services/admin_service.dart';

class CVReviewsScreen extends StatefulWidget {
  const CVReviewsScreen({super.key});

  @override
  _CVReviewsScreenState createState() => _CVReviewsScreenState();
}

class _CVReviewsScreenState extends State<CVReviewsScreen> {
  final AdminService admin = AdminService();
  List<dynamic> cvReviews = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    fetchCVReviews();
  }

  Future<void> fetchCVReviews() async {
    setState(() => loading = true);
    try {
      final data = await admin.listCVReviews(); // no token needed
      setState(() => cvReviews = data);
    } catch (e) {
      debugPrint("Error fetching CV reviews: $e");
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
            child: cvReviews.isEmpty
                ? const Center(child: Text("No CV reviews found"))
                : ListView.builder(
                    itemCount: cvReviews.length,
                    itemBuilder: (_, index) {
                      final c = cvReviews[index];
                      return Card(
                        margin: const EdgeInsets.symmetric(vertical: 8),
                        child: ListTile(
                          title: Text(c['candidate_name']),
                          subtitle: Text("Score: ${c['score']}"),
                        ),
                      );
                    },
                  ),
          );
  }
}
