from flask import Blueprint, request, jsonify, current_app
from flask_jwt_extended import jwt_required, get_jwt_identity
from app.extensions import db
from app.models import User, Requisition, Candidate, Application, AssessmentResult, Interview, Notification
from datetime import datetime
from app.utils.decorators import role_required

admin_bp = Blueprint("admin_bp", __name__)

# ----------------- JOB CRUD -----------------
@admin_bp.route("/jobs", methods=["POST"])
@role_required(["admin", "hiring_manager"])
def create_job():
    try:
        data = request.get_json()
        if not data.get("title") or not data.get("description"):
            return jsonify({"error": "Title and description required"}), 400

        job = Requisition(
            title=data["title"],
            description=data["description"],
            required_skills=data.get("required_skills", []),
            min_experience=data.get("min_experience", 0),
            knockout_rules=data.get("knockout_rules", []),
            weightings=data.get("weightings", {"cv": 60, "assessment": 40}),
            assessment_pack=data.get("assessment_pack", {"questions": []}),
            created_by=get_jwt_identity()
        )
        db.session.add(job)
        db.session.commit()
        return jsonify({"message": "Job created", "job": job.to_dict()}), 201
    except Exception as e:
        current_app.logger.error(f"Create job error: {e}", exc_info=True)
        return jsonify({"error": "Internal server error"}), 500

@admin_bp.route("/jobs/<int:job_id>", methods=["PUT"])
@role_required(["admin", "hiring_manager"])
def update_job(job_id):
    job = Requisition.query.get_or_404(job_id)
    data = request.get_json()
    for field in ["title", "description", "required_skills", "min_experience", "knockout_rules", "weightings", "assessment_pack"]:
        if field in data:
            setattr(job, field, data[field])
    db.session.commit()
    return jsonify({"message": "Job updated", "job": job.to_dict()}), 200

@admin_bp.route("/jobs/<int:job_id>", methods=["DELETE"])
@role_required(["admin", "hiring_manager"])
def delete_job(job_id):
    job = Requisition.query.get_or_404(job_id)
    db.session.delete(job)
    db.session.commit()
    return jsonify({"message": "Job deleted"}), 200

@admin_bp.route("/jobs/<int:job_id>", methods=["GET"])
@role_required(["admin", "hiring_manager"])
def get_job(job_id):
    job = Requisition.query.get_or_404(job_id)
    return jsonify(job.to_dict())

@admin_bp.route("/jobs", methods=["GET"])
@role_required(["admin", "hiring_manager"])
def list_jobs():
    jobs = Requisition.query.all()
    return jsonify([job.to_dict() for job in jobs])

# ----------------- CANDIDATE MANAGEMENT -----------------
@admin_bp.route("/candidates", methods=["GET"])
@role_required(["admin", "hiring_manager"])
def list_candidates():
    candidates = Candidate.query.all()
    return jsonify([c.to_dict() for c in candidates])

@admin_bp.route("/applications/<int:application_id>", methods=["GET"])
@role_required(["admin", "hiring_manager"])
def get_application(application_id):
    application = Application.query.get_or_404(application_id)
    assessment = AssessmentResult.query.filter_by(application_id=application.id).first()
    return jsonify({
        "application": application.to_dict(),
        "assessment": assessment.to_dict() if assessment else None
    })

@admin_bp.route("/jobs/<int:job_id>/shortlist", methods=["GET"])
@role_required(["admin", "hiring_manager"])
def shortlist_candidates(job_id):
    job = Requisition.query.get_or_404(job_id)
    applications = Application.query.filter_by(requisition_id=job.id).all()
    shortlisted = []

    for app in applications:
        cv_score = app.candidate.profile.get("cv_score", 0)
        assessment_score = app.assessment_score or 0
        overall = (cv_score * job.weightings.get("cv", 60)/100) + (assessment_score * job.weightings.get("assessment", 40)/100)
        app.overall_score = overall
        shortlisted.append({
            "application_id": app.id,
            "candidate_id": app.candidate_id,
            "full_name": app.candidate.full_name,
            "cv_score": cv_score,
            "assessment_score": assessment_score,
            "overall_score": overall,
            "status": app.status
        })
    db.session.commit()
    shortlisted_sorted = sorted(shortlisted, key=lambda x: x["overall_score"], reverse=True)
    return jsonify(shortlisted_sorted)

# ----------------- INTERVIEW -----------------
@admin_bp.route("/interviews", methods=["POST"])
@role_required(["admin", "hiring_manager"])
def schedule_interview():
    try:
        data = request.get_json()
        candidate_id = data.get("candidate_id")
        application_id = data.get("application_id")
        scheduled_time = datetime.fromisoformat(data.get("scheduled_time"))
        hiring_manager_id = get_jwt_identity()

        interview = Interview(
            candidate_id=candidate_id,
            application_id=application_id,
            hiring_manager_id=hiring_manager_id,
            scheduled_time=scheduled_time
        )

        notif = Notification(
            user_id=candidate_id,
            message=f"Your interview has been scheduled for {scheduled_time.isoformat()}"
        )

        db.session.add_all([interview, notif])
        db.session.commit()
        return jsonify({"message": "Interview scheduled", "interview": interview.to_dict()}), 201
    except Exception as e:
        current_app.logger.error(f"Schedule interview error: {e}", exc_info=True)
        return jsonify({"error": "Internal server error"}), 500

# ----------------- NOTIFICATIONS -----------------
@admin_bp.route("/notifications/<int:user_id>", methods=["GET"])
@role_required(["admin", "hiring_manager"])
def get_notifications(user_id):
    notifs = Notification.query.filter_by(user_id=user_id).all()
    return jsonify([n.to_dict() for n in notifs])
