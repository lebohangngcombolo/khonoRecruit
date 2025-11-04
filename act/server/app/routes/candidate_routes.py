from flask import Blueprint, request, jsonify, current_app
from flask_jwt_extended import get_jwt_identity, jwt_required
from app.extensions import db, cloudinary_client
from werkzeug.security import check_password_hash, generate_password_hash
from app.extensions import bcrypt
import cloudinary.uploader
from app.models import (
    User, Candidate, Requisition, Application, AssessmentResult, Notification, AuditLog
)
from datetime import datetime
from werkzeug.utils import secure_filename

from app.services.cv_parser_service import HybridResumeAnalyzer
from app.utils.decorators import role_required
from app.utils.helper import get_current_candidate
from app.services.audit2 import AuditService
import fitz



candidate_bp = Blueprint("candidate_bp", __name__)

# ----------------- APPLY FOR JOB -----------------
@candidate_bp.route("/apply/<int:job_id>", methods=["POST"])
@role_required(["candidate"])
def apply_job(job_id):
    try:
        user_id = get_jwt_identity()
        user = User.query.get_or_404(user_id)
        data = request.get_json()

        # Fetch or create Candidate profile
        candidate = Candidate.query.filter_by(user_id=user.id).first()
        if not candidate:
            candidate = Candidate(user_id=user.id)
            db.session.add(candidate)
            db.session.commit()

        # Update candidate info
        candidate.full_name = data.get("full_name", candidate.full_name)
        candidate.phone = data.get("phone", candidate.phone)
        candidate.profile["portfolio"] = data.get("portfolio")
        candidate.profile["cover_letter"] = data.get("cover_letter")
        db.session.commit()

        # Check if candidate already applied
        existing_app = Application.query.filter_by(
            candidate_id=candidate.id,
            requisition_id=job_id
        ).first()
        if existing_app:
            return jsonify({"error": "You have already applied for this job"}), 400

        # Create new application
        application = Application(
            candidate_id=candidate.id,
            requisition_id=job_id,
            status="applied",
            created_at=datetime.utcnow()
        )
        db.session.add(application)
        db.session.commit()

        return jsonify({"message": "Applied successfully!", "application_id": application.id}), 201

    except Exception as e:
        current_app.logger.error(f"Apply job error: {e}", exc_info=True)
        return jsonify({"error": "Internal server error"}), 500


# ----------------- GET AVAILABLE JOBS -----------------
@candidate_bp.route("/jobs", methods=["GET"])
@role_required(["candidate"])
def get_available_jobs():
    try:
        jobs = Requisition.query.all()
        result = []

        for job in jobs:
            result.append({
                "id": job.id,
                "title": job.title or "",
                "description": job.description or "",
                "responsibilities": job.responsibilities or [],
                "qualifications": job.qualifications or [],
                "required_skills": job.required_skills or [],
                "min_experience": job.min_experience or 0,
                "knockout_rules": job.knockout_rules or [],
                "weightings": job.weightings or {"cv": 60, "assessment": 40},
                "assessment_pack": job.assessment_pack or {"questions": []},
                "company_details": job.company_details or "",
                "category": job.category or "",
                "published_on": job.published_on.strftime("%d %b, %Y") if job.published_on else "",
                "vacancy": str(job.vacancy or 0),
                "created_by": job.created_by
            })
        return jsonify(result), 200

    except Exception as e:
        current_app.logger.error(f"Get available jobs error: {e}", exc_info=True)
        return jsonify({"error": "Internal server error"}), 500


