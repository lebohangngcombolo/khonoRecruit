from flask import Blueprint, request, jsonify, current_app
from flask_jwt_extended import jwt_required, get_jwt_identity
from app.models import db, TeamNote, TeamMessage, TeamActivity, User
from app.utils.decorators import role_required
from datetime import datetime

team_bp = Blueprint('team', __name__)

# =====================================================
# 👥 TEAM MEMBERS
# =====================================================

@team_bp.route('/members', methods=['GET'])
@jwt_required()
@role_required(['admin', 'hiring_manager'])
def get_team_members():
    """Get all team members with online status"""
    try:
        current_user_id = get_jwt_identity()
        
        # Update current user's activity
        current_user = User.query.get(current_user_id)
        if current_user:
            current_user.update_activity()
        
        # Get all admin and hiring_manager users
        team_members = User.query.filter(
            User.role.in_(['admin', 'hiring_manager'])
        ).order_by(User.email).all()
        
        members_data = []
        for member in team_members:
            members_data.append({
                'id': member.id,
                'name': member.full_name,
                'role': member.role.replace('_', ' ').title(),
                'email': member.email,
                'isOnline': member.check_online_status(),
                'is_online': member.check_online_status(),
                'last_activity': member.last_activity.isoformat() if member.last_activity else None,
            })
        
        return jsonify(members_data), 200
        
    except Exception as e:
        current_app.logger.error(f"Error fetching team members: {e}", exc_info=True)
        return jsonify({'error': str(e)}), 500


# =====================================================
# 📝 TEAM NOTES
# =====================================================

@team_bp.route('/notes', methods=['GET'])
@jwt_required()
@role_required(['admin', 'hiring_manager'])
def get_team_notes():
    """Get all shared team notes"""
    try:
        notes = TeamNote.query.filter_by(is_shared=True)\
                              .order_by(TeamNote.updated_at.desc())\
                              .all()
        
        return jsonify([note.to_dict() for note in notes]), 200
        
    except Exception as e:
        current_app.logger.error(f"Error fetching team notes: {e}", exc_info=True)
        return jsonify({'error': str(e)}), 500


@team_bp.route('/notes', methods=['POST'])
@jwt_required()
@role_required(['admin', 'hiring_manager'])
def create_team_note():
    """Create a new team note"""
    try:
        current_user_id = get_jwt_identity()
        data = request.get_json()
        
        if not data or not data.get('title') or not data.get('content'):
            return jsonify({'error': 'Title and content are required'}), 400
        
        note = TeamNote(
            user_id=current_user_id,
            title=data['title'],
            content=data['content'],
            is_shared=data.get('is_shared', True)
        )
        
        db.session.add(note)
        
        # Log activity
        activity = TeamActivity(
            user_id=current_user_id,
            action='created_note',
            target_type='note',
            details={'title': note.title}
        )
        db.session.add(activity)
        
        db.session.commit()
        
        return jsonify(note.to_dict()), 201
        
    except Exception as e:
        db.session.rollback()
        current_app.logger.error(f"Error creating team note: {e}", exc_info=True)
        return jsonify({'error': str(e)}), 500


@team_bp.route('/notes/<int:note_id>', methods=['PUT', 'PATCH'])
@jwt_required()
@role_required(['admin', 'hiring_manager'])
def update_team_note(note_id):
    """Update a team note"""
    try:
        current_user_id = get_jwt_identity()
        data = request.get_json()
        
        note = TeamNote.query.get_or_404(note_id)
        
        # Check if user owns the note or is admin
        current_user = User.query.get(current_user_id)
        if note.user_id != current_user_id and current_user.role != 'admin':
            return jsonify({'error': 'You can only edit your own notes'}), 403
        
        if 'title' in data:
            note.title = data['title']
        if 'content' in data:
            note.content = data['content']
        
        note.updated_at = datetime.utcnow()
        
        # Log activity
        activity = TeamActivity(
            user_id=current_user_id,
            action='updated_note',
            target_type='note',
            target_id=note.id,
            details={'title': note.title}
        )
        db.session.add(activity)
        
        db.session.commit()
        
        return jsonify(note.to_dict()), 200
        
    except Exception as e:
        db.session.rollback()
        current_app.logger.error(f"Error updating team note: {e}", exc_info=True)
        return jsonify({'error': str(e)}), 500


