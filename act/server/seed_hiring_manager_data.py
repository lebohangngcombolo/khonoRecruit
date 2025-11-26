"""
Synthetic Data Seed Script for Hiring Manager Dashboard
Run with: python seed_hiring_manager_data.py
"""

from app import create_app
from app.extensions import db
from app.models import *
from datetime import datetime, timedelta
from flask_bcrypt import Bcrypt
import random

app = create_app()
bcrypt = Bcrypt(app)

def clear_all_data():
    """Clear existing data"""
    print("[*] Clearing existing data...")
    with app.app_context():
        TeamActivity.query.delete()
        TeamMessage.query.delete()
        TeamNote.query.delete()
        Notification.query.delete()
        AssessmentResult.query.delete()
        Interview.query.delete()
        Application.query.delete()
        CVAnalysis.query.delete()
        Candidate.query.delete()
        Requisition.query.delete()
        AuditLog.query.delete()
        OAuthConnection.query.delete()
        User.query.delete()
        db.session.commit()
    print("[+] Data cleared")

def seed_users():
    """Create users: hiring managers, admin, candidates"""
    print("\n[*] Creating users...")
    
    users = []
    
    # 1. Admin User
    admin = User(
        email='admin@khonology.com',
        password=bcrypt.generate_password_hash('Admin@123').decode('utf-8'),
        role='admin',
        is_verified=True,
        enrollment_completed=True,
        is_active=True,
        first_login=False,
        is_online=True,
        last_activity=datetime.utcnow(),
        profile={
            'first_name': 'Admin',
            'last_name': 'User',
            'phone': '+27 11 123 4567',
            'department': 'HR Management'
        }
    )
    users.append(admin)
    
    # 2-4. Hiring Managers
    hm_data = [
        {'first': 'Sarah', 'last': 'Johnson', 'email': 'sarah.johnson@khonology.com', 'dept': 'Engineering', 'online': True},
        {'first': 'Michael', 'last': 'Chen', 'email': 'michael.chen@khonology.com', 'dept': 'Product', 'online': True},
        {'first': 'Lisa', 'last': 'Williams', 'email': 'lisa.williams@khonology.com', 'dept': 'Operations', 'online': False},
    ]
    
    for hm in hm_data:
        user = User(
            email=hm['email'],
            password=bcrypt.generate_password_hash('Manager@123').decode('utf-8'),
            role='hiring_manager',
            is_verified=True,
            enrollment_completed=True,
            is_active=True,
            first_login=False,
            is_online=hm['online'],
            last_activity=datetime.utcnow() if hm['online'] else datetime.utcnow() - timedelta(hours=2),
            profile={
                'first_name': hm['first'],
                'last_name': hm['last'],
                'phone': f'+27 {random.randint(10, 99)} {random.randint(100, 999)} {random.randint(1000, 9999)}',
                'department': hm['dept']
            }
        )
        users.append(user)
    
    # 5-20. Candidate Users
    candidate_names = [
        ('John', 'Smith', 'Software Engineer'),
        ('Emma', 'Davis', 'Frontend Developer'),
        ('James', 'Wilson', 'Full Stack Developer'),
        ('Olivia', 'Brown', 'UX Designer'),
        ('William', 'Taylor', 'Data Scientist'),
        ('Ava', 'Martinez', 'Backend Developer'),
        ('Noah', 'Anderson', 'DevOps Engineer'),
        ('Sophia', 'Thomas', 'Product Manager'),
        ('Liam', 'Garcia', 'Mobile Developer'),
        ('Isabella', 'Rodriguez', 'QA Engineer'),
        ('Mason', 'Lee', 'Senior Developer'),
        ('Mia', 'White', 'Junior Developer'),
        ('Ethan', 'Harris', 'Data Analyst'),
        ('Charlotte', 'Clark', 'Business Analyst'),
        ('Alexander', 'Lewis', 'System Administrator'),
    ]
    
    for idx, (first, last, title) in enumerate(candidate_names, 1):
        user = User(
            email=f'{first.lower()}.{last.lower()}@example.com',
            password=bcrypt.generate_password_hash('Candidate@123').decode('utf-8'),
            role='candidate',
            is_verified=True,
            enrollment_completed=True,
            is_active=True,
            profile={
                'first_name': first,
                'last_name': last,
                'phone': f'+27 {random.randint(70, 89)} {random.randint(100, 999)} {random.randint(1000, 9999)}'
            }
        )
        users.append(user)
    
    db.session.add_all(users)
    db.session.commit()
    print(f"[+] Created {len(users)} users")
    return users