# ----------------- UPLOAD RESUME -----------------
@candidate_bp.route("/upload_resume/<int:application_id>", methods=["POST"])
@role_required(["candidate"])
def upload_resume(application_id):
    try:
        application = Application.query.get_or_404(application_id)
        candidate = application.candidate
        job = application.requisition

        if application.candidate.user.id != int(get_jwt_identity()):
            return jsonify({"error": "Unauthorized"}), 403

        if getattr(application, "resume_url", None):
            return jsonify({"error": "Resume already uploaded"}), 400

        if "resume" not in request.files:
            return jsonify({"error": "No resume uploaded"}), 400

        file = request.files["resume"]

        # --- Upload to Cloudinary ---
        resume_url = HybridResumeAnalyzer.upload_cv(file)
        if not resume_url:
            return jsonify({"error": "Failed to upload resume"}), 500

        # --- Extract PDF text if needed ---
        resume_text = request.form.get("resume_text", "")
        if not resume_text and file.filename.lower().endswith(".pdf"):
            file.stream.seek(0)
            pdf_doc = fitz.open(stream=file.stream.read(), filetype="pdf")
            resume_text = ""
            for page in pdf_doc:
                resume_text += page.get_text()

        # --- Hybrid Resume Analysis ---
        analyzer = HybridResumeAnalyzer()
        parser_result = analyzer.analyse(resume_text, job.id)

        # --- Save results ---
        application.resume_url = resume_url
        application.cv_score = parser_result.get("match_score", 0)
        application.cv_parser_result = parser_result
        application.recommendation = parser_result.get("recommendation", "")
        db.session.commit()

        # --- Notify admins ---
        admins = User.query.filter_by(role="admin").all()
        for admin in admins:
            notif = Notification(
                user_id=admin.id,
                message=f"{candidate.full_name} submitted resume for {job.title}."
            )
            db.session.add(notif)
        db.session.commit()

        return jsonify({
            "message": "Resume uploaded and analyzed",
            "cv_score": application.cv_score,
            "missing_skills": parser_result.get("missing_skills", []),
            "suggestions": parser_result.get("suggestions", []),
            "recommendation": application.recommendation,
            "resume_url": resume_url,
            "raw_parser_text": parser_result.get("raw_text", "")
        }), 200

    except Exception as e:
        current_app.logger.error(f"Upload resume error: {e}", exc_info=True)
        return jsonify({"error": "Internal server error"}), 500


# ----------------- CANDIDATE APPLICATIONS -----------------
@candidate_bp.route("/applications", methods=["GET"])
@role_required(["candidate"])
def get_applications():
    try:
        user_id = get_jwt_identity()
        candidate = Candidate.query.filter_by(user_id=user_id).first()
        if not candidate:
            return jsonify([])

        applications = Application.query.filter_by(candidate_id=candidate.id).all()
        result = []
        for app in applications:
            assessment_result = AssessmentResult.query.filter_by(application_id=app.id).first()
            result.append({
                "application_id": app.id,
                "job_title": app.requisition.title if app.requisition else None,
                "status": app.status,
                "cv_score": app.cv_score,
                "assessment_score": app.assessment_score,
                "overall_score": app.overall_score,
                "recommendation": app.recommendation
            })
        return jsonify(result)
    except Exception as e:
        current_app.logger.error(f"Get applications error: {e}", exc_info=True)
        return jsonify({"error": "Internal server error"}), 500


# ----------------- GET ASSESSMENT -----------------
@candidate_bp.route("/applications/<int:application_id>/assessment", methods=["GET"])
@role_required(["candidate"])
def get_assessment(application_id):
    try:
        application = Application.query.get_or_404(application_id)
        candidate = Candidate.query.filter_by(user_id=get_jwt_identity()).first_or_404()
        if application.candidate_id != candidate.id:
            return jsonify({"error": "Unauthorized"}), 403

        result = AssessmentResult.query.filter_by(application_id=application.id).first()
        return jsonify({
            "job_title": application.requisition.title if application.requisition else None,
            "assessment_pack": application.requisition.assessment_pack if application.requisition else {},
            "submitted_result": result.to_dict() if result else None
        })
    except Exception as e:
        current_app.logger.error(f"Get assessment error: {e}", exc_info=True)
        return jsonify({"error": "Internal server error"}), 500


