import pyotp
import qrcode
import io
import base64
from datetime import datetime
from app.extensions import db
from app.models import User


class MFAService:
    """Handles TOTP-based Multi-Factor Authentication for users."""

    @staticmethod
    def generate_secret():
        """Generate a new TOTP secret."""
        return pyotp.random_base32()

    @staticmethod
    def get_qr_code_uri(email, secret, issuer_name="TalentRecruiter"):
        """
        Create a URI that can be scanned by Google Authenticator or Authy.
        Example: otpauth://totp/TalentRecruiter:email?secret=SECRET&issuer=TalentRecruiter
        """
        totp = pyotp.TOTP(secret)
        return totp.provisioning_uri(name=email, issuer_name=issuer_name)

    @staticmethod
    def generate_qr_code_image(uri):
        """Return a base64-encoded PNG QR code image."""
        qr = qrcode.make(uri)
        buffer = io.BytesIO()
        qr.save(buffer, format="PNG")
        return base64.b64encode(buffer.getvalue()).decode()

    @staticmethod
    def verify_token(secret, token):
        """Verify a user-entered TOTP token."""
        totp = pyotp.TOTP(secret)
        # valid_window=1 allows for small clock drift
        return totp.verify(token, valid_window=1)

    # ------------------- User-specific Helpers -------------------
    @staticmethod
    def initiate_mfa_setup(user: User):
        """
        Generate a new secret and QR code for user MFA setup.
        Stores the secret temporarily until verified.
        """
        secret = MFAService.generate_secret()
        uri = MFAService.get_qr_code_uri(user.email, secret)
        qr_image = MFAService.generate_qr_code_image(uri)

        # Update user record with secret (but not yet enabled)
        user.mfa_secret = secret
        user.mfa_verified = False
        db.session.commit()

        return {
            "secret": secret,
            "qr_image": qr_image,
            "uri": uri
        }

    @staticmethod
    def confirm_mfa_setup(user: User, token: str):
        """
        Confirm MFA setup by verifying token.
        If valid, mark MFA as enabled and verified.
        """
        if not user.mfa_secret:
            return {"success": False, "message": "No MFA secret found for user."}

        if MFAService.verify_token(user.mfa_secret, token):
            user.mfa_enabled = True
            user.mfa_verified = True
            db.session.commit()
            return {"success": True, "message": "MFA successfully enabled."}
        else:
            return {"success": False, "message": "Invalid verification code."}

    @staticmethod
    def disable_mfa(user: User):
        """Disable MFA and clear TOTP secret."""
        user.mfa_enabled = False
        user.mfa_verified = False
        user.mfa_secret = None
        db.session.commit()
        return {"success": True, "message": "MFA has been disabled."}

    @staticmethod
    def verify_login_mfa(user: User, token: str):
        """
        Validate MFA during login (if enabled).
        Returns True if valid, False otherwise.
        """
        if not user.mfa_enabled or not user.mfa_secret:
            return True  # MFA not required
        return MFAService.verify_token(user.mfa_secret, token)
