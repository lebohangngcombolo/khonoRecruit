from flask import Blueprint, request, jsonify, current_app
from flask_jwt_extended import jwt_required, get_jwt_identity
from app.extensions import db
from app.models import User, Requisition, Candidate, Application, AssessmentResult, Interview, Notification, AuditLog
from datetime import datetime
from app.utils.decorators import role_required
from app.services.email_service import EmailService
from flask_cors import cross_origin

admin_bp = Blueprint("admin_bp", __name__)

# ----------------- JOB CRUD -----------------
@admin_bp.route("/jobs", methods=["POST"])
@role_required(["admin", "hiring_manager"])
def create_job():
    try:
        data = request.get_json()

        # Mandatory fields
        if not data.get("title") or not data.get("description"):
            return jsonify({"error": "Title and description required"}), 400

        # Optional fields with defaults
        job = Requisition(
            title=data["title"],
            description=data["description"],
            job_summary=data.get("job_summary", ""),
            responsibilities=data.get("responsibilities", []),  # list of strings
            company_details=data.get("company_details", ""),
            qualifications=data.get("qualifications", []),  # list of strings
            category=data.get("category", ""),  # new field
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
        db.session.rollback()  # ensure session consistency
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
        profile = app.candidate.profile or {}
        cv_score = profile.get("cv_score", 0)
        assessment_score = app.assessment_score or 0

        try:
            overall = (
                (cv_score * job.weightings.get("cv", 60) / 100) +
                (assessment_score * job.weightings.get("assessment", 40) / 100)
            )
        except Exception:
            overall = 0

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


# ----------------- NOTIFICATIONS -----------------
@admin_bp.route("/notifications/<int:user_id>", methods=["GET"])
@role_required(["admin", "hiring_manager"])
def get_notifications(user_id):
    user = User.query.get(user_id)
    if not user:
        return jsonify({"error": "User not found"}), 404

    notifications = Notification.query.filter_by(user_id=user_id)\
                                      .order_by(Notification.created_at.desc())\
                                      .all()
    
    unread_count = Notification.query.filter_by(user_id=user_id, is_read=False).count()

    data = [n.to_dict() for n in notifications]

    return jsonify({
        "user_id": user_id,
        "unread_count": unread_count,
        "notifications": data
    }), 200




@admin_bp.route("/cv-reviews", methods=["GET", "OPTIONS"])
@role_required(["admin", "hiring_manager"])
@cross_origin()
def list_cv_reviews():
    if request.method == "OPTIONS":
        return '', 200

    applications = Application.query.all()
    reviews = []

    for app in applications:
        candidate = None
        cv_url = None
        cv_parser = app.cv_parser_result or {}

        if app.candidate_id:
            candidate = Candidate.query.get(app.candidate_id)
            cv_url = candidate.cv_url if candidate else None

        reviews.append({
            "application_id": app.id,
            "status": app.status,
            "resume_url": app.resume_url,
            "cv_score": app.cv_score,
            "cv_parser_result": {
                "skills": cv_parser.get("skills", []),
                "education": cv_parser.get("education", []),
                "work_experience": cv_parser.get("work_experience", []),
            },
            "application_recommendation": app.recommendation,
            "assessment_score": app.assessment_score,
            "overall_score": app.overall_score,

            "candidate_id": candidate.id if candidate else None,
            "full_name": candidate.full_name if candidate else None,
            "cv_url": cv_url,
        })

    return jsonify(reviews), 200



# ----------------- USERS MANAGEMENT -----------------
@admin_bp.route("/users", methods=["GET"])
@role_required(["admin"])
def list_users():
    users = User.query.all()
    result = []
    for u in users:
        profile = u.profile or {}
        full_name = profile.get("full_name") or profile.get("name") or None

        result.append({
            "id": u.id,
            "email": u.email,
            "role": u.role,
            "name": full_name,
            "is_verified": u.is_verified,
            "enrollment_completed": u.enrollment_completed,
            "dark_mode": u.dark_mode,
            "created_at": u.created_at.isoformat() if u.created_at else None
        })

    return jsonify(result), 200


@admin_bp.route("/users/<int:user_id>", methods=["DELETE"])
@role_required(["admin"])
def delete_user(user_id):
    user = User.query.get_or_404(user_id)

    # prevent deleting self
    admin_id = get_jwt_identity()
    if admin_id == user.id:
        return jsonify({"error": "You cannot delete your own account"}), 400

    # delete user
    db.session.delete(user)

    # log audit
    audit = AuditLog(
        admin_id=admin_id,
        action=f"Deleted user {user.email}",
        target_user_id=user.id
    )
    db.session.add(audit)
    db.session.commit()

    return jsonify({"message": "User deleted successfully"}), 200


# ----------------- AUDIT LOGS -----------------
@admin_bp.route("/audits", methods=["GET"])
@role_required(["admin"])
def list_audits():
    """
    Fetch paginated and filtered audit logs.
    Supports:
    - Pagination: ?page=1&per_page=20
    - Filtering: ?user_id=5&action=login
    - Date range: ?start_date=2025-09-01&end_date=2025-09-30
    - Keyword search: ?q=updated
    """

    try:
        # --- Pagination parameters ---
        page = request.args.get("page", 1, type=int)
        per_page = request.args.get("per_page", 20, type=int)

        # --- Filters ---
        user_id = request.args.get("user_id", type=int)
        action = request.args.get("action", type=str)
        start_date = request.args.get("start_date")
        end_date = request.args.get("end_date")
        search = request.args.get("q", type=str)

        # --- Build query dynamically ---
        query = AuditLog.query

        if user_id:
            query = query.filter_by(user_id=user_id)

        if action:
            query = query.filter(AuditLog.action.ilike(f"%{action}%"))

        if search:
            query = query.filter(AuditLog.details.ilike(f"%{search}%"))

        if start_date:
            try:
                start = datetime.fromisoformat(start_date)
                query = query.filter(AuditLog.timestamp >= start)
            except ValueError:
                return jsonify({"error": "Invalid start_date format. Use YYYY-MM-DD"}), 400

        if end_date:
            try:
                end = datetime.fromisoformat(end_date)
                query = query.filter(AuditLog.timestamp <= end)
            except ValueError:
                return jsonify({"error": "Invalid end_date format. Use YYYY-MM-DD"}), 400

        # --- Ordering ---
        query = query.order_by(AuditLog.timestamp.desc())

        # --- Pagination ---
        pagination = query.paginate(page=page, per_page=per_page, error_out=False)
        logs = [log.to_dict() for log in pagination.items]

        return jsonify({
            "total": pagination.total,
            "page": pagination.page,
            "pages": pagination.pages,
            "per_page": pagination.per_page,
            "results": logs
        }), 200

    except Exception as e:
        current_app.logger.error(f"Error fetching audit logs: {e}", exc_info=True)
        return jsonify({"error": "Internal server error"}), 500

@admin_bp.route("/dashboard-counts", methods=["GET"])
@role_required(["admin", "hiring_manager"])
def dashboard_counts():
    try:
        counts = {
            "jobs": Requisition.query.count(),
            "candidates": Candidate.query.count(),
            "cv_reviews": Application.query.count(),
            "audits": AuditLog.query.count(),
            "interviews": Interview.query.count()
        }
        return jsonify(counts), 200
    except Exception as e:
        current_app.logger.error(f"Dashboard counts error: {e}", exc_info=True)
        return jsonify({"error": "Internal server error"}), 500


# =====================================================
# 📅 INTERVIEW MANAGEMENT ROUTES
# =====================================================

@admin_bp.route("/jobs/interviews", methods=["GET", "POST"])
@admin_bp.route("/interviews", methods=["GET", "POST"])  # backward compatibility
@role_required(["admin", "hiring_manager"])
def manage_interviews():
    try:
        # ---------------- GET ----------------
        if request.method == "GET":
            candidate_id = request.args.get("candidate_id", type=int)
            if not candidate_id:
                return jsonify({"error": "candidate_id query parameter is required"}), 400

            interviews = Interview.query.filter_by(candidate_id=candidate_id).all()

            enriched = []
            for i in interviews:
                enriched.append({
                    "id": i.id,
                    "candidate_id": i.candidate_id,
                    "candidate_name": i.candidate.full_name if i.candidate else None,
                    "hiring_manager_id": i.hiring_manager_id,
                    "application_id": i.application_id,
                    "job_title": i.application.requisition.title if i.application and i.application.requisition else None,
                    "scheduled_time": i.scheduled_time.isoformat(),
                    "interview_type": i.interview_type,
                    "meeting_link": i.meeting_link,
                    "status": i.status,
                    "created_at": i.created_at.isoformat()
                })

            return jsonify(enriched), 200

        # ---------------- POST (Schedule) ----------------
        elif request.method == "POST":
            data = request.get_json()
            candidate_id = data.get("candidate_id")
            application_id = data.get("application_id")
            scheduled_time_str = data.get("scheduled_time")
            interview_type = data.get("interview_type", "Online")
            meeting_link = data.get("meeting_link")

            if not all([candidate_id, application_id, scheduled_time_str]):
                return jsonify({"error": "Missing required fields"}), 400

            try:
                scheduled_time = datetime.fromisoformat(scheduled_time_str)
            except ValueError:
                return jsonify({"error": "Invalid datetime format. Use ISO format."}), 400

            hiring_manager_id = get_jwt_identity()

            interview = Interview(
                candidate_id=candidate_id,
                application_id=application_id,
                hiring_manager_id=hiring_manager_id,
                scheduled_time=scheduled_time,
                interview_type=interview_type,
                meeting_link=meeting_link
            )

            db.session.add(interview)
            db.session.commit()

            # Create in-app notification
            notif = Notification(
                user_id=candidate_id,
                message=f"Your {interview_type} interview has been scheduled for {scheduled_time.strftime('%Y-%m-%d %H:%M:%S')}."
            )
            db.session.add(notif)
            db.session.commit()

            # Fetch candidate profile
            candidate_profile = Candidate.query.get(candidate_id)
            if candidate_profile and candidate_profile.user:
                EmailService.send_interview_invitation(
                    email=candidate_profile.user.email,              # User email
                    candidate_name=candidate_profile.full_name,     # Candidate full_name
                    interview_date=scheduled_time.strftime("%A, %d %B %Y at %H:%M"),
                    interview_type=interview_type,
                    meeting_link=meeting_link
                )

            # Return enriched interview data
            enriched_interview = {
                "id": interview.id,
                "candidate_id": interview.candidate_id,
                "candidate_name": candidate_profile.full_name if candidate_profile else None,
                "hiring_manager_id": interview.hiring_manager_id,
                "application_id": interview.application_id,
                "job_title": interview.application.requisition.title if interview.application and interview.application.requisition else None,
                "scheduled_time": interview.scheduled_time.isoformat(),
                "interview_type": interview.interview_type,
                "meeting_link": interview.meeting_link,
                "status": interview.status,
                "created_at": interview.created_at.isoformat()
            }

            return jsonify({
                "message": "Interview scheduled successfully.",
                "interview": enriched_interview
            }), 201

    except Exception as e:
        current_app.logger.error(f"Interview route error: {e}", exc_info=True)
        return jsonify({"error": "Internal server error"}), 500


# =====================================================
# ♻️ RESCHEDULE INTERVIEW
# =====================================================
@admin_bp.route("/jobs/interviews/<int:interview_id>", methods=["PATCH"])
@admin_bp.route("/interviews/<int:interview_id>", methods=["PATCH"])
@role_required(["admin", "hiring_manager"])
def reschedule_interview(interview_id):
    try:
        interview = Interview.query.get_or_404(interview_id)
        data = request.get_json()
        new_time_str = data.get("scheduled_time")

        if not new_time_str:
            return jsonify({"error": "New scheduled_time required"}), 400

        try:
            new_time = datetime.fromisoformat(new_time_str)
        except ValueError:
            return jsonify({"error": "Invalid datetime format. Use ISO format."}), 400

        old_time = interview.scheduled_time
        interview.scheduled_time = new_time
        db.session.commit()

        # Notification
        notif = Notification(
            user_id=interview.candidate_id,
            message=f"Your interview has been rescheduled from {old_time.strftime('%Y-%m-%d %H:%M:%S')} to {new_time.strftime('%Y-%m-%d %H:%M:%S')}."
        )
        db.session.add(notif)
        db.session.commit()

        # Send updated email invitation
        candidate = User.query.get(interview.candidate_id)
        if candidate and candidate.email:
            EmailService.send_interview_invitation(
                email=candidate.email,
                candidate_name=candidate.full_name,
                interview_date=new_time.strftime("%A, %d %B %Y at %H:%M"),
                interview_type=interview.interview_type or "Online",
                meeting_link=interview.meeting_link
            )

        return jsonify({
            "message": "Interview rescheduled successfully.",
            "interview": interview.to_dict()
        }), 200

    except Exception as e:
        current_app.logger.error(f"Reschedule interview error: {e}", exc_info=True)
        return jsonify({"error": "Internal server error"}), 500


# =====================================================
# ❌ CANCEL INTERVIEW
# =====================================================
@admin_bp.route("/jobs/interviews/<int:interview_id>", methods=["DELETE"])
@admin_bp.route("/interviews/<int:interview_id>", methods=["DELETE"])
@role_required(["admin", "hiring_manager"])
def cancel_interview(interview_id):
    try:
        interview = Interview.query.get_or_404(interview_id)
        candidate = User.query.get(interview.candidate_id)

        db.session.delete(interview)
        db.session.commit()

        # Notification
        notif = Notification(
            user_id=candidate.id,
            message=f"Your interview scheduled for {interview.scheduled_time.strftime('%Y-%m-%d %H:%M:%S')} has been cancelled."
        )
        db.session.add(notif)
        db.session.commit()

        # Send cancellation email using same HTML template
        if candidate and candidate.email:
            EmailService.send_interview_invitation(
                email=candidate.email,
                candidate_name=candidate.full_name,
                interview_date=interview.scheduled_time.strftime("%A, %d %B %Y at %H:%M"),
                interview_type=f"Cancelled {interview.interview_type}",
                meeting_link=None
            )

        return jsonify({"message": "Interview cancelled successfully."}), 200

    except Exception as e:
        current_app.logger.error(f"Cancel interview error: {e}", exc_info=True)
        return jsonify({"error": "Internal server error"}), 500
    
@admin_bp.route("/applications", methods=["GET"])
@role_required(["admin", "hiring_manager"])
def get_candidate_applications():
    try:
        candidate_id = request.args.get("candidate_id", type=int)
        if not candidate_id:
            return jsonify({"error": "candidate_id query parameter is required"}), 400

        candidate = Candidate.query.get(candidate_id)
        if not candidate:
            return jsonify({"error": "Candidate not found"}), 404

        applications = Application.query.filter_by(candidate_id=candidate.id).all()
        result = []
        for app in applications:
            assessment_result = AssessmentResult.query.filter_by(application_id=app.id).first()
            result.append({
                "application_id": app.id,
                "job_title": app.requisition.title if app.requisition else None,
                "status": app.status,
                "cv_score": app.cv_score,
                "assessment_score": assessment_result.scores if assessment_result else None,
                "overall_score": app.overall_score,
                "recommendation": assessment_result.recommendation if assessment_result else None
            })

        return jsonify(result), 200

    except Exception as e:
        current_app.logger.error(f"Admin get applications error: {e}", exc_info=True)
        return jsonify({"error": "Internal server error"}), 500
    
@admin_bp.route("/recent-activities", methods=["GET"])
@jwt_required()
@role_required("admin")
def recent_activities():
    try:
        activities = []

        # Recent job applications
        applications = Application.query.order_by(Application.created_at.desc()).limit(5).all()
        for app in applications:
            user_profile = app.candidate.user.profile or {}
            candidate_name = f"{user_profile.get('first_name', '')} {user_profile.get('last_name', '')}".strip() or "Unknown"
            job_title = app.requisition.title if app.requisition else "Unknown Position"
            activities.append(f"{candidate_name} submitted CV for {job_title}")

        # Recent job postings
        requisitions = Requisition.query.order_by(Requisition.created_at.desc()).limit(5).all()
        for req in requisitions:
            activities.append(f"New job posted: {req.title}")

        # Recent interviews (FIXED: scheduled_time)
        interviews = Interview.query.order_by(Interview.scheduled_time.desc()).limit(5).all()
        for i in interviews:
            user_profile = i.candidate.user.profile or {}
            candidate_name = f"{user_profile.get('first_name', '')} {user_profile.get('last_name', '')}".strip() or "Unknown"
            activities.append(f"Interview scheduled: {candidate_name}")

        # Recent CV reviews
        reviews = AssessmentResult.query.order_by(AssessmentResult.created_at.desc()).limit(5).all()
        for r in reviews:
            user_profile = r.application.candidate.user.profile or {}
            candidate_name = f"{user_profile.get('first_name', '')} {user_profile.get('last_name', '')}".strip() or "Unknown"
            activities.append(f"CV review completed: {candidate_name}")

        # Recent notifications
        notifications = Notification.query.order_by(Notification.created_at.desc()).limit(5).all()
        for n in notifications:
            activities.append(f"Notification: {n.message}")

        return jsonify({"recentActivities": activities}), 200

    except Exception as e:
        current_app.logger.error(f"Error fetching recent activities: {str(e)}", exc_info=True)
        return jsonify({"error": str(e)}), 500

# ==========================
# Power BI Data & Status
# ==========================

@admin_bp.route("/powerbi/data", methods=["GET"])
@role_required(["admin"])
def powerbi_data():
    """
    Flattened data for Power BI with optional filters:
    - job_id
    - candidate_id
    - status
    - start_date, end_date (ISO format)
    """
    try:
        # --- Get filters from query params ---
        job_id = request.args.get("job_id", type=int)
        candidate_id = request.args.get("candidate_id", type=int)
        status = request.args.get("status", type=str)
        start_date_str = request.args.get("start_date")
        end_date_str = request.args.get("end_date")

        # --- Build base query ---
        query = Application.query

        if job_id:
            query = query.filter_by(requisition_id=job_id)
        if candidate_id:
            query = query.filter_by(candidate_id=candidate_id)
        if status:
            query = query.filter_by(status=status)

        if start_date_str:
            try:
                start_date = datetime.fromisoformat(start_date_str)
                query = query.filter(Application.created_at >= start_date)
            except ValueError:
                return jsonify({"error": "Invalid start_date format. Use YYYY-MM-DD or ISO format"}), 400

        if end_date_str:
            try:
                end_date = datetime.fromisoformat(end_date_str)
                query = query.filter(Application.created_at <= end_date)
            except ValueError:
                return jsonify({"error": "Invalid end_date format. Use YYYY-MM-DD or ISO format"}), 400

        applications = query.all()
        data = []

        for app in applications:
            candidate = app.candidate
            user = candidate.user if candidate else None
            job = app.requisition
            assessment = AssessmentResult.query.filter_by(application_id=app.id).first()
            interviews = Interview.query.filter_by(application_id=app.id).all()

            data.append({
                "application_id": app.id,
                "application_status": app.status,
                "cv_score": app.cv_score,
                "assessment_score": app.assessment_score,
                "overall_score": app.overall_score,
                "recommendation": assessment.recommendation if assessment else None,
                "candidate_id": candidate.id if candidate else None,
                "candidate_name": candidate.full_name if candidate else None,
                "candidate_email": user.email if user else None,
                "candidate_verified": user.is_verified if user else None,
                "job_id": job.id if job else None,
                "job_title": job.title if job else None,
                "job_category": job.category if job else None,
                "interview_count": len(interviews),
                "interview_dates": [i.scheduled_time.isoformat() for i in interviews]
            })

        return jsonify(data), 200

    except Exception as e:
        current_app.logger.error(f"Power BI filtered data error: {e}", exc_info=True)
        return jsonify({"error": "Internal server error"}), 500


@admin_bp.route("/powerbi/status", methods=["GET"])
@role_required(["admin"])
def powerbi_status():
    """
    Simple status check for admin dashboard:
    - Returns connection success and latest update timestamp
    """
    try:
        latest_application = Application.query.order_by(Application.created_at.desc()).first()
        latest_update = latest_application.created_at.isoformat() if latest_application else None

        return jsonify({
            "connected": True,
            "latest_update": latest_update,
            "message": "Power BI data endpoint reachable."
        }), 200

    except Exception as e:
        current_app.logger.error(f"Power BI status check error: {e}", exc_info=True)
        return jsonify({
            "connected": False,
            "message": "Unable to reach Power BI data endpoint."
        }), 500

@admin_bp.route("/candidates/<int:candidate_id>/download-cv", methods=["GET"])
@role_required(["admin", "hiring_manager"])
def download_candidate_cv(candidate_id):
    """
    Returns the CV URL for the given candidate.
    Frontend can call this endpoint to get the Cloudinary URL.
    """
    candidate = Candidate.query.get_or_404(candidate_id)

    if not candidate.cv_url:
        return jsonify({"error": "CV not uploaded"}), 404

    return jsonify({
        "candidate_id": candidate.id,
        "full_name": candidate.full_name,
        "cv_url": candidate.cv_url
    }), 200