# ----------------- SUBMIT ASSESSMENT -----------------
@candidate_bp.route("/applications/<int:application_id>/assessment", methods=["POST"])
@role_required(["candidate"])
def submit_assessment(application_id):
    try:
        application = Application.query.get_or_404(application_id)
        candidate = Candidate.query.filter_by(user_id=get_jwt_identity()).first_or_404()
        if application.candidate_id != candidate.id:
            return jsonify({"error": "Unauthorized"}), 403

        existing_result = AssessmentResult.query.filter_by(application_id=application.id).first()
        if existing_result:
            return jsonify({"error": "Assessment already submitted"}), 400

        data = request.get_json()
        answers = data.get("answers", {})

        questions = application.requisition.assessment_pack.get("questions", []) if application.requisition else []
        scores = {}
        total_score = 0

        for idx, q in enumerate(questions):
            qid = str(idx)
            correct_index = q.get("correct_answer", 0)
            correct_letter = ["A","B","C","D"][correct_index]
            candidate_answer = answers.get(qid)
            scores[qid] = q.get("weight", 1) if candidate_answer == correct_letter else 0
            total_score += scores[qid]

        max_score = sum(q.get("weight", 1) for q in questions)
        percentage_score = (total_score / max_score * 100) if max_score else 0

        result = AssessmentResult(
            application_id=application.id,
            candidate_id=candidate.id,
            answers=answers,
            scores=scores,
            total_score=total_score,
            percentage_score=percentage_score,
            recommendation="pass" if percentage_score >= 60 else "fail"
        )
        db.session.add(result)

        # Update application with assessment score
        application.assessment_score = percentage_score
        application.overall_score = (application.cv_score * 0.6 + percentage_score * 0.4)
        application.status = "assessment_submitted"
        application.assessed_date = datetime.utcnow()
        db.session.commit()

        return jsonify({
            "message": "Assessment submitted",
            "assessment_score": percentage_score,
            "overall_score": application.overall_score,
            "recommendation": result.recommendation
        }), 201

    except Exception as e:
        current_app.logger.error(f"Submit assessment error: {e}", exc_info=True)
        return jsonify({"error": "Internal server error"}), 500

@candidate_bp.route("/profile", methods=["GET"])
@role_required(["candidate", "admin", "hiring_manager"])
def get_profile():
    try:
        candidate = get_current_candidate()
        if not candidate:
            return jsonify({"success": False, "message": "Candidate not found"}), 404

        # Return user + candidate data
        return jsonify({
            "success": True,
            "data": {
                "user": candidate.user.to_dict() if candidate.user else {},
                "candidate": candidate.to_dict(),
            }
        }), 200

    except Exception as e:
        current_app.logger.error(f"Get profile error: {e}", exc_info=True)
        return jsonify({"success": False, "message": "Internal server error"}), 500

# ----------------- UPDATE PROFILE -----------------
@candidate_bp.route("/profile", methods=["PUT"])
@role_required(["candidate", "admin", "hiring_manager"])
def update_profile():
    try:
        candidate = get_current_candidate()

        # Auto-create candidate if missing but user exists
        if not candidate:
            user_id = get_jwt_identity()
            user = User.query.get(user_id)
            if not user:
                return jsonify({"success": False, "message": "User not found"}), 404

            candidate = Candidate(user_id=user.id)
            db.session.add(candidate)
            db.session.commit()
            current_app.logger.info(f"Created missing candidate for user id {user.id}")

        user = candidate.user
        data = request.get_json() or {}

        for key, value in data.items():
            # Handle date fields
            if key == "dob":
                if value:
                    try:
                        value = datetime.strptime(value, "%Y-%m-%d").date()
                    except ValueError:
                        return jsonify({"success": False, "message": "Invalid date format"}), 400
                else:
                    value = None

            # Handle JSON fields if sent as string
            if key in ["skills", "work_experience", "education", "certifications", "languages", "documents"] and isinstance(value, str):
                import json
                try:
                    value = json.loads(value)
                except json.JSONDecodeError:
                    value = []

            # Update Candidate attributes
            if hasattr(candidate, key):
                setattr(candidate, key, value)
            # Update User attributes if they exist on User
            elif hasattr(user, key):
                setattr(user, key, value)

        db.session.commit()

        return jsonify({
            "success": True,
            "message": "Profile updated successfully",
            "data": {
                "user": user.to_dict(),
                "candidate": candidate.to_dict(),
            },
        }), 200

    except Exception as e:
        current_app.logger.error(f"Update profile error: {e}", exc_info=True)
        db.session.rollback()
        return jsonify({"success": False, "message": "Internal server error"}), 500


