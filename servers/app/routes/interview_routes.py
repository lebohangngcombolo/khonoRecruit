from flask import request, jsonify, current_app
from flask_jwt_extended import jwt_required, get_jwt_identity
from app.services import interview_service, notification_service
from app.utils.decorators import role_required

def init_interview_routes(app):

    @app.route('/api/interviews', methods=['POST'])
    @jwt_required()
    @role_required(['admin', 'hiring_manager'])
    def create_interview():
        try:
            data = request.get_json()
            creator_id = get_jwt_identity()
            interview = interview_service.create_interview(creator_id, data)

            # Notify users
            notification_service.create_notification(
                interview.candidate_id,
                f"New interview scheduled on {interview.scheduled_time}"
            )
            notification_service.create_notification(
                interview.hiring_manager_id,
                f"Interview created with candidate {interview.candidate_id}"
            )
            notification_service.notify_admins(
                f"New interview created by user {creator_id} with candidate {interview.candidate_id}"
            )

            return jsonify(interview.to_dict()), 201
        except Exception as e:
            current_app.logger.error(f"Create interview error: {str(e)}", exc_info=True)
            return jsonify({"error": "Internal server error"}), 500

    @app.route('/api/interviews', methods=['GET'])
    @jwt_required()
    def get_interviews():
        user_id = get_jwt_identity()
        role = request.args.get('role')
        interviews = interview_service.get_interviews(user_id, role)
        return jsonify([i.to_dict() for i in interviews]), 200

    @app.route('/api/interviews/<int:interview_id>', methods=['PUT'])
    @jwt_required()
    @role_required(['admin', 'hiring_manager'])
    def update_interview(interview_id):
        try:
            data = request.get_json()
            interview = interview_service.update_interview(interview_id, data)

            notification_service.create_notification(
                interview.candidate_id,
                f"Your interview has been updated to {interview.scheduled_time}"
            )
            notification_service.create_notification(
                interview.hiring_manager_id,
                f"Interview updated with candidate {interview.candidate_id}"
            )
            notification_service.notify_admins(
                f"Interview {interview_id} updated by user {get_jwt_identity()}"
            )

            return jsonify(interview.to_dict()), 200
        except Exception as e:
            current_app.logger.error(f"Update interview error: {str(e)}", exc_info=True)
            return jsonify({"error": "Internal server error"}), 500

    @app.route('/api/interviews/<int:interview_id>', methods=['DELETE'])
    @jwt_required()
    @role_required(['admin', 'hiring_manager'])
    def delete_interview(interview_id):
        try:
            interview = interview_service.delete_interview(interview_id)

            notification_service.create_notification(
                interview.candidate_id,
                f"Your interview scheduled on {interview.scheduled_time} has been cancelled"
            )
            notification_service.create_notification(
                interview.hiring_manager_id,
                f"Interview with candidate {interview.candidate_id} has been cancelled"
            )
            notification_service.notify_admins(
                f"Interview {interview_id} deleted by user {get_jwt_identity()}"
            )

            return jsonify({"message": "Interview deleted successfully"}), 200
        except Exception as e:
            current_app.logger.error(f"Delete interview error: {str(e)}", exc_info=True)
            return jsonify({"error": "Internal server error"}), 500
