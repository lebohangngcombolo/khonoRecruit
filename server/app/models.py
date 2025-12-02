from app.extensions import db
from datetime import datetime
from sqlalchemy.dialects.postgresql import JSON
from sqlalchemy.dialects.postgresql import JSONB

# ------------------- USER -------------------
class User(db.Model):
    __tablename__ = 'users'

    id = db.Column(db.Integer, primary_key=True)
    email = db.Column(db.String(150), unique=True, nullable=False)
    password = db.Column(db.String(200), nullable=False)
    role = db.Column(db.String(50), default='candidate')

    profile = db.Column(JSON, default={})
    settings = db.Column(JSON, default=dict)
    is_verified = db.Column(db.Boolean, default=False)
    enrollment_completed = db.Column(db.Boolean, default=False)
    dark_mode = db.Column(db.Boolean, default=False)
    is_active = db.Column(db.Boolean, default=True)
    created_at = db.Column(db.DateTime, default=datetime.utcnow)
    first_login = db.Column(db.Boolean, default=True)
    
    # MFA Fields
    mfa_secret = db.Column(db.String(32), nullable=True)
    mfa_enabled = db.Column(db.Boolean, default=False)
    mfa_verified = db.Column(db.Boolean, default=False)
    mfa_backup_codes = db.Column(db.JSON, nullable=True)  # 🆕 ADD THIS LINE

    # 🔗 Relationships
    candidates = db.relationship('Candidate', back_populates='user', lazy=True)
    notifications = db.relationship('Notification', back_populates='user', lazy=True)
    oauth_connections = db.relationship('OAuthConnection', back_populates='user', lazy=True)
    managed_interviews = db.relationship('Interview', back_populates='hiring_manager', lazy=True)

    def to_dict(self):
        """Return sanitized user data for API responses."""
        return {
            "id": self.id,
            "email": self.email,
            "role": self.role,
            "profile": self.profile,
            "settings": self.settings,
            "is_verified": self.is_verified,
            "enrollment_completed": self.enrollment_completed,
            "dark_mode": self.dark_mode,
            "is_active": self.is_active,
            "created_at": self.created_at.isoformat(),
            "first_login": self.first_login,
            "mfa_enabled": self.mfa_enabled  # 🆕 Include MFA status
        }


class OAuthConnection(db.Model):
    __tablename__ = 'oauth_connections'
    
    id = db.Column(db.Integer, primary_key=True)
    user_id = db.Column(db.Integer, db.ForeignKey('users.id'), nullable=False)
    provider = db.Column(db.String(50), nullable=False)
    provider_user_id = db.Column(db.String(255), nullable=False)
    access_token = db.Column(db.String(512), nullable=True)
    created_at = db.Column(db.DateTime, default=datetime.utcnow)
    
    user = db.relationship('User', back_populates='oauth_connections')
    
    __table_args__ = (
        db.UniqueConstraint('provider', 'provider_user_id', name='uq_provider_user'),
    )
    
    def to_dict(self):
        return {
            'id': self.id,
            'provider': self.provider,
            'provider_user_id': self.provider_user_id,
            'created_at': self.created_at.isoformat()
        }


