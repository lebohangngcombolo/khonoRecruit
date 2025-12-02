# sso_routes.py
from flask import Blueprint, current_app, jsonify, url_for, redirect, request, session
from flask_jwt_extended import create_access_token, create_refresh_token
from app.extensions import db, oauth
from app.models import User, OAuthConnection, Candidate
from app.services.audit2 import AuditService
from app.services.auth_service import AuthService
import secrets
import requests
import urllib.parse
import traceback

sso_bp = Blueprint("sso_bp", __name__)

ROLE_DASHBOARD_MAP = {
    "admin": "/admin-dashboard",
    "hiring_manager": "/hiring-manager-dashboard",
    "candidate": "/candidate-dashboard",
}

FRONTEND_URL = "http://localhost:3000"  # Update for production


# ------------------- Configuration Validation -------------------
def validate_sso_config(app):
    """Validate all required SSO configuration is present and metadata URL accessible."""
    required_configs = ["SSO_CLIENT_ID", "SSO_CLIENT_SECRET", "SSO_METADATA_URL"]
    missing = [config for config in required_configs if not app.config.get(config)]
    if missing:
        app.logger.error(f"Missing SSO configuration: {missing}")
        return False

    metadata_url = app.config["SSO_METADATA_URL"]
    try:
        resp = requests.get(metadata_url, timeout=10)
        if resp.status_code != 200:
            app.logger.error(f"SSO metadata URL not accessible: {metadata_url} - Status: {resp.status_code}")
            return False
        app.logger.info("SSO metadata URL is accessible")
    except Exception as e:
        app.logger.error(f"Failed to access SSO metadata URL: {str(e)}")
        return False

    return True


# ------------------- Redirect URI -------------------
def get_redirect_uri():
    """Return callback URL for SSO provider."""
    if current_app.config.get("DEBUG") or current_app.config.get("TESTING"):
        return url_for("sso_bp.sso_callback", _external=True)
    prod_domain = current_app.config.get("PRODUCTION_DOMAIN")
    if prod_domain:
        return f"{prod_domain}/api/auth/sso/callback"
    return url_for("sso_bp.sso_callback", _external=True)


# ------------------- Register SSO Provider -------------------
def register_sso_provider(app):
    """Register the Keycloak OAuth provider."""
    try:
        if not hasattr(app, "oauth_initialized"):
            oauth.init_app(app)
            app.oauth_initialized = True

        if not validate_sso_config(app):
            app.logger.error("SSO config invalid. Skipping registration.")
            return False

        oauth.register(
            name="keycloak",
            client_id=app.config["SSO_CLIENT_ID"],
            client_secret=app.config["SSO_CLIENT_SECRET"],
            server_metadata_url=app.config["SSO_METADATA_URL"],
            client_kwargs={
                "scope": "openid profile email",
                "code_challenge_method": "S256"
            }
        )
        app.logger.info("SSO provider registered successfully")
        return True
    except Exception:
        app.logger.error("Failed to register SSO provider:\n%s", traceback.format_exc())
        return False


# ------------------- SSO Login -------------------
@sso_bp.route("/api/auth/sso")
def sso_login():
    try:
        current_app.logger.info(f"OAuth clients registered: {list(oauth._clients.keys())}")
        if "keycloak" not in oauth._clients:
            return jsonify({"error": "SSO not configured"}), 500

        redirect_uri = get_redirect_uri()
        nonce = secrets.token_urlsafe(16)
        session['oauth_nonce'] = nonce
        current_app.logger.info(f"Redirecting to SSO provider. Redirect URI: {redirect_uri}, Nonce: {nonce}")
        return oauth.keycloak.authorize_redirect(redirect_uri, nonce=nonce)
    except Exception:
        current_app.logger.error("SSO login initiation failed:\n%s", traceback.format_exc())
        return jsonify({"error": "SSO login failed"}), 500


