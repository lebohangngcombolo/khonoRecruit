from flask import jsonify
from flask_jwt_extended import jwt_required, get_jwt_identity
from app.services import notification_service

def init_notification_routes(app):

    @app.route("/api/notifications", methods=["GET"])
    @jwt_required()
    def get_notifications():
        user_id = get_jwt_identity()
        notifications = notification_service.get_user_notifications(user_id)
        return jsonify([n.to_dict() for n in notifications]), 200

    @app.route("/api/notifications/unread", methods=["GET"])
    @jwt_required()
    def get_unread_notifications():
        user_id = get_jwt_identity()
        notifications = notification_service.get_user_notifications(user_id, unread_only=True)
        return jsonify([n.to_dict() for n in notifications]), 200

    @app.route("/api/notifications/<int:notification_id>/read", methods=["PUT"])
    @jwt_required()
    def mark_notification_as_read(notification_id):
        notification = notification_service.mark_notification_read(notification_id)
        return jsonify(notification.to_dict()), 200
