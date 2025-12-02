from flask import Blueprint, request, jsonify, current_app
from flask_jwt_extended import jwt_required, get_jwt_identity, get_jwt
from app.extensions import db
from app.models import User, Requisition, Candidate, Application, AssessmentResult, Interview, Notification, AuditLog, Conversation, SharedNote, Meeting
from datetime import datetime, timedelta
from app.utils.decorators import role_required
from app.services.email_service import EmailService
from app.services.audit_service import AuditService
from app.services.audit2 import AuditService
from flask_cors import cross_origin
from sqlalchemy import func, and_, or_
import bleach



admin_bp = Blueprint("admin_bp", __name__)

# ----------------- ANALYTICS ROUTES -----------------
@admin_bp.route('/analytics/dashboard', methods=['GET'])
@role_required(["admin", "hiring_manager"])
def get_dashboard_stats():
    """Get overall dashboard statistics"""
    
    # Total counts
    total_users = User.query.count()
    total_candidates = Candidate.query.count()
    total_requisitions = Requisition.query.count()
    total_applications = Application.query.count()
    
    # Application status breakdown
    application_statuses = db.session.query(
        Application.status,
        func.count(Application.id)
    ).group_by(Application.status).all()
    
    status_breakdown = {status: count for status, count in application_statuses}
    
    # Recent activity (last 7 days)
    week_ago = datetime.utcnow() - timedelta(days=7)
    
    new_users_week = User.query.filter(User.created_at >= week_ago).count()
    new_applications_week = Application.query.filter(Application.created_at >= week_ago).count()
    new_requisitions_week = Requisition.query.filter(Requisition.created_at >= week_ago).count()
    
    # Average scores
    avg_cv_score = db.session.query(func.avg(Application.cv_score)).scalar() or 0
    avg_assessment_score = db.session.query(func.avg(Application.assessment_score)).scalar() or 0
    
    return jsonify({
        'total_users': total_users,
        'total_candidates': total_candidates,
        'total_requisitions': total_requisitions,
        'total_applications': total_applications,
        'application_status_breakdown': status_breakdown,
        'recent_activity': {
            'new_users': new_users_week,
            'new_applications': new_applications_week,
            'new_requisitions': new_requisitions_week
        },
        'average_scores': {
            'cv_score': round(float(avg_cv_score), 2),
            'assessment_score': round(float(avg_assessment_score), 2)
        }
    })

@admin_bp.route('/analytics/users-growth', methods=['GET'])
@role_required(["admin", "hiring_manager"])
def get_users_growth():
    """Get user growth data over time"""
    
    days = int(request.args.get('days', 30))
    start_date = datetime.utcnow() - timedelta(days=days)
    
    # User growth data
    user_growth = db.session.query(
        func.date(User.created_at).label('date'),
        func.count(User.id).label('count')
    ).filter(
        User.created_at >= start_date
    ).group_by(
        func.date(User.created_at)
    ).order_by('date').all()
    
    # Candidate growth data
    candidate_growth = db.session.query(
        func.date(User.created_at).label('date'),
        func.count(User.id).label('count')
    ).filter(
        User.created_at >= start_date,
        User.role == 'candidate'
    ).group_by(
        func.date(User.created_at)
    ).order_by('date').all()
    
    return jsonify({
        'user_growth': [{'date': str(date), 'count': count} for date, count in user_growth],
        'candidate_growth': [{'date': str(date), 'count': count} for date, count in candidate_growth]
    })

@admin_bp.route('/analytics/applications-analysis', methods=['GET'])
@role_required(["admin", "hiring_manager"])
def get_applications_analysis():
    """Get detailed applications analysis"""
    
    # Applications by requisition
    apps_by_requisition = db.session.query(
        Requisition.title,
        func.count(Application.id).label('application_count')
    ).join(
        Application, Requisition.id == Application.requisition_id
    ).group_by(
        Requisition.id, Requisition.title
    ).order_by(
        func.count(Application.id).desc()
    ).limit(10).all()
    
    # Score distribution
    score_ranges = [
        ('0-20', 0, 20),
        ('21-40', 21, 40),
        ('41-60', 41, 60),
        ('61-80', 61, 80),
        ('81-100', 81, 100)
    ]
    
    cv_score_distribution = []
    for label, min_score, max_score in score_ranges:
        count = Application.query.filter(
            and_(
                Application.cv_score >= min_score,
                Application.cv_score <= max_score
            )
        ).count()
        cv_score_distribution.append({'range': label, 'count': count})
    
    # Monthly applications
    monthly_apps = db.session.query(
        func.date_trunc('month', Application.created_at).label('month'),
        func.count(Application.id).label('count')
    ).group_by(
        func.date_trunc('month', Application.created_at)
    ).order_by('month').all()
    
    return jsonify({
        'applications_by_requisition': [
            {'requisition': title, 'count': count} 
            for title, count in apps_by_requisition
        ],
        'cv_score_distribution': cv_score_distribution,
        'monthly_applications': [
            {'month': month.strftime('%Y-%m'), 'count': count} 
            for month, count in monthly_apps
        ]
    })

