from flask import Blueprint, jsonify
from sqlalchemy import func, cast, Date, text, case
from app.extensions import db
from app.models import (
    Application, Requisition, Interview,
    AssessmentResult, Candidate, CVAnalysis
)
import json

analytics_bp = Blueprint("analytics_bp", __name__)

# ------------------------------------------------------------
# 1. APPLICATION VOLUME PER REQUISITION
# ------------------------------------------------------------
@analytics_bp.route("/analytics/applications-per-requisition")
def applications_per_requisition():
    results = (
        db.session.query(
            Requisition.id,
            Requisition.title,
            func.count(Application.id).label("applications")
        )
        .outerjoin(Application, Application.requisition_id == Requisition.id)
        .group_by(Requisition.id)
        .all()
    )

    return jsonify([
        {"requisition_id": r.id, "title": r.title, "applications": r.applications}
        for r in results
    ])


# ------------------------------------------------------------
# 2. APPLICATION → INTERVIEW CONVERSION RATE
# ------------------------------------------------------------
@analytics_bp.route("/analytics/conversion/application-to-interview")
def application_to_interview():
    total_apps = db.session.query(func.count(Application.id)).scalar()
    interviewed = db.session.query(func.count(func.distinct(Interview.application_id))).scalar()
    rate = (interviewed / total_apps * 100) if total_apps else 0

    return jsonify({
        "total_applications": total_apps,
        "total_interviewed": interviewed,
        "conversion_rate_percent": round(rate, 2)
    })


# ------------------------------------------------------------
# 3. INTERVIEW → OFFER CONVERSION RATE
# ------------------------------------------------------------
@analytics_bp.route("/analytics/conversion/interview-to-offer")
def interview_to_offer():
    interviewed = db.session.query(func.count(func.distinct(Interview.application_id))).scalar()
    offered = db.session.query(func.count(Application.id)).filter(Application.status == "recommended").scalar()
    rate = (offered / interviewed * 100) if interviewed else 0

    return jsonify({
        "interviewed": interviewed,
        "offered": offered,
        "conversion_rate_percent": round(rate, 2)
    })


# ------------------------------------------------------------
# 4. STAGE DROP-OFF RATE
# ------------------------------------------------------------
@analytics_bp.route("/analytics/dropoff")
def stage_dropoff():
    total = db.session.query(func.count(Application.id)).scalar()
    reviewed = db.session.query(func.count(Application.id)).filter(Application.status == "reviewed").scalar()
    interviewed = db.session.query(func.count(func.distinct(Interview.application_id))).scalar()
    offered = db.session.query(func.count(Application.id)).filter(Application.status == "recommended").scalar()

    return jsonify({
        "total_applications": total,
        "reviewed": reviewed,
        "interviewed": interviewed,
        "offered": offered,
        "dropoff": {
            "cv_screening_dropoff": total - reviewed,
            "assessment_or_cv_fail_dropoff": reviewed - interviewed,
            "interview_dropoff": interviewed - offered
        }
    })


# ------------------------------------------------------------
# 5. AVERAGE TIME SPENT PER STAGE
# ------------------------------------------------------------
@analytics_bp.route("/analytics/time-per-stage")
def time_per_stage():
    query = text("""
        SELECT
            a.id AS application_id,
            a.created_at,
            MIN(i.scheduled_at) AS first_interview,
            (SELECT ar.created_at FROM assessment_results ar WHERE ar.application_id = a.id ORDER BY ar.created_at LIMIT 1) AS first_assessment
        FROM applications a
        LEFT JOIN interviews i ON i.application_id = a.id
        GROUP BY a.id
    """)
    rows = db.session.execute(query).fetchall()

    stage_times = []
    for r in rows:
        created = r.created_at
        interview = r.first_interview
        assessment = r.first_assessment

        stage_times.append({
            "application_id": r.application_id,
            "time_to_assessment_days": (assessment - created).days if assessment else None,
            "time_to_interview_days": (interview - created).days if interview else None
        })

    return jsonify(stage_times)


# ------------------------------------------------------------
# 6. APPLICATIONS PER MONTH
# ------------------------------------------------------------
@analytics_bp.route("/analytics/applications/monthly")
def monthly_applications():
    results = (
        db.session.query(
            func.date_trunc("month", Application.created_at).label("month"),
            func.count(Application.id)
        )
        .group_by(func.date_trunc("month", Application.created_at))
        .order_by(func.date_trunc("month", Application.created_at))
        .all()
    )

    return jsonify([
        {"month": r.month.strftime("%Y-%m"), "applications": r[1]}
        for r in results
    ])


