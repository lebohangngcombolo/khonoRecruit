from app.extensions import db
from app.models import Requisition, Application, AssessmentResult
from datetime import datetime


class AssessmentService:

    @staticmethod
    def create_assessment(requisition_id, questions):
        """
        Add or update MCQ assessment for a requisition/job.
        `questions` is a list of dicts:
        {"question_text": str, "options": list[str], "correct_option": int}
        """
        requisition = Requisition.query.get(requisition_id)
        if not requisition:
            raise ValueError("Requisition not found")
        
        requisition.assessment_pack = {"questions": questions}
        db.session.commit()
        return requisition.assessment_pack

    @staticmethod
    def submit_candidate_assessment(application_id, candidate_answers):
        """
        candidate_answers: [{"question_index": int, "selected_option": int}]
        Calculates raw score and percentage, then stores in AssessmentResult.
        """
        application = Application.query.get(application_id)
        if not application:
            raise ValueError("Application not found")

        questions = application.requisition.assessment_pack.get("questions", [])
        if not questions:
            raise ValueError("No assessment found for this requisition")

        # prevent duplicate submissions
        existing = AssessmentResult.query.filter_by(application_id=application.id).first()
        if existing:
            raise ValueError("Candidate has already submitted this assessment")

        score = 0
        detailed_scores = []

        for ans in candidate_answers:
            q_index = ans.get("question_index")
            selected = ans.get("selected_option")

            if q_index is None or selected is None:
                raise ValueError("Each answer must include question_index and selected_option")

            if q_index < 0 or q_index >= len(questions):
                raise ValueError(f"Invalid question index: {q_index}")

            correct = questions[q_index]["correct_option"]
            is_correct = selected == correct
            if is_correct:
                score += 1

            detailed_scores.append({
                "question_index": q_index,
                "selected_option": selected,
                "correct_option": correct,
                "is_correct": is_correct
            })

        total_questions = len(questions)
        percentage_score = (score / total_questions) * 100 if total_questions > 0 else 0

        # store assessment result
        result = AssessmentResult(
            application_id=application.id,
            candidate_id=application.candidate_id,
            answers=candidate_answers,
            scores=detailed_scores,
            total_score=score,
            percentage_score=percentage_score,
            assessed_at=datetime.utcnow()
        )
        db.session.add(result)

        # also update the application for shortlisting
        application.assessment_score = percentage_score
        db.session.commit()

        # return clean dict instead of ORM object
        return {
            "application_id": application.id,
            "total_score": score,
            "percentage": percentage_score,
            "submitted_at": result.assessed_at.isoformat()
        }

    @staticmethod
    def get_candidate_assessment(application_id):
        return AssessmentResult.query.filter_by(application_id=application_id).first()

    @staticmethod
    def shortlist_candidates(requisition_id, cv_weight=60, assessment_weight=40):
        """
        Calculate overall score based on CV and assessment.
        Returns candidates sorted by overall_score descending.
        """
        applications = Application.query.filter_by(requisition_id=requisition_id).all()
        shortlisted = []
        for app in applications:
            overall = (
                (app.candidate.cv_score * cv_weight / 100) +
                (app.assessment_score * assessment_weight / 100)
            )
            app.overall_score = overall
            db.session.commit()
            shortlisted.append(app)
        return sorted(shortlisted, key=lambda x: x.overall_score, reverse=True)