@admin_bp.route('/analytics/interviews-analysis', methods=['GET'])
@role_required(["admin", "hiring_manager"])
def get_interviews_analysis():
    """Get interviews analysis"""
    
    # Interview status breakdown
    interview_statuses = db.session.query(
        Interview.status,
        func.count(Interview.id)
    ).group_by(Interview.status).all()
    
    # Interviews by type
    interviews_by_type = db.session.query(
        Interview.interview_type,
        func.count(Interview.id)
    ).filter(Interview.interview_type.isnot(None)).group_by(Interview.interview_type).all()
    
    # Monthly scheduled interviews
    monthly_interviews = db.session.query(
        func.date_trunc('month', Interview.scheduled_time).label('month'),
        func.count(Interview.id).label('count')
    ).group_by(
        func.date_trunc('month', Interview.scheduled_time)
    ).order_by('month').all()
    
    return jsonify({
        'interview_status_breakdown': [
            {'status': status, 'count': count} 
            for status, count in interview_statuses
        ],
        'interviews_by_type': [
            {'type': interview_type, 'count': count} 
            for interview_type, count in interviews_by_type
        ],
        'monthly_interviews': [
            {'month': month.strftime('%Y-%m'), 'count': count} 
            for month, count in monthly_interviews
        ]
    })

