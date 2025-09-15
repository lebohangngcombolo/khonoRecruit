class Assessment {
  final double score;
  final String feedback;

  Assessment({required this.score, required this.feedback});

  factory Assessment.fromJson(Map<String, dynamic> json) {
    return Assessment(
      score: json['score'].toDouble(),
      feedback: json['feedback'],
    );
  }
}
