class Candidate {
  final int? id;
  final int userId;
  final String? fullName;
  final String? phone;
  final String? cvUrl;
  final String? cvText;
  final List<dynamic> education;
  final List<String> skills;
  final List<dynamic> workExperience;
  final String requisition; // ✅ Add this

  Candidate({
    this.id,
    required this.userId,
    this.fullName,
    this.phone,
    this.cvUrl,
    this.cvText,
    this.education = const [],
    this.skills = const [],
    this.workExperience = const [],
    required this.requisition, // ✅ Add this
  });

  factory Candidate.fromJson(Map<String, dynamic> json) {
    return Candidate(
      id: json['id'],
      userId: json['user_id'],
      fullName: json['full_name'],
      phone: json['phone'],
      cvUrl: json['cv_url'],
      cvText: json['cv_text'],
      education: json['education'] ?? [],
      skills: List<String>.from(json['skills'] ?? []),
      workExperience: json['work_experience'] ?? [],
      requisition: json['requisition'] ?? '', // ✅ Parse from backend
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'full_name': fullName,
      'phone': phone,
      'cv_url': cvUrl,
      'cv_text': cvText,
      'education': education,
      'skills': skills,
      'work_experience': workExperience,
    };
  }
}
