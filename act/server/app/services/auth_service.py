import bcrypt
from app.extensions import db
from app.models import User
from flask import current_app
import jwt
from datetime import datetime, timedelta
from app.extensions import redis_client
import pyotp
from flask_jwt_extended import create_access_token, create_refresh_token
import secrets
import string
import logging


class AuthService:

    @staticmethod
    def hash_password(password: str) -> str:
        """Hash a plain-text password."""
        salt = bcrypt.gensalt()
        hashed = bcrypt.hashpw(password.encode('utf-8'), salt)
        return hashed.decode('utf-8')

    @staticmethod
    def verify_password(password: str, hashed_password: str) -> bool:
        """Verify a plain-text password against a hash."""
        return bcrypt.checkpw(password.encode('utf-8'), hashed_password.encode('utf-8'))

    @staticmethod
    def create_user(email: str, password: str, first_name: str, last_name: str, role: str = 'candidate') -> User:
        """Create a new user and save to DB."""
        hashed_password = AuthService.hash_password(password)
        user = User(
            email=email.strip().lower(),
            password=hashed_password,      # ✅ correct column
            role=role,
            profile={"first_name": first_name, "last_name": last_name}  # store names in JSON
        )
        try:
            db.session.add(user)
            db.session.commit()
        except Exception as e:
            db.session.rollback()
            current_app.logger.error(f'Failed to create user: {str(e)}', exc_info=True)
            raise e
        return user

    @staticmethod
    def validate_user_credentials(email: str, password: str):
        """Return user if credentials are valid."""
        user = User.query.filter(db.func.lower(User.email) == email.strip().lower()).first()
        if user and AuthService.verify_password(password, user.password):
            return user
        return None

    @staticmethod
    def generate_password_reset_token(user_id: int) -> str:
        """Generate JWT token for password reset and store in Redis."""
        payload = {
            "user_id": user_id,
            "exp": datetime.utcnow() + timedelta(hours=1),
            "type": "password_reset"
        }
        token = jwt.encode(payload, current_app.config['JWT_SECRET_KEY'], algorithm='HS256')
        if isinstance(token, bytes):
            token = token.decode('utf-8')
        redis_client.setex(f"password_reset:{token}", 3600, user_id)
        return token

    @staticmethod
    def verify_password_reset_token(token: str):
        """Verify JWT token from Redis for password reset."""
        try:
            user_id = redis_client.get(f"password_reset:{token}")
            if not user_id:
                return None
            payload = jwt.decode(token, current_app.config['JWT_SECRET_KEY'], algorithms=['HS256'])
            if payload.get("type") != "password_reset":
                return None
            redis_client.delete(f"password_reset:{token}")
            return int(user_id)
        except jwt.ExpiredSignatureError:
            redis_client.delete(f"password_reset:{token}")
            return None
        except jwt.InvalidTokenError:
            return None

    @staticmethod
    def verify_otp(user, otp: str) -> bool:
        """
        Verifies the OTP entered by the user using their stored MFA secret.
        Returns True if valid, False otherwise.
        """
        if not user:
            logging.warning("OTP verification failed: user is None")
            return False

        if not user.mfa_secret:
            logging.warning(f"OTP verification failed: user {user.email} has no MFA secret")
            return False

        try:
            totp = pyotp.TOTP(user.mfa_secret)
            # Valid for ±1 time step (30s each)
            if totp.verify(otp, valid_window=1):
                logging.info(f"OTP verified successfully for user {user.email}")
                return True
            else:
                logging.warning(f"Invalid OTP for user {user.email}")
                return False
        except Exception as e:
            logging.error(f"OTP verification error for user {user.email if user else 'Unknown'}: {e}")
            return False
        
    @staticmethod
    def generate_tokens(user):
        """
        Generates access and refresh tokens for a given user.
        Returns a dictionary with 'access_token' and 'refresh_token'.
        """
        try:
            access_token = create_access_token(
                identity=user.id,
                additional_claims={"role": user.role},
                expires_delta=timedelta(hours=1)
            )
            refresh_token = create_refresh_token(
                identity=user.id,
                additional_claims={"role": user.role},
                expires_delta=timedelta(days=7)
            )
            return {"access_token": access_token, "refresh_token": refresh_token}
        except Exception as e:
            print(f"Token generation error: {e}")
            return None
        
        
    @staticmethod
    def generate_mfa_secret() -> str:
        """Generate a new TOTP secret for MFA."""
        return pyotp.random_base32()

    @staticmethod
    def verify_totp(secret: str, token: str) -> bool:
        """
        Verify TOTP token against secret.
        Uses valid_window=1 to allow for time sync issues.
        """
        try:
            totp = pyotp.TOTP(secret)
            return totp.verify(token, valid_window=1)
        except Exception as e:
            logging.error(f"TOTP verification error: {e}")
            return False

    @staticmethod
    def generate_backup_codes(count: int = 10) -> list:
        """Generate backup codes for MFA recovery."""
        codes = []
        for _ in range(count):
            code = ''.join(secrets.choice(string.ascii_uppercase + string.digits) for _ in range(10))
            codes.append({'code': code, 'used': False})
        return codes

    @staticmethod
    def verify_backup_code(user: User, token: str) -> bool:
        """
        Verify if token is a valid backup code.
        Marks the code as used if valid.
        """
        if not user.mfa_backup_codes:
            return False

        for code_data in user.mfa_backup_codes:
            if not code_data['used'] and code_data['code'] == token:
                code_data['used'] = True
                return True
        return False

    @staticmethod
    def create_mfa_session_token(user_id: int, role: str) -> str:
        """
        Create a temporary token for MFA verification during login.
        Short-lived (5 minutes) and only for MFA purposes.
        """
        return create_access_token(
            identity=str(user_id),
            expires_delta=timedelta(minutes=5),
            additional_claims={"mfa_pending": True, "role": role}
        )

    @staticmethod
    def validate_mfa_login(user: User, token: str) -> dict:
        """
        Validate MFA token during login.
        Returns dict with success status and backup code usage info.
        """
        if not user.mfa_enabled:
            return {"success": False, "error": "MFA not enabled"}

        # Check if it's a backup code first
        is_backup_code = AuthService.verify_backup_code(user, token)
        
        if is_backup_code:
            return {
                "success": True, 
                "is_backup_code": True,
                "message": "Backup code accepted"
            }

        # Verify as TOTP code
        if AuthService.verify_totp(user.mfa_secret, token):
            return {
                "success": True,
                "is_backup_code": False,
                "message": "TOTP code accepted"
            }

        return {
            "success": False, 
            "error": "Invalid MFA code"
        }

    @staticmethod
    def enable_mfa_for_user(user: User, secret: str, verification_token: str) -> bool:
        """
        Enable MFA for a user after verifying the initial token.
        """
        if not AuthService.verify_totp(secret, verification_token):
            return False

        user.mfa_secret = secret
        user.mfa_enabled = True
        user.mfa_verified = True
        user.mfa_backup_codes = AuthService.generate_backup_codes()
        
        try:
            db.session.commit()
            return True
        except Exception as e:
            db.session.rollback()
            logging.error(f"Failed to enable MFA for user {user.id}: {e}")
            return False

    @staticmethod
    def disable_mfa_for_user(user: User, password: str) -> bool:
        """
        Disable MFA for a user after password verification.
        """
        if not AuthService.verify_password(password, user.password):
            return False

        user.mfa_enabled = False
        user.mfa_verified = False
        user.mfa_secret = None
        user.mfa_backup_codes = None
        
        try:
            db.session.commit()
            return True
        except Exception as e:
            db.session.rollback()
            logging.error(f"Failed to disable MFA for user {user.id}: {e}")
            return False

    @staticmethod
    def get_remaining_backup_codes(user: User) -> list:
        """Get list of unused backup codes."""
        if not user.mfa_backup_codes:
            return []
        return [c['code'] for c in user.mfa_backup_codes if not c['used']]

    @staticmethod
    def regenerate_backup_codes(user: User) -> bool:
        """Regenerate all backup codes for a user."""
        user.mfa_backup_codes = AuthService.generate_backup_codes()
        try:
            db.session.commit()
            return True
        except Exception as e:
            db.session.rollback()
            logging.error(f"Failed to regenerate backup codes for user {user.id}: {e}")
            return False