@admin_bp.route('/analytics/assessments-analysis', methods=['GET'])
@role_required(["admin", "hiring_manager"])
def get_assessments_analysis():
    """Get assessments analysis"""
    
    # Assessment score distribution
    assessment_score_ranges = [
        ('0-20', 0, 20),
        ('21-40', 21, 40),
        ('41-60', 41, 60),
        ('61-80', 61, 80),
        ('81-100', 81, 100)
    ]
    
    assessment_score_distribution = []
    for label, min_score, max_score in assessment_score_ranges:
        count = AssessmentResult.query.filter(
            and_(
                AssessmentResult.percentage_score >= min_score,
                AssessmentResult.percentage_score <= max_score
            )
        ).count()
        assessment_score_distribution.append({'range': label, 'count': count})
    
    # Recommendation breakdown
    recommendation_breakdown = db.session.query(
        AssessmentResult.recommendation,
        func.count(AssessmentResult.id)
    ).filter(AssessmentResult.recommendation.isnot(None)).group_by(
        AssessmentResult.recommendation
    ).all()
    
    # Average scores by requisition
    avg_scores_by_req = db.session.query(
        Requisition.title,
        func.avg(AssessmentResult.percentage_score).label('avg_score')
    ).join(Application, Application.requisition_id == Requisition.id).join(
        AssessmentResult, AssessmentResult.application_id == Application.id
    ).group_by(Requisition.id, Requisition.title).all()
    
    return jsonify({
        'assessment_score_distribution': assessment_score_distribution,
        'recommendation_breakdown': [
            {'recommendation': rec, 'count': count} 
            for rec, count in recommendation_breakdown
        ],
        'average_scores_by_requisition': [
            {'requisition': title, 'avg_score': round(float(avg_score or 0), 2)} 
            for title, avg_score in avg_scores_by_req
        ]
    })
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
    
    # Get candidate data
    candidate = Candidate.query.get(application.candidate_id) if application.candidate_id else None
    
    # Get user data for email
    user = None
    if candidate and candidate.user_id:
        user = User.query.get(candidate.user_id)
    
    return jsonify({
        "application": application.to_dict(),
        "assessment": assessment.to_dict() if assessment else {},
        "candidate": {
            "full_name": candidate.full_name if candidate else "Unknown Candidate",
            "email": user.email if user else "No email",
            "phone": candidate.phone if candidate else "No phone",
            "education": candidate.education if candidate else [],
            "skills": candidate.skills if candidate else [],
            "work_experience": candidate.work_experience if candidate else [],
        } if candidate else {}
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
                candidate_profile_picture = None
                if i.candidate and getattr(i.candidate, "profile_picture", None):
                    candidate_profile_picture = i.candidate.profile_picture

                enriched.append({
                    "id": i.id,
                    "candidate_id": i.candidate_id,
                    "candidate_name": i.candidate.full_name if i.candidate else None,
                    "candidate_profile_picture": candidate_profile_picture,
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
                "candidate_profile_picture": candidate_profile.profile_picture if candidate_profile and getattr(candidate_profile, "profile_picture", None) else None,
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
@admin_bp.route("/interviews/reschedule/<int:interview_id>", methods=["PATCH", "PUT"])
@role_required(["admin", "hiring_manager"])
def reschedule_interview(interview_id):
    try:
        # Fetch interview
        interview = Interview.query.get_or_404(interview_id)
        data = request.get_json()
        new_time_str = data.get("scheduled_time")

        if not new_time_str:
            return jsonify({"error": "New scheduled_time required"}), 400

        # Parse ISO datetime
        try:
            new_time = datetime.fromisoformat(new_time_str)
        except ValueError:
            return jsonify({"error": "Invalid datetime format. Use ISO format."}), 400

        old_time = interview.scheduled_time
        interview.scheduled_time = new_time
        db.session.commit()

        # Create candidate notification
        notif = Notification(
            user_id=interview.candidate_id,
            message=f"Your interview has been rescheduled from "
                    f"{old_time.strftime('%Y-%m-%d %H:%M:%S')} to "
                    f"{new_time.strftime('%Y-%m-%d %H:%M:%S')}."
        )
        db.session.add(notif)
        db.session.commit()

        # Send reschedule email
        candidate_user = interview.candidate.user  # ⚡ correct relationship
        if candidate_user and candidate_user.email:
            # Construct candidate name safely
            candidate_name = candidate_user.profile.get("full_name")
            if not candidate_name:
                candidate_name = f"{candidate_user.profile.get('first_name', '')} {candidate_user.profile.get('last_name', '')}".strip()

            EmailService.send_interview_reschedule_email(
                email=candidate_user.email,
                candidate_name=candidate_name or "Candidate",
                old_time=old_time.strftime("%A, %d %B %Y at %H:%M"),
                new_time=new_time.strftime("%A, %d %B %Y at %H:%M"),
                interview_type=interview.interview_type or "Online",
                meeting_link=interview.meeting_link
            )

        # Audit log
        from flask_jwt_extended import get_jwt_identity
        current_admin_id = get_jwt_identity()
        AuditService.record_action(
            admin_id=current_admin_id,
            action="Rescheduled Interview",
            target_user_id=interview.candidate_id,
            details=f"Interview {interview_id} rescheduled from {old_time} to {new_time}"
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
@admin_bp.route("/interviews/cancel/<int:interview_id>", methods=["DELETE", "OPTIONS"])
@role_required(["admin", "hiring_manager"])
def cancel_interview(interview_id):
    # Handle CORS preflight
    if request.method == "OPTIONS":
        return jsonify({"status": "OK"}), 200

    try:
        # Fetch the interview
        interview = Interview.query.get(interview_id)
        if not interview:
            return jsonify({"success": False, "error": f"Interview with ID {interview_id} not found"}), 404

        # Fetch candidate
        candidate = Candidate.query.get(interview.candidate_id)
        if not candidate:
            return jsonify({"success": False, "error": "Candidate profile not found"}), 404

        # Fetch the linked user (for email)
        user = User.query.get(candidate.user_id)

        # Delete the interview
        db.session.delete(interview)
        db.session.commit()

        # Add notification
        notif = Notification(
            user_id=candidate.user_id,
            message=f"Your interview scheduled for {interview.scheduled_time.strftime('%Y-%m-%d %H:%M:%S')} has been cancelled."
        )
        db.session.add(notif)
        db.session.commit()

        # Send cancellation email
        if user and user.email:
            EmailService.send_interview_cancellation(
                email=user.email,
                candidate_name=candidate.full_name,
                interview_date=interview.scheduled_time.strftime("%A, %d %B %Y at %H:%M"),
                interview_type=interview.interview_type,
                reason="The interview has been cancelled by the admin."
            )


        # Log the action
        AuditService.log(
            user_id=candidate.user_id,
            action="Interview Cancelled",
            details=f"Interview ID {interview.id} cancelled by admin/hiring manager"
        )

        # Return success response for frontend
        return jsonify({
            "success": True,
            "message": "Interview cancelled successfully.",
            "interview_id": interview_id
        }), 200

    except Exception as e:
        current_app.logger.error(f"Cancel interview error: {e}", exc_info=True)
        db.session.rollback()
        return jsonify({"success": False, "error": "Internal server error"}), 500
    
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
    
@admin_bp.route("/interviews/all", methods=["GET"])
@role_required(["admin", "hiring_manager"])
def get_all_interviews():
    """
    Fetch all interviews with pagination, search, and filters.
    Accessible to admin and hiring_manager roles.
    """
    try:
        # ---------------- Query Params ----------------
        page = request.args.get("page", 1, type=int)
        per_page = request.args.get("per_page", 10, type=int)
        search = request.args.get("search", type=str)
        status = request.args.get("status", type=str)
        interview_type = request.args.get("interview_type", type=str)
        sort_by = request.args.get("sort_by", "created_at")
        sort_order = request.args.get("sort_order", "desc")

        # ---------------- Base Query ----------------
        query = Interview.query.join(Interview.candidate).join(Interview.hiring_manager).outerjoin(Interview.application)

        # ---------------- Filters ----------------
        if status:
            query = query.filter(Interview.status.ilike(f"%{status}%"))
        if interview_type:
            query = query.filter(Interview.interview_type.ilike(f"%{interview_type}%"))
        if search:
            search_pattern = f"%{search}%"
            query = query.filter(
                db.or_(
                    Candidate.full_name.ilike(search_pattern),
                    getattr(User, "first_name", "").ilike(search_pattern),
                    getattr(User, "last_name", "").ilike(search_pattern),
                    Interview.meeting_link.ilike(search_pattern)
                )
            )

        # ---------------- Sorting ----------------
        sort_column = getattr(Interview, sort_by, Interview.created_at)
        if sort_order.lower() == "desc":
            sort_column = sort_column.desc()
        query = query.order_by(sort_column)

        # ---------------- Pagination ----------------
        pagination = query.paginate(page=page, per_page=per_page, error_out=False)
        interviews = pagination.items

        # ---------------- Response ----------------
        enriched = []
        for i in interviews:
            # Safe candidate name
            candidate_name = i.candidate.full_name if i.candidate and hasattr(i.candidate, "full_name") else None

            # Safe hiring manager name
            hiring_manager_name = None
            if i.hiring_manager:
                first = getattr(i.hiring_manager, "first_name", "")
                last = getattr(i.hiring_manager, "last_name", "")
                hiring_manager_name = f"{first} {last}".strip() or None

            enriched.append({
                "id": i.id,
                "candidate_id": i.candidate_id,
                "candidate_name": candidate_name,
                "hiring_manager_id": i.hiring_manager_id,
                "hiring_manager_name": hiring_manager_name,
                "application_id": i.application_id,
                "job_title": (
                    i.application.requisition.title
                    if i.application and hasattr(i.application, "requisition") and i.application.requisition
                    else None
                ),
                "scheduled_time": i.scheduled_time.isoformat() if i.scheduled_time else None,
                "interview_type": i.interview_type,
                "meeting_link": i.meeting_link,
                "status": i.status,
                "created_at": i.created_at.isoformat() if i.created_at else None,
            })

        return jsonify({
            "page": page,
            "per_page": per_page,
            "total": pagination.total,
            "pages": pagination.pages,
            "interviews": enriched
        }), 200

    except Exception as e:
        current_app.logger.error(f"Error fetching all interviews: {e}", exc_info=True)
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
    Enhanced Power BI dataset with optional filters:
    - job_id
    - candidate_id
    - status
    - start_date, end_date
    """
    try:
        job_id = request.args.get("job_id", type=int)
        candidate_id = request.args.get("candidate_id", type=int)
        status = request.args.get("status", type=str)
        start_date_str = request.args.get("start_date")
        end_date_str = request.args.get("end_date")

        # --- Base query ---
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
                return jsonify({"error": "Invalid start_date format"}), 400

        if end_date_str:
            try:
                end_date = datetime.fromisoformat(end_date_str)
                query = query.filter(Application.created_at <= end_date)
            except ValueError:
                return jsonify({"error": "Invalid end_date format"}), 400

        applications = query.all()
        data = []

        for app in applications:
            candidate = app.candidate
            user = candidate.user if candidate else None
            job = app.requisition

            assessment = AssessmentResult.query.filter_by(application_id=app.id).first()
            interviews = Interview.query.filter_by(application_id=app.id).all()

            # Pull latest CV Analysis
            cv_analysis = CVAnalysis.query.filter_by(candidate_id=app.candidate_id) \
                .order_by(CVAnalysis.created_at.desc()).first()

            # Count experience & education
            experience_count = (
                Experience.query.filter_by(candidate_id=candidate.id).count()
                if candidate else 0
            )

            education_count = (
                Education.query.filter_by(candidate_id=candidate.id).count()
                if candidate else 0
            )

            data.append({
                # ------------------
                # APPLICATION
                # ------------------
                "application_id": app.id,
                "application_status": app.status,
                "cv_score": app.cv_score,
                "assessment_score": app.assessment_score,
                "overall_score": app.overall_score,
                "created_at": app.created_at.isoformat() if app.created_at else None,
                "saved_at": app.saved_at.isoformat() if hasattr(app, "saved_at") else None,
                "last_saved_screen": getattr(app, "last_saved_screen", None),

                # Assessment extra fields
                "assessment_total_score": assessment.total_score if assessment else None,
                "assessment_percentage": assessment.percentage if assessment else None,
                "recommendation": assessment.recommendation if assessment else None,

                # ------------------
                # CANDIDATE
                # ------------------
                "candidate_id": candidate.id if candidate else None,
                "candidate_name": candidate.full_name if candidate else None,
                "candidate_email": user.email if user else None,
                "candidate_phone": candidate.phone if candidate else None,
                "candidate_title": candidate.title if candidate else None,
                "candidate_location": candidate.location if candidate else None,
                "candidate_skills": candidate.skills if candidate else None,
                "candidate_verified": user.is_verified if user else None,
                "experience_count": experience_count,
                "education_count": education_count,
                "linkedin": candidate.linkedin if candidate else None,

                # ------------------
                # JOB
                # ------------------
                "job_id": job.id if job else None,
                "job_title": job.title if job else None,
                "job_category": job.category if job else None,
                "job_created_at": job.created_at.isoformat() if job and job.created_at else None,
                "job_published_on": job.published_on.isoformat() if job and job.published_on else None,
                "job_required_skills": job.required_skills if job else None,

                # ------------------
                # INTERVIEWS
                # ------------------
                "interview_count": len(interviews),
                "interview_dates": [i.scheduled_time.isoformat() for i in interviews],
                "interview_types": [i.type for i in interviews],
                "interview_statuses": [i.status for i in interviews],
                "interview_hiring_managers": [
                    User.query.get(i.hiring_manager_id).full_name
                    if i.hiring_manager_id else None for i in interviews
                ],

                # ------------------
                # CV ANALYSIS
                # ------------------
                "cv_skills_match": cv_analysis.skills_match if cv_analysis else None,
                "cv_missing_skills": cv_analysis.missing_skills if cv_analysis else None,
                "cv_analysis_date": cv_analysis.created_at.isoformat() if cv_analysis else None,
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


@admin_bp.route("/applications/<int:application_id>/download-cv", methods=["GET", "OPTIONS"])
@role_required(["admin", "hiring_manager"])
def download_application_cv(application_id):
    """
    Returns the CV URL for the given application.
    Handles CORS preflight OPTIONS request.
    """
    # Handle preflight CORS
    if request.method == "OPTIONS":
        return '', 200

    # Fetch application
    application = Application.query.get_or_404(application_id)

    # Check if CV is uploaded
    if not application.resume_url:
        return jsonify({"error": "CV not uploaded"}), 404

    return jsonify({
        "application_id": application.id,
        "candidate_name": application.candidate.full_name,  # via relationship
        "cv_url": application.resume_url
    }), 200

    
@admin_bp.route("/candidates/all", methods=["GET"])
@role_required(["admin", "hiring_manager"])
def get_all_candidates():
    """
    Fetch all candidates with their profile info.
    """
    try:
        candidates = Candidate.query.all()
        enriched = [c.to_dict() for c in candidates]

        return jsonify({
            "total": len(enriched),
            "candidates": enriched
        }), 200
    except Exception as e:
        current_app.logger.error(f"Error fetching candidates: {e}", exc_info=True)
        return jsonify({"error": "Internal server error"}), 500
    
@admin_bp.route('/api/auth/enroll_mfa/<int:user_id>', methods=['POST'])
@jwt_required()
def enroll_mfa(user_id):
    current_user_id = get_jwt_identity()
    current_user = User.query.get(current_user_id)

    # ------------------- Admin check -------------------
    if current_user.role.lower() != "admin":
        return jsonify({"error": "Only admins can enroll MFA"}), 403

    # ------------------- Target user -------------------
    user = User.query.get(user_id)
    if not user:
        return jsonify({"error": "User not found"}), 404

    # ------------------- Generate MFA secret -------------------
    if not user.mfa_secret:
        user.mfa_secret = pyotp.random_base32()

    user.mfa_enabled = True
    db.session.commit()

    # ------------------- Audit log -------------------
    AuditService.log(
        user_id=current_user.id,
        action=f"enrolled_mfa_for_user_{user.id}"
    )

    # ------------------- Generate QR code URI -------------------
    totp = pyotp.TOTP(user.mfa_secret)
    otp_uri = totp.provisioning_uri(name=user.email, issuer_name="YourAppName")

    return jsonify({
        'message': 'MFA enrollment successful',
        'otp_uri': otp_uri,
        'secret': user.mfa_secret
    }), 200
    
# ============================================================
# SHARED NOTES & MEETINGS MANAGEMENT (ADMIN + HIRING MANAGER)
# ============================================================


# -------------------- SHARED NOTES --------------------
@admin_bp.route('/shared-notes', methods=['GET'])
@role_required(["admin", "hiring_manager"])
def get_shared_notes():
    """Get all shared notes with pagination and filtering"""
    try:
        page = request.args.get('page', 1, type=int)
        per_page = request.args.get('per_page', 20, type=int)
        search = request.args.get('search', '', type=str)
        author_id = request.args.get('author_id', type=int)
        
        # Base query
        query = SharedNote.query
        
        # Apply filters
        if search:
            query = query.filter(
                or_(
                    SharedNote.title.ilike(f'%{search}%'),
                    SharedNote.content.ilike(f'%{search}%')
                )
            )
        
        if author_id:
            query = query.filter(SharedNote.author_id == author_id)
        
        # Order and paginate
        notes = query.order_by(SharedNote.created_at.desc()).paginate(
            page=page, per_page=per_page, error_out=False
        )
        
        return jsonify({
            'notes': [note.to_dict() for note in notes.items],
            'total': notes.total,
            'pages': notes.pages,
            'current_page': page,
            'per_page': per_page
        }), 200
        
    except Exception as e:
        current_app.logger.error(f"Error fetching shared notes: {str(e)}")
        return jsonify({"error": "Failed to fetch shared notes"}), 500


@admin_bp.route('/shared-notes/<int:note_id>', methods=['GET'])
@role_required(["admin", "hiring_manager"])
def get_shared_note(note_id):
    """Get a specific shared note"""
    try:
        note = SharedNote.query.get_or_404(note_id)
        return jsonify(note.to_dict()), 200
    except Exception as e:
        current_app.logger.error(f"Error fetching note {note_id}: {str(e)}")
        return jsonify({"error": "Failed to fetch note"}), 500


def sanitize_html(content):
    """Sanitize HTML content to prevent XSS"""
    allowed_tags = ['p', 'br', 'strong', 'em', 'u', 'ul', 'ol', 'li', 'h1', 'h2', 'h3', 'h4']
    allowed_attributes = {
        'a': ['href', 'title'],
        'img': ['src', 'alt', 'width', 'height']
    }
    return bleach.clean(
        content, 
        tags=allowed_tags, 
        attributes=allowed_attributes,
        strip=True
    )


@admin_bp.route('/shared-notes', methods=['POST'])
@role_required(["admin", "hiring_manager"])
def create_shared_note():
    """Create a new shared note"""
    try:
        data = request.get_json()
        if not data:
            return jsonify({"error": "No JSON data provided"}), 400
            
        user_id = get_jwt_identity()
        title = data.get("title", "").strip()
        content = data.get("content", "").strip()
        tags = data.get("tags", [])
        is_pinned = data.get("is_pinned", False)

        # Validation
        if not title or not content:
            return jsonify({"error": "Title and content are required"}), 400
            
        if len(title) > 255:
            return jsonify({"error": "Title too long (max 255 characters)"}), 400
            
        if len(content) > 10000:
            return jsonify({"error": "Content too long (max 10,000 characters)"}), 400

        # Sanitize content
        sanitized_content = sanitize_html(content)
        
        # Create note
        note = SharedNote(
            title=title, 
            content=sanitized_content, 
            author_id=user_id,
            tags=tags,
            is_pinned=is_pinned
        )
        
        db.session.add(note)
        db.session.commit()

        AuditService.record_action(admin_id=user_id, action="create_shared_note", details=f"Created note '{title}'")
        return jsonify({
            "message": "Note created successfully", 
            "note": note.to_dict()
        }), 201
        
    except Exception as e:
        db.session.rollback()
        current_app.logger.error(f"Error creating shared note: {str(e)}")
        return jsonify({"error": "Internal server error"}), 500


@admin_bp.route('/shared-notes/<int:note_id>', methods=['PUT'])
@role_required(["admin", "hiring_manager"])
def update_shared_note(note_id):
    """Update an existing shared note"""
    try:
        user_id = get_jwt_identity()
        note = SharedNote.query.get_or_404(note_id)
        
        # Authorization check - only author or admin can edit
        user_roles = get_jwt().get("roles", [])
        if note.author_id != user_id and "admin" not in user_roles:
            return jsonify({"error": "Not authorized to edit this note"}), 403

        data = request.get_json()
        if not data:
            return jsonify({"error": "No JSON data provided"}), 400
            
        # Update fields
        if "title" in data:
            title = data.get("title", "").strip()
            if not title:
                return jsonify({"error": "Title cannot be empty"}), 400
            if len(title) > 255:
                return jsonify({"error": "Title too long (max 255 characters)"}), 400
            note.title = title
            
        if "content" in data:
            content = data.get("content", "").strip()
            if not content:
                return jsonify({"error": "Content cannot be empty"}), 400
            if len(content) > 10000:
                return jsonify({"error": "Content too long (max 10,000 characters)"}), 400
            note.content = sanitize_html(content)
            
        if "tags" in data:
            note.tags = data.get("tags", [])
            
        if "is_pinned" in data:
            note.is_pinned = data.get("is_pinned", False)

        note.updated_at = datetime.utcnow()
        db.session.commit()

        AuditService.record_action(admin_id=user_id, action="update_shared_note", details=f"Updated note '{note.title}'")
        return jsonify({
            "message": "Note updated successfully", 
            "note": note.to_dict()
        }), 200
        
    except Exception as e:
        db.session.rollback()
        current_app.logger.error(f"Error updating shared note {note_id}: {str(e)}")
        return jsonify({"error": "Internal server error"}), 500


@admin_bp.route('/shared-notes/<int:note_id>', methods=['DELETE'])
@role_required(["admin", "hiring_manager"])
def delete_shared_note(note_id):
    """Delete a shared note"""
    try:
        user_id = get_jwt_identity()
        note = SharedNote.query.get_or_404(note_id)
        
        # Authorization check - only author or admin can delete
        user_roles = get_jwt_claims().get("roles", [])
        if note.author_id != user_id and "admin" not in user_roles:
            return jsonify({"error": "Not authorized to delete this note"}), 403

        note_title = note.title
        db.session.delete(note)
        db.session.commit()

        AuditService.record_action(admin_id=user_id, action="delete_shared_note", details=f"Deleted note '{note_title}'")
        return jsonify({"message": "Note deleted successfully"}), 200
        
    except Exception as e:
        db.session.rollback()
        current_app.logger.error(f"Error deleting shared note {note_id}: {str(e)}")
        return jsonify({"error": "Internal server error"}), 500


# -------------------- MEETINGS --------------------
def validate_meeting_times(start_time, end_time):
    """Validate meeting time logic"""
    if start_time >= end_time:
        return False, "End time must be after start time"
    
    if start_time < datetime.now():
        return False, "Meeting cannot be scheduled in the past"
        
    # Check if meeting is too long (more than 8 hours)
    meeting_duration = end_time - start_time
    if meeting_duration.total_seconds() > 8 * 3600:
        return False, "Meeting duration cannot exceed 8 hours"
        
    return True, None


def validate_participants(participants):
    """Validate participant email addresses"""
    import re
    email_pattern = re.compile(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$')
    
    for email in participants:
        if not email_pattern.match(email):
            return False, f"Invalid email format: {email}"
            
    return True, None


@admin_bp.route('/meetings', methods=['GET'])
@role_required(["admin", "hiring_manager"])
def get_meetings():
    """Get all meetings with filtering and pagination"""
    try:
        page = request.args.get('page', 1, type=int)
        per_page = request.args.get('per_page', 20, type=int)
        status = request.args.get('status', type=str)  # upcoming, past, cancelled
        search = request.args.get('search', '', type=str)
        
        # Base query
        query = Meeting.query
        
        # Apply filters
        if search:
            query = query.filter(
                or_(
                    Meeting.title.ilike(f'%{search}%'),
                    Meeting.description.ilike(f'%{search}%')
                )
            )
        
        now = datetime.now()
        if status == 'upcoming':
            query = query.filter(
                and_(
                    Meeting.start_time > now,
                    Meeting.cancelled == False
                )
            )
        elif status == 'past':
            query = query.filter(
                and_(
                    Meeting.end_time < now,
                    Meeting.cancelled == False
                )
            )
        elif status == 'cancelled':
            query = query.filter(Meeting.cancelled == True)
        elif status == 'active':
            query = query.filter(
                and_(
                    Meeting.start_time <= now,
                    Meeting.end_time >= now,
                    Meeting.cancelled == False
                )
            )
        # If status is None (All), show all meetings including cancelled
        
        # Order and paginate
        meetings = query.order_by(Meeting.start_time.desc()).paginate(
            page=page, per_page=per_page, error_out=False
        )
        
        return jsonify({
            'meetings': [m.to_dict() for m in meetings.items],
            'total': meetings.total,
            'pages': meetings.pages,
            'current_page': page,
            'per_page': per_page
        }), 200
        
    except Exception as e:
        current_app.logger.error(f"Error fetching meetings: {str(e)}")
        return jsonify({"error": "Failed to fetch meetings"}), 500


@admin_bp.route('/meetings/<int:meeting_id>', methods=['GET'])
@role_required(["admin", "hiring_manager"])
def get_meeting(meeting_id):
    """Get a specific meeting"""
    try:
        meeting = Meeting.query.get_or_404(meeting_id)
        return jsonify(meeting.to_dict()), 200
    except Exception as e:
        current_app.logger.error(f"Error fetching meeting {meeting_id}: {str(e)}")
        return jsonify({"error": "Failed to fetch meeting"}), 500


@admin_bp.route('/meetings', methods=['POST'])
@role_required(["admin", "hiring_manager"])
def create_meeting():
    """Create a new meeting"""
    try:
        user_id = get_jwt_identity()
        data = request.get_json()
        
        if not data:
            return jsonify({"error": "No JSON data provided"}), 400

        # Required fields
        title = data.get("title", "").strip()
        start_time_str = data.get("start_time")
        end_time_str = data.get("end_time")
        
        if not title or not start_time_str or not end_time_str:
            return jsonify({"error": "Title, start_time, and end_time are required"}), 400

        # Parse and validate times
        try:
            # Handle timezone indicators
            start_time_str_clean = start_time_str.replace('Z', '+00:00') if 'Z' in start_time_str else start_time_str
            end_time_str_clean = end_time_str.replace('Z', '+00:00') if 'Z' in end_time_str else end_time_str
            start_time = datetime.fromisoformat(start_time_str_clean)
            end_time = datetime.fromisoformat(end_time_str_clean)
        except (ValueError, AttributeError) as e:
            current_app.logger.error(f"Datetime parsing error: {e}, start_time_str: {start_time_str}, end_time_str: {end_time_str}")
            return jsonify({"error": f"Invalid datetime format. Use ISO format. Error: {str(e)}"}), 400

        # Validate meeting times
        is_valid, error_msg = validate_meeting_times(start_time, end_time)
        if not is_valid:
            return jsonify({"error": error_msg}), 400

        # Optional fields
        description = data.get("description", "").strip()
        participants = data.get("participants", [])
        meeting_link = data.get("meeting_link", "").strip()
        location = data.get("location", "").strip()
        meeting_type = data.get("meeting_type", "general")

        # Validate participants
        if participants:
            is_valid, error_msg = validate_participants(participants)
            if not is_valid:
                return jsonify({"error": error_msg}), 400

        # Check for scheduling conflicts
        conflicting_meeting = Meeting.query.filter(
            Meeting.organizer_id == user_id,
            Meeting.cancelled == False,
            Meeting.start_time < end_time,
            Meeting.end_time > start_time
        ).first()
        
        if conflicting_meeting:
            return jsonify({
                "error": "Scheduling conflict detected",
                "conflicting_meeting": conflicting_meeting.to_dict()
            }), 409

        # Create meeting
        meeting = Meeting(
            title=title,
            description=description,
            start_time=start_time,
            end_time=end_time,
            organizer_id=user_id,
            participants=participants,
            meeting_link=meeting_link,
            location=location,
            meeting_type=meeting_type
        )

        db.session.add(meeting)
        db.session.commit()

        # Send email notifications (if enabled)
        if participants and current_app.config.get('SEND_MEETING_EMAILS', True):
            try:
                for participant in participants:
                    EmailService.send_meeting_invitation(
                        email=participant,
                        meeting_title=title,
                        meeting_date=start_time,
                        meeting_description=description,
                        meeting_link=meeting_link,
                        location=location,
                        organizer_id=user_id
                    )
            except Exception as e:
                current_app.logger.warning(f"Failed to send meeting invite emails: {e}")
                # Don't fail the request if emails fail

        AuditService.record_action(admin_id=user_id, action="create_meeting", details=f"Created meeting '{title}'")
        return jsonify({
            "message": "Meeting created successfully", 
            "meeting": meeting.to_dict()
        }), 201
        
    except Exception as e:
        db.session.rollback()
        current_app.logger.error(f"Error creating meeting: {str(e)}", exc_info=True)
        return jsonify({"error": f"Internal server error: {str(e)}"}), 500


@admin_bp.route('/meetings/<int:meeting_id>', methods=['PUT'])
@role_required(["admin", "hiring_manager"])
def update_meeting(meeting_id):
    """Update meeting details"""
    try:
        user_id = get_jwt_identity()
        meeting = Meeting.query.get_or_404(meeting_id)
        
        # Authorization check
        user_roles = get_jwt_claims().get("roles", [])
        if meeting.organizer_id != user_id and "admin" not in user_roles:
            return jsonify({"error": "Not authorized to edit this meeting"}), 403

        data = request.get_json()
        if not data:
            return jsonify({"error": "No JSON data provided"}), 400

        # Update fields
        if "title" in data:
            meeting.title = data.get("title", "").strip()
            if not meeting.title:
                return jsonify({"error": "Title cannot be empty"}), 400

        if "description" in data:
            meeting.description = data.get("description", "").strip()

        if "participants" in data:
            participants = data.get("participants", [])
            is_valid, error_msg = validate_participants(participants)
            if not is_valid:
                return jsonify({"error": error_msg}), 400
            meeting.participants = participants

        if "meeting_link" in data:
            meeting.meeting_link = data.get("meeting_link", "").strip()

        if "location" in data:
            meeting.location = data.get("location", "").strip()

        if "meeting_type" in data:
            meeting.meeting_type = data.get("meeting_type", "general")

        # Handle time updates with validation
        start_time_changed = "start_time" in data
        end_time_changed = "end_time" in data
        
        if start_time_changed or end_time_changed:
            new_start_time = datetime.fromisoformat(data["start_time"].replace('Z', '+00:00')) if start_time_changed else meeting.start_time
            new_end_time = datetime.fromisoformat(data["end_time"].replace('Z', '+00:00')) if end_time_changed else meeting.end_time
            
            is_valid, error_msg = validate_meeting_times(new_start_time, new_end_time)
            if not is_valid:
                return jsonify({"error": error_msg}), 400
                
            # Check for scheduling conflicts (excluding current meeting)
            conflicting_meeting = Meeting.query.filter(
                Meeting.organizer_id == user_id,
                Meeting.cancelled == False,
                Meeting.id != meeting_id,
                Meeting.start_time < new_end_time,
                Meeting.end_time > new_start_time
            ).first()
            
            if conflicting_meeting:
                return jsonify({
                    "error": "Scheduling conflict detected",
                    "conflicting_meeting": conflicting_meeting.to_dict()
                }), 409

            meeting.start_time = new_start_time
            meeting.end_time = new_end_time

        meeting.updated_at = datetime.utcnow()
        db.session.commit()

        AuditService.record_action(admin_id=user_id, action="update_meeting", details=f"Updated meeting '{meeting.title}'")
        return jsonify({
            "message": "Meeting updated successfully", 
            "meeting": meeting.to_dict()
        }), 200
        
    except Exception as e:
        db.session.rollback()
        current_app.logger.error(f"Error updating meeting {meeting_id}: {str(e)}")
        return jsonify({"error": "Internal server error"}), 500


@admin_bp.route('/meetings/<int:meeting_id>/cancel', methods=['POST'])
@role_required(["admin", "hiring_manager"])
def cancel_meeting(meeting_id):
    """Cancel a meeting"""
    try:
        user_id = get_jwt_identity()
        meeting = Meeting.query.get_or_404(meeting_id)
        
        # Authorization check
        user_roles = get_jwt_claims().get("roles", [])
        if meeting.organizer_id != user_id and "admin" not in user_roles:
            return jsonify({"error": "Not authorized to cancel this meeting"}), 403

        if meeting.cancelled:
            return jsonify({"error": "Meeting is already cancelled"}), 400

        meeting.cancelled = True
        meeting.cancelled_at = datetime.utcnow()
        meeting.cancelled_by = user_id
        db.session.commit()

        # Send cancellation emails
        if meeting.participants and current_app.config.get('SEND_MEETING_EMAILS', True):
            try:
                for participant in meeting.participants:
                    EmailService.send_meeting_cancellation(
                        email=participant,
                        meeting_title=meeting.title,
                        meeting_date=meeting.start_time,
                        cancellation_reason="Meeting cancelled by organizer"
                    )
            except Exception as e:
                current_app.logger.warning(f"Failed to send meeting cancellation emails: {e}")

        AuditService.record_action(admin_id=user_id, action="cancel_meeting", details=f"Cancelled meeting '{meeting.title}'")
        return jsonify({"message": "Meeting cancelled successfully"}), 200
        
    except Exception as e:
        db.session.rollback()
        current_app.logger.error(f"Error cancelling meeting {meeting_id}: {str(e)}")
        return jsonify({"error": "Internal server error"}), 500


@admin_bp.route('/meetings/<int:meeting_id>', methods=['DELETE'])
@role_required(["admin", "hiring_manager"])
def delete_meeting(meeting_id):
    """Delete a meeting"""
    try:
        user_id = get_jwt_identity()
        meeting = Meeting.query.get_or_404(meeting_id)
        
        # Authorization check
        user_roles = get_jwt_claims().get("roles", [])
        if meeting.organizer_id != user_id and "admin" not in user_roles:
            return jsonify({"error": "Not authorized to delete this meeting"}), 403

        meeting_title = meeting.title
        db.session.delete(meeting)
        db.session.commit()

        AuditService.record_action(admin_id=user_id, action="delete_meeting", details=f"Deleted meeting '{meeting_title}'")
        return jsonify({"message": "Meeting deleted successfully"}), 200
        
    except Exception as e:
        db.session.rollback()
        current_app.logger.error(f"Error deleting meeting {meeting_id}: {str(e)}")
        return jsonify({"error": "Internal server error"}), 500


@admin_bp.route('/meetings/upcoming', methods=['GET'])
@jwt_required()
@role_required(["admin", "hiring_manager"])
def get_upcoming_meetings():
    """
    Get upcoming meetings for the current user with pagination, optional filters.
    Filters:
        - start_date, end_date (YYYY-MM-DD)
        - keyword (search in title or description)
    Pagination:
        - limit (default 10)
        - offset (default 0)
    """
    try:
        # --- Get user info from JWT ---
        user_id = get_jwt_identity()
        user = User.query.get(user_id)
        if not user:
            return jsonify({"error": "User not found"}), 404
        user_email = user.email

        # --- Pagination ---
        limit = request.args.get('limit', 10, type=int)
        offset = request.args.get('offset', 0, type=int)

        # --- Optional filters ---
        start_date_str = request.args.get("start_date")
        end_date_str = request.args.get("end_date")
        keyword = request.args.get("keyword", "").strip()

        query = Meeting.query.filter(Meeting.start_time > datetime.now())

        # cancelled filter if column exists
        if hasattr(Meeting, "cancelled"):
            query = query.filter(Meeting.cancelled == False)

        # user is organizer OR participant
        from sqlalchemy.dialects.postgresql import JSONB
        query = query.filter(
            or_(
                Meeting.organizer_id == user_id,
                Meeting.participants.cast(JSONB).contains([user_email])
            )
        )

        # filter by date range
        if start_date_str:
            try:
                start_date = datetime.strptime(start_date_str, "%Y-%m-%d")
                query = query.filter(Meeting.start_time >= start_date)
            except ValueError:
                return jsonify({"error": "Invalid start_date format, use YYYY-MM-DD"}), 400

        if end_date_str:
            try:
                end_date = datetime.strptime(end_date_str, "%Y-%m-%d")
                query = query.filter(Meeting.start_time <= end_date)
            except ValueError:
                return jsonify({"error": "Invalid end_date format, use YYYY-MM-DD"}), 400

        # keyword search
        if keyword:
            query = query.filter(
                or_(
                    Meeting.title.ilike(f"%{keyword}%"),
                    Meeting.description.ilike(f"%{keyword}%")
                )
            )

        total_count = query.count()

        meetings = (
            query.order_by(Meeting.start_time.asc())
                 .offset(offset)
                 .limit(limit)
                 .all()
        )

        # --- Serialize meetings safely ---
        meetings_data = []
        for m in meetings:
            participants_list = m.participants if isinstance(m.participants, list) else []
            meetings_data.append({
                "id": m.id,
                "title": m.title,
                "description": m.description,
                "start_time": m.start_time.isoformat(),
                "end_time": m.end_time.isoformat() if m.end_time else None,
                "organizer_id": m.organizer_id,
                "participants": participants_list,
                "meeting_link": m.meeting_link,
                "cancelled": m.cancelled if hasattr(m, "cancelled") else False
            })

        return jsonify({
            "total": total_count,
            "limit": limit,
            "offset": offset,
            "meetings": meetings_data
        }), 200

    except Exception as e:
        current_app.logger.error(f"Error fetching upcoming meetings: {str(e)}")
        return jsonify({"error": "Failed to fetch upcoming meetings"}), 500