# ------------------- REQUISITION -------------------
class Requisition(db.Model):
    __tablename__ = 'requisitions'
    id = db.Column(db.Integer, primary_key=True)
    title = db.Column(db.String(150), nullable=False)
    description = db.Column(db.Text)
    job_summary = db.Column(db.Text, default="")
    responsibilities = db.Column(JSON, default=[])
    company_details = db.Column(db.Text, default="")
    qualifications = db.Column(JSON, default=[])
    category = db.Column(db.String(100), default="")
    required_skills = db.Column(JSON, default=[])
    min_experience = db.Column(db.Float, default=0)
    knockout_rules = db.Column(JSON, default=[])
    weightings = db.Column(JSON, default={'cv': 60, 'assessment': 40})
    assessment_pack = db.Column(JSON, default={"questions": []})
    created_by = db.Column(db.Integer, db.ForeignKey('users.id'))
    created_at = db.Column(db.DateTime, default=datetime.utcnow)
    published_on = db.Column(db.DateTime, default=datetime.utcnow)
    vacancy = db.Column(db.Integer, default=1)

    applications = db.relationship('Application', back_populates='requisition', lazy=True)

    def to_dict(self):
        return {
            "id": self.id,
            "title": self.title,
            "description": self.description,
            "job_summary": self.job_summary,
            "responsibilities": self.responsibilities,
            "company_details": self.company_details,
            "qualifications": self.qualifications,
            "category": self.category,
            "required_skills": self.required_skills,
            "min_experience": self.min_experience,
            "knockout_rules": self.knockout_rules,
            "weightings": self.weightings,
            "assessment_pack": self.assessment_pack,
            "created_by": self.created_by,
            "created_at": self.created_at.isoformat(),
            "published_on": self.published_on.isoformat(),
            "vacancy": self.vacancy,
        }



# ------------------- CANDIDATE -------------------
class Candidate(db.Model):
    __tablename__ = 'candidates'

    id = db.Column(db.Integer, primary_key=True)
    user_id = db.Column(db.Integer, db.ForeignKey('users.id'))
    full_name = db.Column(db.String(150))
    phone = db.Column(db.String(50))
    dob = db.Column(db.Date)
    address = db.Column(db.String(250))
    gender = db.Column(db.String(50), nullable=True)
    bio = db.Column(db.Text, nullable=True)
    title = db.Column(db.String(100), nullable=True)
    location = db.Column(db.String(150), nullable=True)
    nationality = db.Column(db.String(100), nullable=True)
    id_number = db.Column(db.String(100), nullable=True)       # ✅ added
    linkedin = db.Column(db.String(250), nullable=True)        # ✅ added
    github = db.Column(db.String(250), nullable=True)          # ✅ added
    cv_url = db.Column(db.String(500))
    cv_text = db.Column(db.Text)
    portfolio = db.Column(db.String(500))
    cover_letter = db.Column(db.Text)
    profile_picture = db.Column(db.String(1024), nullable=True)

    # Structured sections
    education = db.Column(JSON, default=[])
    skills = db.Column(JSON, default=[])
    work_experience = db.Column(JSON, default=[])
    certifications = db.Column(JSON, default=[])
    languages = db.Column(JSON, default=[])
    documents = db.Column(JSON, default=[])
    profile = db.Column(JSON, default={})

    cv_score = db.Column(db.Integer, default=0)
    dark_mode = db.Column(db.Boolean, default=False)
    notifications_email = db.Column(db.Boolean, default=True)
    notifications_push = db.Column(db.Boolean, default=False)

    # 🔗 Relationships
    user = db.relationship('User', back_populates='candidates')
    applications = db.relationship('Application', back_populates='candidate', lazy=True)
    interviews = db.relationship('Interview', back_populates='candidate', lazy=True)
    assessments = db.relationship('AssessmentResult', back_populates='candidate', lazy=True)
    analyses = db.relationship('CVAnalysis', back_populates='candidate', lazy=True)

    def to_dict(self):
        """Return candidate data for API responses."""
        return {
            "id": self.id,
            "user_id": self.user_id,
            "full_name": self.full_name,
            "phone": self.phone,
            "dob": self.dob.isoformat() if self.dob else None,
            "address": self.address,
            "gender": self.gender,
            "bio": self.bio,
            "title": self.title,
            "location": self.location,
            "nationality": self.nationality,
            "id_number": self.id_number,
            "linkedin": self.linkedin,
            "github": self.github,
            "cv_url": self.cv_url,
            "cv_text": self.cv_text,
            "portfolio": self.portfolio,
            "cover_letter": self.cover_letter,
            "profile_picture": self.profile_picture,
            "education": self.education,
            "skills": self.skills,
            "work_experience": self.work_experience,
            "certifications": self.certifications,
            "languages": self.languages,
            "documents": self.documents,
            "profile": self.profile,
            "cv_score": self.cv_score,
            "dark_mode": self.dark_mode,
            "notifications_email": self.notifications_email,
            "notifications_push": self.notifications_push,
        }

