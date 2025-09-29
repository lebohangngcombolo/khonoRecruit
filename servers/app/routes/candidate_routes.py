from flask import Blueprint, request, jsonify, current_app
from flask_jwt_extended import get_jwt_identity
from app.extensions import db, cloudinary_client
from app.models import User, Candidate, Requisition, Application, AssessmentResult, Notification
from datetime import datetime
import cloudinary.uploader
from app.services.cv_parser_service import analyse_resume_openrouter
from app.utils.decorators import role_required

candidate_bp = Blueprint("candidate_bp", __name__)

# ----------------- APPLY FOR JOB -----------------
@candidate_bp.route("/apply/<int:job_id>", methods=["POST"])
@role_required(["candidate"])
def apply_for_job(job_id):
    try:
        user_id = get_jwt_identity()
        user = User.query.get_or_404(user_id)
        job = Requisition.query.get_or_404(job_id)

        candidate = Candidate.query.filter_by(user_id=user_id).first()
        if not candidate:
            candidate = Candidate(user_id=user_id)
            db.session.add(candidate)
            db.session.commit()

        data = request.get_json()
        candidate.full_name = data.get("full_name", candidate.full_name)
        candidate.phone = data.get("phone", candidate.phone)
        candidate.profile.update({
            "cover_letter": data.get("cover_letter"),
            "portfolio": data.get("portfolio")
        })
        db.session.commit()

        application = Application(candidate_id=candidate.id, requisition_id=job.id, status="applied")
        db.session.add(application)
        db.session.commit()

        return jsonify({"message": "Application submitted", "application_id": application.id}), 201
    except Exception as e:
        current_app.logger.error(f"Apply for job error: {e}", exc_info=True)
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

        if "resume" not in request.files:
            return jsonify({"error": "No resume uploaded"}), 400

        file = request.files["resume"]
        upload_result = cloudinary.uploader.upload(file, folder="resumes", resource_type="raw")
        resume_url = upload_result.get("secure_url")
        candidate.cv_url = resume_url

        # Optional: get text version from form; if not provided, you could parse PDF later
        resume_content = request.form.get("resume_text", "")

        # Analyse resume automatically using job_id
        parser_result = analyse_resume_openrouter(resume_content, job_id=job.id)

        # Ensure profile dict exists and update parser info
        profile = candidate.profile or {}
        profile.update({
            "cv_parser_result": parser_result
        })
        candidate.profile = profile

        # Update dedicated cv_score column
        candidate.cv_score = parser_result.get("match_score", 0)

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

        return jsonify({
            "message": "Resume uploaded and analyzed",
            "cv_url": resume_url,
            "parser_result": parser_result
        })

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
            assessment = AssessmentResult.query.filter_by(application_id=app.id).first()
            result.append({
                "job_title": app.requisition.title,
                "status": app.status,
                "cv_score": candidate.profile.get("cv_score", 0),
                "assessment_score": assessment.total_score if assessment else None,
                "overall_score": app.overall_score
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
        user_id = get_jwt_identity()
        application = Application.query.get_or_404(application_id)

        # Ensure the application belongs to the logged-in candidate
        candidate = Candidate.query.filter_by(user_id=user_id).first_or_404()
        if application.candidate_id != candidate.id:
            current_app.logger.warning(f"Unauthorized access attempt: user_id={user_id}, application_id={application_id}")
            return jsonify({"error": "Unauthorized"}), 403

        job = application.requisition
        result = AssessmentResult.query.filter_by(application_id=application.id).first()

        return jsonify({
            "job_title": job.title,
            "assessment_pack": job.assessment_pack,
            "submitted_result": result.to_dict() if result else None
        }), 200

    except Exception as e:
        current_app.logger.error(
            f"Get assessment error: {e} | user_id={user_id} | application_id={application_id}",
            exc_info=True
        )
        return jsonify({"error": "Internal server error"}), 500


# ----------------- SUBMIT ASSESSMENT -----------------
@candidate_bp.route("/applications/<int:application_id>/assessment", methods=["POST"])
@role_required(["candidate"])
def submit_assessment(application_id):
    try:
        user_id = get_jwt_identity()
        application = Application.query.get_or_404(application_id)

        candidate = Candidate.query.filter_by(user_id=user_id).first_or_404()
        if application.candidate_id != candidate.id:
            current_app.logger.warning(
                f"Unauthorized submission attempt: user_id={user_id}, application_id={application_id}"
            )
            return jsonify({"error": "Unauthorized"}), 403

        data = request.get_json()
        answers = data.get("answers", {})  # keys = index as string, values = "A"-"D"

        current_app.logger.info(
            f"Submitting assessment: user_id={user_id}, application_id={application_id}, answers={answers}"
        )

        # Check if assessment already submitted
        existing_result = AssessmentResult.query.filter_by(application_id=application.id).first()
        if existing_result:
            current_app.logger.warning(
                f"Assessment already submitted: user_id={user_id}, application_id={application_id}"
            )
            return jsonify({"error": "Assessment already submitted"}), 400

        # Scoring Logic
        job = application.requisition
        assessment_pack = job.assessment_pack or {}
        questions = assessment_pack.get("questions", [])

        scores = {}
        total_score = 0

        for index, q in enumerate(questions):
            qid = str(index)  # use index as key
            correct_index = q.get("correct_answer", 0)  # numeric index
            correct_letter = ["A", "B", "C", "D"][correct_index]  # map to letter
            candidate_answer = answers.get(qid)
            scores[qid] = q.get("weight", 1) if candidate_answer == correct_letter else 0
            total_score += scores[qid]

        max_score = sum(q.get("weight", 1) for q in questions)
        total_score = (total_score / max_score * 100) if max_score > 0 else 0

        # Save AssessmentResult
        result = AssessmentResult(
            application_id=application.id,
            candidate_id=candidate.id,
            answers=answers,
            scores=scores,
            total_score=total_score,
            recommendation="pass" if total_score >= 60 else "fail"
        )
        db.session.add(result)

        # Update application
        application.status = "assessment_submitted"
        application.overall_score = total_score
        db.session.commit()

        current_app.logger.info(
            f"Assessment submitted successfully: user_id={user_id}, application_id={application_id}, total_score={total_score}"
        )

        return jsonify({
            "message": "Assessment submitted",
            "total_score": total_score,
            "recommendation": result.recommendation
        }), 201

    except Exception as e:
        current_app.logger.error(
            f"Submit assessment error: {e} | user_id={user_id} | application_id={application_id} | payload={request.get_json()}",
            exc_info=True
        )
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