# ----------------- UPLOAD DOCUMENT -----------------
@candidate_bp.route("/upload_document", methods=["POST"])
@role_required(["candidate", "admin", "hiring_manager"])
def upload_document():
    try:
        candidate = get_current_candidate()

        if "document" not in request.files:
            return jsonify({"success": False, "message": "No document uploaded"}), 400

        file = request.files["document"]
        filename = secure_filename(file.filename or "")
        if not filename:
            return jsonify({"success": False, "message": "Invalid filename"}), 400

        allowed_docs = {"pdf", "doc", "docx"}
        if not ('.' in filename and filename.rsplit('.', 1)[1].lower() in allowed_docs):
            return jsonify({"success": False, "message": "Invalid file type"}), 400

        url = upload_cv_to_cloudinary(file)
        if not url:
            return jsonify({"success": False, "message": "Failed to upload document"}), 500

        candidate.cv_url = url
        db.session.commit()

        return jsonify({
            "success": True,
            "message": "Document uploaded successfully",
            "data": {"cv_url": url},
        }), 200

    except Exception as e:
        current_app.logger.error(f"Upload document error: {e}", exc_info=True)
        db.session.rollback()
        return jsonify({"success": False, "message": "Internal server error"}), 500


# ----------------- UPLOAD PROFILE PICTURE -----------------
@candidate_bp.route("/upload_profile_picture", methods=["POST"])
@role_required(["candidate", "admin", "hiring_manager"])
def upload_profile_picture():
    try:
        # ---- Get or create Candidate ----
        candidate = get_current_candidate()
        if not candidate:
            user_id = get_jwt_identity()
            user = User.query.get(user_id)
            if not user:
                return jsonify({"success": False, "message": "User not found"}), 404

            candidate = Candidate(user_id=user.id)
            db.session.add(candidate)
            db.session.commit()
            current_app.logger.info(f"Created missing candidate for user id {user.id}")

        # ---- Validate file ----
        if "image" not in request.files:
            return jsonify({"success": False, "message": "No image uploaded"}), 400

        file = request.files["image"]
        filename = secure_filename(file.filename or "")
        if not filename:
            return jsonify({"success": False, "message": "Invalid filename"}), 400

        allowed_images = {"png", "jpg", "jpeg", "webp"}
        ext = filename.rsplit('.', 1)[-1].lower()
        if ext not in allowed_images:
            return jsonify({"success": False, "message": "Invalid image type"}), 400

        # ---- Upload to Cloudinary ----
        result = cloudinary.uploader.upload(
            file,
            folder="profile_pics/",
            format="jpg",  # convert everything to jpg
            resource_type="image",
            public_id=f"candidate_{candidate.id}"
        )
        url = result.get("secure_url")
        if not url:
            return jsonify({"success": False, "message": "Failed to upload image"}), 500

        # ---- Save to candidate profile ----
        candidate.profile_picture = url
        db.session.commit()

        return jsonify({
            "success": True,
            "message": "Profile picture updated successfully",
            "data": {"profile_picture": url},
        }), 200

    except Exception as e:
        current_app.logger.error(f"Upload profile picture error: {e}", exc_info=True)
        db.session.rollback()
        return jsonify({"success": False, "message": "Internal server error"}), 500