def seed_candidates(users):
    """Create candidate profiles"""
    print("\n[*] Creating candidate profiles...")
    
    candidates = []
    candidate_users = [u for u in users if u.role == 'candidate']
    
    locations = ['Johannesburg', 'Cape Town', 'Durban', 'Pretoria', 'Port Elizabeth']
    skills_pool = ['Python', 'JavaScript', 'React', 'Node.js', 'Java', 'C#', 'SQL', 'MongoDB', 
                   'AWS', 'Docker', 'Kubernetes', 'Git', 'Agile', 'Scrum', 'TDD', 'REST APIs']
    
    for idx, user in enumerate(candidate_users):
        first = user.profile['first_name']
        last = user.profile['last_name']
        
        # Varied experience levels
        years_exp = random.randint(1, 10)
        
        candidate = Candidate(
            user_id=user.id,
            full_name=f"{first} {last}",
            phone=user.profile['phone'],
            dob=datetime(random.randint(1985, 2000), random.randint(1, 12), random.randint(1, 28)),
            address=f"{random.randint(1, 999)} Main Street, {random.choice(locations)}",
            gender=random.choice(['Male', 'Female']),
            bio=f"Passionate {['junior', 'mid-level', 'senior'][min(years_exp // 4, 2)]} professional with {years_exp} years of experience in software development.",
            title=f"{'Senior ' if years_exp > 5 else ''}{'Junior ' if years_exp < 3 else ''}Software Developer",
            location=random.choice(locations),
            nationality='South African',
            id_number=f"{random.randint(80, 99)}{random.randint(10, 12)}{random.randint(10, 28)}{random.randint(1000, 9999)}083",
            linkedin=f"https://linkedin.com/in/{first.lower()}-{last.lower()}",
            github=f"https://github.com/{first.lower()}{last.lower()}",
            cv_url=f"https://storage.khonology.com/cvs/{first.lower()}_{last.lower()}_cv.pdf",
            cv_text=f"Professional with {years_exp} years of experience in software development. Skilled in various programming languages and frameworks.",
            portfolio=f"https://{first.lower()}{last.lower()}.dev",
            skills=random.sample(skills_pool, random.randint(5, 10)),
            education=[
                {
                    "degree": random.choice(["BSc Computer Science", "BCom Information Systems", "BTech Software Development"]),
                    "institution": random.choice(["University of Cape Town", "University of Johannesburg", "Stellenbosch University"]),
                    "year": random.randint(2010, 2020)
                }
            ],
            work_experience=[
                {
                    "company": f"{random.choice(['Tech', 'Digital', 'Soft'])}Corp",
                    "position": "Software Developer",
                    "duration": f"{years_exp} years",
                    "description": "Developed and maintained web applications"
                }
            ],
            languages=[
                {"language": "English", "proficiency": "Native"},
                {"language": "Afrikaans", "proficiency": "Intermediate"}
            ],
            cv_score=random.randint(60, 95),
            profile_picture=f"https://ui-avatars.com/api/?name={first}+{last}&size=200"
        )
        candidates.append(candidate)
    
    db.session.add_all(candidates)
    db.session.commit()
    print(f"[+] Created {len(candidates)} candidate profiles")
    return candidates

