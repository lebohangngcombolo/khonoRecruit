from flask import jsonify, request
from flask_jwt_extended import jwt_required
from app.models import User, Requisition, Application
from app.extensions import db
from app.utils.decorators import role_required

def init_admin_routes(app):

    # ------------------ SERIALIZERS ------------------
    def serialize_user(user):
        return {
            'id': user.id,
            'email': user.email,
            'role': user.role,
            'is_verified': user.is_verified,
            'profile': dict(user.profile) if user.profile else {},
            'created_at': user.created_at.isoformat()
        }

    def serialize_job(job):
        return {
            'id': job.id,
            'title': job.title,
            'description': job.description,
            'required_skills': list(job.required_skills) if job.required_skills else [],
            'min_experience': job.min_experience,
            'weightings': dict(job.weightings) if job.weightings else {},
            'created_by': job.created_by,
            'created_at': job.created_at.isoformat()
        }

    def serialize_application(app_obj):
        return {
            'id': app_obj.id,
            'candidate_id': app_obj.candidate_id,
            'requisition_id': app_obj.requisition_id,
            'status': app_obj.status,
            'assessment_score': app_obj.assessment_score,
            'overall_score': app_obj.overall_score,
            'recommendation': app_obj.recommendation,
            'assessed_date': app_obj.assessed_date.isoformat() if app_obj.assessed_date else None,
            'created_at': app_obj.created_at.isoformat()
        }

    # ------------------ ROUTES ------------------
    @app.route('/api/admin/users', methods=['GET'])
    @jwt_required()
    @role_required('admin')
    def get_all_users():
        users = User.query.all()
        return jsonify({'users': [serialize_user(u) for u in users]}), 200

    @app.route('/api/admin/jobs', methods=['GET'])
    @jwt_required()
    @role_required('admin')
    def get_all_jobs():
        jobs = Requisition.query.all()
        return jsonify({'jobs': [serialize_job(j) for j in jobs]}), 200

    @app.route('/api/admin/applications', methods=['GET'])
    @jwt_required()
    @role_required('admin')
    def get_all_applications():
        apps = Application.query.all()
        return jsonify({'applications': [serialize_application(a) for a in apps]}), 200

    @app.route('/api/admin/role/<int:user_id>', methods=['PUT'])
    @jwt_required()
    @role_required('admin')
    def update_user_role(user_id):
        user = User.query.get_or_404(user_id)
        data = request.get_json()
        new_role = data.get('role')
        if not new_role:
            return jsonify({'error': 'Missing role'}), 400
        if new_role not in ['admin', 'hiring_manager', 'candidate']:
            return jsonify({'error': 'Invalid role'}), 400
        user.role = new_role
        db.session.commit()
        return jsonify({'message': 'User role updated', 'user': serialize_user(user)}), 200
