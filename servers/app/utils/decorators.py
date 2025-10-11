from functools import wraps
from flask import jsonify, request, current_app
from flask_jwt_extended import verify_jwt_in_request, get_jwt, get_jwt_identity
from app.models import User
import logging

def role_required(*roles):
    allowed_roles = []
    for r in roles:
        if isinstance(r, (list, tuple)):
            allowed_roles.extend(r)
        else:
            allowed_roles.append(r)

    def wrapper(fn):
        @wraps(fn)
        def decorator(*args, **kwargs):
            # Skip JWT checks for preflight
            if request.method == "OPTIONS":
                return '', 200

            try:
                # 1️⃣ Try standard header check
                try:
                    verify_jwt_in_request()
                except Exception:
                    # 2️⃣ If no header, try JWT from cookies
                    token = request.cookies.get("access_token")
                    if not token:
                        raise
                    verify_jwt_in_request(locations=["cookies"])

                claims = get_jwt()
                identity = get_jwt_identity()
                logging.info(f"JWT claims: {claims}, identity: {identity}")

                token_role = claims.get("role")
                logging.info(f"Token role: {token_role}, Allowed roles: {allowed_roles}")

                # Check role from JWT first
                if token_role and token_role in allowed_roles:
                    return fn(*args, **kwargs)

                # Fallback to DB lookup
                if not identity:
                    return jsonify({"error": "Token identity missing"}), 401

                user = User.query.get(int(identity))
                db_role = user.role if user else None
                logging.info(f"DB role: {db_role}")

                if db_role in allowed_roles:
                    return fn(*args, **kwargs)

                # Unauthorized if role not allowed
                return jsonify({
                    "error": "Unauthorized access",
                    "required_roles": allowed_roles,
                    "your_role": token_role or db_role
                }), 403

            except Exception as e:
                logging.error(f"Role decorator exception: {e}", exc_info=True)
                return jsonify({"error": "Invalid or expired token", "details": str(e)}), 401

        return decorator
    return wrapper
