from flask import request, jsonify
from flask_jwt_extended import jwt_required, get_jwt_identity
from app.extensions import db, cloudinary_client
from app.models import Requisition, Candidate, Application
from app.utils.decorators import role_required
from app.services.matching_service import MatchingService
from app.services.email_service import EmailService
from datetime import datetime

def init_job_routes(app):

    @app.route('/api/jobs', methods=['POST'])
    @jwt_required()
    @role_required('hiring_manager', 'admin')
    def create_job():
        data = request.get_json()
        required_fields = ['title', 'required_skills', 'min_experience']
        if not all(field in data for field in required_fields):
            return jsonify({'error': 'Missing required fields'}), 400

        current_user_id = get_jwt_identity()
        job = Requisition(
            title=data['title'],
            description=data.get('description', ''),
            required_skills=data['required_skills'],
            min_experience=data['min_experience'],
            knockout_rules=data.get('knockout_rules', []),
            weightings=data.get('weightings', {'cv': 60, 'assessment': 40}),
            created_by=current_user_id
        )
        db.session.add(job)
        db.session.commit()
        return jsonify({'message': 'Job created successfully', 'job_id': job.id}), 201

    @app.route('/api/jobs/<int:job_id>/candidates', methods=['GET'])
    @jwt_required()
    @role_required('hiring_manager', 'admin')
    def get_candidates_for_job(job_id):
        job = Requisition.query.get_or_404(job_id)
        applications = Application.query.filter_by(requisition_id=job_id).all()
        candidates_data = []
        for app_entry in applications:
            candidate = Candidate.query.get(app_entry.candidate_id)
            candidates_data.append({
                'candidate_id': candidate.id,
                'profile': candidate.profile,
                'cv_url': candidate.cv_url,
                'application_status': app_entry.status
            })
        return jsonify({'candidates': candidates_data}), 200

    @app.route('/api/jobs/<int:job_id>/shortlist', methods=['POST'])
    @jwt_required()
    @role_required('hiring_manager', 'admin')
    def shortlist_candidates(job_id):
        job = Requisition.query.get_or_404(job_id)
        applications = Application.query.filter_by(requisition_id=job_id, status='applied').all()
        matching_service = MatchingService()
        shortlisted = []

        for app_entry in applications:
            candidate = Candidate.query.get(app_entry.candidate_id)
            if not candidate:
                continue
            cv_score = matching_service.calculate_cv_match_score(
                candidate.profile.get('skills', []),
                candidate.profile.get('experience', 0),
                job.__dict__
            )
            overall_score = matching_service.calculate_overall_score(cv_score, 0, job.weightings)
            recommendation = matching_service.get_recommendation(overall_score)
            app_entry.overall_score = overall_score
            app_entry.recommendation = recommendation
            if recommendation == 'proceed':
                app_entry.status = 'shortlisted'
                shortlisted.append(candidate)
            db.session.commit()

        # Send interview emails
        for candidate in shortlisted:
            EmailService.send_interview_invitation(
                candidate.profile.get('email'),
                candidate.profile.get('name'),
                interview_date=datetime.utcnow().strftime("%Y-%m-%d %H:%M"),
                interview_type='online',
                meeting_link='https://meeting-link.com'
            )

        return jsonify({'message': f'{len(shortlisted)} candidates shortlisted and notified'}), 200