# ----------------- UPDATE GENERAL SETTINGS -----------------
@candidate_bp.route("/settings", methods=["PUT"])
@role_required(["candidate", "admin", "hiring_manager"])
def update_settings():
    try:
        user_id = get_jwt_identity()
        user = User.query.get_or_404(user_id)
        data = request.get_json() or {}

        # Merge new settings into existing
        current_settings = user.settings or {}
        updated_settings = {**current_settings, **data}
        user.settings = updated_settings

        db.session.commit()
        return jsonify({
            "success": True,
            "message": "Settings updated successfully",
            "data": user.settings,
        }), 200
    except Exception as e:
        current_app.logger.error(f"Update settings error: {e}", exc_info=True)
        db.session.rollback()
        return jsonify({"success": False, "message": "Internal server error"}), 500


# ----------------- CHANGE PASSWORD -----------------
@candidate_bp.route("/settings/change_password", methods=["POST"])
@role_required(["candidate", "admin", "hiring_manager"])
def change_password():
    try:
        # Get current user
        user_id = get_jwt_identity()
        user = User.query.get_or_404(user_id)

        data = request.get_json() or {}
        current_pw = data.get("current_password")
        new_pw = data.get("new_password")

        if not all([current_pw, new_pw]):
            return jsonify({
                "success": False,
                "message": "Both current and new passwords are required."
            }), 400

        # Verify password using bcrypt
        if not bcrypt.check_password_hash(user.password, current_pw):
            return jsonify({
                "success": False,
                "message": "Incorrect current password."
            }), 400

        # Validate new password length
        if len(new_pw) < 8:
            return jsonify({
                "success": False,
                "message": "New password must be at least 8 characters long."
            }), 400

        # Update password
        user.password = bcrypt.generate_password_hash(new_pw).decode('utf-8')
        db.session.commit()  # commit password change first

        # Log audit using the shorthand
        AuditService.log(
            user_id=user.id,
            action="Change Password",
            target_user_id=user.id,
            metadata={"info": "Candidate changed their password successfully."}
        )

        return jsonify({
            "success": True,
            "message": "Password updated successfully."
        }), 200

    except Exception as e:
        current_app.logger.error(f"Change password error: {e}", exc_info=True)
        db.session.rollback()
        return jsonify({
            "success": False,
            "message": "An error occurred while updating password. Please try again."
        }), 500
# ----------------- UPDATE NOTIFICATION PREFERENCES -----------------
@candidate_bp.route("/settings/notifications", methods=["PUT"])
@role_required(["candidate", "admin", "hiring_manager"])
def update_notification_preferences():
    try:
        user_id = get_jwt_identity()
        user = User.query.get_or_404(user_id)
        data = request.get_json() or {}

        prefs = user.settings.get("notifications", {}) if user.settings else {}
        prefs.update(data)
        user.settings = {**(user.settings or {}), "notifications": prefs}

        db.session.commit()
        return jsonify({
            "success": True,
            "message": "Notification preferences updated",
            "data": user.settings.get("notifications"),
        }), 200
    except Exception as e:
        current_app.logger.error(f"Notification preferences error: {e}", exc_info=True)
        db.session.rollback()
        return jsonify({"success": False, "message": "Internal server error"}), 500


# ----------------- DEACTIVATE ACCOUNT -----------------
@candidate_bp.route("/settings/deactivate", methods=["POST"])
@role_required(["candidate", "admin", "hiring_manager"])
def deactivate_account():
    try:
        user_id = get_jwt_identity()
        user = User.query.get_or_404(user_id)
        reason = (request.get_json() or {}).get("reason", "")

        user.is_active = False
        db.session.commit()

        current_app.logger.info(f"User {user.email} deactivated account. Reason: {reason}")
        return jsonify({"success": True, "message": "Account deactivated successfully"}), 200
    except Exception as e:
        current_app.logger.error(f"Deactivate account error: {e}", exc_info=True)
        db.session.rollback()
        return jsonify({"success": False, "message": "Internal server error"}), 500
    
