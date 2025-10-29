import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:vector_math/vector_math_64.dart' as vm; // Import vector_math_64
import '../../services/auth_service.dart';
import '../../utils/api_endpoints.dart';

class CandidateListScreen extends StatefulWidget {
  const CandidateListScreen({super.key});

  @override
  State<CandidateListScreen> createState() => _CandidateListScreenState();
}

class _CandidateListScreenState extends State<CandidateListScreen> {
  List<dynamic> candidates = [];
  bool loading = true;

  // Track hovered card
  int? hoveredIndex;

  @override
  void initState() {
    super.initState();
    fetchCandidates();
  }

  Future<void> fetchCandidates() async {
    try {
      final response = await AuthService.authorizedGet(
        "${ApiEndpoints.adminBase}/candidates/all",
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          candidates = data['candidates'];
          loading = false;
        });
      } else {
        setState(() => loading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to load candidates')),
        );
      }
    } catch (e) {
      setState(() => loading = false);
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("All Candidates"),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : candidates.isEmpty
              ? const Center(child: Text("No candidates found"))
              : LayoutBuilder(
                  builder: (context, constraints) {
                    int cardsPerRow = 1;
                    double width = constraints.maxWidth;

                    if (width >= 1200) {
                      cardsPerRow = 3;
                    } else if (width >= 800) {
                      cardsPerRow = 2;
                    }

                    double cardWidth =
                        (width - (16 * (cardsPerRow + 1))) / cardsPerRow;

                    return SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: Wrap(
                        spacing: 16,
                        runSpacing: 16,
                        children: candidates.asMap().entries.map((entry) {
                          int index = entry.key;
                          var c = entry.value;

                          bool isHovered = hoveredIndex == index;

                          return MouseRegion(
                            onEnter: (_) =>
                                setState(() => hoveredIndex = index),
                            onExit: (_) => setState(() => hoveredIndex = null),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              transform: isHovered
                                  ? (Matrix4.identity()..translate(vm.Vector3(0, -8, 0))) // Use vm.Vector3
                                  : Matrix4.identity(),
                              width: cardWidth,
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: isHovered
                                    ? Colors.white
                                        .withAlpha((255 * 0.1).round()) // Use withAlpha
                                    : Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: isHovered
                                        ? const Color.fromRGBO(151, 18, 8, 1)
                                            .withAlpha((255 * 0.1).round()) // Use withAlpha
                                        : Colors.black.withAlpha((255 * 0.1).round()), // Use withAlpha
                                    blurRadius: isHovered ? 12 : 8,
                                    offset: const Offset(2, 2),
                                  ),
                                ],
                                border: Border.all(
                                  color: Colors.grey.withAlpha((255 * 0.2).round()), // Use withAlpha
                                ),
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  CircleAvatar(
                                    radius: 40,
                                    backgroundImage: (() {
                                      final dynamic v = c['profile_picture'];
                                      if (v is String && v.isNotEmpty) {
                                        return NetworkImage(v) as ImageProvider<Object>;
                                      }
                                      return null;
                                    })(),
                                    child: c['profile_picture'] == null
                                        ? const Icon(Icons.person, size: 40)
                                        : null,
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          c['full_name'] ?? 'Unknown',
                                          style: const TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold),
                                        ),
                                        const SizedBox(height: 4),
                                        Text("Email: ${c['email'] ?? 'N/A'}"),
                                        Text("Phone: ${c['phone'] ?? 'N/A'}"),
                                        Text(
                                            "Address: ${c['address'] ?? 'N/A'}"),
                                        Text(
                                            "Location: ${c['location'] ?? 'N/A'}"),
                                        Text("Gender: ${c['gender'] ?? 'N/A'}"),
                                        Text("ID: ${c['id_number'] ?? 'N/A'}"),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    );
                  },
                ),
    );
  }
}
