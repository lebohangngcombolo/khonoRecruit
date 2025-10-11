from flask import Blueprint, request, jsonify, current_app
from flask_jwt_extended import get_jwt_identity
from app.extensions import db, cloudinary_client
from app.models import User, Candidate, Requisition, Application, AssessmentResult, Notification
from datetime import datetime
import cloudinary.uploader
from app.services.cv_parser_service import analyse_resume_openrouter, upload_cv_to_cloudinary
from app.utils.decorators import role_required
import fitz
import io

candidate_bp = Blueprint("candidate_bp", __name__)

# ----------------- APPLY FOR JOB -----------------
# ---------------- Apply for a job ----------------
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
            db.session.commit()  # commit to get candidate.id

        # Update candidate info with submitted fields
        candidate.full_name = data.get("full_name", candidate.full_name)
        candidate.phone = data.get("phone", candidate.phone)
        candidate.profile["portfolio"] = data.get("portfolio")
        candidate.profile["cover_letter"] = data.get("cover_letter")
        db.session.commit()  # save candidate updates

        # Check if candidate already applied for this job
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
                "required_skills": job.required_skills or [],
                "min_experience": job.min_experience or 0,
                "knockout_rules": job.knockout_rules or [],
                "weightings": job.weightings or {"cv": 60, "assessment": 40},
                "assessment_pack": job.assessment_pack or {"questions": []},
                "company": getattr(job, "company", ""),  # optional
                "location": getattr(job, "location", ""),  # optional
                "type": getattr(job, "job_type", ""),  # optional
                "salary": getattr(job, "salary", ""),  # optional
                "published_on": job.published_on.strftime("%d %b, %Y") if job.published_on else "",
                "vacancy": str(job.vacancy or 0),
                "responsibility": getattr(job, "responsibility", ""),
                "qualifications": getattr(job, "qualifications", ""),
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
        # Fetch application, candidate, and job
        application = Application.query.get_or_404(application_id)
        candidate = application.candidate
        job = application.requisition

        # Ensure the logged-in user owns the application
        if application.candidate.user.id != int(get_jwt_identity()):
            return jsonify({"error": "Unauthorized"}), 403

        # Prevent duplicate uploads
        if getattr(application, "resume_url", None):
            return jsonify({"error": "Resume already uploaded for this application"}), 400

        if "resume" not in request.files:
            return jsonify({"error": "No resume uploaded"}), 400

        file = request.files["resume"]

        # Upload file to Cloudinary
        resume_url = upload_cv_to_cloudinary(file)
        if not resume_url:
            return jsonify({"error": "Failed to upload resume"}), 500

        # Extract text from PDF if not provided in form
        resume_text = request.form.get("resume_text", "")
        if not resume_text and file.filename.lower().endswith(".pdf"):
            file.stream.seek(0)
            pdf_doc = fitz.open(stream=file.stream.read(), filetype="pdf")
            resume_text = ""
            for page in pdf_doc:
                resume_text += page.get_text()

        # Analyse resume
        parser_result = analyse_resume_openrouter(resume_text, job_id=job.id)

        # Store CV info in Application table
        application.resume_url = resume_url
        application.cv_score = parser_result.get("match_score", 0)
        application.cv_parser_result = parser_result
        application.recommendation = parser_result.get("recommendation", "")
        db.session.commit()

        # Notify admins
        admins = User.query.filter_by(role="admin").all()
        for admin in admins:
            notif = Notification(
                user_id=admin.id,
                message=f"{candidate.full_name} submitted resume for {job.title}."
            )
            db.session.add(notif)
        db.session.commit()

        # Return full parser result including missing skills and suggestions
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
# ----------------- CANDIDATE APPLICATION STATUS -----------------
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

# ----------------- GET ASSESSMENT FOR APPLICATION -----------------
# ----------------- GET ASSESSMENT FOR APPLICATION -----------------
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

        # Update application with assessment score & overall score
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
    
