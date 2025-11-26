"""
Simple Data Seeder - Bypasses app initialization
Run with: python seed_data_simple.py
"""

import os
import sys
from datetime import datetime, timedelta
import random

# Set Flask environment
os.environ['FLASK_APP'] = 'app:create_app'
os.environ['FLASK_ENV'] = 'development'

# Direct database connection
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker
from flask_bcrypt import Bcrypt

# Import models directly
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from app.models import *

# Database setup
DATABASE_URL = "postgresql://appuser:password@localhost/recruitment_db"
engine = create_engine(DATABASE_URL)
Session = sessionmaker(bind=engine)
session = Session()

# Password hasher
class FakeBcrypt:
    def generate_password_hash(self, password):
        # Simple hash for development
        from werkzeug.security import generate_password_hash
        return generate_password_hash(password)

bcrypt = FakeBcrypt()

def clear_data():
    """Clear all data"""
    print("🗑️  Clearing existing data...")
    session.query(TeamActivity).delete()
    session.query(TeamMessage).delete()
    session.query(TeamNote).delete()
    session.query(Notification).delete()
    session.query(AssessmentResult).delete()
    session.query(Interview).delete()
    session.query(Application).delete()
    session.query(CVAnalysis).delete()
    session.query(Candidate).delete()
    session.query(Requisition).delete()
    session.query(AuditLog).delete()
    session.query(OAuthConnection).delete()
    session.query(User).delete()
    session.commit()
    print("✅ Cleared")

def create_users():
    """Create users"""
    print("\n👥 Creating users...")
    users = []
    
    # Admin
    admin = User(
        email='admin@khonology.com',
        password=bcrypt.generate_password_hash('Admin@123'),
        role='admin',
        is_verified=True,
        enrollment_completed=True,
        is_active=True,
        first_login=False,
        is_online=True,
        last_activity=datetime.utcnow(),
        profile={'first_name': 'Admin', 'last_name': 'User', 'phone': '+27 11 123 4567'}
    )
    users.append(admin)
    
    # Hiring Managers
    for first, last, dept in [('Sarah', 'Johnson', 'Engineering'), ('Michael', 'Chen', 'Product'), ('Lisa', 'Williams', 'Operations')]:
        hm = User(
            email=f'{first.lower()}.{last.lower()}@khonology.com',
            password=bcrypt.generate_password_hash('Manager@123'),
            role='hiring_manager',
            is_verified=True,
            enrollment_completed=True,
            is_online=True,
            last_activity=datetime.utcnow(),
            profile={'first_name': first, 'last_name': last, 'department': dept}
        )
        users.append(hm)
    
    # Candidates
    names = [('John', 'Smith'), ('Emma', 'Davis'), ('James', 'Wilson'), ('Olivia', 'Brown'), 
             ('William', 'Taylor'), ('Ava', 'Martinez'), ('Noah', 'Anderson'), ('Sophia', 'Thomas'),
             ('Liam', 'Garcia'), ('Isabella', 'Rodriguez'), ('Mason', 'Lee'), ('Mia', 'White'),
             ('Ethan', 'Harris'), ('Charlotte', 'Clark'), ('Alexander', 'Lewis')]
    
    for first, last in names:
        user = User(
            email=f'{first.lower()}.{last.lower()}@example.com',
            password=bcrypt.generate_password_hash('Candidate@123'),
            role='candidate',
            is_verified=True,
            enrollment_completed=True,
            profile={'first_name': first, 'last_name': last}
        )
        users.append(user)
    
    session.add_all(users)
    session.commit()
    print(f"✅ Created {len(users)} users")
    return users

def create_candidates(users):
    """Create candidates"""
    print("\n📝 Creating candidates...")
    candidates = []
    candidate_users = [u for u in users if u.role == 'candidate']
    
    for user in candidate_users:
        candidate = Candidate(
            user_id=user.id,
            full_name=f"{user.profile['first_name']} {user.profile['last_name']}",
            phone=f'+27 {random.randint(70, 89)} {random.randint(100, 999)} {random.randint(1000, 9999)}',
            location=random.choice(['Johannesburg', 'Cape Town', 'Durban']),
            title='Software Developer',
            skills=['Python', 'JavaScript', 'React', 'SQL'],
            cv_score=random.randint(60, 95),
            profile_picture=f"https://ui-avatars.com/api/?name={user.profile['first_name']}+{user.profile['last_name']}"
        )
        candidates.append(candidate)
    
    session.add_all(candidates)
    session.commit()
    print(f"✅ Created {len(candidates)} candidates")
    return candidates

def create_jobs(users):
    """Create job requisitions"""
    print("\n💼 Creating jobs...")
    admin = [u for u in users if u.role == 'admin'][0]
    jobs = []
    
    for title, exp in [('Senior Full Stack Developer', 5), ('Frontend Developer (React)', 3), 
                        ('Backend Developer (Python)', 4), ('DevOps Engineer', 4), ('Junior Developer', 1)]:
        job = Requisition(
            title=title,
            description=f'Great opportunity for {title}',
            job_summary=f'Looking for {title}',
            category='Engineering',
            required_skills=['Python', 'JavaScript'],
            min_experience=exp,
            vacancy=random.randint(1, 3),
            created_by=admin.id,
            created_at=datetime.utcnow() - timedelta(days=random.randint(5, 20))
        )
        jobs.append(job)
    
    session.add_all(jobs)
    session.commit()
    print(f"✅ Created {len(jobs)} jobs")
    return jobs

