class ApplicationModel {
  final int id;
  final int candidateId;
  final int requisitionId;
  final String status;
  final double assessmentScore;
  final double overallScore;
  final String? recommendation;

  // ✅ Candidate info
  final String? candidateName;
  final String? candidateEmail;
  final double? cvScore;
  final String? cvAnalysis;
  final String? cvUrl;

  ApplicationModel({
    required this.id,
    required this.candidateId,
    required this.requisitionId,
    required this.status,
    required this.assessmentScore,
    required this.overallScore,
    this.recommendation,
    this.candidateName,
    this.candidateEmail,
    this.cvScore,
    this.cvAnalysis,
    this.cvUrl,
  });

  factory ApplicationModel.fromJson(Map<String, dynamic> json) {
    return ApplicationModel(
      id: json['id'],
      candidateId: json['candidate_id'],
      requisitionId: json['requisition_id'],
      status: json['status'] ?? 'applied',
      assessmentScore: (json['assessment_score'] ?? 0).toDouble(),
      overallScore: (json['overall_score'] ?? 0).toDouble(),
      recommendation: json['recommendation'],
      candidateName: json['candidate']?['full_name'],
      candidateEmail: json['candidate']?['email'],
      cvScore: (json['cv_score'] ?? 0).toDouble(),
      cvAnalysis: json['cv_analysis'],
      cvUrl: json['candidate']?['cv_url'],
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'candidate_id': candidateId,
        'requisition_id': requisitionId,
        'status': status,
        'assessment_score': assessmentScore,
        'overall_score': overallScore,
        'recommendation': recommendation,
        'candidate': {
          'full_name': candidateName,
          'email': candidateEmail,
          'cv_url': cvUrl,
          'cv_score': cvScore,
          'cv_analysis': cvAnalysis,
        },
      };
}
