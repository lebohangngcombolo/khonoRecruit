import 'package:flutter/material.dart';

class HMDashboardData {
  final int openRequisitions;
  final int activeCandidates;
  final int interviewsToday;
  final double avgTimeToFill;
  final List<PipelineData> pipelineData;
  final List<ActivityData> recentActivity;
  final List<AIMatchData> topAIMatches;
  final List<TimeToFillData> timeToFillData;
  final List<DiversityData> genderData;
  final List<DiversityData> ethnicityData;
  final List<SourceData> sourceData;
  final List<ActivityData> recentActivities;
  final List<CandidateData> topCandidates;

  HMDashboardData({
    required this.openRequisitions,
    required this.activeCandidates,
    required this.interviewsToday,
    required this.avgTimeToFill,
    required this.pipelineData,
    required this.recentActivity,
    required this.topAIMatches,
    this.timeToFillData = const [],
    this.genderData = const [],
    this.ethnicityData = const [],
    this.sourceData = const [],
    this.recentActivities = const [],
    this.topCandidates = const [],
  });

  factory HMDashboardData.fromJson(Map<String, dynamic> json) {
    return HMDashboardData(
      openRequisitions: json['open_requisitions'] ?? 0,
      activeCandidates: json['active_candidates'] ?? 0,
      interviewsToday: json['interviews_today'] ?? 0,
      avgTimeToFill: (json['avg_time_to_fill'] ?? 0).toDouble(),
      pipelineData: (json['pipeline_data'] as List?)
              ?.map((item) => PipelineData.fromJson(item))
              .toList() ??
          [],
      recentActivity: (json['recent_activity'] as List?)
              ?.map((item) => ActivityData.fromJson(item))
              .toList() ??
          [],
      topAIMatches: (json['top_ai_matches'] as List?)
              ?.map((item) => AIMatchData.fromJson(item))
              .toList() ??
          [],
      timeToFillData: (json['time_to_fill_data'] as List?)
              ?.map((item) => TimeToFillData.fromJson(item))
              .toList() ??
          [],
      genderData: (json['gender_data'] as List?)
              ?.map((item) => DiversityData.fromJson(item))
              .toList() ??
          [],
      ethnicityData: (json['ethnicity_data'] as List?)
              ?.map((item) => DiversityData.fromJson(item))
              .toList() ??
          [],
      sourceData: (json['source_data'] as List?)
              ?.map((item) => SourceData.fromJson(item))
              .toList() ??
          [],
      recentActivities: (json['recent_activities'] as List?)
              ?.map((item) => ActivityData.fromJson(item))
              .toList() ??
          [],
      topCandidates: (json['top_candidates'] as List?)
              ?.map((item) => CandidateData.fromJson(item))
              .toList() ??
          [],
    );
  }
}

class PipelineData {
  final String stage;
  final int count;
  final double percentage;

  PipelineData({
    required this.stage,
    required this.count,
    required this.percentage,
  });

  factory PipelineData.fromJson(Map<String, dynamic> json) {
    return PipelineData(
      stage: json['stage'] ?? '',
      count: json['count'] ?? 0,
      percentage: (json['percentage'] ?? 0).toDouble(),
    );
  }
}

class ActivityData {
  final String type;
  final String title;
  final String description;
  final String subtitle;
  final DateTime timestamp;
  final String timeAgo;
  final Color color;
  final IconData icon;

  ActivityData({
    required this.type,
    required this.title,
    required this.description,
    this.subtitle = '',
    required this.timestamp,
    this.timeAgo = '',
    this.color = Colors.blue,
    this.icon = Icons.info,
  });

  factory ActivityData.fromJson(Map<String, dynamic> json) {
    return ActivityData(
      type: json['type'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      subtitle: json['subtitle'] ?? '',
      timestamp: DateTime.parse(json['timestamp']),
      timeAgo: json['time_ago'] ?? '',
      color: _getColorFromString(json['color']),
      icon: _getIconFromString(json['icon']),
    );
  }

  static Color _getColorFromString(String? colorName) {
    switch (colorName?.toLowerCase()) {
      case 'red':
        return Colors.red;
      case 'green':
        return Colors.green;
      case 'blue':
        return Colors.blue;
      case 'orange':
        return Colors.orange;
      case 'purple':
        return Colors.purple;
      default:
        return Colors.blue;
    }
  }

  static IconData _getIconFromString(String? iconName) {
    switch (iconName?.toLowerCase()) {
      case 'person':
        return Icons.person;
      case 'work':
        return Icons.work;
      case 'interview':
        return Icons.calendar_today;
      case 'assessment':
        return Icons.assessment;
      default:
        return Icons.info;
    }
  }
}

class AIMatchData {
  final int candidateId;
  final String candidateName;
  final double score;
  final double skillsMatch;
  final double experienceMatch;
  final double educationMatch;
  final String recommendation;

  AIMatchData({
    required this.candidateId,
    required this.candidateName,
    required this.score,
    required this.skillsMatch,
    required this.experienceMatch,
    required this.educationMatch,
    required this.recommendation,
  });

  factory AIMatchData.fromJson(Map<String, dynamic> json) {
    return AIMatchData(
      candidateId: json['candidate_id'] ?? 0,
      candidateName: json['candidate_name'] ?? '',
      score: (json['score'] ?? 0).toDouble(),
      skillsMatch: (json['skills_match'] ?? 0).toDouble(),
      experienceMatch: (json['experience_match'] ?? 0).toDouble(),
      educationMatch: (json['education_match'] ?? 0).toDouble(),
      recommendation: json['recommendation'] ?? '',
    );
  }
}

class CandidateData {
  final int id;
  final String name;
  final String email;
  final String position;
  final List<String> skills;
  final double matchScore;
  final String status;
  final DateTime appliedDate;
  final String requisition; // ✅ Add this

