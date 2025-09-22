class AssessmentQuestion {
  String question;
  String correctAnswer;

  AssessmentQuestion({required this.question, required this.correctAnswer});

  factory AssessmentQuestion.fromJson(Map<String, dynamic> json) {
    return AssessmentQuestion(
      question: json['question'] ?? '',
      correctAnswer: json['correct_answer'] ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'question': question,
        'correct_answer': correctAnswer,
      };
}

class Assessment {
  final int? id; // optional for new admin assessments
  final int? applicationId; // optional for job-level assessments
  final double? score; // used for candidate-level
  final String? recommendation; // used for candidate-level
  final DateTime? assessedAt; // used for candidate-level
  final Map<String, dynamic>? answers; // used for candidate-level
  List<AssessmentQuestion> questions; // used for admin job-level

  Assessment({
    this.id,
    this.applicationId,
    this.score,
    this.recommendation,
    this.assessedAt,
    this.answers,
    this.questions = const [],
  });

  // For candidate-level assessment
  factory Assessment.fromJson(Map<String, dynamic> json) {
    return Assessment(
      id: json['id'],
      applicationId: json['application_id'],
      score:
          json['total_score'] != null ? (json['total_score']).toDouble() : 0.0,
      recommendation: json['recommendation'] ?? 'Not assessed yet',
      assessedAt: json['assessed_at'] != null
          ? DateTime.parse(json['assessed_at'])
          : DateTime.now(),
      answers: json['scores'] != null
          ? Map<String, dynamic>.from(json['scores'])
          : {},
    );
  }

  // For admin job-level assessment
  factory Assessment.fromJsonJob(Map<String, dynamic> json) {
    return Assessment(
      questions: (json['questions'] as List<dynamic>?)
              ?.map((q) => AssessmentQuestion.fromJson(q))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'questions': questions.map((q) => q.toJson()).toList(),
    };
  }
}
