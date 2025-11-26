# Quick Start - Team Collaboration Backend

## 🚀 One-Command Setup

Run this from `/mnt/c/Users/User/Work/khonoRecruit/act/server`:

```bash
chmod +x setup_and_migrate.sh && ./setup_and_migrate.sh
```

This script will:
1. ✅ Remove old broken venv
2. ✅ Create fresh Python virtual environment
3. ✅ Upgrade pip
4. ✅ Install all dependencies from requirements.txt
5. ✅ Set Flask environment variables
6. ✅ Apply database migrations

## 📋 Manual Steps (if script fails)

### 1. Create Virtual Environment
```bash
rm -rf .venv
python3 -m venv .venv
source .venv/bin/activate
```

### 2. Install Dependencies
```bash
python -m pip install --upgrade pip
pip install -r requirements.txt
```

### 3. Set Environment Variables
```bash
export FLASK_APP=app:create_app
export FLASK_CONFIG=development
export FLASK_DEBUG=1
export PYTHONPATH=$(pwd)
```

### 4. Apply Migrations
```bash
# Check current state
python -m flask db current

# Apply migrations
python -m flask db upgrade

# Verify
python -m flask db current
```

### 5. Start Backend
```bash
python -m flask run --host=0.0.0.0 --port=5000
```

## 🧪 Test the API

### Get JWT Token First
```bash
# Login to get token
curl -X POST http://127.0.0.1:5000/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{
    "email": "your_admin@example.com",
    "password": "your_password"
  }'

# Copy the access_token from response
```

### Test Team Endpoints
```bash
# Replace YOUR_TOKEN with actual token

# Get team members
curl -H "Authorization: Bearer YOUR_TOKEN" \
  http://127.0.0.1:5000/api/admin/team/members

# Get team notes
curl -H "Authorization: Bearer YOUR_TOKEN" \
  http://127.0.0.1:5000/api/admin/team/notes

# Create a note
curl -X POST http://127.0.0.1:5000/api/admin/team/notes \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "title": "Test Note",
    "content": "This is a test note from API"
  }'

# Get team messages
curl -H "Authorization: Bearer YOUR_TOKEN" \
  http://127.0.0.1:5000/api/admin/team/messages

# Send a message
curl -X POST http://127.0.0.1:5000/api/admin/team/messages \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "message": "Hello team!"
  }'

# Get activities
curl -H "Authorization: Bearer YOUR_TOKEN" \
  http://127.0.0.1:5000/api/admin/team/activities
```

## 🔧 Common Issues

### Issue: "externally-managed-environment"
**Solution**: You're using system pip instead of venv pip. Always activate venv first:
```bash
source .venv/bin/activate
```

### Issue: "Could not import 'manage'"
**Solution**: Wrong FLASK_APP. Set it correctly:
```bash
export FLASK_APP=app:create_app
```

### Issue: "No such command 'db'"
**Solution**: Flask-Migrate not installed. Install it:
```bash
pip install Flask-Migrate
```

### Issue: "Multiple heads in database"
**Solution**: Check migration chain:
```bash
python -m flask db heads
python -m flask db current
```
Ensure `down_revision` in each migration points to the previous one.

### Issue: Migration fails with "column already exists"
**Solution**: The column might already exist. Check the database or skip that specific column:
```bash
# Check what's in the database
python -m flask shell
>>> from app.models import db
>>> from sqlalchemy import inspect
>>> inspector = inspect(db.engine)
>>> inspector.get_columns('users')
```

## 📁 Migration Files

Current migration chain:
1. `9467f4e67954_initial_migration.py` (creates all tables including team tables)
2. `add_is_draft_001` → `add_is_draft_column.py` (adds is_draft to applications)
3. `team_collab_001` → `add_team_collaboration_fields.py` (adds last_activity, is_online to users)

## 🎯 Next Steps After Setup

1. ✅ Ensure backend is running on port 5000
2. ✅ Test all endpoints with curl or Postman
3. ✅ Start Flutter frontend:
   ```bash
   cd ../../khono_recruite
   flutter run -d chrome --web-port=61589
   ```
4. ✅ Login as admin or hiring manager
5. ✅ Navigate to Team Collaboration page
6. ✅ Test creating notes, sending messages, viewing team members

## 🆘 Need Help?

If you encounter errors:
1. Check Flask server logs
2. Check browser console (F12) for frontend errors
3. Verify JWT token is valid
4. Ensure CORS is configured (already done in __init__.py)
5. Check database connection in app/config.py

---

**Remember**: Always activate the venv before running Flask commands!
```bash
source .venv/bin/activate
```
