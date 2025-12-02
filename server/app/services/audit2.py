import logging
from datetime import datetime
from flask import request
from app.extensions import db
from app.models import AuditLog

logger = logging.getLogger(__name__)


class AuditService:
    @staticmethod
    def record_action(
        admin_id: int,
        action: str,
        target_user_id: int = None,
        details: str = None,
        extra_data: dict = None  # <-- renamed
    ):
        """
        Log an action performed by an admin or system process.
        Automatically captures IP and User-Agent from request.
        """
        try:
            ip_address = request.remote_addr if request else None
            user_agent = request.headers.get("User-Agent", "") if request else None

            log_entry = AuditLog(
                admin_id=admin_id,
                action=action,
                target_user_id=target_user_id,
                details=details,
                extra_data=extra_data,  # <-- use correct field name
                ip_address=ip_address,
                user_agent=user_agent,
                timestamp=datetime.utcnow()
            )

            db.session.add(log_entry)
            db.session.commit()
            logger.info(f"Audit recorded: {action} by admin_id={admin_id}")

        except Exception as e:
            db.session.rollback()
            logger.error(f"Failed to record audit log: {e}", exc_info=True)

    @staticmethod
    def log(user_id: int, action: str, **kwargs):
        """
        Alias for record_action for backward compatibility.
        Maps old 'metadata' kwarg to 'extra_data'.
        """
        extra_data = kwargs.get("metadata")  # support old calls
        AuditService.record_action(admin_id=user_id, action=action, extra_data=extra_data)


# === Helper Decorators (Optional Integration) ===
def audit_action(action_description: str):
    """
    Decorator for automatically recording audits on route actions.
    Example:
    @audit_action("Created new job posting")
    """
    def decorator(func):
        from functools import wraps
        from flask_jwt_extended import get_jwt_identity

        @wraps(func)
        def wrapper(*args, **kwargs):
            response = func(*args, **kwargs)
            try:
                admin_id = get_jwt_identity()
                AuditService.record_action(
                    admin_id=admin_id,
                    action=action_description,
                    metadata={"endpoint": request.path, "method": request.method}
                )
            except Exception as e:
                logger.warning(f"Audit decorator failed: {e}")
            return response

        return wrapper
    return decorator
