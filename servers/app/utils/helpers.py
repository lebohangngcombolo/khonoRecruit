import re
from datetime import datetime, timedelta
from flask import request
from app import db
from app.models import AssessmentPack, Requisition

# ---------- Existing helpers ----------

def validate_email(email):
    pattern = r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$'
    return re.match(pattern, email) is not None

def validate_phone(phone):
    pattern = r'^\+?1?\d{9,15}$'
    return re.match(pattern, phone) is not None

def format_date(date_string, format='%Y-%m-%d'):
    try:
        return datetime.strptime(date_string, format)
    except (ValueError, TypeError):
        return None

def paginate_query(query, model):
    page = request.args.get('page', 1, type=int)
    per_page = request.args.get('per_page', 10, type=int)
    paginated = query.paginate(page=page, per_page=per_page, error_out=False)
    return {
        'items': [item.to_dict() for item in paginated.items],
        'total': paginated.total,
        'pages': paginated.pages,
        'current_page': page,
        'per_page': per_page
    }

def generate_time_slots(start_time, end_time, duration_minutes):
    slots = []
    current_time = start_time
    while current_time < end_time:
        slot_end = current_time + timedelta(minutes=duration_minutes)
        if slot_end <= end_time:
            slots.append({'start': current_time, 'end': slot_end})
        current_time = slot_end
    return slots

def calculate_age(birth_date):
    if not birth_date:
        return None
    today = datetime.now()
    age = today.year - birth_date.year
    if (today.month, today.day) < (birth_date.month, birth_date.day):
        age -= 1
    return age

def sanitize_input(input_string):
    if not input_string:
        return ""
    sanitized = re.sub(r'[<>{}[\]\\]', '', input_string)
    return sanitized.strip()

def format_currency(amount, currency='USD'):
    if amount is None:
        return None
    if currency == 'USD':
        return f"${amount:,.2f}"
    elif currency == 'EUR':
        return f"€{amount:,.2f}"
    elif currency == 'GBP':
        return f"£{amount:,.2f}"
    else:
        return f"{amount:,.2f} {currency}"

# ---------- Assessment Pack & Requisition helpers ----------

def get_or_create_default_assessment_pack():
    """
    Ensure there is at least one default assessment pack in the database.
    Returns the AssessmentPack object.
    """
    default_pack = AssessmentPack.query.filter_by(name='Default Pack').first()
    if default_pack:
        return default_pack

    # Create default assessment pack
    default_pack = AssessmentPack(
        name='Default Pack',
        description='This is a default assessment pack for new requisitions.',
        type='technical',  # or behavioral/cognitive depending on your default
        questions=[],      # empty list by default
        time_limit=30,     # default 30 mins
        passing_score=50.0,
        created_by=1,      # set a default admin user ID
        created_at=datetime.utcnow()
    )
    db.session.add(default_pack)
    db.session.commit()
    return default_pack


def create_requisition_helper(
    title,
    created_by,
    department=None,
    description=None,
    requirements=None,
    required_skills=None,
    min_experience=None,
    location=None,
    seniority_level=None,
    status='draft',
    weightings=None,
    knockout_rules=None
):
    """
    Creates a new requisition, ensuring it has a valid assessment_pack_id.
    """
    # Ensure default assessment pack exists
    assessment_pack = get_or_create_default_assessment_pack()

    requisition = Requisition(
        title=title,
        created_by=created_by,
        department=department,
        description=description,
        requirements=requirements,
        required_skills=required_skills or [],
        min_experience=min_experience,
        location=location,
        seniority_level=seniority_level,
        status=status,
        weightings=weightings or {},
        knockout_rules=knockout_rules or [],
        assessment_pack_id=assessment_pack.id
    )
    db.session.add(requisition)
    db.session.commit()
    return requisition
