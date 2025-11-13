import 'package:flutter/material.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import '../../../constants/app_colors.dart';
import '../../widgets/widgets1/glass_card.dart';
import '../../services/team_service.dart';

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
    // Load real data from API
    try {
      // Update user activity
      TeamService.updateUserActivity();
      
      // Load team members from API
      final membersData = await TeamService.getTeamMembers();
      final members = membersData.map((json) => TeamMember(
        name: json['name'] ?? 'Unknown',
        role: json['role'] ?? 'Team Member',
        isOnline: json['isOnline'] ?? false,
      )).toList();

      // Load shared notes from API
      final notesData = await TeamService.getTeamNotes();
      final notes = notesData.map((json) => SharedNote(
        title: json['title'] ?? '',
        content: json['content'] ?? '',
        author: json['author'] ?? 'Unknown',
        lastModified: DateTime.tryParse(json['updated_at'] ?? '') ?? DateTime.now(),
      )).toList();

      // Load messages from API
      final messagesData = await TeamService.getTeamMessages();
      final messages = messagesData.map((json) => CollaborationMessage(
        author: json['author'] ?? 'Unknown',
        content: json['message'] ?? '',
        timestamp: DateTime.tryParse(json['created_at'] ?? '') ?? DateTime.now(),
        entity: json['entity_type'] ?? 'general',
      )).toList();

      setState(() {
        _teamMembers.clear();
        _teamMembers.addAll(members);
        _sharedNotes.clear();
        _sharedNotes.addAll(notes);
        _messages.clear();
        _messages.addAll(messages.reversed); // Show newest first
      });
    } catch (e) {
      debugPrint('Error loading team data: $e');
      // Fallback to empty or show error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to load team data: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
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
                      Expanded(
                        child: Column(
                          children: [
                            Expanded(
                              flex: 2,
                              child: _buildSharedNotesPanel(),
                            ),
                            const SizedBox(height: 16),
                            Flexible(
                              flex: 1,
                              child: _buildUpcomingMeetingsWidget(),
                            ),
                          ],
                        ),
                      ),
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
            const Text(
              'Team Collaboration',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                shadows: [
                  Shadow(
                    color: Colors.black54,
                    blurRadius: 8,
                    offset: Offset(0, 2),
                  )
                ],
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
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Team Members',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                shadows: [
                  Shadow(
                    color: Colors.black54,
                    blurRadius: 8,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: _teamMembers.isEmpty
                  ? Center(
                      child: Text(
                        'No team members found',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                        ),
                      ),
                    )
                  : ListView.builder(
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
                    color: Colors.white,
                  ),
                ),
                Text(
                  member.role,
                  style: const TextStyle(
                    color: Colors.white70,
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
                Text(
                  'Shared Notes',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    shadows: [
                      Shadow(
                        color: Colors.black54,
                        blurRadius: 8,
                        offset: Offset(0, 2),
                      ),
                    ],
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
            Expanded(
              child: _sharedNotes.isEmpty
                  ? const Center(
                      child: Text(
                        'No shared notes yet',
                        style: TextStyle(color: Colors.white70),
                      ),
                    )
                  : ListView.builder(
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
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                note.content,
                style: const TextStyle(
                  color: Colors.white70,
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
                      color: Colors.white60,
                      fontSize: 10,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    _formatTimeAgo(note.lastModified),
                    style: const TextStyle(
                      color: Colors.white60,
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
                Text(
                  'Team Chat',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    shadows: [
                      Shadow(
                        color: Colors.black54,
                        blurRadius: 8,
                        offset: Offset(0, 2),
                      ),
                    ],
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
                        color: Colors.white,
                        fontSize: 12,
                      ),
                    ),
                  _buildMessageContent(message.content),
                  const SizedBox(height: 4),
                  Text(
                    _formatTimeAgo(message.timestamp),
                    style: const TextStyle(
                      color: Colors.white60,
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
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.primaryWhite,
        borderRadius: BorderRadius.circular(25),
        border: Border.all(color: AppColors.primaryRed.withValues(alpha: 0.3)),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryRed.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // @mention button
          IconButton(
            onPressed: _showMentionPicker,
            icon: const Icon(Icons.alternate_email, size: 18),
            color: AppColors.primaryRed,
            tooltip: 'Mention someone',
            padding: const EdgeInsets.all(8),
            constraints: const BoxConstraints(
              minWidth: 36,
              minHeight: 36,
            ),
          ),
          Expanded(
            child: TextField(
              controller: _messageController,
              decoration: const InputDecoration(
                hintText: 'Type a message... (use @ to mention)',
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(horizontal: 4, vertical: 8),
              ),
              maxLines: null,
              onSubmitted: (value) => _sendMessage(),
              onChanged: (value) => _checkForMention(value),
            ),
          ),
          const SizedBox(width: 4),
          // Send button with circular background
          Material(
            color: AppColors.primaryRed,
            borderRadius: BorderRadius.circular(18),
            child: InkWell(
              borderRadius: BorderRadius.circular(18),
              onTap: _sendMessage,
              child: Container(
                padding: const EdgeInsets.all(8),
                child: const Icon(
                  Icons.send,
                  color: AppColors.primaryWhite,
                  size: 18,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _sendMessage() async {
    if (_messageController.text.trim().isEmpty) return;

    final messageText = _messageController.text.trim();
    
    try {
      // Extract mentions from message
      final mentions = _extractMentions(messageText);
      
      // Send message to API
      await TeamService.sendTeamMessage(messageText);
      
      // If there are mentions, send notifications
      if (mentions.isNotEmpty) {
        await _sendMentionNotifications(mentions, messageText);
      }
      
      // Clear input and reload messages
      _messageController.clear();
      _loadTeamData();
      
    } catch (e) {
      debugPrint('Error sending message: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to send message: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Extract @mentions from message
  List<String> _extractMentions(String text) {
    final mentions = <String>[];
    final mentionRegex = RegExp(r'@([\w\.\-]+)');
    final matches = mentionRegex.allMatches(text);
    
    for (final match in matches) {
      mentions.add(match.group(1)!);
    }
    
    return mentions;
  }

  // Send notifications to mentioned users
  Future<void> _sendMentionNotifications(List<String> mentions, String messageText) async {
    try {
      for (final mention in mentions) {
        // Find the user by name/email
        final mentionedUser = _teamMembers.firstWhere(
          (member) => member.name.toLowerCase().contains(mention.toLowerCase()),
          orElse: () => TeamMember(name: '', role: '', isOnline: false),
        );
        
        if (mentionedUser.name.isNotEmpty) {
          // Send notification via API
          // This would call a notifications endpoint
          debugPrint('Sending notification to ${mentionedUser.name} for mention');
        }
      }
    } catch (e) {
      debugPrint('Error sending mention notifications: $e');
    }
  }

  // Show mention picker dialog
  void _showMentionPicker() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Mention Someone'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: _teamMembers.length,
            itemBuilder: (context, index) {
              final member = _teamMembers[index];
              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: member.isOnline 
                      ? Colors.green.withValues(alpha: 0.2)
                      : Colors.grey.withValues(alpha: 0.2),
                  child: Text(
                    member.name.substring(0, 2).toUpperCase(),
                    style: TextStyle(
                      color: member.isOnline ? Colors.green : Colors.grey,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                title: Text(member.name),
                subtitle: Text(member.role),
                trailing: member.isOnline
                    ? Container(
                        width: 10,
                        height: 10,
                        decoration: const BoxDecoration(
                          color: Colors.green,
                          shape: BoxShape.circle,
                        ),
                      )
                    : null,
                onTap: () {
                  final currentText = _messageController.text;
                  final mention = '@${member.name.replaceAll(' ', '')}';
                  _messageController.text = currentText + mention + ' ';
                  _messageController.selection = TextSelection.fromPosition(
                    TextPosition(offset: _messageController.text.length),
                  );
                  Navigator.pop(context);
                  // Focus back on text field
                  FocusScope.of(context).requestFocus(FocusNode());
                },
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  // Check for @ symbol to show mention suggestions
  void _checkForMention(String text) {
    if (text.endsWith('@')) {
      // Could show a popup with mention suggestions
      // For now, users can use the @ button
    }
  }

  // Build message content with highlighted @mentions
  Widget _buildMessageContent(String content) {
    final mentionRegex = RegExp(r'@([\w\.\-]+)');
    final matches = mentionRegex.allMatches(content);
    
    if (matches.isEmpty) {
      return Text(
        content,
        style: const TextStyle(color: Colors.white),
      );
    }
    
    final spans = <TextSpan>[];
    int currentIndex = 0;
    
    for (final match in matches) {
      // Add text before mention
      if (match.start > currentIndex) {
        spans.add(TextSpan(
          text: content.substring(currentIndex, match.start),
          style: const TextStyle(color: Colors.white),
        ));
      }
      
      // Add highlighted mention
      spans.add(TextSpan(
        text: match.group(0),
        style: const TextStyle(
          color: AppColors.primaryRed,
          fontWeight: FontWeight.bold,
          backgroundColor: Color(0x20FF0000),
        ),
      ));
      
      currentIndex = match.end;
    }
    
    // Add remaining text
    if (currentIndex < content.length) {
      spans.add(TextSpan(
        text: content.substring(currentIndex),
        style: const TextStyle(color: Colors.white),
      ));
    }
    
    return RichText(
      text: TextSpan(children: spans),
    );
  }

  void _createSharedNote() {
    final titleController = TextEditingController();
    final contentController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Create Shared Note'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleController,
              decoration: const InputDecoration(
                labelText: 'Title',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: contentController,
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
            onPressed: () async {
              if (titleController.text.isNotEmpty && contentController.text.isNotEmpty) {
                try {
                  await TeamService.createTeamNote(
                    titleController.text,
                    contentController.text,
                  );
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Shared note created successfully'),
                      backgroundColor: Colors.green,
                    ),
                  );
                  _loadTeamData(); // Reload to show new note
                } catch (e) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Failed to create note: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
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
    final titleController = TextEditingController();
    final descriptionController = TextEditingController();
    DateTime selectedDate = DateTime.now();
    TimeOfDay selectedTime = TimeOfDay.now();
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Schedule Team Meeting'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: titleController,
                  decoration: const InputDecoration(
                    labelText: 'Meeting Title',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.title),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Description',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.description),
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 16),
                ListTile(
                  leading: const Icon(Icons.calendar_today, color: AppColors.primaryRed),
                  title: Text('Date: ${selectedDate.day}/${selectedDate.month}/${selectedDate.year}'),
                  trailing: const Icon(Icons.arrow_drop_down),
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: selectedDate,
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                    );
                    if (date != null) {
                      setDialogState(() => selectedDate = date);
                    }
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.access_time, color: AppColors.primaryRed),
                  title: Text('Time: ${selectedTime.format(context)}'),
                  trailing: const Icon(Icons.arrow_drop_down),
                  onTap: () async {
                    final time = await showTimePicker(
                      context: context,
                      initialTime: selectedTime,
                    );
                    if (time != null) {
                      setDialogState(() => selectedTime = time);
                    }
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (titleController.text.isNotEmpty) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Meeting "${titleController.text}" scheduled for '
                        '${selectedDate.day}/${selectedDate.month} at ${selectedTime.format(context)}',
                      ),
                      backgroundColor: Colors.green,
                      duration: const Duration(seconds: 3),
                    ),
                  );
                  // Here you would call the API to save the meeting
                  // await TeamService.scheduleMeeting(...);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryRed,
                foregroundColor: Colors.white,
              ),
              child: const Text('Schedule'),
            ),
          ],
        ),
      ),
    );
  }

  // Build upcoming meetings widget
  Widget _buildUpcomingMeetingsWidget() {
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
                const Icon(Icons.calendar_month, color: AppColors.primaryRed, size: 20),
                const SizedBox(width: 8),
                const Text(
                  'Upcoming Meetings',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textDark,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.add_circle_outline, size: 20),
                  color: AppColors.primaryRed,
                  onPressed: _scheduleMeeting,
                  tooltip: 'Schedule new meeting',
                ),
              ],
            ),
            const SizedBox(height: 12),
            Expanded(
              child: ListView(
                children: [
                  _buildMeetingItem(
                    'Team Sync',
                    'Weekly team alignment',
                    DateTime.now().add(const Duration(hours: 2)),
                    Icons.people,
                  ),
                  _buildMeetingItem(
                    'Candidate Review',
                    'Review shortlisted candidates',
                    DateTime.now().add(const Duration(days: 1)),
                    Icons.person_search,
                  ),
                  _buildMeetingItem(
                    'Strategy Planning',
                    'Q1 recruitment strategy',
                    DateTime.now().add(const Duration(days: 2)),
                    Icons.business_center,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMeetingItem(String title, String description, DateTime dateTime, IconData icon) {
    final now = DateTime.now();
    final isToday = dateTime.day == now.day && dateTime.month == now.month && dateTime.year == now.year;
    final isTomorrow = dateTime.day == now.day + 1 && dateTime.month == now.month && dateTime.year == now.year;
    
    String timeText;
    if (isToday) {
      timeText = 'Today ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
    } else if (isTomorrow) {
      timeText = 'Tomorrow ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
    } else {
      timeText = '${dateTime.day}/${dateTime.month} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
    }
    
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: AppColors.primaryRed.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.primaryRed.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 16, color: AppColors.primaryRed),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                    color: AppColors.textDark,
                  ),
                ),
                Text(
                  description,
                  style: const TextStyle(
                    fontSize: 10,
                    color: AppColors.textGrey,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Text(
            timeText,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: isToday ? AppColors.primaryRed : AppColors.textGrey,
            ),
          ),
        ],
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
