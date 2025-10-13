# app/routes/ai_routes.py
from flask import Blueprint, request, jsonify
from flask_jwt_extended import get_jwt_identity
from app.utils.decorators import role_required
from app.services.ai_parser_service import analyse_resume_gemini
from app.extensions import db, cloudinary_client
from app.models import CVAnalysis, Conversation, Candidate, User
import cloudinary.uploader
import datetime
import logging

logger = logging.getLogger(__name__)
ai_bp = Blueprint("ai_bp", __name__, url_prefix="/api/ai")


@ai_bp.route("/chat", methods=["POST"])
def chat():
    """
    Public chat endpoint (optionally require auth if desired).
    body: {"message": "hello"}
    """
    data = request.get_json(silent=True) or {}
    message = (data.get("message") or "").strip()
    if not message:
        return jsonify({"error": "Message required"}), 400

    # Lazy import to avoid cycle
    from app.services.ai_service import AIService
    ai = AIService()

    try:
        reply = ai.chat(message)

        # Optionally persist conversation if authenticated
        user_id = None
        try:
            user_id = get_jwt_identity()
        except Exception:
            user_id = None

        if user_id:
            try:
                conv = Conversation(user_id=user_id, user_message=message, assistant_message=reply)
                db.session.add(conv)
                db.session.commit()
            except Exception:
                db.session.rollback()
                logger.exception("Failed to save conversation")

        return jsonify({"reply": reply}), 200

    except Exception as e:
        logger.exception("Chat error")
        return jsonify({
            "error": "AI chat failed",
            "details": str(e)
        }), 502  # use 502 Bad Gateway for upstream AI errors


@ai_bp.route("/parse_cv", methods=["POST"])
@role_required(["candidate"])
def parse_cv():
    """
    Accepts:
    - JSON: { "cv_text": "...", "job_description": "..." }
    - or multipart: file field "resume" and job_description form field.
    """
    user_id = get_jwt_identity()
    user = User.query.get_or_404(user_id)
    candidate = Candidate.query.filter_by(user_id=user_id).first()
    if not candidate:
        candidate = Candidate(user_id=user_id)
        db.session.add(candidate)
        db.session.commit()

    # Accept cv_text and job_description
    cv_text = request.form.get("cv_text") or (request.json and request.json.get("cv_text"))
    job_description = request.form.get("job_description") or (request.json and request.json.get("job_description"))

    # If a file is uploaded, push to Cloudinary
    resume_url = None
    if "resume" in request.files:
        file = request.files["resume"]
        try:
            upload_result = cloudinary.uploader.upload(file, folder="resumes", resource_type="raw")
            resume_url = upload_result.get("secure_url")
            candidate.cv_url = resume_url
        except Exception:
            logger.exception("Cloudinary upload failed")

    if not job_description:
        return jsonify({"error": "job_description is required"}), 400

    if not cv_text:
        cv_text = candidate.cv_text or ""
        if not cv_text:
            return jsonify({"error": "cv_text is required (or upload text)"}), 400

    # Run Gemini CV analysis with safe fallback
    parser_result = analyse_resume_gemini(cv_text=cv_text, job_description=job_description)

    # Save analysis record
    try:
        analysis = CVAnalysis(
            candidate_id=candidate.id,
            job_description=job_description,
            cv_text=cv_text,
            result=parser_result,
            created_at=datetime.datetime.utcnow(),
        )
        db.session.add(analysis)

        candidate.profile = candidate.profile or {}
        candidate.profile["cv_parser_result"] = parser_result
        candidate.cv_score = parser_result.get("match_score", candidate.cv_score or 0)
        db.session.commit()
    except Exception:
        db.session.rollback()
        logger.exception("Failed to save CV analysis")

    # Notify admins
    try:
        from app.models import User as UserModel, Notification
        admins = UserModel.query.filter_by(role="admin").all()
        for admin in admins:
            n = Notification(user_id=admin.id, message=f"{user.email} performed CV analysis for a job.")
            db.session.add(n)
        db.session.commit()
    except Exception:
        db.session.rollback()
        logger.exception("Failed to create admin notifications")

    return jsonify({
        "message": "Analysis completed",
        "parser_result": parser_result,
        "cv_url": resume_url,
    }), 200



@ai_bp.route("/analysis/<int:analysis_id>", methods=["GET"])
@role_required(["candidate"])
def get_analysis(analysis_id):
    try:
        user_id = get_jwt_identity()
        analysis = CVAnalysis.query.get_or_404(analysis_id)
        candidate = Candidate.query.filter_by(user_id=user_id).first_or_404()

        if analysis.candidate_id != candidate.id:
            return jsonify({"error": "Unauthorized"}), 403

        return jsonify({"analysis": analysis.to_dict()}), 200
    except Exception:
        logger.exception("Failed to fetch analysis")
        return jsonify({"error": "Internal server error"}), 500