def seed_requisitions(users):
    """Create job requisitions"""
    print("\n[*] Creating job requisitions...")
    
    requisitions = []
    admin = [u for u in users if u.role == 'admin'][0]
    
    jobs_data = [
        {
            'title': 'Senior Full Stack Developer',
            'category': 'Engineering',
            'summary': 'We are seeking an experienced Full Stack Developer to join our growing engineering team.',
            'skills': ['React', 'Node.js', 'PostgreSQL', 'AWS', 'Docker'],
            'experience': 5,
            'vacancy': 2
        },
        {
            'title': 'Frontend Developer (React)',
            'category': 'Engineering',
            'summary': 'Looking for a talented Frontend Developer with strong React experience.',
            'skills': ['React', 'JavaScript', 'CSS', 'Redux', 'TypeScript'],
            'experience': 3,
            'vacancy': 3
        },
        {
            'title': 'Backend Developer (Python)',
            'category': 'Engineering',
            'summary': 'Join our backend team to build scalable APIs and microservices.',
            'skills': ['Python', 'Django', 'Flask', 'PostgreSQL', 'Redis'],
            'experience': 4,
            'vacancy': 2
        },
        {
            'title': 'DevOps Engineer',
            'category': 'Infrastructure',
            'summary': 'We need a DevOps Engineer to manage our cloud infrastructure.',
            'skills': ['AWS', 'Kubernetes', 'Docker', 'Terraform', 'CI/CD'],
            'experience': 4,
            'vacancy': 1
        },
        {
            'title': 'Junior Developer',
            'category': 'Engineering',
            'summary': 'Entry-level position for fresh graduates or developers with 1-2 years experience.',
            'skills': ['JavaScript', 'Python', 'Git', 'REST APIs'],
            'experience': 1,
            'vacancy': 4
        },
    ]
    
    for job in jobs_data:
        requisition = Requisition(
            title=job['title'],
            description=f"Full description for {job['title']} position.",
            job_summary=job['summary'],
            company_details="Khonology is a leading recruitment platform revolutionizing hiring in Africa.",
            responsibilities=[
                "Develop and maintain applications",
                "Collaborate with cross-functional teams",
                "Write clean, maintainable code",
                "Participate in code reviews"
            ],
            qualifications=[
                f"{job['experience']}+ years of experience",
                "Strong problem-solving skills",
                "Excellent communication skills",
                "Bachelor's degree in Computer Science or related field"
            ],
            category=job['category'],
            required_skills=job['skills'],
            min_experience=job['experience'],
            vacancy=job['vacancy'],
            created_by=admin.id,
            created_at=datetime.utcnow() - timedelta(days=random.randint(5, 30)),
            published_on=datetime.utcnow() - timedelta(days=random.randint(1, 25)),
            knockout_rules=[
                {"field": "experience", "operator": ">=", "value": job['experience']},
                {"field": "skills", "operator": "contains_any", "value": job['skills'][:3]}
            ],
            weightings={'cv': 60, 'assessment': 40},
            assessment_pack={
                "questions": [
                    {"id": 1, "question": "Describe your experience with the required technologies", "type": "text"},
                    {"id": 2, "question": "What is your greatest technical achievement?", "type": "text"}
                ]
            }
        )
        requisitions.append(requisition)
    
    db.session.add_all(requisitions)
    db.session.commit()
    print(f"[+] Created {len(requisitions)} job requisitions")
    return requisitions

