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
                # Verify the token
                verify_jwt_in_request()
                claims = get_jwt()
                identity = get_jwt_identity()

                # Check role in token claims first
                token_role = claims.get("role")
                if token_role:
                    if token_role in roles:
                        return fn(*args, **kwargs)
                    else:
                        return jsonify({
                            "error": "Unauthorized access",
                            "required_roles": roles,
                            "your_role": token_role
                        }), 403

                # Fallback: query the DB for user role
                if not identity:
                    return jsonify({"error": "Token identity missing"}), 401

                try:
                    user_id = int(identity)
                except (TypeError, ValueError):
                    return jsonify({"error": "Invalid token identity"}), 422

                user = User.query.get(user_id)
                if not user:
                    return jsonify({"error": "User not found"}), 404

                if user.role not in roles:
                    return jsonify({
                        "error": "Unauthorized access",
                        "required_roles": roles,
                        "your_role": user.role
                    }), 403

                return fn(*args, **kwargs)

            except Exception as e:
                # Return detailed info for debugging
                return jsonify({"error": "Invalid or expired token", "details": str(e)}), 401

        return decorator
    return wrapper

