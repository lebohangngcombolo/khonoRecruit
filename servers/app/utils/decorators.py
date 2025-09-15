from functools import wraps
from flask import jsonify
from flask_jwt_extended import verify_jwt_in_request, get_jwt_identity
from app.models import User


def role_required(*roles):
    """
    Restrict access to users with specific roles.
    Usage:
        @app.route("/api/admin")
        @role_required("admin")
        def admin_only():
            ...
    """
    def wrapper(fn):
        @wraps(fn)
        def decorator(*args, **kwargs):
            try:
                # 🔑 Ensure JWT is valid
                verify_jwt_in_request()
                user_id = int(get_jwt_identity())
                user = User.query.get(user_id)

                if not user:
                    return jsonify({"error": "User not found"}), 404

                if user.role not in roles:
                    return jsonify({"error": "Unauthorized access"}), 403

                return fn(*args, **kwargs)

            except Exception:
                return jsonify({"error": "Invalid or expired token"}), 401

        return decorator
    return wrapper