def seed_applications(candidates, requisitions):
    """Create job applications"""
    print("\n[*] Creating applications...")
    
    applications = []
    statuses = ['applied', 'screening', 'shortlisted', 'interview', 'offer', 'rejected', 'hired']
    
    # Create 30-40 applications with varied statuses
    for _ in range(35):
        candidate = random.choice(candidates)
        requisition = random.choice(requisitions)
        
        # Check if application already exists
        existing = next((a for a in applications if a.candidate_id == candidate.id and a.requisition_id == requisition.id), None)
        if existing:
            continue
        
        status = random.choice(statuses)
        cv_score = random.randint(55, 95)
        assessment_score = random.randint(50, 100) if status not in ['applied', 'screening'] else 0
        
        application = Application(
            candidate_id=candidate.id,
            requisition_id=requisition.id,
            status=status,
            is_draft=False,
            resume_url=candidate.cv_url,
            cv_score=cv_score,
            assessment_score=assessment_score,
            overall_score=(cv_score * 0.6) + (assessment_score * 0.4),
            recommendation=['Strong Hire', 'Hire', 'Maybe', 'No Hire'][min(int((cv_score + assessment_score) / 50), 3)],
            assessed_date=datetime.utcnow() - timedelta(days=random.randint(1, 10)) if assessment_score > 0 else None,
            created_at=datetime.utcnow() - timedelta(days=random.randint(1, 20)),
            cv_parser_result={
                'skills_match': random.randint(60, 95),
                'experience_match': random.randint(50, 100),
                'education_match': random.randint(70, 100)
            }
        )
        applications.append(application)
    
    db.session.add_all(applications)
    db.session.commit()
    print(f"[+] Created {len(applications)} applications")
    return applications

def seed_interviews(applications, users):
    """Create interviews"""
    print("\n[*] Creating interviews...")
    
    interviews = []
    hiring_managers = [u for u in users if u.role == 'hiring_manager']
    
    # Create interviews for shortlisted/interview/offer candidates
    interview_apps = [a for a in applications if a.status in ['interview', 'offer', 'shortlisted']]
    
    for app in interview_apps[:15]:  # Create 15 interviews
        hm = random.choice(hiring_managers)
        
        # Mix of past, today, and future interviews
        days_offset = random.choice([-5, -3, -1, 0, 1, 2, 5, 7, 10])
        scheduled_time = datetime.utcnow() + timedelta(days=days_offset, hours=random.randint(9, 17))
        
        status_map = {
            -5: 'completed', -3: 'completed', -1: 'completed',
            0: 'in_progress', 1: 'scheduled', 2: 'scheduled',
            5: 'scheduled', 7: 'scheduled', 10: 'scheduled'
        }
        
        interview = Interview(
            candidate_id=app.candidate_id,
            hiring_manager_id=hm.id,
            application_id=app.id,
            scheduled_time=scheduled_time,
            interview_type=random.choice(['Phone Screen', 'Technical', 'Behavioral', 'Final Round']),
            meeting_link=f"https://meet.google.com/{random.randint(1000, 9999)}-{random.randint(1000, 9999)}",
            status=status_map.get(days_offset, 'scheduled'),
            created_at=datetime.utcnow() - timedelta(days=random.randint(1, 15))
        )
        interviews.append(interview)
    
    db.session.add_all(interviews)
    db.session.commit()
    print(f"[+] Created {len(interviews)} interviews")
    return interviews

def seed_assessment_results(applications):
    """Create assessment results"""
    print("\n[*] Creating assessment results...")
    
    results = []
    assessed_apps = [a for a in applications if a.assessment_score > 0]
    
    for app in assessed_apps:
        result = AssessmentResult(
            application_id=app.id,
            candidate_id=app.candidate_id,
            answers={
                "q1": "I have extensive experience with these technologies...",
                "q2": "My greatest achievement was building a scalable microservices architecture..."
            },
            scores={"q1": random.randint(70, 100), "q2": random.randint(60, 100)},
            total_score=app.assessment_score,
            percentage_score=app.assessment_score,
            recommendation=app.recommendation,
            assessed_at=app.assessed_date or datetime.utcnow(),
            created_at=app.created_at
        )
        results.append(result)
    
    db.session.add_all(results)
    db.session.commit()
    print(f"[+] Created {len(results)} assessment results")
    return results

