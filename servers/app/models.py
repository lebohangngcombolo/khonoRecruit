from app.extensions import db
from datetime import datetime
from sqlalchemy.dialects.postgresql import JSON

class User(db.Model):
    __tablename__ = 'users'
    id = db.Column(db.Integer, primary_key=True)
    email = db.Column(db.String(150), unique=True, nullable=False)
    password = db.Column(db.String(200), nullable=False)
    role = db.Column(db.String(50), default='candidate')  # candidate, hiring_manager, admin
    profile = db.Column(JSON, default={})
    is_verified = db.Column(db.Boolean, default=False)
    created_at = db.Column(db.DateTime, default=datetime.utcnow)

    def to_dict(self):
        return {
            "id": self.id,
            "email": self.email,
            "role": self.role,
            "profile": self.profile,
            "is_verified": self.is_verified,
            "created_at": self.created_at.isoformat()
        }

class Requisition(db.Model):
    __tablename__ = 'requisitions'
    id = db.Column(db.Integer, primary_key=True)
    title = db.Column(db.String(150), nullable=False)
    description = db.Column(db.Text)
    required_skills = db.Column(JSON, default=[])
    min_experience = db.Column(db.Float, default=0)
    knockout_rules = db.Column(JSON, default=[])
    weightings = db.Column(JSON, default={'cv': 60, 'assessment': 40})
    created_by = db.Column(db.Integer, db.ForeignKey('users.id'))
    created_at = db.Column(db.DateTime, default=datetime.utcnow)

    def to_dict(self):
        return {
            "id": self.id,
            "title": self.title,
            "description": self.description,
            "required_skills": self.required_skills,
            "min_experience": self.min_experience,
            "knockout_rules": self.knockout_rules,
            "weightings": self.weightings,
            "created_by": self.created_by,
            "created_at": self.created_at.isoformat()
        }

class Candidate(db.Model):
    __tablename__ = 'candidates'
    id = db.Column(db.Integer, primary_key=True)
    user_id = db.Column(db.Integer, db.ForeignKey('users.id'))
    cv_url = db.Column(db.String(500))
    cv_text = db.Column(db.Text)
    profile = db.Column(JSON, default={})

    def to_dict(self):
        return {
            "id": self.id,
            "user_id": self.user_id,
            "cv_url": self.cv_url,
            "cv_text": self.cv_text,
            "profile": self.profile
        }

class Application(db.Model):
    __tablename__ = 'applications'
    id = db.Column(db.Integer, primary_key=True)
    candidate_id = db.Column(db.Integer, db.ForeignKey('candidates.id'))
    requisition_id = db.Column(db.Integer, db.ForeignKey('requisitions.id'))
    status = db.Column(db.String(50), default='applied')
    assessment_score = db.Column(db.Float, default=0)
    overall_score = db.Column(db.Float, default=0)
    recommendation = db.Column(db.String(50))
    assessed_date = db.Column(db.DateTime)
    created_at = db.Column(db.DateTime, default=datetime.utcnow)

    def to_dict(self):
        return {
            "id": self.id,
            "candidate_id": self.candidate_id,
            "requisition_id": self.requisition_id,
            "status": self.status,
            "assessment_score": self.assessment_score,
            "overall_score": self.overall_score,
            "recommendation": self.recommendation,
            "assessed_date": self.assessed_date.isoformat() if self.assessed_date else None,
            "created_at": self.created_at.isoformat()
        }

class AssessmentResult(db.Model):
    __tablename__ = 'assessment_results'
    id = db.Column(db.Integer, primary_key=True)
    application_id = db.Column(db.Integer, db.ForeignKey('applications.id'), nullable=False)
    scores = db.Column(JSON, default={})
    total_score = db.Column(db.Float, default=0)
    recommendation = db.Column(db.String(50))
    assessed_at = db.Column(db.DateTime, default=datetime.utcnow)

    application = db.relationship('Application', backref=db.backref('assessment_results', lazy=True))

    def to_dict(self):
        return {
            "id": self.id,
            "application_id": self.application_id,
            "scores": self.scores,
            "total_score": self.total_score,
            "recommendation": self.recommendation,
            "assessed_at": self.assessed_at.isoformat()
        }

class VerificationCode(db.Model):
    __tablename__ = 'verification_codes'
    id = db.Column(db.Integer, primary_key=True)
    email = db.Column(db.String(150), nullable=False)
    code = db.Column(db.String(10), nullable=False)
    is_used = db.Column(db.Boolean, default=False)
    created_at = db.Column(db.DateTime, default=datetime.utcnow)
    expires_at = db.Column(db.DateTime, nullable=False)

    def is_valid(self):
        return not self.is_used and datetime.utcnow() < self.expires_at

    def to_dict(self):
        return {
            "id": self.id,
            "email": self.email,
            "code": self.code,
            "is_used": self.is_used,
            "created_at": self.created_at.isoformat(),
            "expires_at": self.expires_at.isoformat()
        }
