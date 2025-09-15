from flask import request, jsonify, current_app
from flask_jwt_extended import jwt_required, get_jwt_identity
from app.models import Application, AssessmentResult, Requisition
from app.extensions import db
from app.utils.decorators import role_required
from datetime import datetime
from app.services.matching_service import MatchingService

def init_assessment_routes(app):

    @app.route('/api/applications/<int:application_id>/assessment', methods=['POST'])
    @jwt_required()
    @role_required('candidate')
    def submit_assessment(application_id):
        application = Application.query.get_or_404(application_id)
        if application.status not in ['shortlisted']:
            return jsonify({'error': 'Application not ready for assessment'}), 400

        data = request.get_json()
        answers = data.get('answers', [])
        time_taken = data.get('time_taken', 0)

        requisition = Requisition.query.get(application.requisition_id)
        if not requisition:
            return jsonify({'error': 'Requisition not found'}), 404

        assessment_pack = requisition.__dict__.get('assessment_pack', {'questions': []})
        correct_answers = [q.get('correct_answer') for q in assessment_pack.get('questions', [])]

        score = MatchingService().calculate_assessment_score(answers, correct_answers)
        application.assessment_score = score
        application.overall_score = MatchingService().calculate_overall_score(
            application.overall_score, score, requisition.weightings
        )
        application.recommendation = MatchingService().get_recommendation(application.overall_score)
        application.status = 'assessed'
        application.assessed_date = datetime.utcnow()

        result = AssessmentResult(
            application_id=application.id,
            score=score,
            answers=answers,
            time_taken=time_taken
        )
        db.session.add(result)
        db.session.commit()

        return jsonify({
            'message': 'Assessment submitted',
            'score': score,
            'overall_score': application.overall_score,
            'recommendation': application.recommendation
        }), 200

    @app.route('/api/applications/<int:application_id>/assessment', methods=['GET'])
    @jwt_required()
    @role_required('hiring_manager', 'admin')
    def get_assessment_result(application_id):
        result = AssessmentResult.query.filter_by(application_id=application_id).first()
        if not result:
            return jsonify({'error': 'Assessment not found'}), 404
        return jsonify({'assessment_result': result.__dict__}), 200
