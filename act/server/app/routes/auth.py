from flask import request, jsonify, current_app, redirect, url_for, make_response
from flask_jwt_extended import (
    create_access_token,
    create_refresh_token,
    jwt_required,
    unset_jwt_cookies,
    verify_jwt_in_request, 
    get_jwt_identity
)
from app.extensions import db, oauth  
from app.models import User, VerificationCode, OAuthConnection, Candidate
from app.services.auth_service import AuthService
from app.services.email_service import EmailService
from app.services.audit2 import AuditService
from app.utils.decorators import role_required
from datetime import datetime, timedelta
import secrets


# ------------------- ROLE DASHBOARD MAP -------------------
ROLE_DASHBOARD_MAP = {
    "admin": "/api/dashboard/admin",
    "hiring_manager": "/api/dashboard/hiring-manager",
    "candidate": "/dashboard/candidate"
}

# OAuth providers config
OAUTH_PROVIDERS = {
    "google": {
        "userinfo": {
            "url": "https://www.googleapis.com/oauth2/v3/userinfo",
            "email": lambda data: data["email"],
            "first_name": lambda data: data.get("given_name", ""),
            "last_name": lambda data: data.get("family_name", "")
        }
    },
    "github": {
        "userinfo": {
            "url": "https://api.github.com/user",
            "email": lambda data: data.get("email", ""),
            "first_name": lambda data: data.get("name", "").split(" ")[0] if data.get("name") else "",
            "last_name": lambda data: data.get("name", "").split(" ")[1] if data.get("name") and " " in data.get("name") else ""
        }
    }
}


