# Team Collaboration Feature - Setup & Testing Guide

## ✅ What Was Implemented

### Backend (Python/Flask)
1. **Models** (`app/models.py`):
   - `TeamNote` - Shared notes among team members
   - `TeamMessage` - Team chat messages
   - `TeamActivity` - Activity feed tracking
   - Updated `User` model with `last_activity` and `is_online` fields

2. **Routes** (`app/routes/team_routes.py`):
   - `GET /api/admin/team/members` - Get team members with online status
   - `GET /api/admin/team/notes` - List all shared notes
   - `POST /api/admin/team/notes` - Create new note
   - `PUT /api/admin/team/notes/<id>` - Update note
   - `DELETE /api/admin/team/notes/<id>` - Delete note
   - `GET /api/admin/team/messages` - Get chat messages
   - `POST /api/admin/team/messages` - Send message
   - `GET /api/admin/team/activities` - Get activity feed
   - `POST /api/admin/team/update-activity` - Update user's online status

3. **Migration**:
   - Added `last_activity` and `is_online` columns to `users` table

### Frontend (Flutter/Dart)
1. **Service** (`lib/services/team_service.dart`):
   - Complete API integration for all team collaboration endpoints

2. **Updated UI** (`lib/screens/hiring_manager/hm_team_collaboration_page.dart`):
   - Replaced mock data with real API calls
   - Team members fetched from database
   - Notes created/viewed from real data
   - Messages sent and received via API

## 🚀 Deployment Steps

### 1. Apply Database Migration

```bash
cd c:\Users\User\Work\khonoRecruit\act\server

# Activate virtual environment
.venv\Scripts\activate  # Windows
# OR
source .venv/bin/activate  # Linux/Mac

# Run migration
python -m flask db upgrade
```

### 2. Start Backend Server

```bash
# Set environment variables
export FLASK_APP=app:create_app
export FLASK_CONFIG=development
export FLASK_DEBUG=True

# Start server
python -m flask run --host=0.0.0.0 --port=5000
```

### 3. Start Flutter Frontend

```bash
cd c:\Users\User\Work\khonoRecruit\khono_recruite

# Run app
flutter run -d chrome --web-port=61589
```

## 🧪 Testing the Features

### Test Team Members
1. Login as hiring manager or admin
2. Navigate to Team Collaboration page
3. **Expected**: See list of all team members (users with admin/hiring_manager roles)
4. **Online Status**: Users active in last 5 minutes show as online (green dot)

### Test Shared Notes
1. Click "New Note" button
2. Enter title and content
3. Click "Create"
4. **Expected**: 
   - Note appears in the shared notes list
   - Activity logged
   - Success message displayed
5. Click on a note to view full content
6. Notes can be edited/deleted by their author or admins

### Test Team Chat
1. Type a message in the chat input
2. Click send
3. **Expected**:
   - Message appears in chat history
   - Shows author name and timestamp
   - Message persists on page reload

### Test Activity Feed
- View activities on dashboard or collaboration page
- Shows recent team actions (notes created, messages sent, etc.)

## 📊 API Endpoints Reference

| Method | Endpoint | Description | Auth Required |
|--------|----------|-------------|---------------|
| GET | `/api/admin/team/members` | List team members | JWT + HM/Admin |
| GET | `/api/admin/team/notes` | List shared notes | JWT + HM/Admin |
| POST | `/api/admin/team/notes` | Create note | JWT + HM/Admin |
| PUT | `/api/admin/team/notes/<id>` | Update note | JWT + HM/Admin |
| DELETE | `/api/admin/team/notes/<id>` | Delete note | JWT + HM/Admin |
| GET | `/api/admin/team/messages` | Get chat messages | JWT + HM/Admin |
| POST | `/api/admin/team/messages` | Send message | JWT + HM/Admin |
| GET | `/api/admin/team/activities` | Get activities | JWT + HM/Admin |
| POST | `/api/admin/team/update-activity` | Update status | JWT |

## 🐛 Troubleshooting

### Migration Issues
```bash
# If migration fails, check current revision
python -m flask db current

# If needed, stamp the database
python -m flask db stamp head

# Then try upgrade again
python -m flask db upgrade
```

### Backend Not Starting
- Ensure virtual environment is activated
- Check if all dependencies are installed: `pip install -r requirements.txt`
- Verify database connection in config

### Frontend Not Fetching Data
- Check browser console for CORS errors
- Verify JWT token is valid (check localStorage)
- Ensure backend is running on correct port (5000)

### Online Status Not Working
- The page automatically updates activity every 2 minutes
- Users appear online if active within last 5 minutes
- Refresh the members list to see updated status

## 🎯 Next Steps (Optional Enhancements)

1. **Real-time Updates**: Implement WebSocket for instant message delivery
2. **File Attachments**: Add ability to attach files to notes
3. **@Mentions**: Notify specific users in messages
4. **Rich Text Editor**: Enhance note editor with formatting
5. **Search & Filter**: Add search for notes and messages
6. **Notification Integration**: Link chat mentions to notification system

## 📝 Notes

- The admin version of collaboration page (`lib/screens/admin/hm_team_collaboration_page.dart`) has more polished UI but wasn't updated
- Current implementation uses polling (30-second refresh) instead of WebSocket
- Activity tracking is passive - users marked online when they make API calls
- Chat messages are stored in order sent (newest shown at bottom)

## ✅ Summary

**Status**: ✅ READY FOR TESTING

All core team collaboration features are now:
- ✅ Backed by database
- ✅ Exposed via REST API  
- ✅ Integrated in Flutter UI
- ✅ Authenticated with JWT
- ✅ Role-protected (admin & hiring_manager only)

The collaboration page is now fully functional with real data!