@candidate_bp.route("/applications", methods=["GET"])
@role_required(["candidate"])
def list_candidate_applications():
    try:
        candidate = Candidate.query.filter_by(user_id=g.current_user.id).first()
        if not candidate:
            return jsonify([])

        applications = Application.query.filter_by(candidate_id=candidate.id).all()
        data = []

        for app in applications:
            job = app.requisition
            data.append({
                "application_id": app.id,
                "job_title": job.title if job else None,
                "job_description": job.description if job else None,
                "assessment_score": app.assessment_score,
                "cv_score": candidate.cv_score,
                "status": app.status,
                "assessed_date": app.assessed_date.isoformat() if app.assessed_date else None
            })

        return jsonify(data)

    except Exception as e:
        current_app.logger.error(f"Error fetching applications: {e}", exc_info=True)
        return jsonify({"error": "Internal server error"}), 500

# ----------------- GET CANDIDATE PROFILE -----------------
@candidate_bp.route("/profile", methods=["GET"])
@role_required(["candidate"])
def get_profile():
    try:
        user_id = get_jwt_identity()
        user = User.query.get_or_404(user_id)
        candidate = Candidate.query.filter_by(user_id=user_id).first()

        return jsonify({
            "user": user.to_dict(),
            "candidate": candidate.to_dict() if candidate else {}
        }), 200

    except Exception as e:
        current_app.logger.error(f"Get profile error: {e}", exc_info=True)
        return jsonify({"error": "Internal server error"}), 500


# ----------------- UPDATE CANDIDATE PROFILE -----------------
@candidate_bp.route("/profile", methods=["PUT"])
@role_required(["candidate"])
def update_profile():
    try:
        user_id = get_jwt_identity()
        user = User.query.get_or_404(user_id)
        candidate = Candidate.query.filter_by(user_id=user_id).first()
        if not candidate:
            candidate = Candidate(user_id=user_id)
            db.session.add(candidate)

        data = request.get_json()

        # Update User-level info
        user.profile.update(data.get("user_profile", {}))
        if "dark_mode" in data:
            user.dark_mode = data["dark_mode"]

        # Update Candidate-level info
        candidate.full_name = data.get("full_name", candidate.full_name)
        candidate.phone = data.get("phone", candidate.phone)
        candidate.education = data.get("education", candidate.education)
        candidate.skills = data.get("skills", candidate.skills)
        candidate.work_experience = data.get("work_experience", candidate.work_experience)
        candidate.cv_text = data.get("cv_text", candidate.cv_text)
        candidate.cv_url = data.get("cv_url", candidate.cv_url)
        candidate.profile.update(data.get("candidate_profile", {}))

        db.session.commit()

        return jsonify({
            "message": "Profile updated successfully",
            "user": user.to_dict(),
            "candidate": candidate.to_dict()
        }), 200

    except Exception as e:
        current_app.logger.error(f"Update profile error: {e}", exc_info=True)
        return jsonify({"error": "Internal server error"}), 500


# ----------------- GET USER SETTINGS -----------------
@candidate_bp.route("/settings", methods=["GET"])
@role_required(["candidate"])
def get_settings():
    try:
        user_id = get_jwt_identity()
        user = User.query.get_or_404(user_id)
        # Return only settings-related fields
        settings = {
            "dark_mode": user.dark_mode,
            "enrollment_completed": user.enrollment_completed,
            "notifications_enabled": user.profile.get("notifications_enabled", True)
        }
        return jsonify(settings), 200

    except Exception as e:
        current_app.logger.error(f"Get settings error: {e}", exc_info=True)
        return jsonify({"error": "Internal server error"}), 500


# ----------------- UPDATE USER SETTINGS -----------------
@candidate_bp.route("/settings", methods=["PUT"])
@role_required(["candidate"])
def update_settings():
    try:
        user_id = get_jwt_identity()
        user = User.query.get_or_404(user_id)
        data = request.get_json()

        if "dark_mode" in data:
            user.dark_mode = data["dark_mode"]
        if "notifications_enabled" in data:
            profile = user.profile or {}
            profile["notifications_enabled"] = data["notifications_enabled"]
            user.profile = profile
        if "enrollment_completed" in data:
            user.enrollment_completed = data["enrollment_completed"]

        db.session.commit()

        return jsonify({
            "message": "Settings updated successfully",
            "settings": {
                "dark_mode": user.dark_mode,
                "enrollment_completed": user.enrollment_completed,
                "notifications_enabled": user.profile.get("notifications_enabled", True)
            }
        }), 200

    except Exception as e:
        current_app.logger.error(f"Update settings error: {e}", exc_info=True)
        return jsonify({"error": "Internal server error"}), 500
