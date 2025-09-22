from sklearn.feature_extraction.text import TfidfVectorizer
from sklearn.metrics.pairwise import cosine_similarity
import numpy as np
from app.extensions import redis_client
from app.models import Candidate, Application


class MatchingService:
    def __init__(self):
        self.vectorizer = TfidfVectorizer(stop_words='english')

    # -------------------------
    # CV Match Score
    # -------------------------
    def calculate_cv_match_score(self, candidate_skills, candidate_experience, requisition):
        try:
            # Use skill confidence if available
            if isinstance(candidate_skills, dict):
                candidate_skill_set = set([skill.lower() for skill, conf in candidate_skills.items() if conf > 0])
            else:
                candidate_skill_set = set([skill.lower() for skill in candidate_skills])

            required_skills = set([skill['name'].lower() for skill in requisition.get('required_skills', [])])
            
            # Skill matching ratio
            matched_skills = candidate_skill_set.intersection(required_skills)
            skill_match_ratio = len(matched_skills) / len(required_skills) if required_skills else 0

            # Experience matching
            min_exp = requisition.get('min_experience', 0)
            exp_match = 1 if candidate_experience >= min_exp else candidate_experience / (min_exp or 1)

            # Weighted score
            skill_weight = 0.7
            exp_weight = 0.3
            score = (skill_match_ratio * skill_weight) + (exp_match * exp_weight)

            # Knockout rules
            for rule in requisition.get('knockout_rules', []):
                if rule['type'] == 'skill' and rule['value'].lower() not in candidate_skill_set:
                    return 0
                if rule['type'] == 'experience' and candidate_experience < rule['value']:
                    return 0

            return min(score * 100, 100)
        except Exception as e:
            log_error(f"Error calculating CV match score: {str(e)}")
            return 0

    # -------------------------
    # Assessment Score
    # -------------------------
    def calculate_assessment_score(self, answers, correct_answers):
        try:
            correct_count = sum(1 for i, ans in enumerate(answers) if i < len(correct_answers) and ans == correct_answers[i])
            total = len(correct_answers)
            return (correct_count / total) * 100 if total > 0 else 0
        except Exception as e:
            log_error(f"Error calculating assessment score: {str(e)}")
            return 0

    # -------------------------
    # Overall Score
    # -------------------------
    def calculate_overall_score(self, cv_score, assessment_score, weightings):
        try:
            cv_weight = weightings.get('cv', 60) / 100
            assess_weight = weightings.get('assessment', 40) / 100
            return (cv_score * cv_weight) + (assessment_score * assess_weight)
        except Exception as e:
            log_error(f"Error calculating overall score: {str(e)}")
            return 0

    # -------------------------
    # Recommendation
    # -------------------------
    def get_recommendation(self, overall_score, knockout_passed=True):
        if not knockout_passed:
            return 'reject'
        if overall_score >= 80:
            return 'proceed'
        elif overall_score >= 60:
            return 'hold'
        else:
            return 'reject'

    # -------------------------
    # Find Similar Candidates
    # -------------------------
    def find_similar_candidates(self, candidate_id, requisition_id, limit=5):
        try:
            candidate_text = redis_client.get(f'candidate_text:{candidate_id}')
            if not candidate_text:
                candidate = Candidate.query.get(candidate_id)
                candidate_text = candidate.cv_text if candidate else ""
                redis_client.setex(f'candidate_text:{candidate_id}', 3600, candidate_text)

            applications = Application.query.filter(
                Application.requisition_id == requisition_id,
                Application.candidate_id != candidate_id
            ).all()

            candidate_texts = [candidate_text]
            candidate_ids = [candidate_id]

            for app in applications:
                text = redis_client.get(f'candidate_text:{app.candidate_id}')
                if not text:
                    candidate = Candidate.query.get(app.candidate_id)
                    text = candidate.cv_text if candidate else ""
                    redis_client.setex(f'candidate_text:{app.candidate_id}', 3600, text)
                candidate_texts.append(text)
                candidate_ids.append(app.candidate_id)

            tfidf_matrix = self.vectorizer.fit_transform(candidate_texts)
            similarity_matrix = cosine_similarity(tfidf_matrix[0:1], tfidf_matrix[1:])
            similar_indices = similarity_matrix.argsort()[0][-limit:][::-1]

            return [
                {'candidate_id': candidate_ids[idx + 1], 'similarity_score': float(similarity_matrix[0][idx])}
                for idx in similar_indices if idx < len(candidate_ids) - 1
            ]
        except Exception as e:
            log_error(f"Error finding similar candidates: {str(e)}")
            return []
