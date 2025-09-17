from flask import request, jsonify, current_app
from flask_jwt_extended import (
    create_access_token,
    create_refresh_token,
    jwt_required,
    get_jwt_identity
)
from app.extensions import db
from app.models import User, VerificationCode
from app.services.auth_service import AuthService
from app.services.email_service import EmailService
from app.utils.decorators import role_required
from datetime import datetime, timedelta
import random
import string

# ------------------- ROLE DASHBOARD MAP -------------------
ROLE_DASHBOARD_MAP = {
    "admin": "/dashboard/admin",
    "hiring_manager": "/dashboard/hiring-manager",
    "candidate": "/dashboard/candidate"
}

def init_auth_routes(app):

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

            # Create user
            user = AuthService.create_user(email, password, first_name, last_name, role)

            # Generate verification code
            code = ''.join(random.choices(string.digits, k=6))
            expires_at = datetime.utcnow() + timedelta(minutes=30)

            verification_code = VerificationCode(
                email=email,
                code=code,
                expires_at=expires_at
            )
            db.session.add(verification_code)
            db.session.commit()

            # Send email
            EmailService.send_verification_email(email, code)

            current_app.logger.info(f'User registered: {user.email}, ID: {user.id}, Role: {user.role}')

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

            verification_code = VerificationCode.query.filter_by(
                email=email,
                code=code,
                is_used=False
            ).order_by(VerificationCode.created_at.desc()).first()

            if not verification_code or not verification_code.is_valid():
                return jsonify({'error': 'Invalid or expired verification code'}), 400

            verification_code.is_used = True

            user = User.query.filter(db.func.lower(User.email) == email).first()
            if not user:
                return jsonify({'error': 'User not found'}), 404

            user.is_verified = True
            db.session.commit()

            # Embed role in JWT claims
            additional_claims = {"role": user.role}

            access_token = create_access_token(identity=str(user.id), additional_claims=additional_claims)
            refresh_token = create_refresh_token(identity=str(user.id), additional_claims=additional_claims)

            dashboard_url = ROLE_DASHBOARD_MAP.get(user.role, "/dashboard")

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

            # Embed role inside JWT claims
            additional_claims = {"role": user.role}

            access_token = create_access_token(identity=str(user.id), additional_claims=additional_claims)
            refresh_token = create_refresh_token(identity=str(user.id), additional_claims=additional_claims)

            dashboard_url = ROLE_DASHBOARD_MAP.get(user.role, "/dashboard")

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

            return jsonify({
                'access_token': new_access_token,
                'role': user.role,
                'dashboard': ROLE_DASHBOARD_MAP.get(user.role, "/dashboard")
            }), 200

        except Exception as e:
            current_app.logger.error(f'Token refresh error: {str(e)}', exc_info=True)
            return jsonify({'error': 'Internal server error'}), 500

    # ------------------- FORGOT PASSWORD -------------------
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

            return jsonify({'message': 'If that email exists, reset instructions have been sent.'}), 200

        except Exception as e:
            current_app.logger.error(f'Forgot password error: {str(e)}', exc_info=True)
            return jsonify({'error': 'Internal server error'}), 500

    # ------------------- RESET PASSWORD -------------------
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
            current_user_id = get_jwt_identity()
            try:
                current_user_id = int(current_user_id)
            except (ValueError, TypeError):
                return jsonify({"error": "Invalid token identity"}), 422

            user = User.query.get(current_user_id)
            if not user:
                return jsonify({"error": "User not found"}), 404

            return jsonify({
                "user": user.to_dict(),
                "role": user.role,
                "dashboard": ROLE_DASHBOARD_MAP.get(user.role, "/dashboard")
            }), 200

        except Exception as e:
            current_app.logger.error(f"Get current user error: {str(e)}", exc_info=True)
            return jsonify({"error": "Internal server error"}), 500

    # ------------------- DASHBOARDS -------------------
    @app.route("/api/dashboard/admin", methods=["GET"])
    @role_required("admin")
    def admin_dashboard():
        return jsonify({"message": "Welcome to the Admin Dashboard"}), 200

    @app.route("/api/dashboard/hiring-manager", methods=["GET"])
    @role_required("hiring_manager")
    def hiring_manager_dashboard():
        return jsonify({"message": "Welcome to the Hiring Manager Dashboard"}), 200

    @app.route("/api/dashboard/candidate", methods=["GET"])
    @role_required("candidate")
    def candidate_dashboard():
        return jsonify({"message": "Welcome to the Candidate Dashboard"}), 200
