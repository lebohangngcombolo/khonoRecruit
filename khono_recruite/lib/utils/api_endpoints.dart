class ApiEndpoints {
  // ------------------- Base URLs -------------------
  static const authBase = "http://127.0.0.1:5000/api/auth";
  static const candidateBase = "http://127.0.0.1:5000/api/candidate";
  static const adminBase = "http://127.0.0.1:5000/api/admin";
  static const chatbotBase = "http://127.0.0.1:5000/api/chatbot";
  static const hmBase = "http://127.0.0.1:5000/api/admin";

  // ------------------- Auth -------------------
  static const register = "$authBase/register";
  static const verify = "$authBase/verify";
  static const login = "$authBase/login";
  static const logout = "$authBase/logout";
  static const forgotPassword = "$authBase/forgot-password";
  static const resetPassword = "$authBase/reset-password";
  static const changePassword = "$authBase/change-password"; // ✅ NEW
  static const currentUser = "$authBase/me";
  // ✅ NEW: Admin Enroll Candidate with Temp Password
  static const adminEnroll = "$authBase/admin-enroll";
  static const firebaseLogin = "$authBase/firebase-login";

  // ------------------- OAuth -------------------
  static const googleOAuth = "$authBase/google";
  static const googleOAuthCallback = "$authBase/google/callback";
  static const githubOAuth = "$authBase/github";
  static const githubOAuthCallback = "$authBase/github/callback";

  // ------------------- MFA -------------------
// Initiate MFA setup (requires JWT)
  static const mfaSetup = "$authBase/mfa/setup";
// Confirm MFA setup (requires JWT)
  static const mfaConfirm = "$authBase/mfa/confirm";
// Verify MFA during login (email + token)
  static const mfaVerify = "$authBase/mfa/verify";

  // ------------------- Candidate -------------------
  static const enrollment = "$candidateBase/enrollment";
  static const applyJob = "$candidateBase/apply"; // POST /apply/<job_id>
  static const submitAssessment =
      "$candidateBase/applications"; // POST /applications/<application_id>/assessment
  static const uploadResume =
      "$candidateBase/upload_resume"; // POST /upload_resume/<application_id>
  static const getApplications = "$candidateBase/applications"; // GET
  static const getAvailableJobs = "$candidateBase/jobs"; // GET
  // ✅ NEW: Save for Later (Draft Application Endpoints)
  static const saveDraft =
      "$candidateBase/apply/save_draft"; // POST /save_draft/<job_id>
  static const getDrafts = "$candidateBase/applications/drafts"; // GET
  static const submitDraft =
      "$candidateBase/applications/submit_draft"; // PUT /submit_draft/<draft_id>

  // ------------------- Admin / Hiring Manager -------------------
  static const adminJobs = "$adminBase/jobs"; // GET / POST / PUT / DELETE
  static const getJobById = "$adminBase/jobs"; // + /jobId
  static const createJob = "$adminBase/jobs"; // POST
  static const updateJob = "$adminBase/jobs"; // PUT + /jobId
  static const deleteJob = "$adminBase/jobs"; // DELETE + /jobId
  static const viewCandidates = "$adminBase/candidates";
  static const getApplicationById =
      "$adminBase/applications"; // + /applicationId
  static const shortlistCandidates = "$adminBase/jobs"; // + /jobId/shortlist
  static const scheduleInterview = "$adminBase/interviews"; // POST
  static const getAllInterviews = "$adminBase/interviews"; // GET
  static const cancelInterview =
      "$adminBase/interviews"; // DELETE + /interviewId
  static const getNotifications = "$adminBase/notifications"; // + /userId
  static const auditLogs = "$adminBase/audit/logs";
  static const parseResume = "$adminBase/cv/parse";
  static const cvReviews = "$adminBase/cv-reviews";

  // ------------------- AI Chatbot -------------------
  static const parseCV = "$chatbotBase/parse_cv"; // POST -> CV + job desc
  static const askBot = "$chatbotBase/ask"; // POST -> normal Q/A chat
}
