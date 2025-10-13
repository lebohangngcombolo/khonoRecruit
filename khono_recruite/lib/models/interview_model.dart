class Interview {
  final int? id;
  final int candidateId;
  final int hiringManagerId;
  final int? applicationId;
  final DateTime scheduledTime;
  final String status;
  final DateTime? createdAt;

  Interview({
    this.id,
    required this.candidateId,
    required this.hiringManagerId,
    this.applicationId,
    required this.scheduledTime,
    this.status = 'scheduled',
    this.createdAt,
  });

  factory Interview.fromJson(Map<String, dynamic> json) {
    return Interview(
      id: json['id'],
      candidateId: json['candidate_id'],
      hiringManagerId: json['hiring_manager_id'],
      applicationId: json['application_id'],
      scheduledTime: DateTime.parse(json['scheduled_time']),
      status: json['status'] ?? 'scheduled',
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'candidate_id': candidateId,
      'hiring_manager_id': hiringManagerId,
      'application_id': applicationId,
      'scheduled_time': scheduledTime.toIso8601String(),
      'status': status,
    };
  }
}