# ------------------- APPLICATION -------------------
class Application(db.Model):
    __tablename__ = 'applications'
    id = db.Column(db.Integer, primary_key=True)
    candidate_id = db.Column(db.Integer, db.ForeignKey('candidates.id'))
    requisition_id = db.Column(db.Integer, db.ForeignKey('requisitions.id'))
    status = db.Column(db.String(50), default='applied')  # could be 'draft', 'applied', 'reviewed', etc.
    is_draft = db.Column(db.Boolean, default=False)
    draft_data = db.Column(JSON, nullable=True)  # store partial info before submission
    resume_url = db.Column(db.String(500))
    cv_score = db.Column(db.Float, default=0)
    cv_parser_result = db.Column(JSON, default={})
    assessment_score = db.Column(db.Float, default=0)
    overall_score = db.Column(db.Float, default=0)
    recommendation = db.Column(db.String(50))
    assessed_date = db.Column(db.DateTime)
    created_at = db.Column(db.DateTime, default=datetime.utcnow)
    last_saved_screen = db.Column(db.String(50))
    saved_at = db.Column(db.DateTime)

    candidate = db.relationship('Candidate', back_populates='applications')
    requisition = db.relationship('Requisition', back_populates='applications')
    interviews = db.relationship('Interview', back_populates='application', lazy=True)
    assessment_results = db.relationship('AssessmentResult', back_populates='application', lazy=True)

    def to_dict(self):
        return {
            "id": self.id,
            "candidate_id": self.candidate_id,
            "requisition_id": self.requisition_id,
            "status": self.status,
            "is_draft": self.is_draft,
            "draft_data": self.draft_data,
            "resume_url": self.resume_url,
            "cv_score": self.cv_score,
            "cv_parser_result": self.cv_parser_result,
            "assessment_score": self.assessment_score,
            "overall_score": self.overall_score,
            "recommendation": self.recommendation,
            "assessed_date": self.assessed_date.isoformat() if self.assessed_date else None,
            "created_at": self.created_at.isoformat(),
            "assessment_results": [ar.to_dict() for ar in self.assessment_results],
            "last_saved_screen": self.last_saved_screen,
            "saved_at": self.saved_at.isoformat() if self.saved_at else None
        }


# ------------------- ASSESSMENT RESULT -------------------
class AssessmentResult(db.Model):
    __tablename__ = 'assessment_results'
    id = db.Column(db.Integer, primary_key=True)
    application_id = db.Column(db.Integer, db.ForeignKey('applications.id'), nullable=False)
    candidate_id = db.Column(db.Integer, db.ForeignKey('candidates.id'), nullable=False)
    answers = db.Column(JSON, default={})
    scores = db.Column(JSON, default={})
    total_score = db.Column(db.Float, default=0)
    percentage_score = db.Column(db.Float, default=0)
    recommendation = db.Column(db.String(50))
    assessed_at = db.Column(db.DateTime, default=datetime.utcnow)
    created_at = db.Column(db.DateTime, default=datetime.utcnow) 

    application = db.relationship('Application', back_populates='assessment_results')
    candidate = db.relationship('Candidate', back_populates='assessments')
    
    def to_dict(self):
        return {
            "id": self.id,
            "application_id": self.application_id,
            "candidate_id": self.candidate_id,
            "answers": self.answers,
            "scores": self.scores,
            "total_score": self.total_score,
            "percentage_score": self.percentage_score,
            "recommendation": self.recommendation,
            "assessed_at": self.assessed_at.isoformat() if self.assessed_at else None
        }


