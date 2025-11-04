import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../constants/app_colors.dart';
import '../../../providers/theme_provider.dart'; // ADD THIS IMPORT

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
    _isConnected = false; // Disabled temporarily
  }

  Future<void> _loadTeamData() async {
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
          content:
              'Looking for React/TypeScript experience with 3+ years in modern frontend development...',
          author: 'John Smith',
          lastModified: DateTime.now().subtract(const Duration(hours: 2)),
        ),
        SharedNote(
          title: 'Interview Process Updates',
          content:
              'Updated interview questions for technical roles including system design and behavioral questions...',
          author: 'Sarah Johnson',
          lastModified: DateTime.now().subtract(const Duration(days: 1)),
        ),
      ]);
    });
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(themeProvider),
          const SizedBox(height: 20),
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Left Panel
                Expanded(
                  flex: 1,
                  child: Column(
                    children: [
                      _buildTeamMembersPanel(themeProvider),
                      const SizedBox(height: 20),
                      _buildSharedNotesPanel(themeProvider),
                    ],
                  ),
                ),
                const SizedBox(width: 20),
                // Right Panel
                Expanded(
                  flex: 2,
                  child: _buildChatPanel(themeProvider),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(ThemeProvider themeProvider) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color:
            themeProvider.isDarkMode ? const Color(0xFF14131E) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.primaryRed.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Image.asset(
                  'assets/icons/teamC.png', // Your custom icon path
                  width: 30,
                  height: 30,
                  color: AppColors.primaryRed, // Same color as before
                ),
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Team Collaboration',
                    style: GoogleFonts.poppins(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: themeProvider.isDarkMode
                          ? Colors.white
                          : AppColors.textDark,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Real-time communication with your hiring team',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: themeProvider.isDarkMode
                          ? Colors.grey.shade400
                          : AppColors.textGrey,
                    ),
                  ),
                ],
              ),
            ],
          ),
          Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: _isConnected ? Colors.green : AppColors.primaryRed,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color:
                          (_isConnected ? Colors.green : AppColors.primaryRed)
                              .withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _isConnected ? Icons.wifi : Icons.wifi_off,
                      size: 16,
                      color: Colors.white,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _isConnected ? 'Connected' : 'Disconnected',
                      style: GoogleFonts.inter(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              _buildActionButton(
                icon: Icons.note_add,
                label: 'New Note',
                color: Colors.blue,
                onPressed: _createSharedNote,
              ),
              const SizedBox(width: 12),
              _buildActionButton(
                icon: Icons.video_call,
                label: 'Schedule Meeting',
                color: AppColors.primaryRed,
                onPressed: _scheduleMeeting,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(
      {required IconData icon,
      required String label,
      required Color color,
      required VoidCallback onPressed}) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 20),
        label:
            Text(label, style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  Widget _buildTeamMembersPanel(ThemeProvider themeProvider) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color:
              themeProvider.isDarkMode ? const Color(0xFF14131E) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.people_alt,
                    color: AppColors.primaryRed, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Team Members',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: themeProvider.isDarkMode
                        ? Colors.white
                        : AppColors.textDark,
                  ),
                ),
                const Spacer(),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.primaryRed.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${_teamMembers.where((m) => m.isOnline).length} Online',
                    style: GoogleFonts.inter(
                      color: AppColors.primaryRed,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Expanded(
              child: ListView.builder(
                itemCount: _teamMembers.length,
                itemBuilder: (context, index) {
                  final member = _teamMembers[index];
                  return _buildTeamMemberCard(member, themeProvider);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTeamMemberCard(TeamMember member, ThemeProvider themeProvider) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color:
            themeProvider.isDarkMode ? const Color(0xFF14131E) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: themeProvider.isDarkMode
                ? Colors.grey.shade800
                : Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Stack(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.primaryRed.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    member.name.substring(0, 2).toUpperCase(),
                    style: GoogleFonts.inter(
                      color: AppColors.primaryRed,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: member.isOnline ? Colors.green : Colors.grey,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  member.name,
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w600,
                    color: themeProvider.isDarkMode
                        ? Colors.white
                        : AppColors.textDark,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  member.role,
                  style: GoogleFonts.inter(
                    color: themeProvider.isDarkMode
                        ? Colors.grey.shade400
                        : AppColors.textGrey,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () {},
            icon: Icon(Icons.chat, color: AppColors.primaryRed, size: 20),
          ),
        ],
      ),
    );
  }

  Widget _buildSharedNotesPanel(ThemeProvider themeProvider) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color:
              themeProvider.isDarkMode ? const Color(0xFF14131E) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.note_alt,
                    color: AppColors.primaryRed, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Shared Notes',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: themeProvider.isDarkMode
                        ? Colors.white
                        : AppColors.textDark,
                  ),
                ),
                const Spacer(),
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primaryRed.withOpacity(0.2),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: IconButton(
                    onPressed: _createSharedNote,
                    icon: const Icon(Icons.add, color: Colors.white),
                    style: IconButton.styleFrom(
                      backgroundColor: AppColors.primaryRed,
                      padding: const EdgeInsets.all(8),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Expanded(
              child: ListView.builder(
                itemCount: _sharedNotes.length,
                itemBuilder: (context, index) {
                  final note = _sharedNotes[index];
                  return _buildSharedNoteCard(note, themeProvider);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSharedNoteCard(SharedNote note, ThemeProvider themeProvider) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color:
            themeProvider.isDarkMode ? const Color(0xFF14131E) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: themeProvider.isDarkMode
                ? Colors.grey.shade800
                : Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _viewSharedNote(note),
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        note.title,
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.w600,
                          color: themeProvider.isDarkMode
                              ? Colors.white
                              : AppColors.textDark,
                          fontSize: 16,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.primaryRed.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        _formatTimeAgo(note.lastModified),
                        style: GoogleFonts.inter(
                          color: AppColors.primaryRed,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  note.content,
                  style: GoogleFonts.inter(
                    color: themeProvider.isDarkMode
                        ? Colors.grey.shade400
                        : AppColors.textGrey,
                    fontSize: 13,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: AppColors.primaryRed.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          note.author.substring(0, 1).toUpperCase(),
                          style: GoogleFonts.inter(
                            color: AppColors.primaryRed,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'By ${note.author}',
                      style: GoogleFonts.inter(
                        color: themeProvider.isDarkMode
                            ? Colors.grey.shade400
                            : AppColors.textGrey,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildChatPanel(ThemeProvider themeProvider) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color:
            themeProvider.isDarkMode ? const Color(0xFF14131E) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          // Chat Header
          Row(
            children: [
              const Icon(Icons.chat_bubble_outline,
                  color: AppColors.primaryRed, size: 20),
              const SizedBox(width: 8),
              Text(
                'Team Chat',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: themeProvider.isDarkMode
                      ? Colors.white
                      : AppColors.textDark,
                ),
              ),
              const Spacer(),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: themeProvider.isDarkMode
                      ? Colors.grey.shade800
                      : Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: DropdownButton<String>(
                  value: _selectedEntity,
                  items: const [
                    DropdownMenuItem(
                        value: 'general', child: Text('General Chat')),
                    DropdownMenuItem(
                        value: 'candidate:123',
                        child: Text('Candidate Discussion')),
                    DropdownMenuItem(
                        value: 'requisition:456',
                        child: Text('Job Requisition')),
                  ],
                  onChanged: (value) =>
                      setState(() => _selectedEntity = value!),
                  underline: const SizedBox(),
                  icon: const Icon(Icons.arrow_drop_down, size: 16),
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color:
                        themeProvider.isDarkMode ? Colors.white : Colors.black,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          // Messages
          Expanded(
            child: _messages.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.chat_bubble_outline,
                          size: 64,
                          color: themeProvider.isDarkMode
                              ? Colors.grey.shade600
                              : Colors.grey.shade300,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No messages yet',
                          style: GoogleFonts.inter(
                            color: themeProvider.isDarkMode
                                ? Colors.grey.shade400
                                : Colors.grey.shade500,
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Start a conversation with your team',
                          style: GoogleFonts.inter(
                            color: themeProvider.isDarkMode
                                ? Colors.grey.shade500
                                : Colors.grey.shade400,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    reverse: true,
                    itemCount: _messages.length,
                    itemBuilder: (context, index) =>
                        _buildMessageCard(_messages[index], themeProvider),
                  ),
          ),
          const SizedBox(height: 20),
          _buildMessageInput(themeProvider),
        ],
      ),
    );
  }

  Widget _buildMessageCard(
      CollaborationMessage message, ThemeProvider themeProvider) {
    final isCurrentUser = message.author == _currentUser;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Row(
        mainAxisAlignment:
            isCurrentUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isCurrentUser) ...[
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppColors.primaryRed.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  message.author.substring(0, 2).toUpperCase(),
                  style: GoogleFonts.inter(
                    color: AppColors.primaryRed,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
          ],
          Flexible(
            child: Column(
              crossAxisAlignment: isCurrentUser
                  ? CrossAxisAlignment.end
                  : CrossAxisAlignment.start,
              children: [
                if (!isCurrentUser)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Text(
                      message.author,
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.w600,
                        color: themeProvider.isDarkMode
                            ? Colors.white
                            : AppColors.textDark,
                        fontSize: 12,
                      ),
                    ),
                  ),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isCurrentUser
                        ? AppColors.primaryRed
                        : (themeProvider.isDarkMode
                            ? const Color(0xFF2D2D2D)
                            : Colors.grey.shade50),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Text(
                    message.content,
                    style: GoogleFonts.inter(
                      color: isCurrentUser
                          ? Colors.white
                          : (themeProvider.isDarkMode
                              ? Colors.white
                              : AppColors.textDark),
                      fontSize: 14,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _formatTimeAgo(message.timestamp),
                  style: GoogleFonts.inter(
                    color: themeProvider.isDarkMode
                        ? Colors.grey.shade500
                        : Colors.grey.shade500,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
          if (isCurrentUser) ...[
            const SizedBox(width: 12),
            Container(
              width: 36,
              height: 36,
              decoration: const BoxDecoration(
                color: AppColors.primaryRed,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  message.author.substring(0, 2).toUpperCase(),
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMessageInput(ThemeProvider themeProvider) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: themeProvider.isDarkMode
            ? const Color(0xFF2D2D2D)
            : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: themeProvider.isDarkMode
                ? Colors.grey.shade800
                : Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _messageController,
              decoration: InputDecoration(
                hintText: 'Type a message...',
                border: InputBorder.none,
                hintStyle: GoogleFonts.inter(
                    color: themeProvider.isDarkMode
                        ? Colors.grey.shade500
                        : Colors.grey.shade500),
                contentPadding: const EdgeInsets.symmetric(horizontal: 0),
              ),
              maxLines: null,
              style: GoogleFonts.inter(
                fontSize: 14,
                color: themeProvider.isDarkMode ? Colors.white : Colors.black,
              ),
              onSubmitted: (value) => _sendMessage(),
            ),
          ),
          const SizedBox(width: 12),
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primaryRed.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: IconButton(
              onPressed: _sendMessage,
              icon: const Icon(Icons.send, color: Colors.white),
              style: IconButton.styleFrom(
                backgroundColor: AppColors.primaryRed,
                padding: const EdgeInsets.all(12),
              ),
            ),
          ),
        ],
      ),
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
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor:
            themeProvider.isDarkMode ? const Color(0xFF14131E) : Colors.white,
        title: Text('Create Shared Note',
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.w600,
              color: themeProvider.isDarkMode ? Colors.white : Colors.black,
            )),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              decoration: InputDecoration(
                labelText: 'Title',
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                labelStyle: GoogleFonts.inter(
                  color: themeProvider.isDarkMode
                      ? Colors.grey.shade400
                      : Colors.black,
                ),
              ),
              style: GoogleFonts.inter(
                color: themeProvider.isDarkMode ? Colors.white : Colors.black,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              decoration: InputDecoration(
                labelText: 'Content',
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                labelStyle: GoogleFonts.inter(
                  color: themeProvider.isDarkMode
                      ? Colors.grey.shade400
                      : Colors.black,
                ),
              ),
              maxLines: 4,
              style: GoogleFonts.inter(
                color: themeProvider.isDarkMode ? Colors.white : Colors.black,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel',
                style: GoogleFonts.inter(
                    color: themeProvider.isDarkMode
                        ? Colors.grey.shade400
                        : AppColors.textGrey)),
          ),
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primaryRed.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Shared note created successfully',
                        style: GoogleFonts.inter()),
                    backgroundColor: Colors.green,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryRed,
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
              child: Text('Create',
                  style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
            ),
          ),
        ],
      ),
    );
  }

  void _viewSharedNote(SharedNote note) {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor:
            themeProvider.isDarkMode ? const Color(0xFF14131E) : Colors.white,
        title: Text(note.title,
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.w600,
              color: themeProvider.isDarkMode ? Colors.white : Colors.black,
            )),
        content: SingleChildScrollView(
          child: Text(note.content,
              style: GoogleFonts.inter(
                fontSize: 14,
                color: themeProvider.isDarkMode ? Colors.white : Colors.black,
              )),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Close',
                style: GoogleFonts.inter(color: AppColors.primaryRed)),
          ),
        ],
      ),
    );
  }

  void _scheduleMeeting() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Meeting scheduling feature coming soon',
            style: GoogleFonts.inter()),
        backgroundColor: AppColors.primaryRed,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  String _formatTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);
    if (difference.inDays > 0) return '${difference.inDays}d ago';
    if (difference.inHours > 0) return '${difference.inHours}h ago';
    if (difference.inMinutes > 0) return '${difference.inMinutes}m ago';
    return 'Just now';
  }

  @override
  void dispose() {
    _messageController.dispose();
    _channel?.sink.close();
    super.dispose();
  }
}

// Models remain unchanged
class CollaborationMessage {
  final String author;
  final String content;
  final DateTime timestamp;
  final String entity;

  CollaborationMessage(
      {required this.author,
      required this.content,
      required this.timestamp,
      required this.entity});

  factory CollaborationMessage.fromJson(String json) => CollaborationMessage(
      author: 'User',
      content: json,
      timestamp: DateTime.now(),
      entity: 'general');

  String toJson() => content;
}

class TeamMember {
  final String name;
  final String role;
  final bool isOnline;

  TeamMember({required this.name, required this.role, required this.isOnline});
}

class SharedNote {
  final String title;
  final String content;
  final String author;
  final DateTime lastModified;

  SharedNote(
      {required this.title,
      required this.content,
      required this.author,
      required this.lastModified});
}
