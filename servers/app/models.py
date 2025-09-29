from app.extensions import db
from datetime import datetime
from sqlalchemy.dialects.postgresql import JSON

# ------------------- USER -------------------
class User(db.Model):
    __tablename__ = 'users'
    id = db.Column(db.Integer, primary_key=True)
    email = db.Column(db.String(150), unique=True, nullable=False)
    password = db.Column(db.String(200), nullable=False)
    role = db.Column(db.String(50), default='candidate')  # candidate, hiring_manager, admin
    profile = db.Column(JSON, default={})
    is_verified = db.Column(db.Boolean, default=False)
    enrollment_completed = db.Column(db.Boolean, default=False)  # ✅ new flag
    created_at = db.Column(db.DateTime, default=datetime.utcnow)

    candidates = db.relationship('Candidate', backref='user', lazy=True)
    notifications = db.relationship('Notification', backref='user', lazy=True)

    def to_dict(self):
        return {
            "id": self.id,
            "email": self.email,
            "role": self.role,
            "profile": self.profile,
            "is_verified": self.is_verified,
            "enrollment_completed": self.enrollment_completed,
            "created_at": self.created_at.isoformat()
        }

# ------------------- REQUISITION -------------------
class Requisition(db.Model):
    __tablename__ = 'requisitions'
    id = db.Column(db.Integer, primary_key=True)
    title = db.Column(db.String(150), nullable=False)
    description = db.Column(db.Text)
    required_skills = db.Column(JSON, default=[])
    min_experience = db.Column(db.Float, default=0)
    knockout_rules = db.Column(JSON, default=[])
    weightings = db.Column(JSON, default={'cv': 60, 'assessment': 40})
    assessment_pack = db.Column(JSON, default={"questions": []})
    created_by = db.Column(db.Integer, db.ForeignKey('users.id'))
    created_at = db.Column(db.DateTime, default=datetime.utcnow)
    published_on = db.Column(db.DateTime, default=datetime.utcnow)
    vacancy = db.Column(db.Integer, default=1)

    def to_dict(self):
        return {
            "id": self.id,
            "title": self.title,
            "description": self.description,
            "required_skills": self.required_skills,
            "min_experience": self.min_experience,
            "knockout_rules": self.knockout_rules,
            "weightings": self.weightings,
            "assessment_pack": self.assessment_pack,
            "created_by": self.created_by,
            "created_at": self.created_at.isoformat()
        }

# ------------------- CANDIDATE -------------------
class Candidate(db.Model):
    __tablename__ = 'candidates'
    id = db.Column(db.Integer, primary_key=True)
    user_id = db.Column(db.Integer, db.ForeignKey('users.id'))
    cv_url = db.Column(db.String(500))
    cv_text = db.Column(db.Text)

    # ✅ Expanded fields for enrollment
    full_name = db.Column(db.String(150))
    phone = db.Column(db.String(50))
    education = db.Column(JSON, default=[])       # list of schools/degrees
    skills = db.Column(JSON, default=[])          # list of skills
    work_experience = db.Column(JSON, default=[]) # list of jobs/roles
    cv_score = db.Column(db.Integer, default=0)
    profile = db.Column(JSON, default={})

    applications = db.relationship('Application', backref='candidate', lazy=True)
    interviews = db.relationship('Interview', backref='candidate', lazy=True)

    def to_dict(self):
        return {
            "id": self.id,
            "user_id": self.user_id,
            "cv_url": self.cv_url,
            "cv_text": self.cv_text,
            "full_name": self.full_name,
            "phone": self.phone,
            "education": self.education,
            "skills": self.skills,
            "work_experience": self.work_experience,
            "profile": self.profile
        }

# ------------------- APPLICATION -------------------
class Application(db.Model):
    __tablename__ = 'applications'
    id = db.Column(db.Integer, primary_key=True)
    candidate_id = db.Column(db.Integer, db.ForeignKey('candidates.id'))
    requisition_id = db.Column(db.Integer, db.ForeignKey('requisitions.id'))  # already exists
    status = db.Column(db.String(50), default='applied')
    assessment_score = db.Column(db.Float, default=0)
    overall_score = db.Column(db.Float, default=0)
    recommendation = db.Column(db.String(50))
    assessed_date = db.Column(db.DateTime)
    created_at = db.Column(db.DateTime, default=datetime.utcnow)

    assessment_results = db.relationship('AssessmentResult', backref='application', lazy=True)
    interviews = db.relationship('Interview', backref='application', lazy=True)

    # ✅ Add this relationship:
    requisition = db.relationship('Requisition', backref='applications', lazy=True)

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


# ------------------- ASSESSMENT RESULT -------------------
class AssessmentResult(db.Model):
    __tablename__ = 'assessment_results'
    id = db.Column(db.Integer, primary_key=True)

    application_id = db.Column(db.Integer, db.ForeignKey('applications.id'), nullable=False)
    candidate_id = db.Column(db.Integer, db.ForeignKey('candidates.id'), nullable=False)

    # Store candidate answers
    answers = db.Column(db.JSON, default={})

    # Per-question/section scores
    scores = db.Column(db.JSON, default={})

    # Aggregated evaluation
    total_score = db.Column(db.Float, default=0)
    recommendation = db.Column(db.String(50))

    assessed_at = db.Column(db.DateTime, default=datetime.utcnow)

    def to_dict(self):
        return {
            "id": self.id,
            "application_id": self.application_id,
            "candidate_id": self.candidate_id,
            "answers": self.answers,
            "scores": self.scores,
            "total_score": self.total_score,
            "recommendation": self.recommendation,
            "assessed_at": self.assessed_at.isoformat()
        }


# ------------------- VERIFICATION CODE -------------------
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

# ------------------- INTERVIEW -------------------
class Interview(db.Model):
    __tablename__ = 'interviews'
    id = db.Column(db.Integer, primary_key=True)
    candidate_id = db.Column(db.Integer, db.ForeignKey('candidates.id'), nullable=False)
    hiring_manager_id = db.Column(db.Integer, db.ForeignKey('users.id'), nullable=False)
    application_id = db.Column(db.Integer, db.ForeignKey('applications.id'), nullable=True)
    scheduled_time = db.Column(db.DateTime, nullable=False)
    status = db.Column(db.String(50), default='scheduled')  # scheduled, completed, cancelled
    created_at = db.Column(db.DateTime, default=datetime.utcnow)

    def to_dict(self):
        return {
            "id": self.id,
            "candidate_id": self.candidate_id,
            "hiring_manager_id": self.hiring_manager_id,
            "application_id": self.application_id,
            "scheduled_time": self.scheduled_time.isoformat(),
            "status": self.status,
            "created_at": self.created_at.isoformat()
        }

# ------------------- NOTIFICATION -------------------
class Notification(db.Model):
    __tablename__ = 'notifications'
    id = db.Column(db.Integer, primary_key=True)
    user_id = db.Column(db.Integer, db.ForeignKey('users.id'), nullable=False)
    message = db.Column(db.String(500), nullable=False)
    is_read = db.Column(db.Boolean, default=False)
    created_at = db.Column(db.DateTime, default=datetime.utcnow)

    def to_dict(self):
        return {
            "id": self.id,
            "user_id": self.user_id,
            "message": self.message,
            "is_read": self.is_read,
            "created_at": self.created_at.isoformat()
        }