  CandidateData({
    required this.id,
    required this.name,
    required this.email,
    required this.position,
    required this.skills,
    required this.matchScore,
    required this.status,
    required this.appliedDate,
    required this.requisition, // ✅ Add this
  });

  factory CandidateData.fromJson(Map<String, dynamic> json) {
    return CandidateData(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      position: json['position'] ?? '',
      skills: List<String>.from(json['skills'] ?? []),
      matchScore: (json['match_score'] ?? 0).toDouble(),
      status: json['status'] ?? '',
      appliedDate: DateTime.parse(json['applied_date']),
      requisition: json['requisition'] ?? '', // ✅ Parse from backend
    );
  }
}

class RequisitionData {
  final int id;
  final String title;
  final String description;
  final List<String> requiredSkills;
  final int minExperience;
  final String status;
  final DateTime createdAt;
  final String department;
  final DateTime createdDate;
  final String priority;
  final int candidateCount;
  final int applicants;
  final DateTime? deadline;

  RequisitionData({
    required this.id,
    required this.title,
    required this.description,
    required this.requiredSkills,
    required this.minExperience,
    required this.status,
    required this.createdAt,
    this.department = '',
    DateTime? createdDate,
    this.priority = 'Medium',
    this.candidateCount = 0,
    this.applicants = 0,
    this.deadline,
  }) : createdDate = createdDate ?? createdAt;

  factory RequisitionData.fromJson(Map<String, dynamic> json) {
    return RequisitionData(
      id: json['id'] ?? 0,
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      requiredSkills: List<String>.from(json['required_skills'] ?? []),
      minExperience: json['min_experience'] ?? 0,
      status: json['status'] ?? 'active',
      createdAt: DateTime.parse(json['created_at']),
    );
  }
}

class InterviewData {
  final int id;
  final String candidateName;
  final String position;
  final DateTime scheduledTime;
  final String location;
  final String status;
  final String interviewer;

  InterviewData({
    required this.id,
    required this.candidateName,
    required this.position,
    required this.scheduledTime,
    required this.location,
    required this.status,
    required this.interviewer,
  });

  factory InterviewData.fromJson(Map<String, dynamic> json) {
    return InterviewData(
      id: json['id'] ?? 0,
      candidateName: json['candidate_name'] ?? '',
      position: json['position'] ?? '',
      scheduledTime:
          DateTime.tryParse(json['scheduled_time']?.toString() ?? '') ??
              DateTime.now(),
      location: json['location'] ?? '',
      status: json['status'] ?? '',
      interviewer: json['interviewer'] ?? '',
    );
  }
}

class AssessmentData {
  final int id;
  final String name;
  final String description;
  final int totalQuestions;
  final int passingScore;
  final List<AssessmentResult> results;

  AssessmentData({
    required this.id,
    required this.name,
    required this.description,
    required this.totalQuestions,
    required this.passingScore,
    required this.results,
  });

  factory AssessmentData.fromJson(Map<String, dynamic> json) {
    return AssessmentData(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      totalQuestions: json['total_questions'] ?? 0,
      passingScore: json['passing_score'] ?? 60,
      results: (json['results'] as List?)
              ?.map((e) => AssessmentResult.fromJson(e))
              .toList() ??
          [],
    );
  }
}

class AssessmentResult {
  final int candidateId;
  final String candidateName;
  final int score;
  final DateTime submittedAt;
  final bool passed;

  AssessmentResult({
    required this.candidateId,
    required this.candidateName,
    required this.score,
    required this.submittedAt,
    required this.passed,
  });

  factory AssessmentResult.fromJson(Map<String, dynamic> json) {
    return AssessmentResult(
      candidateId: json['candidate_id'] ?? 0,
      candidateName: json['candidate_name'] ?? '',
      score: json['score'] ?? 0,
      submittedAt: DateTime.tryParse(json['submitted_at']?.toString() ?? '') ??
          DateTime.now(),
      passed: json['passed'] ?? false,
    );
  }
}

// Missing classes for HM overview page
class TimeToFillData {
  final String month;
  final int days;

  TimeToFillData({required this.month, required this.days});

  factory TimeToFillData.fromJson(Map<String, dynamic> json) {
    return TimeToFillData(
      month: json['month'] ?? '',
      days: json['days'] ?? 0,
    );
  }
}

class DiversityData {
  final String category;
  final int count;
  final double percentage;

  DiversityData({
    required this.category,
    required this.count,
    required this.percentage,
  });

  factory DiversityData.fromJson(Map<String, dynamic> json) {
    return DiversityData(
      category: json['category'] ?? '',
      count: json['count'] ?? 0,
      percentage: (json['percentage'] ?? 0).toDouble(),
    );
  }
}

class SourceData {
  final String source;
  final int applications;
  final int interviews;
  final int hires;
  final double conversionRate;

  SourceData({
    required this.source,
    required this.applications,
    required this.interviews,
    required this.hires,
    required this.conversionRate,
  });

  factory SourceData.fromJson(Map<String, dynamic> json) {
    return SourceData(
      source: json['source'] ?? '',
      applications: json['applications'] ?? 0,
      interviews: json['interviews'] ?? 0,
      hires: json['hires'] ?? 0,
      conversionRate: (json['conversion_rate'] ?? 0).toDouble(),
    );
  }
}
