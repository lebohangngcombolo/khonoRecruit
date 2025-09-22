from datetime import datetime
from flask import request, jsonify
from flask_jwt_extended import jwt_required
from app.models import Requisition, Application, AssessmentResult, db
from app.utils.decorators import role_required
from app.services.matching_service import MatchingService

def init_assessment_routes(app):

    # ------------------ Admin / Hiring Manager ------------------ #
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

        return jsonify({"message": "Assessment created successfully", "assessment": job.assessment_pack}), 201

    @app.route('/api/jobs/<int:job_id>/assessment', methods=['GET'])
    @jwt_required()
    @role_required('hiring_manager', 'admin')
    def get_assessment(job_id):
        job = Requisition.query.get_or_404(job_id)
        return jsonify({
            "assessment": getattr(job, "assessment_pack", {"questions": []}),
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
        return jsonify({"message": "Assessment updated successfully", "assessment": job.assessment_pack}), 200

    @app.route('/api/jobs/<int:job_id>/assessment', methods=['DELETE'])
    @jwt_required()
    @role_required('hiring_manager', 'admin')
    def delete_assessment(job_id):
        job = Requisition.query.get_or_404(job_id)
        job.assessment_pack = {"questions": []}
        job.weightings = {}
        db.session.commit()
        return jsonify({"message": "Assessment deleted successfully"}), 200

    @app.route('/api/applications/<int:application_id>/assessment', methods=['GET'])
    @jwt_required()
    @role_required('hiring_manager', 'admin')
    def get_assessment_result_for_admin(application_id):
        result = AssessmentResult.query.filter_by(application_id=application_id).first()
        if not result:
            return jsonify({'error': 'Assessment not found'}), 404

        return jsonify({
            'id': result.id,
            'application_id': application_id,
            'scores': result.scores,
            'total_score': result.total_score,
            'recommendation': result.recommendation,
            'assessed_at': result.assessed_at.isoformat()
        }), 200
