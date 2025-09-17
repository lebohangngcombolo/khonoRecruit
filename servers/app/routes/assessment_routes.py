from flask import request, jsonify
from flask_jwt_extended import jwt_required
from app.models import Application, AssessmentResult, Requisition
from app.extensions import db
from app.utils.decorators import role_required
from datetime import datetime
from app.services.matching_service import MatchingService


from datetime import datetime
from flask import request, jsonify, current_app
from flask_jwt_extended import jwt_required, get_jwt_identity
from app.models import Requisition, Application, AssessmentResult, Candidate, db
from app.utils.decorators import role_required
from app.services.matching_service import MatchingService

def init_assessment_routes(app):

    # ------------------ Hiring Manager / Admin CRUD ------------------ #

    @app.route('/api/jobs/<int:job_id>/assessment', methods=['POST'])
    @jwt_required()
    @role_required('hiring_manager', 'admin')
    def create_assessment(job_id):
        data = request.get_json()
        questions = data.get('questions', [])
        weightings = data.get('weightings', {})

        job = Requisition.query.get_or_404(job_id)
        job.assessment_pack = {"questions": questions}
        job.weightings = weightings
        db.session.commit()

        return jsonify({
            "message": "Assessment created successfully",
            "assessment": job.assessment_pack
        }), 201

    @app.route('/api/jobs/<int:job_id>/assessment', methods=['GET'])
    @jwt_required()
    @role_required('hiring_manager', 'admin')
    def get_assessment(job_id):
        job = Requisition.query.get_or_404(job_id)
        return jsonify({
            "assessment": job.assessment_pack,
            "weightings": job.weightings
        }), 200

    @app.route('/api/jobs/<int:job_id>/assessment', methods=['PUT'])
    @jwt_required()
    @role_required('hiring_manager', 'admin')
    def update_assessment(job_id):
        data = request.get_json()
        questions = data.get('questions')
        weightings = data.get('weightings')

        job = Requisition.query.get_or_404(job_id)
        if questions is not None:
            job.assessment_pack = {"questions": questions}
        if weightings is not None:
            job.weightings = weightings

        db.session.commit()
        return jsonify({
            "message": "Assessment updated successfully",
            "assessment": job.assessment_pack
        }), 200

    @app.route('/api/jobs/<int:job_id>/assessment', methods=['DELETE'])
    @jwt_required()
    @role_required('hiring_manager', 'admin')
    def delete_assessment(job_id):
        job = Requisition.query.get_or_404(job_id)
        job.assessment_pack = {"questions": []}
        job.weightings = {}
        db.session.commit()
        return jsonify({"message": "Assessment deleted successfully"}), 200

    # ------------------ Candidate Access ------------------ #

    @app.route('/api/jobs/<int:job_id>/assessment/candidate', methods=['GET'])
    @jwt_required()
    @role_required('candidate')
    def get_candidate_assessment(job_id):
        job = Requisition.query.get_or_404(job_id)
        return jsonify({"assessment": job.assessment_pack}), 200

    @app.route('/api/applications/<int:application_id>/assessment', methods=['POST'])
    @jwt_required()
    @role_required('candidate')
    def submit_assessment(application_id):
        application = Application.query.get_or_404(application_id)

        # Only allow assessment if application is shortlisted
        if application.status != 'shortlisted':
            return jsonify({'error': 'Application not ready for assessment'}), 400

        data = request.get_json()
        answers = data.get('answers', [])
        time_taken = data.get('time_taken', 0)

        # Fetch the requisition to calculate scores
        requisition = Requisition.query.get(application.requisition_id)
        if not requisition:
            return jsonify({'error': 'Requisition not found'}), 404

        assessment_pack = getattr(requisition, 'assessment_pack', {'questions': []})
        correct_answers = [q.get('correct_answer') for q in assessment_pack.get('questions', [])]

        # Calculate scores
        matching_service = MatchingService()
        score = matching_service.calculate_assessment_score(answers, correct_answers)
        overall_score = matching_service.calculate_overall_score(score, 0, requisition.weightings)
        recommendation = matching_service.get_recommendation(overall_score)

        # Update application
        application.assessment_score = score
        application.overall_score = overall_score
        application.recommendation = recommendation
        application.status = 'assessed'
        application.assessed_date = datetime.utcnow()

        # Save AssessmentResult
        result = AssessmentResult(
            application_id=application.id,
            scores={'answers': answers, 'score': score, 'time_taken': time_taken},
            total_score=score,
            recommendation=recommendation,
            assessed_at=datetime.utcnow()
        )

        db.session.add(result)
        db.session.commit()

        return jsonify({
            'message': 'Assessment submitted successfully',
            'assessment_result': {
                'id': result.id,
                'application_id': result.application_id,
                'scores': result.scores,
                'total_score': result.total_score,
                'recommendation': result.recommendation,
                'assessed_at': result.assessed_at.isoformat()
            }
        }), 200

    @app.route('/api/applications/<int:application_id>/assessment', methods=['GET'])
    @jwt_required()
    @role_required('hiring_manager', 'admin')
    def get_assessment_result(application_id):
        result = AssessmentResult.query.filter_by(application_id=application_id).first()
        if not result:
            return jsonify({'error': 'Assessment not found'}), 404

        return jsonify({
            'id': result.id,
            'application_id': result.application_id,
            'scores': result.scores if result.scores else {},
            'total_score': result.total_score,
            'recommendation': result.recommendation,
            'assessed_at': result.assessed_at.isoformat() if result.assessed_at else None
        }), 200