def seed_notifications(users):
    """Create notifications"""
    print("\n[*] Creating notifications...")
    
    notifications = []
    hm_and_admin = [u for u in users if u.role in ['admin', 'hiring_manager']]
    
    notification_templates = [
        "New application received for Senior Full Stack Developer position",
        "Interview scheduled with John Smith for tomorrow at 2:00 PM",
        "Candidate Emma Davis has completed the assessment",
        "Reminder: Review pending applications for Frontend Developer role",
        "New candidate message received",
        "Application status updated to 'Interview'",
        "Assessment results available for James Wilson",
        "Meeting scheduled: Team sync on recruitment strategy",
        "You were mentioned in team chat by Sarah Johnson",
        "New shared note created: 'Q1 Hiring Goals'",
    ]
    
    for user in hm_and_admin:
        # 5-10 notifications per hiring manager
        for _ in range(random.randint(5, 10)):
            notification = Notification(
                user_id=user.id,
                message=random.choice(notification_templates),
                is_read=random.choice([True, True, False]),  # Most read, some unread
                created_at=datetime.utcnow() - timedelta(hours=random.randint(1, 72))
            )
            notifications.append(notification)
    
    db.session.add_all(notifications)
    db.session.commit()
    print(f"[+] Created {len(notifications)} notifications")
    return notifications

def seed_team_collaboration(users):
    """Create team collaboration data"""
    print("\n[*] Creating team collaboration data...")
    
    hm_and_admin = [u for u in users if u.role in ['admin', 'hiring_manager']]
    
    # Team Notes
    notes = []
    note_data = [
        ('Frontend Developer Requirements', 'Looking for React experts with 3+ years experience. Must have TypeScript knowledge and understanding of modern state management.'),
        ('Interview Questions - Backend', 'Key questions: 1) Experience with microservices 2) Database optimization 3) API design principles 4) Testing strategies'),
        ('Q1 Recruitment Goals', 'Target: Hire 5 senior developers, 3 mid-level, and 2 junior positions. Focus on diversity and cultural fit.'),
        ('Candidate Feedback Process', 'All interviewers must submit feedback within 24 hours. Use the standardized rubric for technical assessments.'),
        ('Upcoming Tech Events', 'Career fair on March 15th. DevConf in April. Plan recruitment booth and prepare materials.'),
    ]
    
    for title, content in note_data:
        note = TeamNote(
            user_id=random.choice(hm_and_admin).id,
            title=title,
            content=content,
            is_shared=True,
            created_at=datetime.utcnow() - timedelta(days=random.randint(1, 10)),
            updated_at=datetime.utcnow() - timedelta(days=random.randint(0, 5))
        )
        notes.append(note)
    
    db.session.add_all(notes)
    
    # Team Messages
    messages = []
    message_texts = [
        "Great interview with @Sarah Johnson's candidate today!",
        "Can we schedule a sync about the Frontend Developer role?",
        "@Michael Chen - have you reviewed the latest applications?",
        "Reminder: Team standup at 10 AM tomorrow",
        "Excellent candidate pipeline for Senior Developer role",
        "Need feedback on the new assessment questions",
        "@Admin User can you approve the new job posting?",
        "Interview went well, moving candidate to final round",
        "Question about the salary range for DevOps role",
        "Let's discuss diversity hiring initiatives",
    ]
    
    for text in message_texts:
        message = TeamMessage(
            user_id=random.choice(hm_and_admin).id,
            message=text,
            created_at=datetime.utcnow() - timedelta(hours=random.randint(1, 48))
        )
        messages.append(message)
    
    db.session.add_all(messages)
    
    # Team Activities
    activities = []
    activity_data = [
        ('reviewed_application', 'application', 'Reviewed application for Senior Developer'),
        ('scheduled_interview', 'interview', 'Scheduled interview with candidate'),
        ('created_note', 'note', 'Created shared note about recruitment goals'),
        ('sent_message', 'message', 'Sent message in team chat'),
        ('updated_status', 'application', 'Updated application status to Interview'),
        ('completed_interview', 'interview', 'Completed interview with candidate'),
        ('shortlisted_candidate', 'application', 'Shortlisted candidate for next round'),
        ('mentioned_user', 'user', 'Mentioned team member in chat'),
    ]
    
    for action, target_type, description in activity_data * 3:  # Repeat for more activities
        activity = TeamActivity(
            user_id=random.choice(hm_and_admin).id,
            action=action,
            target_type=target_type,
            target_id=random.randint(1, 10),
            details={'description': description},
            created_at=datetime.utcnow() - timedelta(hours=random.randint(1, 72))
        )
        activities.append(activity)
    
    db.session.add_all(activities)
    db.session.commit()
    
    print(f"[+] Created team collaboration data:")
    print(f"   - {len(notes)} notes")
    print(f"   - {len(messages)} messages")
    print(f"   - {len(activities)} activities")

