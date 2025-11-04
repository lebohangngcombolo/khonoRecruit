import os
import re
import logging
import subprocess
from dotenv import load_dotenv
from openai import OpenAI
from app.models import Requisition
from cloudinary.uploader import upload as cloudinary_upload
import spacy
from sentence_transformers import SentenceTransformer, util

# ----------------------------
# Environment & Logging Setup
# ----------------------------
load_dotenv()
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# ----------------------------
# Hybrid Resume Analyzer Class
# ----------------------------
class HybridResumeAnalyzer:
    def __init__(self):
        # --- Online AI client ---
        api_key = os.getenv("OPENROUTER_API_KEY")
        self.openai_client = None
        if api_key:
            try:
                self.openai_client = OpenAI(
                    base_url="https://openrouter.ai/api/v1",
                    api_key=api_key,
                    default_headers={"HTTP-Referer": "http://localhost:5000"}
                )
                logger.info("OpenRouter client initialized.")
            except Exception as e:
                logger.error(f"Failed to initialize OpenRouter client: {e}")

        # --- Offline NLP ---
        self.nlp = self._load_spacy_model("en_core_web_sm")

        # --- Offline embeddings ---
        try:
            self.embed_model = SentenceTransformer('all-MiniLM-L6-v2')
            logger.info("SentenceTransformer embedding model loaded.")
        except Exception as e:
            logger.error(f"Failed to load embedding model: {e}")
            self.embed_model = None

    # ----------------------------
    # Private Methods
    # ----------------------------
    def _load_spacy_model(self, model_name):
        """Load spaCy model, download if not found."""
        try:
            return spacy.load(model_name)
        except OSError:
            logger.info(f"{model_name} not found. Downloading...")
            subprocess.run(["python", "-m", "spacy", "download", model_name], check=True)
            return spacy.load(model_name)

    def _parse_openrouter_response(self, text):
        """Parse OpenRouter AI response for score, missing skills, suggestions."""
        score_match = re.search(r"(\d{1,3})(?:/100|%)", text)
        match_score = int(score_match.group(1)) if score_match else 0

        missing_skills_match = re.search(r"Missing Skills:\s*(.*?)(?:Suggestions:|$)", text, re.DOTALL)
        missing_skills = []
        if missing_skills_match:
            skills_text = missing_skills_match.group(1)
            missing_skills = [line.strip("- ").strip() for line in skills_text.strip().splitlines() if line.strip()]

        suggestions_match = re.search(r"Suggestions:\s*(.*)", text, re.DOTALL)
        suggestions = []
        if suggestions_match:
            suggestions_text = suggestions_match.group(1)
            suggestions = [line.strip("- ").strip() for line in suggestions_text.strip().splitlines() if line.strip()]

        return match_score, missing_skills, suggestions

    # ----------------------------
    # Online Analysis
    # ----------------------------
    def analyse_online(self, resume_content, job_description):
        """Analyse resume using OpenRouter API."""
        if not self.openai_client:
            return None

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
            response = self.openai_client.chat.completions.create(
                model="openrouter/auto",
                messages=[
                    {"role": "system", "content": "You are an AI recruitment assistant. Always return results in the required format only."},
                    {"role": "user", "content": prompt}
                ],
                temperature=0.7,
                top_p=0.9,
                max_tokens=1024,
                request_timeout=10
            )
            text = getattr(response.choices[0].message, "content", "") or ""
            match_score, missing_skills, suggestions = self._parse_openrouter_response(text)

            return {
                "match_score": match_score,
                "missing_skills": missing_skills,
                "suggestions": suggestions,
                "raw_text": text
            }

        except Exception as e:
            logger.error(f"Online analysis failed: {e}")
            return {
                "match_score": 0,
                "missing_skills": [],
                "suggestions": [],
                "raw_text": f"Error during online analysis: {str(e)}"
            }

    # ----------------------------
    # Embedding-based Offline Analysis
    # ----------------------------
    def analyse_offline_embedding(self, resume_content, job_description):
        """Offline embedding-based NLP analysis."""
        # --- Keyword extraction ---
        resume_doc = self.nlp(resume_content.lower())
        job_doc = self.nlp(job_description.lower())

        resume_skills = set(token.lemma_ for token in resume_doc if token.pos_ in ["NOUN", "PROPN", "VERB", "ADJ"])
        job_skills = set(token.lemma_ for token in job_doc if token.pos_ in ["NOUN", "PROPN", "VERB", "ADJ"])
        missing_skills = list(job_skills - resume_skills)

        # --- Embedding similarity ---
        if self.embed_model:
            embeddings = self.embed_model.encode([resume_content, job_description], convert_to_tensor=True)
            similarity_score = float(util.cos_sim(embeddings[0], embeddings[1]).item())
            match_score = int(similarity_score * 100)
        else:
            # fallback to keyword match if embeddings fail
            total_skills = len(job_skills)
            matched_skills = total_skills - len(missing_skills)
            match_score = int((matched_skills / total_skills) * 100) if total_skills else 0

        suggestions = ["Consider highlighting missing skills in your resume."] if missing_skills else []

        return {
            "match_score": match_score,
            "missing_skills": missing_skills,
            "suggestions": suggestions,
            "raw_text": "Offline embedding-based analysis performed" if self.embed_model else "Offline keyword-based analysis performed"
        }

    # ----------------------------
    # Keyword-only Offline Analysis
    # ----------------------------
    def analyse_offline_keywords(self, resume_content, job_description):
        """Simple keyword-only offline NLP analysis as final fallback."""
        resume_doc = self.nlp(resume_content.lower())
        job_doc = self.nlp(job_description.lower())

        resume_skills = set(token.lemma_ for token in resume_doc if token.pos_ in ["NOUN", "PROPN"])
        job_skills = set(token.lemma_ for token in job_doc if token.pos_ in ["NOUN", "PROPN"])
        missing_skills = list(job_skills - resume_skills)

        total_skills = len(job_skills)
        matched_skills = total_skills - len(missing_skills)
        match_score = int((matched_skills / total_skills) * 100) if total_skills else 0

        suggestions = ["Consider highlighting missing skills in your resume."] if missing_skills else []

        return {
            "match_score": match_score,
            "missing_skills": missing_skills,
            "suggestions": suggestions,
            "raw_text": "Offline keyword-only analysis performed"
        }

    # ----------------------------
    # Hybrid Wrapper with 3-level Fallback
    # ----------------------------
    def analyse(self, resume_content, job_id):
        """Hybrid analysis: online -> embedding offline -> keyword offline."""
        job = Requisition.query.get(job_id)
        if not job:
            return {
                "match_score": 0,
                "missing_skills": [],
                "suggestions": [],
                "raw_text": "Job not found"
            }

        job_description = job.description or ""

        # --- 1. Online OpenRouter ---
        if self.openai_client:
            result = self.analyse_online(resume_content, job_description)
            if result and "Error during online analysis" not in result["raw_text"]:
                return result

        # --- 2. Offline Embedding ---
        result = self.analyse_offline_embedding(resume_content, job_description)
        if self.embed_model or result["match_score"] > 0:
            return result

        # --- 3. Offline Keyword-only ---
        return self.analyse_offline_keywords(resume_content, job_description)

    # ----------------------------
    # Cloudinary Upload
    # ----------------------------
    @staticmethod
    def upload_cv(file):
        """Upload CV to Cloudinary and return secure URL."""
        try:
            result = cloudinary_upload(
                file,
                resource_type="raw",
                folder="candidate_cvs"
            )
            return result.get("secure_url")
        except Exception as e:
            logger.error(f"Cloudinary upload failed: {e}")
            return None
