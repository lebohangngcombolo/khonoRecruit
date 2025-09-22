from app.extensions import db
from app.models import Interview

# Create interview
def create_interview(creator_id, data):
    interview = Interview(
        candidate_id=data["candidate_id"],
        hiring_manager_id=data["hiring_manager_id"],
        created_by=creator_id,
        scheduled_time=data["scheduled_time"],
        status=data.get("status", "scheduled"),
        platform=data.get("platform", "video")
    )
    db.session.add(interview)
    db.session.commit()
    return interview

# Get interviews
def get_interviews(user_id, role=None):
    query = Interview.query
    if role == "candidate":
        query = query.filter_by(candidate_id=user_id)
    elif role == "hiring_manager":
        query = query.filter_by(hiring_manager_id=user_id)
    # Admins can see all
    return query.order_by(Interview.scheduled_time.desc()).all()

# Update interview
def update_interview(interview_id, data):
    interview = Interview.query.get_or_404(interview_id)
    interview.scheduled_time = data.get("scheduled_time", interview.scheduled_time)
    interview.status = data.get("status", interview.status)
    db.session.commit()
    return interview

# Delete interview
def delete_interview(interview_id):
    interview = Interview.query.get_or_404(interview_id)
    db.session.delete(interview)
    db.session.commit()
    return interview