def create_applications(candidates, jobs):
    """Create applications"""
    print("\n📋 Creating applications...")
    apps = []
    
    for _ in range(30):
        candidate = random.choice(candidates)
        job = random.choice(jobs)
        
        if any(a.candidate_id == candidate.id and a.requisition_id == job.id for a in apps):
            continue
        
        status = random.choice(['applied', 'screening', 'shortlisted', 'interview', 'offer'])
        app = Application(
            candidate_id=candidate.id,
            requisition_id=job.id,
            status=status,
            cv_score=random.randint(60, 95),
            assessment_score=random.randint(50, 100) if status != 'applied' else 0,
            overall_score=random.randint(60, 90),
            recommendation=random.choice(['Strong Hire', 'Hire', 'Maybe']),
            created_at=datetime.utcnow() - timedelta(days=random.randint(1, 15))
        )
        apps.append(app)
    
    session.add_all(apps)
    session.commit()
    print(f"✅ Created {len(apps)} applications")
    return apps

def create_interviews(apps, users):
    """Create interviews"""
    print("\n📅 Creating interviews...")
    hms = [u for u in users if u.role == 'hiring_manager']
    interviews = []
    
    interview_apps = [a for a in apps if a.status in ['interview', 'offer', 'shortlisted']][:12]
    
    for app in interview_apps:
        interview = Interview(
            candidate_id=app.candidate_id,
            hiring_manager_id=random.choice(hms).id,
            application_id=app.id,
            scheduled_time=datetime.utcnow() + timedelta(days=random.randint(-3, 7)),
            interview_type=random.choice(['Phone Screen', 'Technical', 'Final Round']),
            meeting_link=f'https://meet.google.com/{random.randint(1000, 9999)}',
            status='scheduled'
        )
        interviews.append(interview)
    
    session.add_all(interviews)
    session.commit()
    print(f"✅ Created {len(interviews)} interviews")
    return interviews

def create_notifications(users):
    """Create notifications"""
    print("\n🔔 Creating notifications...")
    notifs = []
    hms = [u for u in users if u.role in ['admin', 'hiring_manager']]
    
    messages = ['New application received', 'Interview scheduled', 'Assessment completed', 
                'Application status updated', 'New team message']
    
    for user in hms:
        for _ in range(random.randint(5, 8)):
            notif = Notification(
                user_id=user.id,
                message=random.choice(messages),
                is_read=random.choice([True, False]),
                created_at=datetime.utcnow() - timedelta(hours=random.randint(1, 48))
            )
            notifs.append(notif)
    
    session.add_all(notifs)
    session.commit()
    print(f"✅ Created {len(notifs)} notifications")

def create_team_data(users):
    """Create team collaboration data"""
    print("\n👥 Creating team data...")
    hms = [u for u in users if u.role in ['admin', 'hiring_manager']]
    
    # Notes
    notes = []
    for title in ['Frontend Requirements', 'Interview Questions', 'Q1 Goals', 'Candidate Feedback']:
        note = TeamNote(
            user_id=random.choice(hms).id,
            title=title,
            content=f'Important notes about {title}',
            is_shared=True,
            created_at=datetime.utcnow() - timedelta(days=random.randint(1, 7))
        )
        notes.append(note)
    session.add_all(notes)
    
    # Messages
    messages = []
    for text in ['Great interview today!', 'Can we sync about Frontend role?', 'Need feedback on assessment',
                 'Team standup at 10 AM', 'Excellent candidate pipeline']:
        msg = TeamMessage(
            user_id=random.choice(hms).id,
            message=text,
            created_at=datetime.utcnow() - timedelta(hours=random.randint(1, 24))
        )
        messages.append(msg)
    session.add_all(messages)
    
    # Activities
    activities = []
    for action in ['reviewed_application', 'scheduled_interview', 'created_note', 'sent_message'] * 5:
        activity = TeamActivity(
            user_id=random.choice(hms).id,
            action=action,
            target_type='application',
            details={'description': f'Performed {action}'},
            created_at=datetime.utcnow() - timedelta(hours=random.randint(1, 48))
        )
        activities.append(activity)
    session.add_all(activities)
    
    session.commit()
    print(f"✅ Created team data: {len(notes)} notes, {len(messages)} messages, {len(activities)} activities")

def main():
    print("\n" + "="*60)
    print("  SYNTHETIC DATA SEEDER")
    print("="*60)
    
    try:
        clear_data()
        users = create_users()
        candidates = create_candidates(users)
        jobs = create_jobs(users)
        apps = create_applications(candidates, jobs)
        interviews = create_interviews(apps, users)
        create_notifications(users)
        create_team_data(users)
        
        print("\n" + "="*60)
        print("  ✅ SEEDING COMPLETE!")
        print("="*60)
        print("\n🔐 Login Credentials:")
        print("  Admin: admin@khonology.com / Admin@123")
        print("  HM: sarah.johnson@khonology.com / Manager@123")
        print("  Candidate: john.smith@example.com / Candidate@123")
        print("="*60 + "\n")
        
    except Exception as e:
        print(f"\n❌ Error: {e}")
        session.rollback()
    finally:
        session.close()

if __name__ == '__main__':
    main()
