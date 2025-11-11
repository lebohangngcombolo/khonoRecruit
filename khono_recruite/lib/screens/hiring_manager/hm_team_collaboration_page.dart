import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
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
  final List<SharedNote> _sharedNotes = [];
  final List<Meeting> _meetings = [];

  bool _isLoadingNotes = true;
  bool _isLoadingMeetings = true;
  String _selectedEntity = 'general';
  String _currentUser = 'Hiring Manager';

  final String baseUrl =
      "http://127.0.0.1:5000/api/admin"; // replace with actual

  @override
  void initState() {
    super.initState();
    _loadNotes();
    _loadMeetings();
  }

  // ---------------- API CALLS ----------------
  Future<void> _loadNotes() async {
    setState(() => _isLoadingNotes = true);
    try {
      final response = await http.get(Uri.parse('$baseUrl/notes'));
      if (response.statusCode == 200) {
        final List data = jsonDecode(response.body);
        setState(() {
          _sharedNotes.clear();
          _sharedNotes.addAll(data.map((e) => SharedNote.fromJson(e)));
        });
      } else {
        throw Exception('Failed to load notes');
      }
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Failed to load notes: $e')));
    } finally {
      setState(() => _isLoadingNotes = false);
    }
  }

  Future<void> _loadMeetings() async {
    setState(() => _isLoadingMeetings = true);
    try {
      final response = await http.get(Uri.parse('$baseUrl/meetings'));
      if (response.statusCode == 200) {
        final List data = jsonDecode(response.body);
        setState(() {
          _meetings.clear();
          _meetings.addAll(data.map((e) => Meeting.fromJson(e)));
        });
      } else {
        throw Exception('Failed to load meetings');
      }
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Failed to load meetings: $e')));
    } finally {
      setState(() => _isLoadingMeetings = false);
    }
  }

  Future<void> _createNote(String title, String content) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/notes/create'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'title': title, 'content': content}),
      );
      if (response.statusCode == 201) {
        _loadNotes();
      } else {
        throw Exception('Failed to create note');
      }
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Error creating note: $e')));
    }
  }

  Future<void> _updateNote(String id, String title, String content) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/notes/update/$id'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'title': title, 'content': content}),
      );
      if (response.statusCode == 200) {
        _loadNotes();
      } else {
        throw Exception('Failed to update note');
      }
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Error updating note: $e')));
    }
  }

  Future<void> _deleteNote(String id) async {
    try {
      final response =
          await http.delete(Uri.parse('$baseUrl/notes/delete/$id'));
      if (response.statusCode == 200) {
        _loadNotes();
      } else {
        throw Exception('Failed to delete note');
      }
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Error deleting note: $e')));
    }
  }

  Future<void> _shareNote(String id) async {
    try {
      final response = await http.post(Uri.parse('$baseUrl/notes/share'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'note_id': id}));
      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Note shared successfully!')));
      } else {
        throw Exception('Failed to share note');
      }
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Error sharing note: $e')));
    }
  }

  Future<void> _createMeeting(String title, String datetime) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/meetings/create'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'title': title, 'datetime': datetime}),
      );
      if (response.statusCode == 201) {
        _loadMeetings();
      } else {
        throw Exception('Failed to create meeting');
      }
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Error creating meeting: $e')));
    }
  }

  Future<void> _updateMeeting(String id, String title, String datetime) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/meetings/update/$id'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'title': title, 'datetime': datetime}),
      );
      if (response.statusCode == 200) {
        _loadMeetings();
      } else {
        throw Exception('Failed to update meeting');
      }
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Error updating meeting: $e')));
    }
  }

  Future<void> _deleteMeeting(String id) async {
    try {
      final response =
          await http.delete(Uri.parse('$baseUrl/meetings/delete/$id'));
      if (response.statusCode == 200) {
        _loadMeetings();
      } else {
        throw Exception('Failed to delete meeting');
      }
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Error deleting meeting: $e')));
    }
  }

  // ---------------- UI ----------------
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
                // Left Panel - Notes & Meetings
                Expanded(
                  flex: 1,
                  child: Column(
                    children: [
                      _buildSharedNotesPanel(),
                      const SizedBox(height: 16),
                      _buildMeetingsPanel(),
                    ],
                  ),
                ),
                const SizedBox(width: 16),

                // Right Panel - Chat (in-memory)
                Expanded(flex: 2, child: _buildChatPanel()),
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
        const Text(
          'Team Collaboration',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        Row(
          children: [
            ElevatedButton.icon(
              onPressed: () => _showCreateNoteDialog(),
              icon: const Icon(Icons.note_add),
              label: const Text('New Note'),
            ),
            const SizedBox(width: 8),
            ElevatedButton.icon(
              onPressed: () => _showScheduleMeetingDialog(),
              icon: const Icon(Icons.video_call),
              label: const Text('Schedule Meeting'),
            ),
          ],
        ),
      ],
    );
  }

  // ---------------- Dialogs ----------------
  void _showCreateNoteDialog() {
    final titleController = TextEditingController();
    final contentController = TextEditingController();
    showDialog(
        context: context,
        builder: (_) => AlertDialog(
              title: const Text('Create Note'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                      controller: titleController,
                      decoration: const InputDecoration(labelText: 'Title')),
                  TextField(
                      controller: contentController,
                      decoration: const InputDecoration(labelText: 'Content')),
                ],
              ),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel')),
                ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      _createNote(titleController.text, contentController.text);
                    },
                    child: const Text('Create')),
              ],
            ));
  }

  void _showScheduleMeetingDialog() {
    final titleController = TextEditingController();
    final datetimeController = TextEditingController();
    showDialog(
        context: context,
        builder: (_) => AlertDialog(
              title: const Text('Schedule Meeting'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                      controller: titleController,
                      decoration: const InputDecoration(labelText: 'Title')),
                  TextField(
                      controller: datetimeController,
                      decoration:
                          const InputDecoration(labelText: 'Date & Time')),
                ],
              ),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel')),
                ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      _createMeeting(
                          titleController.text, datetimeController.text);
                    },
                    child: const Text('Schedule')),
              ],
            ));
  }

  // ---------------- Notes & Meetings Panels ----------------
  Widget _buildSharedNotesPanel() {
    return GlassCard(
      blur: 8,
      opacity: 0.1,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Shared Notes',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            _isLoadingNotes
                ? const Center(child: CircularProgressIndicator())
                : _sharedNotes.isEmpty
                    ? const Text('No notes yet')
                    : SizedBox(
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
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.lightGrey.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.primaryRed.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(note.title,
              style: const TextStyle(
                  fontWeight: FontWeight.bold, color: AppColors.textDark)),
          const SizedBox(height: 4),
          Text(note.content, maxLines: 2, overflow: TextOverflow.ellipsis),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              IconButton(
                  icon: const Icon(Icons.edit, color: Colors.blue),
                  onPressed: () => _showUpdateNoteDialog(note)),
              IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () => _deleteNote(note.id)),
              IconButton(
                  icon: const Icon(Icons.share, color: Colors.green),
                  onPressed: () => _shareNote(note.id)),
            ],
          ),
        ],
      ),
    );
  }

  void _showUpdateNoteDialog(SharedNote note) {
    final titleController = TextEditingController(text: note.title);
    final contentController = TextEditingController(text: note.content);
    showDialog(
        context: context,
        builder: (_) => AlertDialog(
              title: const Text('Update Note'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                      controller: titleController,
                      decoration: const InputDecoration(labelText: 'Title')),
                  TextField(
                      controller: contentController,
                      decoration: const InputDecoration(labelText: 'Content')),
                ],
              ),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel')),
                ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      _updateNote(note.id, titleController.text,
                          contentController.text);
                    },
                    child: const Text('Update')),
              ],
            ));
  }

  Widget _buildMeetingsPanel() {
    return GlassCard(
      blur: 8,
      opacity: 0.1,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Meetings',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            _isLoadingMeetings
                ? const Center(child: CircularProgressIndicator())
                : _meetings.isEmpty
                    ? const Text('No meetings yet')
                    : SizedBox(
                        height: 240,
                        child: ListView.builder(
                          itemCount: _meetings.length,
                          itemBuilder: (context, index) {
                            final meeting = _meetings[index];
                            return _buildMeetingCard(meeting);
                          },
                        ),
                      ),
          ],
        ),
      ),
    );
  }

  Widget _buildMeetingCard(Meeting meeting) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.lightGrey.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.primaryRed.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(meeting.title,
              style: const TextStyle(
                  fontWeight: FontWeight.bold, color: AppColors.textDark)),
          Text(meeting.datetime, style: const TextStyle(fontSize: 12)),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              IconButton(
                  icon: const Icon(Icons.edit, color: Colors.blue),
                  onPressed: () => _showUpdateMeetingDialog(meeting)),
              IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () => _deleteMeeting(meeting.id)),
            ],
          ),
        ],
      ),
    );
  }

  void _showUpdateMeetingDialog(Meeting meeting) {
    final titleController = TextEditingController(text: meeting.title);
    final datetimeController = TextEditingController(text: meeting.datetime);
    showDialog(
        context: context,
        builder: (_) => AlertDialog(
              title: const Text('Update Meeting'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                      controller: titleController,
                      decoration: const InputDecoration(labelText: 'Title')),
                  TextField(
                      controller: datetimeController,
                      decoration:
                          const InputDecoration(labelText: 'Date & Time')),
                ],
              ),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel')),
                ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      _updateMeeting(meeting.id, titleController.text,
                          datetimeController.text);
                    },
                    child: const Text('Update')),
              ],
            ));
  }

  // ---------------- Chat Panel ----------------
  Widget _buildChatPanel() {
    return GlassCard(
      blur: 8,
      opacity: 0.1,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                const Text('Team Chat',
                    style:
                        TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
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
            Expanded(
              child: _messages.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.chat_bubble_outline,
                              size: 48,
                              color: AppColors.textGrey.withValues(alpha: 0.5)),
                          const SizedBox(height: 8),
                          const Text('No messages yet'),
                        ],
                      ),
                    )
                  : ListView.builder(
                      reverse: true,
                      itemCount: _messages.length,
                      itemBuilder: (context, index) =>
                          _buildMessageCard(_messages[index]),
                    ),
            ),
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
          Flexible(
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isCurrentUser
                    ? AppColors.primaryRed.withValues(alpha: 0.1)
                    : AppColors.lightGrey.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(message.content),
            ),
          ),
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
              decoration: const InputDecoration(hintText: 'Type a message...')),
        ),
        IconButton(icon: const Icon(Icons.send), onPressed: _sendMessage),
      ],
    );
  }

  void _sendMessage() {
    if (_messageController.text.trim().isEmpty) return;
    setState(() {
      _messages.insert(
          0,
          CollaborationMessage(
            author: _currentUser,
            content: _messageController.text.trim(),
            timestamp: DateTime.now(),
            entity: _selectedEntity,
          ));
    });
    _messageController.clear();
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }
}

// ---------------- Models ----------------
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
}

class SharedNote {
  final String id;
  final String title;
  final String content;
  final String author;
  final DateTime lastModified;

  SharedNote(
      {required this.id,
      required this.title,
      required this.content,
      required this.author,
      required this.lastModified});

  factory SharedNote.fromJson(Map<String, dynamic> json) {
    return SharedNote(
      id: json['id'],
      title: json['title'],
      content: json['content'],
      author: json['author'] ?? 'Unknown',
      lastModified: DateTime.parse(json['last_modified']),
    );
  }
}

class Meeting {
  final String id;
  final String title;
  final String datetime;
  final String organizer;

  Meeting(
      {required this.id,
      required this.title,
      required this.datetime,
      required this.organizer});

  factory Meeting.fromJson(Map<String, dynamic> json) {
    return Meeting(
      id: json['id'],
      title: json['title'],
      datetime: json['datetime'],
      organizer: json['organizer'] ?? 'Unknown',
    );
  }
}
