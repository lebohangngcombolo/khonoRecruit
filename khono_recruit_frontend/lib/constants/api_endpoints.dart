class ApiEndpoints {
  static const String baseUrl = 'http://127.0.0.1:5000/api';

  // Auth
  static const String register = '/auth/register';
  static const String login = '/auth/login';
  static const String refresh = '/auth/refresh';
  static const String me = '/auth/me';
  static const String verifyEmail = '/auth/verify';
  static const String forgotPassword = '/auth/forgot-password';
  static const String resetPassword = '/auth/reset-password';

  // Admin
  static const String adminUsers = '/admin/users';
  static const String adminJobs = '/admin/jobs';
  static const String adminApplications = '/admin/applications';
  static const String updateRole = '/admin/role';

  // Jobs
  static const String jobs = '/jobs';
  static const String jobCandidates = '/jobs'; // append /<job_id>/candidates
  static const String jobShortlist = '/jobs'; // append /<job_id>/shortlist

  // Applications
  static const String applicationAssessment =
      '/applications'; // append /<application_id>/assessment
}
