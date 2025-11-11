from flask import Blueprint, request, jsonify, current_app
from flask_jwt_extended import jwt_required, get_jwt_identity, create_access_token, decode_token, create_refresh_token
from app.models import db, User
from app.services.auth_service import AuthService
from app.services.audit2 import AuditService
from io import BytesIO
import pyotp
import qrcode
import base64
from datetime import timedelta

mfa_bp = Blueprint('mfa', __name__)


ROLE_DASHBOARD_MAP = {
    "admin": "/admin-dashboard",
    "hiring_manager": "/hiring-manager-dashboard",
    "candidate": "/candidate-dashboard",
}


@mfa_bp.route('/mfa/enable', methods=['POST'])
@jwt_required()
def enable_mfa():
    """Enable MFA for user"""
    try:
        current_user_id = get_jwt_identity()
        user = User.query.get(current_user_id)
        
        if user.mfa_enabled:
            return jsonify({'error': 'MFA is already enabled'}), 400

        # Generate TOTP secret using AuthService
        secret = AuthService.generate_mfa_secret()
        user.mfa_secret = secret
        user.mfa_verified = False
        db.session.commit()

        # Generate otpauth URL for authenticator apps
        totp = pyotp.TOTP(secret)
        otpauth_url = totp.provisioning_uri(name=user.email, issuer_name=current_app.config.get('APP_NAME', 'MyApp'))

        # Generate QR code
        qr = qrcode.QRCode(version=1, box_size=10, border=5)
        qr.add_data(otpauth_url)
        qr.make(fit=True)
        img = qr.make_image(fill_color="black", back_color="white")
        buffered = BytesIO()
        img.save(buffered, format="PNG")
        qr_code_base64 = base64.b64encode(buffered.getvalue()).decode()

        AuditService.log(user_id=user.id, action="mfa_enable_initiated")

        return jsonify({
            'secret': secret,
            'qr_code': f"data:image/png;base64,{qr_code_base64}",
            'otpauth_url': otpauth_url
        }), 200

    except Exception as e:
        db.session.rollback()
        current_app.logger.error(f"MFA enable error: {str(e)}")
        return jsonify({'error': 'Internal server error'}), 500

@mfa_bp.route('/mfa/verify', methods=['POST'])
@jwt_required()
def verify_mfa_setup():
    """Verify MFA setup with a token"""
    try:
        current_user_id = get_jwt_identity()
        data = request.get_json()
        token = data.get('token')
        if not token:
            return jsonify({'error': 'Token is required'}), 400

        user = User.query.get(current_user_id)
        if not user.mfa_secret:
            return jsonify({'error': 'MFA setup not initiated'}), 400
        if user.mfa_enabled:
            return jsonify({'error': 'MFA is already enabled'}), 400

        # Use AuthService to enable MFA
        if AuthService.enable_mfa_for_user(user, user.mfa_secret, token):
            unused_codes = AuthService.get_remaining_backup_codes(user)
            AuditService.log(user_id=user.id, action="mfa_enabled")
            
            return jsonify({
                'message': 'MFA enabled successfully',
                'backup_codes': unused_codes
            }), 200
        else:
            AuditService.log(user_id=user.id, action="mfa_verification_failed")
            return jsonify({'error': 'Invalid verification code'}), 400

    except Exception as e:
        db.session.rollback()
        current_app.logger.error(f"MFA verify error: {str(e)}")
        return jsonify({'error': 'Internal server error'}), 500

