import re
import os
from dotenv import load_dotenv
from openai import OpenAI
from app.models import Requisition
from cloudinary.uploader import upload as cloudinary_upload

load_dotenv()

# OpenRouter API configuration
api_key = os.getenv("OPENROUTER_API_KEY")
openai_client = OpenAI(
    base_url="https://openrouter.ai/api/v1",
    api_key=api_key,
    default_headers={"HTTP-Referer": "http://localhost:5000"}  # Replace with your app's URL
)

def analyse_resume_openrouter(resume_content, job_id):
    """
    Analyse resume against job description from the Requisition table.
    Returns structured data: match_score, missing_skills, suggestions
    """

    # Fetch job from DB
    job = Requisition.query.get(job_id)
    if not job:
        return {
            "match_score": 0,
            "missing_skills": [],
            "suggestions": [],
            "raw_text": "Job not found"
        }

    job_description = job.description or ""

    # Construct prompt
    prompt = f"""
Resume:
{resume_content}

Job Description:
{job_description}

Task:
- Analyze the resume against the job description.
- Give a match score out of 100.
- Highlight missing skills or experiences.
- Suggest improvements.

Return in format:
Match Score: XX/100
Missing Skills:
- ...
Suggestions:
- ...
"""

    try:
        # Call OpenRouter with system role
        response = openai_client.chat.completions.create(
            model="openrouter/auto",
            messages=[
                {"role": "system", "content": "You are an AI recruitment assistant. Always return results in the required format only."},
                {"role": "user", "content": prompt}
            ],
            temperature=0.7,
            top_p=0.9,
            max_tokens=1024
        )

        text = response.choices[0].message.content or ""

        # --- Parsing ---
        # Match score (flexible: accepts 75/100 or 75%)
        score_match = re.search(r"(\d{1,3})(?:/100|%)", text)
        match_score = int(score_match.group(1)) if score_match else 0

        # Missing skills
        missing_skills_match = re.search(r"Missing Skills:\s*(.*?)(?:Suggestions:|$)", text, re.DOTALL)
        missing_skills = []
        if missing_skills_match:
            skills_text = missing_skills_match.group(1)
            missing_skills = [line.strip("- ").strip() for line in skills_text.strip().splitlines() if line.strip()]

        # Suggestions
        suggestions_match = re.search(r"Suggestions:\s*(.*)", text, re.DOTALL)
        suggestions = []
        if suggestions_match:
            suggestions_text = suggestions_match.group(1)
            suggestions = [line.strip("- ").strip() for line in suggestions_text.strip().splitlines() if line.strip()]

        return {
            "match_score": match_score,
            "missing_skills": missing_skills,
            "suggestions": suggestions,
            "raw_text": text
        }

    except Exception as e:
        return {
            "match_score": 0,
            "missing_skills": [],
            "suggestions": [],
            "raw_text": f"Error during analysis: {str(e)}"
        }


def upload_cv_to_cloudinary(file):
    """Uploads CV to Cloudinary and returns secure URL."""
    try:
        result = cloudinary_upload(
            file,
            resource_type="raw",
            folder="candidate_cvs"
        )
        return result.get("secure_url")
    except Exception as e:
        return None

