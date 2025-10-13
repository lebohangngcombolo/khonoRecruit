import 'package:flutter/material.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import '../../../constants/app_colors.dart';
import '../../widgets/widgets1/glass_card.dart';

class HMTeamCollaborationPage extends StatefulWidget {
  const HMTeamCollaborationPage({super.key});

  @override
  State<HMTeamCollaborationPage> createState() =>
      _HMTeamCollaborationPageState();
}

class _HMTeamCollaborationPageState extends State<HMTeamCollaborationPage> {
  final TextEditingController _messageController = TextEditingController();
  final List<CollaborationMessage> _messages = [];
  final List<TeamMember> _teamMembers = [];
  final List<SharedNote> _sharedNotes = [];

  WebSocketChannel? _channel;
  bool _isConnected = false;
  String _selectedEntity = 'general';
  String _currentUser = 'Hiring Manager';

  @override
  void initState() {
    super.initState();
    _initializeWebSocket();
    _loadTeamData();
  }

  void _initializeWebSocket() {
    // Temporarily disabled to avoid connection errors during development
    _isConnected = false;
    return;
    // try {
    //   _channel = WebSocketChannel.connect(Uri.parse('ws://localhost:8000/ws/collab'));
    //   _channel!.stream.listen(
    //     (data) {
    //       final message = CollaborationMessage.fromJson(data);
    //       setState(() {
    //         _messages.insert(0, message);
    //       });
    //     },
    //     onError: (error) {
    //       setState(() => _isConnected = false);
    //     },
    //     onDone: () {
    //       setState(() => _isConnected = false);
    //     },
    //   );
    //   setState(() => _isConnected = true);
    // } catch (e) {
    //   setState(() => _isConnected = false);
    // }
  }

