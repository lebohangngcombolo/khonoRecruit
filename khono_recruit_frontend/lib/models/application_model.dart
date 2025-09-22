class Application {
  final int id;
  final int jobId; // ✅ add jobId
  final String candidateName;
  final String jobTitle;
  final bool graded;

  Application({
    required this.id,
    required this.jobId, // ✅ required
    required this.candidateName,
    required this.jobTitle,
    this.graded = false, // default to false
  });

  factory Application.fromJson(Map<String, dynamic> json) {
    return Application(
      id: json['id'] ?? 0, // fallback to 0 if null
      jobId: json['job_id'] ?? 0, // ✅ parse from API response
      candidateName: json['candidate_name']?.toString() ?? 'Unknown',
      jobTitle: json['job_title']?.toString() ?? 'Unknown',
      graded: json['graded'] ?? false,
    );
  }
}