# ----------------- UPLOAD DOCUMENT -----------------
@candidate_bp.route("/profile/documents", methods=["POST"])
@role_required(["candidate"])
def upload_document():
    try:
        user_id = get_jwt_identity()
        candidate = Candidate.query.filter_by(user_id=user_id).first_or_404()

        if "file" not in request.files:
            return jsonify({"error": "No file uploaded"}), 400

        file = request.files["file"]
        upload_result = cloudinary.uploader.upload(file, folder="candidate_documents", resource_type="raw")
        document_url = upload_result.get("secure_url")
        doc_name = file.filename

        candidate.documents = candidate.documents or []
        candidate.documents.append({"name": doc_name, "url": document_url})
        db.session.commit()

        return jsonify({"message": "Document uploaded", "document": {"name": doc_name, "url": document_url}})
    except Exception as e:
        current_app.logger.error(f"Upload document error: {e}", exc_info=True)
        return jsonify({"error": "Internal server error"}), 500

# ----------------- DELETE DOCUMENT -----------------
@candidate_bp.route("/profile/documents/<int:index>", methods=["DELETE"])
@role_required(["candidate"])
def delete_document(index):
    try:
        user_id = get_jwt_identity()
        candidate = Candidate.query.filter_by(user_id=user_id).first_or_404()

        if not candidate.documents or index >= len(candidate.documents):
            return jsonify({"error": "Document not found"}), 404

        removed = candidate.documents.pop(index)
        db.session.commit()
        return jsonify({"message": "Document deleted", "document": removed})
    except Exception as e:
        current_app.logger.error(f"Delete document error: {e}", exc_info=True)
        return jsonify({"error": "Internal server error"}), 500


# ----------------- NOTIFICATIONS -----------------
@candidate_bp.route("/settings/notifications", methods=["GET", "PUT"])
@role_required(["candidate"])
def notifications_settings():
    try:
        user_id = get_jwt_identity()
        candidate = Candidate.query.filter_by(user_id=user_id).first_or_404()

        if request.method == "GET":
            return jsonify({
                "email_notifications": candidate.notifications_email or True,
                "push_notifications": candidate.notifications_push or False
            })
        else:
            data = request.get_json()
            candidate.notifications_email = data.get("email_notifications", candidate.notifications_email)
            candidate.notifications_push = data.get("push_notifications", candidate.notifications_push)
            db.session.commit()
            return jsonify({"message": "Notification settings updated"}), 200
    except Exception as e:
        current_app.logger.error(f"Notifications settings error: {e}", exc_info=True)
        return jsonify({"error": "Internal server error"}), 500

@candidate_bp.route("/notifications", methods=["GET"])
@role_required(["candidate"])
def get_candidate_notifications():
    try:
        # Get current logged-in user id
        user_id = get_jwt_identity()
        
        # Ensure the user is a candidate
        candidate = Candidate.query.filter_by(user_id=user_id).first()
        if not candidate:
            return jsonify([])

        # Fetch notifications by user_id
        notifications = Notification.query.filter_by(user_id=user_id).order_by(Notification.created_at.desc()).all()

        # Convert to list of dicts
        data = [n.to_dict() for n in notifications]

        return jsonify(data)

    except Exception as e:
        current_app.logger.error(f"Error fetching notifications: {e}", exc_info=True)
        return jsonify({"error": "Internal server error"}), 500
    
# ----------------- THEME SETTINGS -----------------
@candidate_bp.route("/settings/theme", methods=["PUT"])
@role_required(["candidate"])
def theme_settings():
    try:
        user_id = get_jwt_identity()
        candidate = Candidate.query.filter_by(user_id=user_id).first_or_404()
        data = request.get_json()
        candidate.dark_mode = data.get("dark_mode", candidate.dark_mode)
        db.session.commit()
        return jsonify({"message": "Theme updated"}), 200
    except Exception as e:
        current_app.logger.error(f"Theme settings error: {e}", exc_info=True)
        return jsonify({"error": "Internal server error"}), 500
    