def init_auth_routes(app):

    # ------------------- Initialize OAuth -------------------
    if not hasattr(app, "oauth_initialized"):
        oauth.init_app(app)

        # Google OAuth
        oauth.register(
            name="google",
            client_id=app.config["GOOGLE_CLIENT_ID"],
            client_secret=app.config["GOOGLE_CLIENT_SECRET"],
            server_metadata_url="https://accounts.google.com/.well-known/openid-configuration",
            client_kwargs={"scope": "openid email profile"},
            userinfo_endpoint=OAUTH_PROVIDERS["google"]["userinfo"]["url"]
        )

        # GitHub OAuth
        oauth.register(
            name="github",
            client_id=app.config["GITHUB_CLIENT_ID"],
            client_secret=app.config["GITHUB_CLIENT_SECRET"],
            authorize_url="https://github.com/login/oauth/authorize",
            access_token_url="https://github.com/login/oauth/access_token",
            client_kwargs={"scope": "user:email"}
        )

        app.oauth_initialized = True

    # ------------------- LOGOUT -------------------
    @app.route("/api/auth/logout", methods=["POST"])
    @jwt_required()
    def logout():
        try:
            response = jsonify({"message": "Successfully logged out"})
            unset_jwt_cookies(response)
            return response, 200
        except Exception as e:
            current_app.logger.error(f"Logout error: {str(e)}", exc_info=True)
            return jsonify({"error": "Internal server error"}), 500

    # ------------------- GOOGLE LOGIN -------------------
    @app.route("/api/auth/google")
    def google_login():
        try:
            redirect_uri = url_for("google_callback", _external=True)
            # For Flutter Web, navigate in same tab
            return oauth.google.authorize_redirect(redirect_uri)
        except Exception as e:
            current_app.logger.error(f"Google login initiation error: {str(e)}", exc_info=True)
            return jsonify({"error": "OAuth configuration error"}), 500

    @app.route("/api/auth/google/callback")
    def google_callback():
        try:
            oauth.google.authorize_access_token()
            user_info = oauth.google.get(OAUTH_PROVIDERS["google"]["userinfo"]["url"]).json()
        
            # ⚡ handle_oauth_callback() already returns redirect()
            return handle_oauth_callback("google", user_info)

        except Exception as e:
            current_app.logger.error(f"Google OAuth callback error: {str(e)}", exc_info=True)
            return jsonify({"error": "Authentication failed"}), 400


    # ------------------- GITHUB LOGIN -------------------
    @app.route("/api/auth/github")
    def github_login():
        try:
            redirect_uri = url_for("github_callback", _external=True)
            return oauth.github.authorize_redirect(redirect_uri)
        except Exception as e:
            current_app.logger.error(f"GitHub login initiation error: {str(e)}", exc_info=True)
            return jsonify({"error": "OAuth configuration error"}), 500

    @app.route("/api/auth/github/callback")
    def github_callback():
        try:
            oauth.github.authorize_access_token()
            user_info = oauth.github.get(OAUTH_PROVIDERS["github"]["userinfo"]["url"]).json()
            if not user_info.get("email"):
                emails = oauth.github.get("https://api.github.com/user/emails").json()
                primary_email = next((e for e in emails if e.get("primary")), None)
                if primary_email:
                    user_info["email"] = primary_email["email"]
            return handle_oauth_callback("github", user_info)
        except Exception as e:
            current_app.logger.error(f"GitHub OAuth callback error: {str(e)}", exc_info=True)
            return jsonify({"error": "Authentication failed"}), 400

    # ------------------- OAUTH CALLBACK HANDLER -------------------
    def handle_oauth_callback(provider: str, user_info: dict):
        try:
            email = user_info.get("email")
            if not email:
                return jsonify({"error": "Email not provided by OAuth provider"}), 400
            email = email.strip().lower()

            provider_config = OAUTH_PROVIDERS[provider]
            first_name = provider_config["userinfo"]["first_name"](user_info)
            last_name = provider_config["userinfo"]["last_name"](user_info)

            # User lookup / creation
            user = User.query.filter(db.func.lower(User.email) == email).first()
            if not user:
                random_password = secrets.token_urlsafe(16)
                user = AuthService.create_user(
                    email=email,
                    password=random_password,
                    first_name=first_name,
                    last_name=last_name,
                    role="candidate"
                )
                user.is_verified = True

            # OAuth connection
            oauth_conn = OAuthConnection.query.filter_by(user_id=user.id, provider=provider).first()
            if not oauth_conn:
                oauth_conn = OAuthConnection(
                    user_id=user.id,
                    provider=provider,
                    provider_user_id=str(user_info.get("id") or user_info.get("sub")),
                    access_token=secrets.token_urlsafe(32)
                )
                db.session.add(oauth_conn)
            db.session.commit()

            # Tokens
            additional_claims = {"role": user.role}
            access_token = create_access_token(identity=str(user.id), additional_claims=additional_claims)
            refresh_token = create_refresh_token(identity=str(user.id), additional_claims=additional_claims)

            # ✅ Determine dashboard route safely (fixed)
            dashboard_path = (
                "/enrollment"
                if user.role == "candidate" and not getattr(user, "enrollment_completed", False)
                else ROLE_DASHBOARD_MAP.get(user.role, "/dashboard")
            )

            # ✅ Ensure no accidental /api/ prefix (this is your issue)
            if dashboard_path.startswith("/api/"):
                dashboard_path = dashboard_path.replace("/api", "", 1)

            # ✅ Redirect to frontend cleanly
            frontend_redirect = (
                f"{current_app.config['FRONTEND_URL']}/oauth-callback"
                f"?access_token={access_token}&refresh_token={refresh_token}&role={user.role}"
            )

            current_app.logger.info(f"Redirecting {user.email} ({user.role}) → {frontend_redirect}")
            return redirect(frontend_redirect)


        except Exception as e:
            db.session.rollback()
            current_app.logger.error(f"OAuth callback handler error: {str(e)}", exc_info=True)
            return jsonify({"error": "Internal server error"}), 500


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

            # ---- Basic validation ----
            if not all([email, password]):
                return jsonify({'error': 'Email and password are required'}), 400

            email = email.strip().lower()
            user = User.query.filter(db.func.lower(User.email) == email).first()

            # ---- Invalid credentials ----
            if not user or not AuthService.verify_password(password, user.password):
                return jsonify({'error': 'Invalid credentials'}), 401

            # ---- Handle unverified user ----
            if not user.is_verified:
                AuditService.log(user_id=user.id, action="login_attempt_unverified")
                return jsonify({
                    'message': 'Please verify your email before continuing.',
                    'redirect': '/verify-email',
                    'verified': False
                }), 403

            # 🆕 MFA CHECK - If MFA enabled, return MFA session token instead of final tokens
            if user.mfa_enabled:
                # Create temporary MFA session token (5 minutes)
                mfa_session_token = create_access_token(
                    identity=str(user.id),
                    expires_delta=timedelta(minutes=5),
                    additional_claims={"mfa_pending": True, "role": user.role}
                )
            
                AuditService.log(user_id=user.id, action="login_mfa_required")
            
                return jsonify({
                    'message': 'MFA verification required',
                    'mfa_required': True,
                    'mfa_session_token': mfa_session_token,
                    'user_id': user.id
                }), 200

            # ---- Create JWT tokens (for non-MFA users) ----
            additional_claims = {"role": user.role}
            access_token = create_access_token(identity=str(user.id), additional_claims=additional_claims)
            refresh_token = create_refresh_token(identity=str(user.id), additional_claims=additional_claims)

            # ---- Determine dashboard URL ----
            dashboard_url = "/enrollment" if user.role == "candidate" and not user.enrollment_completed \
                else ROLE_DASHBOARD_MAP.get(user.role, "/dashboard")

            # ---- Log successful login ----
            AuditService.log(user_id=user.id, action="login_success")

            # ---- Return successful response ----
            return jsonify({
                'access_token': access_token,
                'refresh_token': refresh_token,
                'user': user.to_dict(),
                'verified': True,
                'dashboard': dashboard_url
            }), 200

        except Exception as e:
            current_app.logger.error(f'Login error: {str(e)}', exc_info=True)
            return jsonify({'error': 'Internal server error'}), 500  # 🆕 Changed from 200 to 500

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

            # Get candidate profile if user is a candidate
            candidate_profile = Candidate.query.filter_by(user_id=user.id).first()
            if candidate_profile:
                candidate_profile = candidate_profile.to_dict()

            dashboard_url = "/enrollment" if user.role == "candidate" and not user.enrollment_completed \
                else ROLE_DASHBOARD_MAP.get(user.role, "/dashboard")

            AuditService.log(user_id=user.id, action="get_current_user")


            response_data = {
                "user": {
                    # User table fields only
                    "id": user.id,
                    "email": user.email,
                    "role": user.role,
                    "enrollment_completed": user.enrollment_completed,
                    "created_at": user.created_at.isoformat() if user.created_at else None,
                },
                "role": user.role,
                "dashboard": dashboard_url
            }
        
            # Add full candidate profile data if available
            if candidate_profile:
                response_data["candidate_profile"] = candidate_profile

            return jsonify(response_data), 200

        except Exception as e:
            current_app.logger.error(f"Get current user error: {str(e)}", exc_info=True)
            return jsonify({"error": "Internal server error"}), 500
    # ------------------- DASHBOARDS -------------------
    @app.route("/api/dashboard/admin", methods=["GET"])
    @role_required("admin")
    def admin_dashboard():
        verify_jwt_in_request()
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
    import re, secrets, string

    @app.route("/api/auth/admin-enroll", methods=["POST"])
    @role_required("admin")
    def admin_enroll_user():
        try:
            data = request.get_json() or {}
            email = data.get("email")
            role = data.get("role")
            first_name = data.get("first_name", "")
            last_name = data.get("last_name", "")
            password = data.get("password")  # optional; will generate if missing

            # ---- Validation ----
            if not all([email, role]):
                return jsonify({"error": "Email and role are required"}), 400

            if role not in ["admin", "hiring_manager"]:
                return jsonify({"error": "Role must be admin or hiring_manager"}), 400

            if not re.match(r"[^@]+@[^@]+\.[^@]+", email):
                return jsonify({"error": "Invalid email format"}), 400

            email = email.strip().lower()

            # ---- Check if user already exists ----
            user = User.query.filter(db.func.lower(User.email) == email).first()
            if user:
                return jsonify({"message": f"User with email {email} already exists", "user_id": user.id}), 200

            # ---- Generate random password if missing ----
            if not password:
                password = ''.join(secrets.choice(string.ascii_letters + string.digits + "!@#$%^&*") for _ in range(12))

            # ---- Create user ----
            user = AuthService.create_user(
                email=email,
                password=password,
                first_name=first_name,
                last_name=last_name,
                role=role
            )
            user.is_verified = True
            db.session.add(user)
            db.session.commit()

            # ---- Send temporary password email ----
            # ---- Send temporary password email ----
            EmailService.send_temporary_password(email=user.email, password=password, first_name=first_name)


            # ---- Audit log ----
            AuditService.log(user_id=int(get_jwt_identity()), action=f"enroll_{role}", target_user_id=user.id)

            # ---- Response ----
            return jsonify({
                "message": f"{role.capitalize()} enrolled successfully",
                "user_id": user.id,
            }), 201

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