# ------------------- INTERVIEW -------------------
class Interview(db.Model):
    __tablename__ = 'interviews'
    id = db.Column(db.Integer, primary_key=True)
    candidate_id = db.Column(db.Integer, db.ForeignKey('candidates.id'), nullable=False)
    hiring_manager_id = db.Column(db.Integer, db.ForeignKey('users.id'), nullable=False)
    application_id = db.Column(db.Integer, db.ForeignKey('applications.id'), nullable=True)
    scheduled_time = db.Column(db.DateTime, nullable=False)
    interview_type = db.Column(db.String(50), nullable=True)
    meeting_link = db.Column(db.String(255), nullable=True)
    status = db.Column(db.String(50), default='scheduled')
    created_at = db.Column(db.DateTime, default=datetime.utcnow)

    candidate = db.relationship('Candidate', back_populates='interviews')
    application = db.relationship('Application', back_populates='interviews')
    hiring_manager = db.relationship('User', back_populates='managed_interviews')

    def to_dict(self):
        return {
            "id": self.id,
            "candidate_id": self.candidate_id,
            "hiring_manager_id": self.hiring_manager_id,
            "application_id": self.application_id,
            "scheduled_time": self.scheduled_time.isoformat() if self.scheduled_time else None,
            "interview_type": self.interview_type,
            "meeting_link": self.meeting_link,
            "status": self.status,
            "created_at": self.created_at.isoformat() if self.created_at else None,
            "candidate": {
                "id": self.candidate.id,
                "full_name": self.candidate.full_name if hasattr(self.candidate, "full_name") else self.candidate.user.profile.get("full_name") if self.candidate.user else None,
                "email": self.candidate.user.email if self.candidate.user else None
            } if self.candidate else None,
            "hiring_manager": {
                "id": self.hiring_manager.id,
                "full_name": f"{self.hiring_manager.profile.get('first_name', '')} {self.hiring_manager.profile.get('last_name', '')}".strip() if self.hiring_manager.profile else None,
                "email": self.hiring_manager.email
            } if self.hiring_manager else None,
        }



# ------------------- CV ANALYSIS -------------------
class CVAnalysis(db.Model):
    __tablename__ = "cv_analyses"
    id = db.Column(db.Integer, primary_key=True)
    candidate_id = db.Column(db.Integer, db.ForeignKey('candidates.id'), nullable=False)
    job_description = db.Column(db.Text)
    cv_text = db.Column(db.Text)
    result = db.Column(JSON, default={})
    created_at = db.Column(db.DateTime, default=datetime.utcnow)

    candidate = db.relationship('Candidate', back_populates='analyses')


