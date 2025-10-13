from app.models import Notification, User
from app.extensions import db, socketio
from flask_socketio import emit
from flask import current_app

# Create notification for a user
def create_notification(user_id, message):
    try:
        notification = Notification(user_id=user_id, message=message)
        db.session.add(notification)
        db.session.commit()

        # Emit real-time notification
        socketio.emit(
            f"notification_{user_id}",
            notification.to_dict(),
            broadcast=True
        )
        return notification
    except Exception as e:
        db.session.rollback()
        current_app.logger.error(f"Create notification error: {str(e)}")
        raise

# Notify all admins
def notify_admins(message):
    try:
        admin_users = User.query.filter_by(role="admin").all()
        notifications = []
        for admin in admin_users:
            notification = Notification(user_id=admin.id, message=message)
            db.session.add(notification)
            notifications.append(notification)
            socketio.emit(
                f"notification_{admin.id}",
                notification.to_dict(),
                broadcast=True
            )
        db.session.commit()
        return notifications
    except Exception as e:
        db.session.rollback()
        current_app.logger.error(f"Notify admins error: {str(e)}")
        raise

# Get notifications for a user
def get_user_notifications(user_id, unread_only=False):
    query = Notification.query.filter_by(user_id=user_id)
    if unread_only:
        query = query.filter_by(is_read=False)
    return query.order_by(Notification.created_at.desc()).all()

# Mark notification as read
def mark_notification_read(notification_id):
    notification = Notification.query.get_or_404(notification_id)
    notification.is_read = True
    db.session.commit()
    return notification