@candidate_bp.route("/settings", methods=["GET"])
@role_required(["candidate", "admin", "hiring_manager"])
def get_settings():
    user_id = get_jwt_identity()
    user = User.query.get_or_404(user_id)
    return jsonify({
        "success": True,
        "data": user.settings or {}
    }), 200
    
@candidate_bp.route('/notifications', methods=['GET'])
@jwt_required()
def get_candidate_notifications():
    """
    Get all notifications for the current candidate
    Returns: List of notification objects (matching your Flutter service expectation)
    """
    try:
        current_user_id = get_jwt_identity()
        
        # Get all notifications for the user, ordered by most recent first
        notifications = Notification.query.filter_by(
            user_id=current_user_id
        ).order_by(Notification.created_at.desc()).all()
        
        # Convert to list of dictionaries using your existing to_dict method
        notifications_data = [notification.to_dict() for notification in notifications]
        
        # Return the list directly (matching your Flutter service expectation)
        return jsonify(notifications_data), 200
        
    except Exception as e:
        current_app.logger.error(f"Get notifications error: {str(e)}")
        return jsonify({'error': f'Failed to fetch notifications: {str(e)}'}), 500

# ----------------- SAVE APPLICATION DRAFT -----------------
@candidate_bp.route("/apply/save_draft/<int:application_id>", methods=["POST"])
@role_required(["candidate"])
def save_application_draft(application_id):
    """
    Allows a candidate to save an existing application as a draft (by application ID).
    """
    try:
        user_id = get_jwt_identity()
        user = User.query.get_or_404(user_id)

        candidate = Candidate.query.filter_by(user_id=user.id).first()
        if not candidate:
            return jsonify({"error": "Candidate profile not found"}), 404

        data = request.get_json() or {}
        draft_data = data.get("draft_data", {})

        # Look up the application by ID and candidate
        application = Application.query.filter_by(
            id=application_id, candidate_id=candidate.id
        ).first()

        if not application:
            return jsonify({"error": f"Application with id {application_id} not found"}), 404

        # Update the draft
        application.draft_data = draft_data
        application.is_draft = True
        db.session.commit()

        return jsonify({
            "message": "Draft updated",
            "application_id": application.id
        }), 200

    except Exception as e:
        current_app.logger.error(f"Update draft error: {e}", exc_info=True)
        db.session.rollback()
        return jsonify({"error": "Internal server error"}), 500



# ----------------- GET ALL DRAFT APPLICATIONS -----------------
@candidate_bp.route("/applications/drafts", methods=["GET"])
@role_required(["candidate"])
def get_application_drafts():
    """
    Retrieve all saved (draft) applications for the current candidate.
    """
    try:
        user_id = get_jwt_identity()
        candidate = Candidate.query.filter_by(user_id=user_id).first()
        if not candidate:
            return jsonify([]), 200

        drafts = Application.query.filter_by(candidate_id=candidate.id, is_draft=True).all()
        return jsonify([d.to_dict() for d in drafts]), 200

    except Exception as e:
        current_app.logger.error(f"Get application drafts error: {e}", exc_info=True)
        return jsonify({"error": "Internal server error"}), 500


# ----------------- SUBMIT SAVED DRAFT -----------------
@candidate_bp.route("/applications/submit_draft/<int:draft_id>", methods=["PUT"])
@role_required(["candidate"])
def submit_draft(draft_id):
    """
    Converts a saved draft application into a real (applied) application.
    """
    try:
        user_id = get_jwt_identity()
        candidate = Candidate.query.filter_by(user_id=user_id).first_or_404()

        draft = Application.query.filter_by(
            id=draft_id, candidate_id=candidate.id, is_draft=True
        ).first_or_404()

        draft.is_draft = False
        draft.status = "applied"
        draft.created_at = datetime.utcnow()
        db.session.commit()

        return jsonify({
            "message": "Draft submitted successfully",
            "application": draft.to_dict()
        }), 200

    except Exception as e:
        current_app.logger.error(f"Submit draft error: {e}", exc_info=True)
        db.session.rollback()
        return jsonify({"error": "Internal server error"}), 500
