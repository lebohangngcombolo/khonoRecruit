import pyotp
import qrcode
import io
import base64

class MFAService:
    @staticmethod
    def generate_secret():
        """Create a new base32 TOTP secret."""
        return pyotp.random_base32()

    @staticmethod
    def get_qr_code_uri(email, secret, issuer_name="TalentRecruiter"):
        """Generate a URI for Google Authenticator."""
        totp = pyotp.TOTP(secret)
        return totp.provisioning_uri(name=email, issuer_name=issuer_name)

    @staticmethod
    def generate_qr_code_image(uri):
        """Generate a base64 QR code image."""
        qr = qrcode.make(uri)
        buffer = io.BytesIO()
        qr.save(buffer, format="PNG")
        return base64.b64encode(buffer.getvalue()).decode()

    @staticmethod
    def verify_token(secret, token):
        """Check if user-entered code is valid."""
        totp = pyotp.TOTP(secret)
        return totp.verify(token, valid_window=1)