# ------------------- NOTIFICATION -------------------
class Notification(db.Model):
    __tablename__ = 'notifications'
    id = db.Column(db.Integer, primary_key=True)
    user_id = db.Column(db.Integer, db.ForeignKey('users.id'), nullable=False)
    message = db.Column(db.String(500), nullable=False)
    is_read = db.Column(db.Boolean, default=False)
    created_at = db.Column(db.DateTime, default=datetime.utcnow)

    user = db.relationship('User', back_populates='notifications')

    def to_dict(self):
        return {
            "id": self.id,
            "user_id": self.user_id,
            "message": self.message,
            "is_read": self.is_read,
            "created_at": self.created_at.isoformat()
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
        
class Conversation(db.Model):
    __tablename__ = "conversations"
    id = db.Column(db.Integer, primary_key=True)
    user_id = db.Column(db.Integer, db.ForeignKey('users.id'), nullable=True)
    user_message = db.Column(db.Text)
    assistant_message = db.Column(db.Text)
    created_at = db.Column(db.DateTime, default=datetime.utcnow)

    user = db.relationship('User', backref=db.backref('conversations', lazy=True))

    def to_dict(self):
        return {
            "id": self.id,
            "user_id": self.user_id,
            "user_message": self.user_message,
            "assistant_message": self.assistant_message,
            "created_at": self.created_at.isoformat()
        }
        
class AuditLog(db.Model):
    __tablename__ = 'audit_logs'

    id = db.Column(db.Integer, primary_key=True)
    admin_id = db.Column(db.Integer, db.ForeignKey("users.id"), nullable=True)
    action = db.Column(db.String(255), nullable=False)
    target_user_id = db.Column(db.Integer, db.ForeignKey("users.id"), nullable=True)
    details = db.Column(db.Text, nullable=True)
    ip_address = db.Column(db.String(100), nullable=True)
    user_agent = db.Column(db.String(500), nullable=True)
    extra_data = db.Column(JSON, nullable=True)  # <- renamed from metadata
    timestamp = db.Column(db.DateTime, default=datetime.utcnow)

    def to_dict(self):
        return {
            "id": self.id,
            "admin_id": self.admin_id,
            "action": self.action,
            "target_user_id": self.target_user_id,
            "details": self.details,
            "ip_address": self.ip_address,
            "user_agent": self.user_agent,
            "extra_data": self.extra_data,  # <- updated here too
            "timestamp": self.timestamp.isoformat(),
        }

# ------------------- SHARED NOTE -------------------
class SharedNote(db.Model):
    __tablename__ = "shared_notes"

    id = db.Column(db.Integer, primary_key=True)
    title = db.Column(db.String(255), nullable=False)
    content = db.Column(db.Text, nullable=False)
    author_id = db.Column(db.Integer, db.ForeignKey("users.id"), nullable=False)
    created_at = db.Column(db.DateTime, default=datetime.utcnow)
    updated_at = db.Column(db.DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)
    tags = db.Column(db.String(255))
    author = db.relationship("User", backref=db.backref("shared_notes", lazy=True))
    is_pinned = db.Column(db.Boolean, default=False)  # <-- add this

    def to_dict(self):
        return {
            "id": self.id,
            "title": self.title,
            "content": self.content,
            "author_id": self.author_id,
            "author": {
                "id": self.author.id,
                "email": self.author.email,
                "profile": self.author.profile
            } if self.author else None,
            "created_at": self.created_at.isoformat(),
            "updated_at": self.updated_at.isoformat()
        }


# ------------------- MEETING -------------------
class Meeting(db.Model):
    __tablename__ = "meetings"

    id = db.Column(db.Integer, primary_key=True)
    title = db.Column(db.String(255), nullable=False)
    description = db.Column(db.Text)
    start_time = db.Column(db.DateTime, nullable=False)
    end_time = db.Column(db.DateTime, nullable=False)
    organizer_id = db.Column(db.Integer, db.ForeignKey("users.id"), nullable=False)
    participants = db.Column(JSONB, nullable=False, default=[])  # list of user emails or IDs
    meeting_link = db.Column(db.String(500))
    location = db.Column(db.String(500))
    meeting_type = db.Column(db.String(50), default="general")
    created_at = db.Column(db.DateTime, default=datetime.utcnow)
    updated_at = db.Column(db.DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)
    cancelled = db.Column(db.Boolean, default=False)
    cancelled_at = db.Column(db.DateTime, nullable=True)
    cancelled_by = db.Column(db.Integer, db.ForeignKey("users.id"), nullable=True)

    organizer = db.relationship("User", backref=db.backref("organized_meetings", lazy=True), foreign_keys=[organizer_id])

    def to_dict(self):
        return {
            "id": self.id,
            "title": self.title,
            "description": self.description,
            "start_time": self.start_time.isoformat(),
            "end_time": self.end_time.isoformat(),
            "organizer_id": self.organizer_id,
            "organizer": {
                "id": self.organizer.id,
                "email": self.organizer.email,
                "profile": self.organizer.profile
            } if self.organizer else None,
            "participants": self.participants if isinstance(self.participants, list) else [],
            "meeting_link": self.meeting_link,
            "location": self.location,
            "meeting_type": self.meeting_type,
            "created_at": self.created_at.isoformat(),
            "updated_at": self.updated_at.isoformat() if self.updated_at else None,
            "cancelled": self.cancelled,
            "cancelled_at": self.cancelled_at.isoformat() if self.cancelled_at else None,
            "cancelled_by": self.cancelled_by
        }