  Future<void> _loadTeamData() async {
    // Load team members and shared notes
    setState(() {
      _teamMembers.addAll([
        TeamMember(
            name: 'John Smith', role: 'Senior Recruiter', isOnline: true),
        TeamMember(name: 'Sarah Johnson', role: 'HR Manager', isOnline: true),
        TeamMember(name: 'Mike Davis', role: 'Technical Lead', isOnline: false),
        TeamMember(name: 'Lisa Chen', role: 'Recruiter', isOnline: true),
      ]);

      _sharedNotes.addAll([
        SharedNote(
          title: 'Frontend Developer Requirements',
          content: 'Looking for React/TypeScript experience...',
          author: 'John Smith',
          lastModified: DateTime.now().subtract(const Duration(hours: 2)),
        ),
        SharedNote(
          title: 'Interview Process Updates',
          content: 'Updated interview questions for technical roles...',
          author: 'Sarah Johnson',
          lastModified: DateTime.now().subtract(const Duration(days: 1)),
        ),
      ]);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          _buildHeader(),
          const SizedBox(height: 16),

          // Main Content
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Left Panel - Team & Notes
                Expanded(
                  flex: 1,
                  child: Column(
                    children: [
                      _buildTeamMembersPanel(),
                      const SizedBox(height: 16),
                      _buildSharedNotesPanel(),
                    ],
                  ),
                ),
                const SizedBox(width: 16),

                // Right Panel - Chat & Comments
                Expanded(
                  flex: 2,
                  child: _buildChatPanel(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Text(
              'Team Collaboration',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppColors.textDark,
              ),
            ),
            const SizedBox(width: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: _isConnected ? Colors.green : AppColors.primaryRed,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    _isConnected ? Icons.wifi : Icons.wifi_off,
                    size: 12,
                    color: AppColors.primaryWhite,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    _isConnected ? 'Connected' : 'Disconnected',
                    style: const TextStyle(
                      color: AppColors.primaryWhite,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        Row(
          children: [
            ElevatedButton.icon(
              onPressed: _createSharedNote,
              icon: const Icon(Icons.note_add),
              label: const Text('New Note'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: AppColors.primaryWhite,
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
            ),
            const SizedBox(width: 8),
            ElevatedButton.icon(
              onPressed: _scheduleMeeting,
              icon: const Icon(Icons.video_call),
              label: const Text('Schedule Meeting'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryRed,
                foregroundColor: AppColors.primaryWhite,
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTeamMembersPanel() {
    return GlassCard(
      blur: 8,
      opacity: 0.1,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Team Members',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textDark,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 240,
              child: ListView.builder(
                itemCount: _teamMembers.length,
                itemBuilder: (context, index) {
                  final member = _teamMembers[index];
                  return _buildTeamMemberCard(member);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTeamMemberCard(TeamMember member) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.lightGrey.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: AppColors.primaryRed.withValues(alpha: 0.1),
        ),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor:
                member.isOnline ? Colors.green : AppColors.textGrey,
            child: Text(
              member.name.substring(0, 2).toUpperCase(),
              style: const TextStyle(
                color: AppColors.primaryWhite,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  member.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppColors.textDark,
                  ),
                ),
                Text(
                  member.role,
                  style: const TextStyle(
                    color: AppColors.textGrey,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: member.isOnline ? Colors.green : AppColors.textGrey,
              shape: BoxShape.circle,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSharedNotesPanel() {
    return GlassCard(
      blur: 8,
      opacity: 0.1,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text(
                  'Shared Notes',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textDark,
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: _createSharedNote,
                  icon: const Icon(Icons.add, color: AppColors.primaryRed),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 240,
              child: ListView.builder(
                itemCount: _sharedNotes.length,
                itemBuilder: (context, index) {
                  final note = _sharedNotes[index];
                  return _buildSharedNoteCard(note);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSharedNoteCard(SharedNote note) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: () => _viewSharedNote(note),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.lightGrey.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: AppColors.primaryRed.withValues(alpha: 0.1),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                note.title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: AppColors.textDark,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                note.content,
                style: const TextStyle(
                  color: AppColors.textGrey,
                  fontSize: 12,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Text(
                    'By ${note.author}',
                    style: const TextStyle(
                      color: AppColors.textGrey,
                      fontSize: 10,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    _formatTimeAgo(note.lastModified),
                    style: const TextStyle(
                      color: AppColors.textGrey,
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildChatPanel() {
    return GlassCard(
      blur: 8,
      opacity: 0.1,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Chat Header
            Row(
              children: [
                const Text(
                  'Team Chat',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textDark,
                  ),
                ),
                const Spacer(),
                DropdownButton<String>(
                  value: _selectedEntity,
                  items: const [
                    DropdownMenuItem(value: 'general', child: Text('General')),
                    DropdownMenuItem(
                        value: 'candidate:123',
                        child: Text('Candidate Discussion')),
                    DropdownMenuItem(
                        value: 'requisition:456',
                        child: Text('Job Requisition')),
                  ],
                  onChanged: (value) =>
                      setState(() => _selectedEntity = value!),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Messages
            Expanded(
              child: _messages.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.chat_bubble_outline,
                            size: 48,
                            color: AppColors.textGrey.withValues(alpha: 0.5),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'No messages yet',
                            style: TextStyle(
                              color: AppColors.textGrey,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      reverse: true,
                      itemCount: _messages.length,
                      itemBuilder: (context, index) {
                        final message = _messages[index];
                        return _buildMessageCard(message);
                      },
                    ),
            ),

            // Message Input
            const SizedBox(height: 16),
            _buildMessageInput(),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageCard(CollaborationMessage message) {
    final isCurrentUser = message.author == _currentUser;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment:
            isCurrentUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (!isCurrentUser) ...[
            CircleAvatar(
              radius: 16,
              backgroundColor: AppColors.primaryRed.withValues(alpha: 0.1),
              child: Text(
                message.author.substring(0, 2).toUpperCase(),
                style: const TextStyle(
                  color: AppColors.primaryRed,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isCurrentUser
                    ? AppColors.primaryRed.withValues(alpha: 0.1)
                    : AppColors.lightGrey.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isCurrentUser
                      ? AppColors.primaryRed.withValues(alpha: 0.3)
                      : AppColors.primaryRed.withValues(alpha: 0.1),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (!isCurrentUser)
                    Text(
                      message.author,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppColors.textDark,
                        fontSize: 12,
                      ),
                    ),
                  Text(
                    message.content,
                    style: const TextStyle(
                      color: AppColors.textDark,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _formatTimeAgo(message.timestamp),
                    style: const TextStyle(
                      color: AppColors.textGrey,
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (isCurrentUser) ...[
            const SizedBox(width: 8),
            CircleAvatar(
              radius: 16,
              backgroundColor: AppColors.primaryRed,
              child: Text(
                message.author.substring(0, 2).toUpperCase(),
                style: const TextStyle(
                  color: AppColors.primaryWhite,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMessageInput() {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: _messageController,
            decoration: InputDecoration(
              hintText: 'Type a message...',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(20),
                borderSide: BorderSide(
                    color: AppColors.primaryRed.withValues(alpha: 0.3)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(20),
                borderSide: const BorderSide(color: AppColors.primaryRed),
              ),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            ),
            maxLines: null,
            onSubmitted: (value) => _sendMessage(),
          ),
        ),
        const SizedBox(width: 8),
        IconButton(
          onPressed: _sendMessage,
          icon: const Icon(Icons.send, color: AppColors.primaryRed),
        ),
      ],
    );
  }

  void _sendMessage() {
    if (_messageController.text.trim().isEmpty) return;

    final message = CollaborationMessage(
      author: _currentUser,
      content: _messageController.text.trim(),
      timestamp: DateTime.now(),
      entity: _selectedEntity,
    );

    if (_channel != null && _isConnected) {
      _channel!.sink.add(message.toJson());
    }

    setState(() {
      _messages.insert(0, message);
    });

    _messageController.clear();
  }

  void _createSharedNote() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Create Shared Note'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              decoration: const InputDecoration(
                labelText: 'Title',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              decoration: const InputDecoration(
                labelText: 'Content',
                border: OutlineInputBorder(),
              ),
              maxLines: 4,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Shared note created successfully'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryRed,
              foregroundColor: AppColors.primaryWhite,
            ),
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  void _viewSharedNote(SharedNote note) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(note.title),
        content: SingleChildScrollView(
          child: Text(note.content),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _scheduleMeeting() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Meeting scheduling feature coming soon'),
        backgroundColor: AppColors.primaryRed,
      ),
    );
  }

  String _formatTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    _channel?.sink.close();
    super.dispose();
  }
}

// Data Models
class CollaborationMessage {
  final String author;
  final String content;
  final DateTime timestamp;
  final String entity;

  CollaborationMessage({
    required this.author,
    required this.content,
    required this.timestamp,
    required this.entity,
  });

  factory CollaborationMessage.fromJson(String json) {
    // Parse JSON string to create message
    return CollaborationMessage(
      author: 'User',
      content: json,
      timestamp: DateTime.now(),
      entity: 'general',
    );
  }

  String toJson() {
    return content; // Simplified for WebSocket
  }
}

class TeamMember {
  final String name;
  final String role;
  final bool isOnline;

  TeamMember({
    required this.name,
    required this.role,
    required this.isOnline,
  });
}

class SharedNote {
  final String title;
  final String content;
  final String author;
  final DateTime lastModified;

  SharedNote({
    required this.title,
    required this.content,
    required this.author,
    required this.lastModified,
  });
}
