from flask import request, jsonify, current_app, redirect, url_for
from flask_jwt_extended import (
    create_access_token,
    create_refresh_token,
    jwt_required,
    unset_jwt_cookies,
    get_jwt_identity
)
from app.extensions import db
from app.models import User, VerificationCode
from app.services.auth_service import AuthService
from app.services.email_service import EmailService
from app.services.audit2 import AuditService
from app.utils.decorators import role_required
from datetime import datetime, timedelta
import secrets
import firebase_admin
from firebase_admin import auth as firebase_auth

# ------------------- ROLE DASHBOARD MAP -------------------
ROLE_DASHBOARD_MAP = {
    "admin": "/api/dashboard/admin",
    "hiring_manager": "/api/dashboard/hiring-manager",
    "candidate": "/dashboard/candidate"
}

def init_auth_routes(app):

    # ------------------- LOGOUT -------------------
    @app.route("/api/auth/logout", methods=["POST"])
    @jwt_required()
    def logout():
        try:
            current_user_id = int(get_jwt_identity())
            AuditService.log(user_id=current_user_id, action="logout")
            response = jsonify({"message": "Successfully logged out"})
            unset_jwt_cookies(response)
            return response, 200
        except Exception as e:
            current_app.logger.error(f"Logout error: {str(e)}", exc_info=True)
            return jsonify({"error": "Internal server error"}), 500

    # ------------------- FIREBASE LOGIN -------------------
    @app.route("/api/auth/firebase-login", methods=["POST"])
    def firebase_login():
        id_token = request.headers.get("Authorization", "").replace("Bearer ", "")
        if not id_token:
            return jsonify({"error": "Firebase ID token required"}), 400

        try:
            decoded_token = firebase_auth.verify_id_token(id_token)
            email = decoded_token.get("email")
            name = decoded_token.get("name", "")
            first_name = name.split(" ")[0] if name else ""
            last_name = name.split(" ")[-1] if " " in name else ""

            if not email:
                return jsonify({"error": "Email not provided by Firebase"}), 400

            email = email.strip().lower()
            user = User.query.filter(db.func.lower(User.email) == email).first()

            # Create user if doesn't exist
            if not user:
                user = AuthService.create_user(
                    email=email,
                    password=None,
                    first_name=first_name,
                    last_name=last_name,
                    role="candidate"
                )
                user.is_verified = True
                db.session.add(user)
                db.session.commit()

            # Log login
            AuditService.log(user_id=user.id, action="firebase_oauth_login")

            additional_claims = {"role": user.role}
            access_token = create_access_token(identity=str(user.id), additional_claims=additional_claims)
            refresh_token = create_refresh_token(identity=str(user.id), additional_claims=additional_claims)

            dashboard_url = (
                "/enrollment" if user.role == "candidate" and not getattr(user, "enrollment_completed", False)
                else ROLE_DASHBOARD_MAP.get(user.role, "/dashboard")
            )

            referrer = request.referrer or ""
            redirect_uri = request.args.get("redirect_uri", "")
            is_flutter = "myapp" in referrer or "myapp" in redirect_uri

            if is_flutter:
                redirect_link = (
                    f"myapp://callback"
                    f"?access_token={access_token}"
                    f"&refresh_token={refresh_token}"
                    f"&role={user.role}"
                    f"&dashboard={dashboard_url}"
                )
                return redirect(redirect_link)

            frontend_url = current_app.config.get("FRONTEND_URL", "http://localhost:3000")
            redirect_with_tokens = (
                f"{frontend_url}{dashboard_url}"
                f"?access_token={access_token}"
                f"&refresh_token={refresh_token}"
                f"&role={user.role}"
            )
            return redirect(redirect_with_tokens)

        except Exception as e:
            current_app.logger.error(f"Firebase login error: {str(e)}", exc_info=True)
            return jsonify({"error": "Firebase token verification failed"}), 400

    # ------------------- REGISTER -------------------
    @app.route('/api/auth/register', methods=['POST'])
    def register():
        try:
            data = request.get_json()
            email = data.get('email')
            password = data.get('password')
            first_name = data.get('first_name')
            last_name = data.get('last_name')
            role = data.get('role', 'candidate')

            if role not in ROLE_DASHBOARD_MAP:
                return jsonify({"error": "Invalid role"}), 400
            if not all([email, password, first_name, last_name]):
                return jsonify({'error': 'Missing required fields'}), 400

            email = email.strip().lower()
            if User.query.filter(db.func.lower(User.email) == email).first():
                return jsonify({'error': 'User already exists'}), 409

            user = AuthService.create_user(email, password, first_name, last_name, role)

            code = f"{secrets.randbelow(1000000):06d}"
            expires_at = datetime.utcnow() + timedelta(minutes=30)
            VerificationCode.query.filter_by(email=email, is_used=False).delete()
            verification_code = VerificationCode(email=email, code=code, expires_at=expires_at)
            db.session.add(verification_code)
            db.session.commit()

            EmailService.send_verification_email(email, code)
            AuditService.log(user_id=user.id, action="register")

            return jsonify({
                'message': 'User registered successfully. Please check your email for verification code.',
                'user_id': user.id
            }), 201

        except Exception as e:
            db.session.rollback()
            current_app.logger.error(f'Registration error: {str(e)}', exc_info=True)
            return jsonify({'error': 'Internal server error'}), 500

    # ------------------- VERIFY EMAIL -------------------
    @app.route('/api/auth/verify', methods=['POST'])
    def verify_email():
        try:
            data = request.get_json()
            email = data.get('email')
            code = data.get('code')
            if not all([email, code]):
                return jsonify({'error': 'Email and code are required'}), 400
            email = email.strip().lower()

            verification_code = VerificationCode.query.filter_by(email=email, code=code, is_used=False)\
                .order_by(VerificationCode.created_at.desc()).first()
            if not verification_code or not verification_code.is_valid():
                return jsonify({'error': 'Invalid or expired verification code'}), 400

            verification_code.is_used = True
            user = User.query.filter(db.func.lower(User.email) == email).first()
            if not user:
                return jsonify({'error': 'User not found'}), 404

            user.is_verified = True
            db.session.commit()

            AuditService.log(user_id=user.id, action="email_verified")

            additional_claims = {"role": user.role}
            access_token = create_access_token(identity=str(user.id), additional_claims=additional_claims)
            refresh_token = create_refresh_token(identity=str(user.id), additional_claims=additional_claims)
            dashboard_url = "/enrollment" if user.role == "candidate" and not user.enrollment_completed \
                else ROLE_DASHBOARD_MAP.get(user.role, "/dashboard")

            return jsonify({
                'message': 'Email verified successfully',
                'access_token': access_token,
                'refresh_token': refresh_token,
                'user': user.to_dict(),
                'dashboard': dashboard_url
            }), 200

        except Exception as e:
            db.session.rollback()
            current_app.logger.error(f'Verification error: {str(e)}', exc_info=True)
            return jsonify({'error': 'Internal server error'}), 500

    # ------------------- LOGIN -------------------
    @app.route('/api/auth/login', methods=['POST'])
    def login():
        try:
            data = request.get_json()
            email = data.get('email')
            password = data.get('password')
            if not all([email, password]):
                return jsonify({'error': 'Email and password are required'}), 400

            email = email.strip().lower()
            user = User.query.filter(db.func.lower(User.email) == email).first()
            if not user or not AuthService.verify_password(password, user.password):
                return jsonify({'error': 'Invalid credentials'}), 401
            if not user.is_verified:
                return jsonify({'error': 'Please verify your email first'}), 403

            additional_claims = {"role": user.role}
            access_token = create_access_token(identity=str(user.id), additional_claims=additional_claims)
            refresh_token = create_refresh_token(identity=str(user.id), additional_claims=additional_claims)
            dashboard_url = "/enrollment" if user.role == "candidate" and not user.enrollment_completed \
                else ROLE_DASHBOARD_MAP.get(user.role, "/dashboard")

            AuditService.log(user_id=user.id, action="login")

            return jsonify({
                'access_token': access_token,
                'refresh_token': refresh_token,
                'user': user.to_dict(),
                'dashboard': dashboard_url
            }), 200

        except Exception as e:
            current_app.logger.error(f'Login error: {str(e)}', exc_info=True)
            return jsonify({'error': 'Internal server error'}), 500

    # ------------------- REFRESH TOKEN -------------------
    @app.route('/api/auth/refresh', methods=['POST'])
    @jwt_required(refresh=True)
    def refresh_token():
        try:
            current_user_id = int(get_jwt_identity())
            user = User.query.get(current_user_id)
            if not user:
                return jsonify({'error': 'User not found'}), 404

            additional_claims = {"role": user.role}
            new_access_token = create_access_token(identity=str(current_user_id), additional_claims=additional_claims)
            dashboard_url = "/enrollment" if user.role == "candidate" and not user.enrollment_completed \
                else ROLE_DASHBOARD_MAP.get(user.role, "/dashboard")

            AuditService.log(user_id=user.id, action="refresh_token")

            return jsonify({
                'access_token': new_access_token,
                'role': user.role,
                'dashboard': dashboard_url
            }), 200

        except Exception as e:
            current_app.logger.error(f'Token refresh error: {str(e)}', exc_info=True)
            return jsonify({'error': 'Internal server error'}), 500

    # ------------------- FORGOT & RESET PASSWORD -------------------
    @app.route('/api/auth/forgot-password', methods=['POST'])
    def forgot_password():
        try:
            data = request.get_json()
            email = data.get('email')
            if not email:
                return jsonify({'error': 'Email is required'}), 400

            email = email.strip().lower()
            user = User.query.filter(db.func.lower(User.email) == email).first()
            if user:
                reset_token = AuthService.generate_password_reset_token(user.id)
                EmailService.send_password_reset_email(email, reset_token)
                AuditService.log(user_id=user.id, action="forgot_password")

            return jsonify({'message': 'If that email exists, reset instructions have been sent.'}), 200

        except Exception as e:
            current_app.logger.error(f'Forgot password error: {str(e)}', exc_info=True)
            return jsonify({'error': 'Internal server error'}), 500

    @app.route('/api/auth/reset-password', methods=['POST'])
    def reset_password():
        try:
            data = request.get_json()
            token = data.get('token')
            new_password = data.get('new_password')
            if not all([token, new_password]):
                return jsonify({'error': 'Token and new password are required'}), 400

            user_id = AuthService.verify_password_reset_token(token)
            if not user_id:
                return jsonify({'error': 'Invalid or expired token'}), 400

            user = User.query.get(user_id)
            if not user:
                return jsonify({'error': 'User not found'}), 404

            user.password = AuthService.hash_password(new_password)
            db.session.commit()

            AuditService.log(user_id=user.id, action="reset_password")

            return jsonify({'message': 'Password reset successfully'}), 200

        except Exception as e:
            db.session.rollback()
            current_app.logger.error(f'Password reset error: {str(e)}', exc_info=True)
            return jsonify({'error': 'Internal server error'}), 500

    # ------------------- GET CURRENT USER -------------------
    @app.route("/api/auth/me", methods=["GET"])
    @jwt_required()
    def get_current_user():
        try:
            current_user_id = int(get_jwt_identity())
            user = User.query.get(current_user_id)
            if not user:
                return jsonify({"error": "User not found"}), 404

            dashboard_url = "/enrollment" if user.role == "candidate" and not user.enrollment_completed \
                else ROLE_DASHBOARD_MAP.get(user.role, "/dashboard")

            AuditService.log(user_id=user.id, action="get_current_user")

            return jsonify({
                "user": user.to_dict(),
                "role": user.role,
                "dashboard": dashboard_url
            }), 200

        except Exception as e:
            current_app.logger.error(f"Get current user error: {str(e)}", exc_info=True)
            return jsonify({"error": "Internal server error"}), 500

    # ------------------- DASHBOARDS -------------------
    @app.route("/api/dashboard/admin", methods=["GET"])
    @role_required("admin")
    def admin_dashboard():
        current_user_id = int(get_jwt_identity())
        AuditService.log(user_id=current_user_id, action="view_admin_dashboard")
        return jsonify({"message": "Welcome to the Admin Dashboard"}), 200

    @app.route("/api/dashboard/hiring-manager", methods=["GET"])
    @role_required("hiring_manager")
    def hiring_manager_dashboard():
        current_user_id = int(get_jwt_identity())
        AuditService.log(user_id=current_user_id, action="view_hiring_manager_dashboard")
        return jsonify({"message": "Welcome to the Hiring Manager Dashboard"}), 200

    @app.route("/api/dashboard/candidate", methods=["GET"])
    @role_required("candidate")
    def candidate_dashboard():
        current_user_id = int(get_jwt_identity())
        AuditService.log(user_id=current_user_id, action="view_candidate_dashboard")
        return jsonify({"message": "Welcome to the Candidate Dashboard"}), 200

    # ------------------- CANDIDATE ENROLLMENT -------------------
    @app.route("/api/candidate/enrollment", methods=["POST"])
    @role_required("candidate")
    def candidate_enrollment():
        try:
            current_user_id = int(get_jwt_identity())
            user = User.query.get(current_user_id)
            data = request.get_json()

            user.profile.update(data)
            user.enrollment_completed = True
            db.session.commit()

            AuditService.log(user_id=user.id, action="complete_enrollment")

            return jsonify({"message": "Enrollment completed successfully"}), 200

        except Exception as e:
            db.session.rollback()
            current_app.logger.error(f"Candidate enrollment error: {str(e)}", exc_info=True)
            return jsonify({"error": "Internal server error"}), 500

    # ------------------- ADMIN ENROLLMENT -------------------
    @app.route("/api/admin/enroll-user", methods=["POST"])
    @role_required("admin")
    def admin_enroll_user():
        try:
            data = request.get_json()
            email = data.get("email")
            role = data.get("role")
            if not all([email, role]):
                return jsonify({"error": "Email and role required"}), 400
            if role not in ["admin", "hiring_manager"]:
                return jsonify({"error": "Role must be admin or hiring_manager"}), 400

            email = email.strip().lower()
            user = User.query.filter(db.func.lower(User.email) == email).first()
            if not user:
                user = AuthService.create_user(email=email, password=None, first_name="", last_name="", role=role)
                user.is_verified = True
                db.session.add(user)
                db.session.commit()

            AuditService.log(user_id=int(get_jwt_identity()), action=f"enroll_{role}", target_user_id=user.id)

            return jsonify({"message": f"{role} enrolled successfully", "user_id": user.id}), 201

        except Exception as e:
            db.session.rollback()
            current_app.logger.error(f"Admin enroll error: {str(e)}", exc_info=True)
            return jsonify({"error": "Internal server error"}), 500

            
            
    # ------------------- CHANGE PASSWORD (FIRST LOGIN) -------------------
    @app.route("/api/auth/change-password", methods=["POST"])
    @jwt_required()
    def change_password():
        try:
            data = request.get_json(force=True, silent=True)  # <-- force JSON parsing
            if not data:
                return jsonify({"error": "Invalid or missing JSON body"}), 400

            user_id = int(get_jwt_identity())

            temp_password = data.get("temporary_password")
            new_password = data.get("new_password")
            confirm_password = data.get("confirm_password")

            if not all([temp_password, new_password, confirm_password]):
                return jsonify({
                    "error": "Temporary password, new password, and confirmation are required"
             }), 400

            if new_password != confirm_password:
                return jsonify({"error": "New password and confirmation do not match"}), 400

            user = User.query.get(user_id)
            if not user:
                return jsonify({"error": "User not found"}), 404

            if not getattr(user, "first_login", False):
                return jsonify({
                    "error": "Password change not required. Already completed first login."
                }), 400

            if not AuthService.verify_password(temp_password, user.password):
                return jsonify({"error": "Temporary password is incorrect"}), 401

            user.password = AuthService.hash_password(new_password)
            user.first_login = False
            db.session.commit()

            return jsonify({"message": "Password changed successfully", "role": user.role}), 200

        except Exception as e:
            db.session.rollback()
            current_app.logger.error(f"Change password error: {str(e)}", exc_info=True)
            return jsonify({"error": "Internal server error"}), 500
