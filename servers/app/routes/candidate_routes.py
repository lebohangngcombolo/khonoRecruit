from flask import request, jsonify, current_app
from flask_jwt_extended import get_jwt_identity, verify_jwt_in_request
from werkzeug.utils import secure_filename
import os
from datetime import datetime
from functools import wraps
from flask_cors import cross_origin

from app.extensions import db, cloudinary_client, redis_client
from app.models import Candidate, Application, Requisition, AssessmentResult
from app.utils.decorators import role_required
from app.services.cv_parser import CVParser
from app.services.matching_service import MatchingService

matching_service = MatchingService()


# -------------------------
# JWT decorator that skips OPTIONS
# -------------------------
def jwt_required_for_non_options(fn):
    @wraps(fn)
    def wrapper(*args, **kwargs):
        if request.method != 'OPTIONS':
            verify_jwt_in_request()
        return fn(*args, **kwargs)
    return wrapper


def init_candidate_routes(app):

    # -------------------------
    # Upload CV
    # -------------------------
    @app.route('/api/candidate/upload-cv', methods=['POST', 'OPTIONS'])
    @cross_origin()
    @jwt_required_for_non_options
    @role_required('candidate')
    def upload_cv():
        if request.method == 'OPTIONS':
            return '', 200

        try:
            candidate_id = get_jwt_identity()
            file = request.files.get('cv')
            if not file:
                return jsonify({'error': 'No file uploaded'}), 400

            filename = secure_filename(file.filename)
            if not filename:
                return jsonify({'error': 'Invalid file name'}), 400

            file_type = filename.split('.')[-1].lower()
            file_path = os.path.join('/tmp', filename)
            file.save(file_path)

            # Parse CV
            parser = CVParser()
            cv_text = parser.extract_text_from_file(file_path, file_type)
            parsed_data = parser.parse_cv(cv_text)

            # Upload to Cloudinary
            cloud_url = cloudinary_client.upload(file_path)

            # Update candidate record
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
                'education': parsed_data['education'],
                'certificates': parsed_data.get('certificates', []),
            }
            db.session.commit()

            # Cache CV text
            redis_client.setex(f'candidate_text:{candidate_id}', 3600, cv_text)

            # Cleanup temp file
            if os.path.exists(file_path):
                os.remove(file_path)

            return jsonify({
                'message': 'CV uploaded and parsed successfully',
                'cv_url': cloud_url['secure_url'],
                'parsed_profile': candidate.profile
            }), 200

        except Exception as e:
            current_app.logger.error(f"CV upload failed: {str(e)}", exc_info=True)
            return jsonify({'error': 'Internal server error'}), 500

    # -------------------------
    # Update Candidate Profile
    # -------------------------
    @app.route('/api/candidate/profile', methods=['GET', 'PUT', 'OPTIONS'])
    @cross_origin()
    @jwt_required_for_non_options
    @role_required('candidate')
    def candidate_profile():
        if request.method == 'OPTIONS':
            return '', 200

        candidate_id = get_jwt_identity()
        candidate = Candidate.query.filter_by(user_id=candidate_id).first()
        if not candidate:
            return jsonify({'error': 'Candidate not found'}), 404

        if request.method == 'GET':
            profile_data = candidate.profile or {}
            profile_data['cv_url'] = candidate.cv_url if candidate.cv_url else ''
            return jsonify({'profile': profile_data}), 200

        if request.method == 'PUT':
            try:
                data = request.get_json()
                if not candidate.profile:
                    candidate.profile = {}
                candidate.profile.update(data)
                db.session.commit()
                return jsonify({'message': 'Profile updated successfully', 'profile': candidate.profile}), 200
            except Exception as e:
                current_app.logger.error(f"Profile update failed: {str(e)}", exc_info=True)
                return jsonify({'error': 'Internal server error'}), 500

    # -------------------------
    # Get All Available Jobs
    # -------------------------
    @app.route('/api/jobs', methods=['GET', 'OPTIONS'])
    @cross_origin()
    @jwt_required_for_non_options
    @role_required('candidate')
    def get_available_jobs():
        if request.method == 'OPTIONS':
            return '', 200

        try:
            jobs = Requisition.query.all()
            jobs_data = [job.to_dict() for job in jobs]
            return jsonify({'jobs': jobs_data}), 200
        except Exception as e:
            current_app.logger.error(f"Failed to fetch jobs: {str(e)}", exc_info=True)
            return jsonify({'error': 'Internal server error'}), 500

    # -------------------------
    # Get Candidate Applied Jobs
    # -------------------------
    @app.route('/api/candidate/applied-jobs', methods=['GET', 'OPTIONS'])
    @cross_origin()
    @jwt_required_for_non_options
    @role_required('candidate')
    def get_applied_jobs():
        if request.method == 'OPTIONS':
            return '', 200

        try:
            candidate_id = get_jwt_identity()
            candidate = Candidate.query.filter_by(user_id=candidate_id).first()
            if not candidate:
                return jsonify({'error': 'Candidate not found'}), 404

            applications = Application.query.filter_by(candidate_id=candidate.id).all()
            jobs_data = []
            for app_entry in applications:
                requisition = Requisition.query.get(app_entry.requisition_id)
                jobs_data.append({
                    'application_id': app_entry.id,
                    'job_id': requisition.id,
                    'title': requisition.title,
                    'status': app_entry.status,
                    'applied_at': app_entry.created_at.isoformat()
                })

            return jsonify({'applied_jobs': jobs_data}), 200
        except Exception as e:
            current_app.logger.error(f"Failed to fetch applied jobs: {str(e)}", exc_info=True)
            return jsonify({'error': 'Internal server error'}), 500

    # -------------------------
    # Apply for a Job
    # -------------------------
    @app.route('/api/jobs/<int:job_id>/apply', methods=['POST', 'OPTIONS'])
    @cross_origin()
    @jwt_required_for_non_options
    @role_required('candidate')
    def apply_for_job(job_id):
        if request.method == 'OPTIONS':
            return '', 200

        try:
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

        except Exception as e:
            current_app.logger.error(f"Job application failed: {str(e)}", exc_info=True)
            return jsonify({'error': 'Internal server error'}), 500

    # -------------------------
    # Submit Assessment
    # -------------------------
    @app.route('/api/applications/<int:application_id>/assessment', methods=['GET', 'POST', 'OPTIONS'])
    @cross_origin()
    @jwt_required_for_non_options
    @role_required('candidate')
    def handle_assessment(application_id):
        if request.method == 'OPTIONS':
            return '', 200

        if request.method == 'GET':
            try:
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
            except Exception as e:
                current_app.logger.error(f"Failed to fetch assessment: {str(e)}", exc_info=True)
                return jsonify({'error': 'Internal server error'}), 500

        if request.method == 'POST':
            try:
                application = Application.query.get_or_404(application_id)
                if application.status != 'shortlisted':
                    return jsonify({'error': 'Application not ready for assessment'}), 400

                data = request.get_json()
                answers = data.get('answers', [])
                time_taken = data.get('time_taken', 0)

                requisition = Requisition.query.get(application.requisition_id)
                assessment_pack = getattr(requisition, "assessment_pack", {"questions": []})
                correct_answers = [q.get('correct_answer') for q in assessment_pack.get('questions', [])]

                score = matching_service.calculate_assessment_score(answers, correct_answers)
                overall_score = matching_service.calculate_overall_score(score, 0, requisition.weightings)
                recommendation = matching_service.get_recommendation(overall_score)

                application.assessment_score = score
                application.overall_score = overall_score
                application.recommendation = recommendation
                application.status = 'assessed'
                application.assessed_date = datetime.utcnow()

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

            except Exception as e:
                current_app.logger.error(f"Assessment submission failed: {str(e)}", exc_info=True)
                return jsonify({'error': 'Internal server error'}), 500
