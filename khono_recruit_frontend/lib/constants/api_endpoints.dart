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

  // Candidate
  static const String uploadCV = '/candidate/upload-cv';
  static const String updateCandidateProfile = '/candidate/profile';
  static const String jobs = '/jobs';
  static const String appliedJobs = '/candidate/applied-jobs'; // ✅ add this
  static const String applyJob = '/jobs'; // append /<job_id>/apply
  static const String applicationAssessment =
      '/applications'; // append /<application_id>/assessment
  static const String getProfile = "/candidate/profile";

  // Dynamic endpoint for job candidates
  static String jobCandidates(int jobId) => '/jobs/$jobId/candidates';

  // Admin
  static const String adminUsers = '/admin/users';
  static const String adminJobs = '/admin/jobs';
  static const String adminApplications = '/admin/applications';
  static const String updateRole = '/admin/role';
}
