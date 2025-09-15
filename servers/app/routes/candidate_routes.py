from flask import request, jsonify
from flask_jwt_extended import jwt_required, get_jwt_identity
from app.extensions import db, cloudinary_client
from app.models import Candidate, Application, Requisition
from app.utils.decorators import role_required
from app.services.cv_parser import CVParser

def init_candidate_routes(app):

    @app.route('/api/candidates/upload-cv', methods=['POST'])
    @jwt_required()
    @role_required('candidate')
    def upload_cv():
        candidate_id = get_jwt_identity()
        file = request.files.get('cv')
        if not file:
            return jsonify({'error': 'No file uploaded'}), 400

        file_type = file.filename.split('.')[-1].lower()
        file_path = f'/tmp/{file.filename}'
        file.save(file_path)

        parser = CVParser()
        cv_text = parser.extract_text_from_file(file_path, file_type)
        parsed_data = parser.parse_cv(cv_text)

        cloud_url = cloudinary_client.upload(file_path)

        candidate = Candidate.query.filter_by(user_id=candidate_id).first()
        if not candidate:
            candidate = Candidate(user_id=candidate_id)
            db.session.add(candidate)

        candidate.cv_url = cloud_url['secure_url']
        candidate.cv_text = parsed_data['raw_text']
        candidate.profile = {
            'name': parsed_data['name'],
            'email': parsed_data['email'],
            'phone': parsed_data['phone'],
            'skills': parsed_data['skills'],
            'experience': parsed_data['experience']['total_years'],
            'education': parsed_data['education']
        }
        db.session.commit()
        return jsonify({'message': 'CV uploaded and parsed successfully', 'cv_url': cloud_url['secure_url']}), 200

    @app.route('/api/candidates/profile', methods=['PUT'])
    @jwt_required()
    @role_required('candidate')
    def update_profile():
        data = request.get_json()
        candidate_id = get_jwt_identity()
        candidate = Candidate.query.filter_by(user_id=candidate_id).first()
        if not candidate:
            return jsonify({'error': 'Candidate not found'}), 404

        candidate.profile.update(data)
        db.session.commit()
        return jsonify({'message': 'Profile updated successfully'}), 200

    @app.route('/api/jobs', methods=['GET'])
    @jwt_required()
    @role_required('candidate')
    def get_available_jobs():
        jobs = Requisition.query.all()
        return jsonify({'jobs': [job.__dict__ for job in jobs]}), 200

    @app.route('/api/jobs/<int:job_id>/apply', methods=['POST'])
    @jwt_required()
    @role_required('candidate')
    def apply_for_job(job_id):
        candidate_id = get_jwt_identity()
        candidate = Candidate.query.filter_by(user_id=candidate_id).first()
        if not candidate:
            return jsonify({'error': 'Candidate profile not found'}), 404

        existing = Application.query.filter_by(candidate_id=candidate.id, requisition_id=job_id).first()
        if existing:
            return jsonify({'error': 'Already applied'}), 400

        app_entry = Application(candidate_id=candidate.id, requisition_id=job_id, status='applied')
        db.session.add(app_entry)
        db.session.commit()
        return jsonify({'message': 'Applied successfully'}), 200
