# app/utils/helpers.py

from flask import current_app
from flask_jwt_extended import get_jwt_identity
from app.models import Candidate, User
from app.extensions import db

# ------------------ Candidate Helpers ------------------

def get_current_candidate(auto_create: bool = True) -> Candidate:
    """
    Returns the Candidate object associated with the current JWT identity.
    If auto_create=True, will create a Candidate for a user if missing.
    """
    user_id = get_jwt_identity()
    if not user_id:
        current_app.logger.error("JWT identity not found.")
        return None

    user = User.query.get(user_id)
    if not user:
        current_app.logger.error(f"User not found for id {user_id}")
        return None

    candidate = Candidate.query.filter_by(user_id=user.id).first()

    if not candidate and auto_create:
        # Auto-create Candidate row for admins, hiring_managers, or missing candidates
        candidate = Candidate(user_id=user.id)
        db.session.add(candidate)
        try:
            db.session.commit()
            current_app.logger.info(f"Auto-created candidate for user id {user.id}")
        except Exception as e:
            db.session.rollback()
            current_app.logger.error(f"Failed to auto-create candidate for user {user.id}: {e}")
            return None

    if not candidate:
        current_app.logger.error(f"Candidate not found for user id {user_id}")
        return None

    return candidate

# ------------------ Additional Utilities ------------------

def safe_commit():
    """
    Commits the current transaction safely.
    Rolls back and logs if there is an exception.
    """
    try:
        db.session.commit()
        return True
    except Exception as e:
        db.session.rollback()
        current_app.logger.error(f"Database commit failed: {e}", exc_info=True)
        return False

def update_object_from_dict(obj, data: dict):
    """
    Update attributes of a SQLAlchemy model object from a dictionary.
    Only updates existing attributes.
    """
    for key, value in data.items():
        if hasattr(obj, key):
            setattr(obj, key, value)
