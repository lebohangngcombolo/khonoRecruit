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
  static const changePassword = "$authBase/change-password";
  static const currentUser = "$authBase/me";
  static const adminEnroll = "$authBase/admin-enroll";
  static const firebaseLogin = "$authBase/firebase-login";

  // ------------------- OAuth (UPDATED FOR SUPABASE) -------------------
  static const googleOAuth = "$authBase/google";
  static const githubOAuth = "$authBase/github";
  static const supabaseCallback = "$authBase/callback"; // New unified callback
  // ------------------- SSO -------------------
  static const ssoLogout = "$authBase/sso/logout"; // <-- ADDED

  // ------------------- MFA (UPDATED TO MATCH BACKEND) -------------------
  static const enableMfa = "$authBase/mfa/enable"; // POST - Initiate MFA setup
  static const verifyMfaSetup =
      "$authBase/mfa/verify"; // POST - Verify MFA setup
  static const mfaLogin =
      "$authBase/mfa/login"; // POST - Verify MFA during login
  static const disableMfa = "$authBase/mfa/disable"; // POST - Disable MFA
  static const mfaStatus = "$authBase/mfa/status"; // GET - Get MFA status
  static const backupCodes =
      "$authBase/mfa/backup-codes"; // GET - Get backup codes
  static const regenerateBackupCodes =
      "$authBase/mfa/regenerate-backup-codes"; // POST - Regenerate backup codes

  // ------------------- Candidate -------------------
  static const enrollment = "$candidateBase/enrollment";
  static const applyJob = "$candidateBase/apply";
  static const submitAssessment = "$candidateBase/applications";
  static const uploadResume = "$candidateBase/upload_resume";
  static const getApplications = "$candidateBase/applications";
  static const getAvailableJobs = "$candidateBase/jobs";
  static const saveDraft = "$candidateBase/apply/save_draft";
  static const getDrafts = "$candidateBase/applications/drafts";
  static const submitDraft = "$candidateBase/applications/submit_draft";

  // ------------------- Admin / Hiring Manager -------------------
  static const adminJobs = "$adminBase/jobs";
  static const getJobById = "$adminBase/jobs";
  static const createJob = "$adminBase/jobs";
  static const updateJob = "$adminBase/jobs";
  static const deleteJob = "$adminBase/jobs";
  static const viewCandidates = "$adminBase/candidates";
  static const getApplicationById = "$adminBase/applications";
  static const shortlistCandidates = "$adminBase/jobs";
  static const scheduleInterview = "$adminBase/interviews";
  static const getAllInterviews = "$adminBase/interviews";
  static const cancelInterview = "$adminBase/interviews";
  static const getNotifications = "$adminBase/notifications";
  static const auditLogs = "$adminBase/audit/logs";
  static const parseResume = "$adminBase/cv/parse";
  static const cvReviews = "$adminBase/cv-reviews";

  // Shared Notes
  static const createNote = "$adminBase/shared-notes";
  static const getNotes = "$adminBase/shared-notes";
  static const getNoteById = "$adminBase/shared-notes"; // Use with /{id}
  static const updateNote =
      "$adminBase/shared-notes"; // Use with /{id} and PUT method
  static const deleteNote =
      "$adminBase/shared-notes"; // Use with /{id} and DELETE method

// Meetings
  static const createMeeting = "$adminBase/meetings";
  static const getMeetings = "$adminBase/meetings";
  static const getMeetingById = "$adminBase/meetings"; // Use with /{id}
  static const updateMeeting =
      "$adminBase/meetings"; // Use with /{id} and PUT method
  static const deleteMeeting =
      "$adminBase/meetings"; // Use with /{id} and DELETE method
  static const cancelMeeting =
      "$adminBase/meetings/cancel"; // Use with /{id} and POST method
  static const getUpcomingMeetings = "$adminBase/meetings/upcoming";

  // ------------------- AI Chatbot -------------------
  static const parseCV = "$chatbotBase/parse_cv";
  static const askBot = "$chatbotBase/ask";
}
