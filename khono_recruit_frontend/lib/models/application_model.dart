class Application {
  final int id;
  final String candidateName;
  final String jobTitle;

  Application(
      {required this.id, required this.candidateName, required this.jobTitle});

  factory Application.fromJson(Map<String, dynamic> json) {
    return Application(
      id: json['id'],
      candidateName: json['candidate_name'],
      jobTitle: json['job_title'],
    );
  }
}
