from functools import wraps
from flask import jsonify
from flask_jwt_extended import verify_jwt_in_request, get_jwt, get_jwt_identity
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
                claims = get_jwt()
                user_id = get_jwt_identity()

                # 1. First try role from JWT claims (faster, no DB hit)
                token_role = claims.get("role")

                if token_role and token_role in roles:
                    return fn(*args, **kwargs)

                # 2. If role missing in token, fallback to DB
                try:
                    user_id = int(user_id)
                except (ValueError, TypeError):
                    return jsonify({"error": "Invalid token identity"}), 422

                user = User.query.get(user_id)
                if not user:
                    return jsonify({"error": "User not found"}), 404

                if user.role not in roles:
                    return jsonify({"error": "Unauthorized access"}), 403

                return fn(*args, **kwargs)

            except Exception as e:
                return jsonify({"error": "Invalid or expired token"}), 401

        return decorator
    return wrapper