def seed_audit_logs(users):
    """Create audit logs"""
    print("\n[*] Creating audit logs...")
    
    logs = []
    admins = [u for u in users if u.role in ['admin', 'hiring_manager']]
    
    actions = [
        'User login',
        'Application reviewed',
        'Interview scheduled',
        'Candidate status updated',
        'Job posting created',
        'Assessment completed',
        'Team note created',
        'Settings updated'
    ]
    
    for _ in range(50):
        log = AuditLog(
            admin_id=random.choice(admins).id,
            action=random.choice(actions),
            target_user_id=random.choice(users).id if random.random() > 0.5 else None,
            details=f"Action performed successfully",
            ip_address=f"192.168.1.{random.randint(1, 255)}",
            user_agent="Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36",
            timestamp=datetime.utcnow() - timedelta(hours=random.randint(1, 168))
        )
        logs.append(log)
    
    db.session.add_all(logs)
    db.session.commit()
    print(f"[+] Created {len(logs)} audit logs")

def main():
    """Run all seed functions"""
    print("\n" + "="*60)
    print("  KHONOLOGY HIRING MANAGER - SYNTHETIC DATA SEEDER")
    print("="*60)
    
    with app.app_context():
        # Clear existing data
        clear_all_data()
        
        # Seed in order (respecting foreign key constraints)
        users = seed_users()
        candidates = seed_candidates(users)
        requisitions = seed_requisitions(users)
        applications = seed_applications(candidates, requisitions)
        interviews = seed_interviews(applications, users)
        assessment_results = seed_assessment_results(applications)
        notifications = seed_notifications(users)
        seed_team_collaboration(users)
        seed_audit_logs(users)
        
        print("\n" + "="*60)
        print("  [+] SEEDING COMPLETE!")
        print("="*60)
        print("\n[*] Summary:")
        print(f"  - Users: {len(users)} (1 admin, 3 hiring managers, {len([u for u in users if u.role == 'candidate'])} candidates)")
        print(f"  - Candidates: {len(candidates)} with full profiles")
        print(f"  - Job Requisitions: {len(requisitions)}")
        print(f"  - Applications: {len(applications)}")
        print(f"  - Interviews: {len(interviews)}")
        print(f"  - Assessment Results: {len(assessment_results)}")
        print(f"  - Notifications: Multiple per user")
        print(f"  - Team Collaboration: Notes, Messages, Activities")
        print(f"  - Audit Logs: 50 entries")
        
        print("\n[*] Login Credentials:")
        print("  Admin:")
        print("    Email: admin@khonology.com")
        print("    Password: Admin@123")
        print("\n  Hiring Managers:")
        print("    Email: sarah.johnson@khonology.com | Password: Manager@123")
        print("    Email: michael.chen@khonology.com | Password: Manager@123")
        print("    Email: lisa.williams@khonology.com | Password: Manager@123")
        print("\n  Candidates:")
        print("    Email: john.smith@example.com | Password: Candidate@123")
        print("    (All candidates use: Candidate@123)")
        
        print("\n[+] Ready to test all Hiring Manager features!")
        print("="*60 + "\n")

if __name__ == '__main__':
    main()