# ------------------------------------------------------------
# 7. CV SCREENING DROP TREND
# ------------------------------------------------------------
# CV SCREENING DROP TREND
@analytics_bp.route("/analytics/cv-screening-drop")
def cv_screening_drop():
    results = (
        db.session.query(
            func.date_trunc("month", Application.created_at).label("month"),
            func.count(Application.id).label("total"),
            func.sum(
                case(
                    (Application.status == "rejected", 1),
                    else_=0
                )
            ).label("rejected")
        )
        .group_by(func.date_trunc("month", Application.created_at))
        .all()
    )

    return jsonify([
        {
            "month": r.month.strftime("%Y-%m"),
            "total_applications": r.total,
            "rejected": r.rejected,
            "drop_rate_percent": round((r.rejected / r.total * 100), 2) if r.total else 0
        }
        for r in results
    ])


# ASSESSMENT PASS RATE TREND
@analytics_bp.route("/analytics/assessments/pass-rate")
def assessment_pass_rate():
    results = (
        db.session.query(
            func.date_trunc("month", AssessmentResult.created_at).label("month"),
            func.count(AssessmentResult.id).label("taken"),
            func.sum(
                case(
                    (AssessmentResult.percentage_score >= 50, 1),
                    else_=0
                )
            ).label("passed")
        )
        .group_by(func.date_trunc("month", AssessmentResult.created_at))
        .all()
    )

    return jsonify([
        {
            "month": r.month.strftime("%Y-%m") if r.month else None,
            "taken": r.taken,
            "passed": r.passed,
            "pass_rate_percent": round((r.passed / r.taken * 100), 2) if r.taken else 0
        }
        for r in results
    ])



# ------------------------------------------------------------
# 9. INTERVIEW SCHEDULING RATE OVER TIME
# ------------------------------------------------------------
@analytics_bp.route("/analytics/interviews/scheduled")
def interview_scheduling():
    results = (
        db.session.query(
            func.date_trunc("month", Interview.created_at).label("month"),
            func.count(Interview.id)
        )
        .group_by(func.date_trunc("month", Interview.created_at))
        .order_by(func.date_trunc("month", Interview.created_at))
        .all()
    )

    return jsonify([
        {"month": r.month.strftime("%Y-%m"), "interviews": r[1]}
        for r in results
    ])


# ------------------------------------------------------------
# 10. OFFER TREND BY JOB CATEGORY
# ------------------------------------------------------------
@analytics_bp.route("/analytics/offers-by-category")
def offers_by_category():
    results = (
        db.session.query(
            Requisition.category,
            func.count(Application.id)
        )
        .join(Application, Application.requisition_id == Requisition.id)
        .filter(Application.status == "recommended")
        .group_by(Requisition.category)
        .all()
    )

    return jsonify([{"category": r[0], "offers": r[1]} for r in results])


# ============================================================
#  CANDIDATE INSIGHTS SECTION
# ============================================================

# ------------------------------------------------------------
# 11. AVERAGE CV SCORE
# ------------------------------------------------------------
@analytics_bp.route("/analytics/candidate/avg-cv-score")
def avg_cv_score():
    avg_score = db.session.query(func.avg(Candidate.cv_score)).scalar()
    return jsonify({"average_cv_score": round(avg_score, 2) if avg_score else 0})


# ------------------------------------------------------------
# 12. AVERAGE ASSESSMENT SCORE
# ------------------------------------------------------------
@analytics_bp.route("/analytics/candidate/avg-assessment-score")
def avg_assessment_score():
    avg_score = db.session.query(func.avg(AssessmentResult.percentage_score)).scalar()
    return jsonify({"average_assessment_score": round(avg_score, 2) if avg_score else 0})


# ------------------------------------------------------------
# 13. SKILL FREQUENCY FROM CANDIDATE.SKILLS
# ------------------------------------------------------------
@analytics_bp.route("/analytics/candidate/skills-frequency")
def skill_frequency():
    candidates = Candidate.query.with_entities(Candidate.skills).all()
    freq = {}

    for c in candidates:
        if not c.skills:
            continue
        for skill in c.skills:
            freq[skill] = freq.get(skill, 0) + 1

    return jsonify(freq)


# ------------------------------------------------------------
# 14. EXPERIENCE DISTRIBUTION (YEARS)
# ------------------------------------------------------------
@analytics_bp.route("/analytics/candidate/experience-distribution")
def experience_distribution():
    candidates = Candidate.query.all()
    distribution = {}

    for c in candidates:
        if not c.work_experience:
            continue

        # Ensure we have a list of dicts
        try:
            jobs = c.work_experience
            if isinstance(jobs, str):
                jobs = json.loads(jobs)
        except Exception:
            continue

        for j in jobs:
            if isinstance(j, dict):
                years = j.get("years", 0)
                distribution[years] = distribution.get(years, 0) + 1

    return jsonify(distribution)
