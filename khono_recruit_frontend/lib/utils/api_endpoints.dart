class ApiEndpoints {
  // ------------------- Auth -------------------
  static const baseUrl = "http://127.0.0.1:5000/api/auth";

  static const register = "$baseUrl/register";
  static const verify = "$baseUrl/verify";
  static const login = "$baseUrl/login";
  static const forgotPassword = "$baseUrl/forgot-password";
  static const resetPassword = "$baseUrl/reset-password";

  // ------------------- Candidate -------------------
  static const candidateBase = "http://127.0.0.1:5000/api/candidate";

  static const enrollment = "$candidateBase/enrollment";
  static const applyJob = "$candidateBase/apply"; // POST /apply/<job_id>
  static const submitAssessment =
      "$candidateBase/applications"; // POST /applications/<application_id>/assessment
  static const uploadResume =
      "$candidateBase/upload_resume"; // POST /upload_resume/<application_id>
  static const getApplications = "$candidateBase/applications"; // GET
  static const getAvailableJobs = "$candidateBase/jobs"; // GET /jobs

  // ------------------- Admin / Hiring Manager -------------------
  static const adminBase = "http://127.0.0.1:5000/api/admin";

  // Jobs
  static const adminJobs = "$adminBase/jobs"; // GET / POST / PUT / DELETE
  static const getJobById = "$adminBase/jobs"; // + /jobId
  static const createJob = "$adminBase/jobs"; // POST
  static const updateJob = "$adminBase/jobs"; // PUT + /jobId
  static const deleteJob = "$adminBase/jobs"; // DELETE + /jobId

  // Candidates & Applications
  static const viewCandidates = "$adminBase/candidates";
  static const getApplicationById =
      "$adminBase/applications"; // + /applicationId
  static const shortlistCandidates = "$adminBase/jobs"; // + /jobId/shortlist

  // Interviews
  static const scheduleInterview = "$adminBase/interviews"; // POST
  static const getAllInterviews = "$adminBase/interviews"; // GET
  static const cancelInterview =
      "$adminBase/interviews"; // DELETE + /interviewId

  // Notifications
  static const getNotifications = "$adminBase/notifications"; // + /userId

  // Audit / Logs
  static const auditLogs = "$adminBase/audit/logs";

  // CV Parser
  static const parseResume = "$adminBase/cv/parse";
}
