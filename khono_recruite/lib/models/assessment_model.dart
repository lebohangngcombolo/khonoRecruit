class AssessmentResult {
  final int? id;
  final int applicationId;
  final Map<String, dynamic> scores;
  final double totalScore;
  final String? recommendation;
  final DateTime? assessedAt;

  AssessmentResult({
    this.id,
    required this.applicationId,
    this.scores = const {},
    this.totalScore = 0,
    this.recommendation,
    this.assessedAt,
  });

  factory AssessmentResult.fromJson(Map<String, dynamic> json) {
    return AssessmentResult(
      id: json['id'],
      applicationId: json['application_id'],
      scores: Map<String, dynamic>.from(json['scores'] ?? {}),
      totalScore: (json['total_score'] ?? 0).toDouble(),
      recommendation: json['recommendation'],
      assessedAt: json['assessed_at'] != null
          ? DateTime.parse(json['assessed_at'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'application_id': applicationId,
      'scores': scores,
      'total_score': totalScore,
      'recommendation': recommendation,
    };
  }
}
