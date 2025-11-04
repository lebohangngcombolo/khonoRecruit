# app/services/cv_parser_service.py
from .ai_service import AIService
from typing import Dict, Any
import logging

logger = logging.getLogger(__name__)

ai = AIService()

def analyse_resume_gemini(cv_text: str, job_description: str) -> Dict[str, Any]:
    """
    Public function used by routes: returns structured parser result.
    """
    try:
        result = ai.analyze_cv_vs_job(cv_text= cv_text, job_description=job_description)
        return result
    except Exception as e:
        logger.exception("Error analyzing resume: %s", e)
        # Return safe fallback
        return {
            "match_score": 0,
            "missing_skills": [],
            "suggestions": [],
            "interview_questions": [],
            "error": str(e)
        }
