from sklearn.feature_extraction.text import TfidfVectorizer
from sklearn.metrics.pairwise import cosine_similarity
import numpy as np
from app.extensions import redis_client
import json

class MatchingService:
    def __init__(self):
        self.vectorizer = TfidfVectorizer(stop_words='english')
    
    def calculate_cv_match_score(self, candidate_skills, candidate_experience, requisition):
        try:
            # Calculate skill match
            required_skills = requisition.get('required_skills', [])
            candidate_skill_set = set([skill.lower() for skill in candidate_skills])
            required_skill_set = set([skill['name'].lower() for skill in required_skills])
            
            # Skill matching
            matched_skills = candidate_skill_set.intersection(required_skill_set)
            skill_match_ratio = len(matched_skills) / len(required_skill_set) if required_skill_set else 0
            
            # Experience matching
            min_experience = requisition.get('min_experience', 0)
            experience_match = 1 if candidate_experience >= min_experience else candidate_experience / min_experience
            
            # Calculate weighted score
            skill_weight = 0.7
            experience_weight = 0.3
            
            score = (skill_match_ratio * skill_weight) + (experience_match * experience_weight)
            
            # Apply knockout rules
            knockout_rules = requisition.get('knockout_rules', [])
            for rule in knockout_rules:
                if rule['type'] == 'skill' and rule['value'] not in candidate_skill_set:
                    score = 0
                    break
                if rule['type'] == 'experience' and candidate_experience < rule['value']:
                    score = 0
                    break
            
            return min(score * 100, 100)  # Convert to percentage
            
        except Exception as e:
            raise Exception(f"Error calculating CV match score: {str(e)}")
    
    def calculate_assessment_score(self, answers, correct_answers):
        try:
            correct_count = 0
            total_questions = len(correct_answers)
            
            for i, answer in enumerate(answers):
                if i < len(correct_answers) and answer == correct_answers[i]:
                    correct_count += 1
            
            return (correct_count / total_questions) * 100 if total_questions > 0 else 0
            
        except Exception as e:
            raise Exception(f"Error calculating assessment score: {str(e)}")
    
    def calculate_overall_score(self, cv_score, assessment_score, weightings):
        try:
            cv_weight = weightings.get('cv', 60) / 100
            assessment_weight = weightings.get('assessment', 40) / 100
            
            return (cv_score * cv_weight) + (assessment_score * assessment_weight)
            
        except Exception as e:
            raise Exception(f"Error calculating overall score: {str(e)}")
    
    def get_recommendation(self, overall_score, knockout_passed=True):
        if not knockout_passed:
            return 'reject'
        
        if overall_score >= 80:
            return 'proceed'
        elif overall_score >= 60:
            return 'hold'
        else:
            return 'reject'
    
    def find_similar_candidates(self, candidate_id, requisition_id, limit=5):
        try:
            # This would use more advanced ML models in production
            # For now, we'll use a simple TF-IDF based approach
            
            # Get candidate CV text from cache or database
            candidate_text = redis_client.get(f'candidate_text:{candidate_id}')
            if not candidate_text:
                # Fallback to database query
                from app.models.postgres_models import Candidate
                candidate = Candidate.query.get(candidate_id)
                candidate_text = candidate.cv_text if candidate else ""
                redis_client.setex(f'candidate_text:{candidate_id}', 3600, candidate_text)
            
            # Get other candidates for comparison
            from app.models.postgres_models import Application, Candidate
            applications = Application.query.filter(
                Application.requisition_id == requisition_id,
                Application.candidate_id != candidate_id
            ).all()
            
            candidate_texts = [candidate_text]
            candidate_ids = [candidate_id]
            
            for app in applications:
                other_candidate_text = redis_client.get(f'candidate_text:{app.candidate_id}')
                if not other_candidate_text:
                    candidate = Candidate.query.get(app.candidate_id)
                    other_candidate_text = candidate.cv_text if candidate else ""
                    redis_client.setex(f'candidate_text:{app.candidate_id}', 3600, other_candidate_text)
                
                candidate_texts.append(other_candidate_text)
                candidate_ids.append(app.candidate_id)
            
            # Calculate similarity
            tfidf_matrix = self.vectorizer.fit_transform(candidate_texts)
            similarity_matrix = cosine_similarity(tfidf_matrix[0:1], tfidf_matrix[1:])
            
            # Get top similar candidates
            similar_indices = similarity_matrix.argsort()[0][-limit:][::-1]
            similar_candidates = []
            
            for idx in similar_indices:
                if idx < len(candidate_ids) - 1:  # -1 because we skipped the first candidate
                    candidate_id = candidate_ids[idx + 1]
                    similarity_score = similarity_matrix[0][idx]
                    similar_candidates.append({
                        'candidate_id': candidate_id,
                        'similarity_score': float(similarity_score)
                    })
            
            return similar_candidates
            
        except Exception as e:
            raise Exception(f"Error finding similar candidates: {str(e)}")