# ------------------- SSO Callback (Fixed) -------------------
@sso_bp.route("/api/auth/sso/callback")
def sso_callback():
    try:
        # ----- Handle error from SSO provider -----
        error = request.args.get("error")
        error_description = request.args.get("error_description")
        if error:
            msg = urllib.parse.quote(error_description or error)
            return redirect(f"{FRONTEND_URL}/login?error={msg}")

        # ----- Get access token & parse user info -----
        token = oauth.keycloak.authorize_access_token()
        if not token:
            return redirect(f"{FRONTEND_URL}/login?error=Failed to obtain access token")

        nonce = session.pop("oauth_nonce", None) or secrets.token_urlsafe(16)
        user_info = oauth.keycloak.parse_id_token(token, nonce=nonce)

        if not user_info or "email" not in user_info:
            return redirect(f"{FRONTEND_URL}/login?error=Failed to parse user info")

        email = user_info["email"].strip().lower()
        first_name = user_info.get("given_name", "")
        last_name = user_info.get("family_name", "")
        sso_id = user_info.get("sub")

        # ----- Lookup or create user -----
        user = User.query.filter(db.func.lower(User.email) == email).first()
        user_created = False

        if not user:
            random_password = secrets.token_urlsafe(16)
            user = AuthService.create_user(email=email, password=random_password, role="candidate")
            user.profile = {"first_name": first_name, "last_name": last_name}
            user.is_verified = True
            db.session.commit()
            user_created = True
        else:
            profile = user.profile or {}
            profile.setdefault("first_name", first_name)
            profile.setdefault("last_name", last_name)
            user.profile = profile
            db.session.commit()

        # ----- Ensure Candidate record exists -----
        candidate = Candidate.query.filter_by(user_id=user.id).first()
        if not candidate:
            candidate = Candidate(user_id=user.id)
            db.session.add(candidate)
            db.session.commit()
            current_app.logger.info(f"Created missing candidate for SSO user id {user.id}")

        # ----- OAuth connection record -----
        oauth_conn = OAuthConnection.query.filter_by(user_id=user.id, provider="sso").first()
        if not oauth_conn:
            oauth_conn = OAuthConnection(
                user_id=user.id,
                provider="sso",
                provider_user_id=sso_id,
                access_token=secrets.token_urlsafe(32)
            )
            db.session.add(oauth_conn)
            db.session.commit()

        # ----- Generate JWT with all roles -----
        roles = [user.role]
        if Candidate.query.filter_by(user_id=user.id).first() and "candidate" not in roles:
            roles.append("candidate")

        # ------------------- JWT Tokens -------------------
        # Match the regular login JWT format: single 'role' string
        additional_claims = {"role": user.role}  # user.role is already 'admin', 'candidate', or 'hiring_manager'
        access_token = create_access_token(identity=str(user.id), additional_claims=additional_claims)
        refresh_token = create_refresh_token(identity=str(user.id), additional_claims=additional_claims)


        # ----- Determine dashboard path -----
        dashboard_path = (
            "/enrollment"
            if "candidate" in roles and not getattr(user, "enrollment_completed", False)
            else ROLE_DASHBOARD_MAP.get(user.role, "/dashboard")
        )
        if dashboard_path.startswith("/api/"):
            dashboard_path = dashboard_path.replace("/api", "", 1)

        # ----- Audit log -----
        AuditService.record_action(
            admin_id=user.id,
            action="sso_login",
            extra_data={"provider": "keycloak", "user_created": user_created}
        )

        # ----- Redirect to frontend with tokens -----
        query_params = {
            "access_token": access_token,
            "refresh_token": refresh_token,
            "id": user.id,
            "email": user.email,
            "role": user.role,
            "first_name": user.profile.get("first_name"),
            "last_name": user.profile.get("last_name"),
            "enrollment_completed": getattr(user, "enrollment_completed", False),
            "dashboard": dashboard_path
        }

        redirect_url = f"{FRONTEND_URL}/sso-redirect?{urllib.parse.urlencode(query_params)}"
        return redirect(redirect_url)

    except Exception:
        current_app.logger.error("SSO callback failed:\n%s", traceback.format_exc())
        db.session.rollback()
        return redirect(f"{FRONTEND_URL}/login?error={urllib.parse.quote('SSO callback failed')}")


# ------------------- SSO Status -------------------
@sso_bp.route("/api/auth/sso/status")
def sso_status():
    try:
        status = {
            "configured": "keycloak" in oauth._clients,
            "metadata_url": current_app.config.get("SSO_METADATA_URL", ""),
            "client_id": current_app.config.get("SSO_CLIENT_ID", ""),
            "redirect_uri": get_redirect_uri()
        }

        if status["configured"]:
            try:
                resp = requests.get(status["metadata_url"], timeout=5)
                status["metadata_accessible"] = resp.status_code == 200
            except:
                status["metadata_accessible"] = False

        return jsonify(status), 200
    except Exception:
        current_app.logger.error("SSO status check failed:\n%s", traceback.format_exc())
        return jsonify({"error": "Status check failed"}), 500
    
# ------------------- SSO Logout -------------------
@sso_bp.route("/api/auth/sso/logout", methods=["GET"])
def sso_logout():
    try:
        # Keycloak logout endpoint from provider metadata
        metadata_url = current_app.config.get("SSO_METADATA_URL")
        if not metadata_url:
            return jsonify({"error": "Missing SSO metadata URL"}), 500

        # Fetch provider end_session_endpoint dynamically
        metadata = requests.get(metadata_url).json()
        end_session_endpoint = metadata.get("end_session_endpoint")

        if not end_session_endpoint:
            return jsonify({"error": "SSO provider does not expose logout endpoint"}), 500

        # ID Token is required by many providers (Keycloak, Azure AD)
        id_token = request.args.get("id_token")

        # Where the SSO provider should redirect after logout
        post_logout = f"{FRONTEND_URL}/login"

        # Construct final logout URL
        logout_url = (
            f"{end_session_endpoint}"
            f"?post_logout_redirect_uri={urllib.parse.quote(post_logout)}"
        )

        if id_token:
            logout_url += f"&id_token_hint={id_token}"

        # Clear Flask session
        session.clear()

        # Redirect user to provider logout
        return redirect(logout_url)

    except Exception:
        current_app.logger.error("SSO logout failed:\n%s", traceback.format_exc())
        return jsonify({"error": "SSO logout failed"}), 500