@mfa_bp.route('/mfa/login', methods=['POST'])
def mfa_login():
    """MFA verification step during login"""
    try:
        data = request.get_json()
        mfa_session_token = data.get('mfa_session_token')
        token = data.get('token')

        if not mfa_session_token or not token:
            return jsonify({'error': 'MFA session token and verification token are required'}), 400

        # Verify the MFA session token
        try:
            claims = decode_token(mfa_session_token)
            if not claims.get('mfa_pending'):
                return jsonify({'error': 'Invalid MFA session'}), 401
            user_id = claims['sub']
        except Exception as e:
            current_app.logger.error(f"MFA session token decode error: {str(e)}")
            return jsonify({'error': 'Invalid or expired MFA session'}), 401

        user = User.query.get(user_id)
        if not user or not user.mfa_enabled:
            return jsonify({'error': 'MFA not enabled for this user'}), 400

        # Use AuthService to validate MFA login
        result = AuthService.validate_mfa_login(user, token)
        if not result['success']:
            AuditService.log(user_id=user.id, action="mfa_login_failed")
            return jsonify({'error': result['error']}), 400

        # Create final JWT tokens
        additional_claims = {"role": user.role}
        access_token = create_access_token(identity=str(user.id), additional_claims=additional_claims)
        refresh_token = create_refresh_token(identity=str(user.id), additional_claims=additional_claims)

        db.session.commit()

        AuditService.log(
            user_id=user.id, 
            action="mfa_login_success",
            details=f"used_backup_code: {result.get('is_backup_code', False)}"
        )
        
        # Determine dashboard route
        dashboard_path = "/enrollment" if user.role == "candidate" and not getattr(user, "enrollment_completed", False) \
            else ROLE_DASHBOARD_MAP.get(user.role, "/dashboard")

        return jsonify({
            'message': 'MFA verification successful',
            'access_token': access_token,
            'refresh_token': refresh_token,
            'user': user.to_dict(),
            'used_backup_code': result.get('is_backup_code', False),
            'dashboard': dashboard_path  # <-- add this
        }), 200

    except Exception as e:
        db.session.rollback()
        current_app.logger.error(f"MFA login error: {str(e)}")
        return jsonify({'error': 'Internal server error'}), 500

@mfa_bp.route('/mfa/disable', methods=['POST'])
@jwt_required()
def disable_mfa():
    """Disable MFA for user"""
    try:
        current_user_id = get_jwt_identity()
        data = request.get_json()
        password = data.get('password')
        if not password:
            return jsonify({'error': 'Password is required to disable MFA'}), 400

        user = User.query.get(current_user_id)
        
        # Use AuthService to disable MFA
        if AuthService.disable_mfa_for_user(user, password):
            AuditService.log(user_id=user.id, action="mfa_disabled")
            return jsonify({'message': 'MFA disabled successfully'}), 200
        else:
            AuditService.log(user_id=user.id, action="mfa_disable_failed_wrong_password")
            return jsonify({'error': 'Invalid password'}), 401

    except Exception as e:
        db.session.rollback()
        current_app.logger.error(f"MFA disable error: {str(e)}")
        return jsonify({'error': 'Internal server error'}), 500

@mfa_bp.route('/mfa/backup-codes', methods=['GET'])
@jwt_required()
def get_backup_codes():
    """Get current backup codes"""
    try:
        current_user_id = get_jwt_identity()
        user = User.query.get(current_user_id)

        if not user.mfa_enabled:
            return jsonify({'error': 'MFA is not enabled'}), 400

        unused_codes = AuthService.get_remaining_backup_codes(user)
        return jsonify({'backup_codes': unused_codes}), 200

    except Exception as e:
        current_app.logger.error(f"Get backup codes error: {str(e)}")
        return jsonify({'error': 'Internal server error'}), 500

@mfa_bp.route('/mfa/regenerate-backup-codes', methods=['POST'])
@jwt_required()
def regenerate_backup_codes():
    """Regenerate backup codes"""
    try:
        current_user_id = get_jwt_identity()
        user = User.query.get(current_user_id)

        if not user.mfa_enabled:
            return jsonify({'error': 'MFA is not enabled'}), 400

        if AuthService.regenerate_backup_codes(user):
            unused_codes = AuthService.get_remaining_backup_codes(user)
            AuditService.log(user_id=user.id, action="mfa_backup_codes_regenerated")
            return jsonify({
                'message': 'Backup codes regenerated successfully',
                'backup_codes': unused_codes
            }), 200
        else:
            return jsonify({'error': 'Failed to regenerate backup codes'}), 500

    except Exception as e:
        db.session.rollback()
        current_app.logger.error(f"Regenerate backup codes error: {str(e)}")
        return jsonify({'error': 'Internal server error'}), 500

@mfa_bp.route('/mfa/status', methods=['GET'])
@jwt_required()
def mfa_status():
    """Get MFA status for current user"""
    try:
        current_user_id = get_jwt_identity()
        user = User.query.get(current_user_id)
        
        unused_codes = AuthService.get_remaining_backup_codes(user)
        
        return jsonify({
            'mfa_enabled': user.mfa_enabled,
            'mfa_verified': user.mfa_verified,
            'backup_codes_remaining': len(unused_codes)
        }), 200

    except Exception as e:
        current_app.logger.error(f"MFA status error: {str(e)}")
        return jsonify({'error': 'Internal server error'}), 500