@team_bp.route('/notes/<int:note_id>', methods=['DELETE'])
@jwt_required()
@role_required(['admin', 'hiring_manager'])
def delete_team_note(note_id):
    """Delete a team note"""
    try:
        current_user_id = get_jwt_identity()
        
        note = TeamNote.query.get_or_404(note_id)
        
        # Check if user owns the note or is admin
        current_user = User.query.get(current_user_id)
        if note.user_id != current_user_id and current_user.role != 'admin':
            return jsonify({'error': 'You can only delete your own notes'}), 403
        
        # Log activity before deletion
        activity = TeamActivity(
            user_id=current_user_id,
            action='deleted_note',
            target_type='note',
            target_id=note_id,
            details={'title': note.title}
        )
        db.session.add(activity)
        
        db.session.delete(note)
        db.session.commit()
        
        return jsonify({'success': True, 'message': 'Note deleted successfully'}), 200
        
    except Exception as e:
        db.session.rollback()
        current_app.logger.error(f"Error deleting team note: {e}", exc_info=True)
        return jsonify({'error': str(e)}), 500


# =====================================================
# 💬 TEAM MESSAGES
# =====================================================

@team_bp.route('/messages', methods=['GET'])
@jwt_required()
@role_required(['admin', 'hiring_manager'])
def get_team_messages():
    """Get team chat messages"""
    try:
        # Get the last 100 messages
        messages = TeamMessage.query.order_by(TeamMessage.created_at.desc()).limit(100).all()
        
        # Reverse to show oldest first
        messages_data = [message.to_dict() for message in reversed(messages)]
        
        return jsonify(messages_data), 200
        
    except Exception as e:
        current_app.logger.error(f"Error fetching team messages: {e}", exc_info=True)
        return jsonify({'error': str(e)}), 500


@team_bp.route('/messages', methods=['POST'])
@jwt_required()
@role_required(['admin', 'hiring_manager'])
def create_team_message():
    """Send a team message"""
    try:
        current_user_id = get_jwt_identity()
        data = request.get_json()
        
        if not data or not data.get('message'):
            return jsonify({'error': 'Message content is required'}), 400
        
        message_text = data['message']
        
        # Create message
        message = TeamMessage(
            user_id=current_user_id,
            message=message_text
        )
        
        db.session.add(message)
        db.session.flush()  # Get the message ID before commit
        
        # Extract @mentions from message
        import re
        mention_pattern = r'@([\w\.\-]+)'
        mentions = re.findall(mention_pattern, message_text)
        
        # Send notifications to mentioned users
        if mentions:
            current_user = User.query.get(current_user_id)
            sender_name = current_user.full_name if current_user else 'Someone'
            
            for mention in mentions:
                # Find users by name (case-insensitive partial match)
                mentioned_users = User.query.filter(
                    User.role.in_(['admin', 'hiring_manager'])
                ).all()
                
                for user in mentioned_users:
                    if mention.lower() in user.full_name.lower() and user.id != current_user_id:
                        # Create notification
                        from app.models import Notification
                        notification = Notification(
                            user_id=user.id,
                            message=f'{sender_name} mentioned you in team chat: {message_text[:100]}',
                            is_read=False
                        )
                        db.session.add(notification)
                        
                        # Log activity
                        activity = TeamActivity(
                            user_id=current_user_id,
                            action='mentioned_user',
                            target_type='user',
                            target_id=user.id,
                            details={'message': message_text[:100], 'mentioned_user': user.full_name}
                        )
                        db.session.add(activity)
        
        db.session.commit()
        
        return jsonify(message.to_dict()), 201
        
    except Exception as e:
        db.session.rollback()
        current_app.logger.error(f"Error creating team message: {e}", exc_info=True)
        return jsonify({'error': str(e)}), 500


# =====================================================
# 📊 TEAM ACTIVITIES
# =====================================================

@team_bp.route('/activities', methods=['GET'])
@jwt_required()
@role_required(['admin', 'hiring_manager'])
def get_team_activities():
    """Get team activity feed"""
    try:
        limit = request.args.get('limit', 50, type=int)
        
        activities = TeamActivity.query\
                                 .order_by(TeamActivity.created_at.desc())\
                                 .limit(limit)\
                                 .all()
        
        return jsonify([activity.to_dict() for activity in activities]), 200
        
    except Exception as e:
        current_app.logger.error(f"Error fetching team activities: {e}", exc_info=True)
        return jsonify({'error': str(e)}), 500


# =====================================================
# 🟢 ONLINE STATUS
# =====================================================

@team_bp.route('/update-activity', methods=['POST'])
@jwt_required()
def update_user_activity():
    """Update user's last activity timestamp"""
    try:
        current_user_id = get_jwt_identity()
        user = User.query.get(current_user_id)
        
        if user:
            user.update_activity()
            
        return jsonify({'success': True, 'message': 'Activity updated'}), 200
        
    except Exception as e:
        current_app.logger.error(f"Error updating user activity: {e}", exc_info=True)
        return jsonify({'error': str(e)}), 500
