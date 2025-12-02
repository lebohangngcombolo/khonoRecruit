import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../constants/app_colors.dart';
import '../../../providers/theme_provider.dart';
import '../../services/admin_service.dart';

class HMMeetingsPage extends StatefulWidget {
  const HMMeetingsPage({super.key});

  @override
  State<HMMeetingsPage> createState() => _HMMeetingsPageState();
}

class _HMMeetingsPageState extends State<HMMeetingsPage> {
  final AdminService _apiService = AdminService();
  final List<Meeting> _meetings = [];
  bool _isLoading = true;
  int _selectedTab = 0; // 0: Upcoming, 1: Past, 2: All
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadMeetings();
  }

  Future<void> _loadMeetings() async {
    setState(() => _isLoading = true);
    try {
      // Determine status filter based on selected tab
      String? status;
      final now = DateTime.now().toUtc(); // Use UTC for consistency
      if (_selectedTab == 0) {
        status = 'upcoming';
      } else if (_selectedTab == 1) {
        status = 'past';
      } else {
        status = null; // All meetings
      }

      final meetingsResponse = await _apiService.getMeetings(
        page: 1,
        perPage: 50,
        status: status,
        search: _searchQuery.isEmpty ? null : _searchQuery,
      );

      print("Meetings response: $meetingsResponse");
      final meetingsData = meetingsResponse['meetings'] as List<dynamic>? ?? [];
      print("Fetched ${meetingsData.length} meetings from API");

      // Convert to Meeting objects
      final loadedMeetings =
          meetingsData.map((meeting) => Meeting.fromJson(meeting)).toList();

      // Optional: filter manually by start/end time to ensure upcoming/past correctness
      List<Meeting> filteredMeetings;
      if (_selectedTab == 0) {
        filteredMeetings = loadedMeetings
            .where((m) => m.endTime.toUtc().isAfter(now))
            .toList();
      } else if (_selectedTab == 1) {
        filteredMeetings = loadedMeetings
            .where((m) => m.endTime.toUtc().isBefore(now))
            .toList();
      } else {
        filteredMeetings = loadedMeetings;
      }

      setState(() {
        _meetings.clear();
        _meetings.addAll(filteredMeetings);
      });
      print("Displayed meetings count: ${_meetings.length}");
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:
              Text('Failed to load meetings: $e', style: GoogleFonts.inter()),
          backgroundColor: AppColors.primaryRed,
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return Scaffold(
      backgroundColor: themeProvider.isDarkMode
          ? const Color(0xFF0B0B13)
          : const Color(0xFFF5F6FA),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(themeProvider),
              const SizedBox(height: 20),
              Expanded(child: _buildMeetingsSection(themeProvider)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(ThemeProvider themeProvider) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'Meetings',
          style: GoogleFonts.poppins(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: themeProvider.isDarkMode ? Colors.white : AppColors.textDark,
          ),
        ),
        ElevatedButton.icon(
          onPressed: () => _showMeetingForm(),
          icon: const Icon(Icons.video_call, size: 20),
          label: Text('New Meeting', style: GoogleFonts.inter()),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primaryRed,
            foregroundColor: Colors.white,
          ),
        ),
      ],
    );
  }

  Widget _buildMeetingsSection(ThemeProvider themeProvider) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color:
            themeProvider.isDarkMode ? const Color(0xFF14131E) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          // Tabs
          Row(
            children: [
              _buildTab('Upcoming', 0, themeProvider),
              const SizedBox(width: 8),
              _buildTab('Past', 1, themeProvider),
              const SizedBox(width: 8),
              _buildTab('All', 2, themeProvider),
              const Spacer(),
              // Search
              SizedBox(
                width: 250,
                child: TextField(
                  onChanged: (value) {
                    setState(() => _searchQuery = value);
                    _loadMeetings();
                  },
                  decoration: InputDecoration(
                    hintText: 'Search meetings...',
                    prefixIcon: const Icon(Icons.search, size: 18),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide.none),
                    fillColor: themeProvider.isDarkMode
                        ? Colors.grey.shade800
                        : Colors.grey.shade100,
                    filled: true,
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _meetings.isEmpty
                    ? Center(
                        child: Text('No meetings found',
                            style: GoogleFonts.inter()))
                    : ListView.builder(
                        itemCount: _meetings.length,
                        itemBuilder: (context, index) {
                          final meeting = _meetings[index];
                          return _buildMeetingCard(meeting, themeProvider);
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildTab(String text, int index, ThemeProvider themeProvider) {
    final isSelected = _selectedTab == index;
    return GestureDetector(
      onTap: () {
        setState(() => _selectedTab = index);
        _loadMeetings();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primaryRed : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          text,
          style: GoogleFonts.inter(
            color: isSelected
                ? Colors.white
                : themeProvider.isDarkMode
                    ? Colors.grey.shade400
                    : AppColors.textGrey,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildMeetingCard(Meeting meeting, ThemeProvider themeProvider) {
    final isPast = meeting.endTime.isBefore(DateTime.now());
    final isCancelled = meeting.cancelled;

    return Card(
      color: themeProvider.isDarkMode ? const Color(0xFF1E1E2C) : Colors.white,
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: ListTile(
        title: Text(meeting.title,
            style: GoogleFonts.inter(
              fontWeight: FontWeight.bold,
              decoration: isCancelled ? TextDecoration.lineThrough : null,
            )),
        subtitle: Text(
            '${DateFormat('MMM dd, yyyy – hh:mm a').format(meeting.startTime)}'),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!isCancelled && !isPast)
              IconButton(
                  onPressed: () => _showMeetingForm(meeting: meeting),
                  icon: Icon(Icons.edit, color: AppColors.primaryRed)),
            if (!isCancelled && !isPast)
              IconButton(
                  onPressed: () => _cancelMeeting(meeting),
                  icon: const Icon(Icons.cancel, color: Colors.orange)),
            if (isCancelled)
              IconButton(
                  onPressed: () => _deleteMeeting(meeting),
                  icon: const Icon(Icons.delete, color: Colors.red)),
          ],
        ),
        onTap: () => _showMeetingDetailsDialog(meeting),
      ),
    );
  }

  void _showMeetingForm({Meeting? meeting}) {
    final titleController =
        TextEditingController(text: meeting != null ? meeting.title : '');
    final descController =
        TextEditingController(text: meeting != null ? meeting.description : '');
    final linkController =
        TextEditingController(text: meeting != null ? meeting.meetingLink : '');
    final locationController =
        TextEditingController(text: meeting != null ? meeting.location : '');

    // Initialize with current time + 1 hour for new meetings, or existing times for edits
    final now = DateTime.now();
    final defaultStart =
        meeting?.startTime ?? now.add(const Duration(hours: 1));
    final defaultEnd =
        meeting?.endTime ?? defaultStart.add(const Duration(hours: 1));

    DateTime? startTime = defaultStart;
    DateTime? endTime = defaultEnd;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(meeting != null ? 'Edit Meeting' : 'Create Meeting',
              style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                    controller: titleController,
                    decoration: const InputDecoration(labelText: 'Title *')),
                const SizedBox(height: 12),
                TextField(
                    controller: descController,
                    maxLines: 3,
                    decoration:
                        const InputDecoration(labelText: 'Description')),
                const SizedBox(height: 12),
                TextField(
                    controller: linkController,
                    decoration:
                        const InputDecoration(labelText: 'Meeting Link')),
                const SizedBox(height: 12),
                TextField(
                    controller: locationController,
                    decoration: const InputDecoration(labelText: 'Location')),
                const SizedBox(height: 16),
                // Start Date & Time
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () async {
                          final date = await showDatePicker(
                            context: context,
                            initialDate: startTime ?? now,
                            firstDate: now,
                            lastDate: DateTime(2100),
                          );
                          if (date != null) {
                            final time = await showTimePicker(
                              context: context,
                              initialTime:
                                  TimeOfDay.fromDateTime(startTime ?? now),
                            );
                            if (time != null) {
                              setState(() {
                                startTime = DateTime(
                                  date.year,
                                  date.month,
                                  date.day,
                                  time.hour,
                                  time.minute,
                                );
                                // Auto-adjust end time if it's before start time
                                if (endTime == null ||
                                    endTime!.isBefore(startTime!)) {
                                  endTime =
                                      startTime!.add(const Duration(hours: 1));
                                }
                              });
                            }
                          }
                        },
                        icon: const Icon(Icons.calendar_today, size: 18),
                        label: Text(
                          startTime != null
                              ? 'Start: ${DateFormat('MMM dd, yyyy HH:mm').format(startTime!)}'
                              : 'Select Start Date & Time *',
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // End Date & Time
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () async {
                          final date = await showDatePicker(
                            context: context,
                            initialDate: endTime ?? (startTime ?? now),
                            firstDate: startTime ?? now,
                            lastDate: DateTime(2100),
                          );
                          if (date != null) {
                            final time = await showTimePicker(
                              context: context,
                              initialTime: TimeOfDay.fromDateTime(
                                  endTime ?? (startTime ?? now)),
                            );
                            if (time != null) {
                              setState(() {
                                endTime = DateTime(
                                  date.year,
                                  date.month,
                                  date.day,
                                  time.hour,
                                  time.minute,
                                );
                              });
                            }
                          }
                        },
                        icon: const Icon(Icons.event, size: 18),
                        label: Text(
                          endTime != null
                              ? 'End: ${DateFormat('MMM dd, yyyy HH:mm').format(endTime!)}'
                              : 'Select End Date & Time *',
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () async {
                if (titleController.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Title is required')),
                  );
                  return;
                }

                if (startTime == null || endTime == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('Start and end times are required')),
                  );
                  return;
                }

                if (endTime!.isBefore(startTime!) ||
                    endTime!.isAtSameMomentAs(startTime!)) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('End time must be after start time')),
                  );
                  return;
                }

                if (startTime!.isBefore(DateTime.now())) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('Start time cannot be in the past')),
                  );
                  return;
                }

                try {
                  if (meeting == null) {
                    await _apiService.createMeeting({
                      'title': titleController.text.trim(),
                      'description': descController.text.trim(),
                      'start_time': startTime!.toIso8601String(),
                      'end_time': endTime!.toIso8601String(),
                      'meeting_link': linkController.text.trim(),
                      'location': locationController.text.trim(),
                    });
                  } else {
                    await _apiService.updateMeeting(meeting.id, {
                      'title': titleController.text.trim(),
                      'description': descController.text.trim(),
                      'start_time': startTime!.toIso8601String(),
                      'end_time': endTime!.toIso8601String(),
                      'meeting_link': linkController.text.trim(),
                      'location': locationController.text.trim(),
                    });
                  }
                  Navigator.pop(context);
                  await _loadMeetings();
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Text(meeting == null
                          ? 'Meeting created successfully'
                          : 'Meeting updated successfully')));
                } catch (e) {
                  String errorMessage = 'Failed to create meeting';
                  // Extract error message from exception
                  final errorStr = e.toString();
                  if (errorStr.contains('Exception: ')) {
                    errorMessage = errorStr.split('Exception: ')[1];
                  } else {
                    errorMessage = errorStr;
                  }
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(errorMessage),
                      backgroundColor: AppColors.primaryRed,
                      duration: const Duration(seconds: 4),
                    ),
                  );
                }
              },
              child: Text(meeting != null ? 'Update' : 'Create'),
            ),
          ],
        ),
      ),
    );
  }

  void _cancelMeeting(Meeting meeting) async {
    try {
      await _apiService.cancelMeeting(meeting.id);
      await _loadMeetings();
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Meeting cancelled')));
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  void _deleteMeeting(Meeting meeting) async {
    try {
      await _apiService.deleteMeeting(meeting.id);
      await _loadMeetings();
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Meeting deleted')));
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  void _showMeetingDetailsDialog(Meeting meeting) {
    showDialog(
        context: context,
        builder: (context) => AlertDialog(
              title: Text(meeting.title),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Description: ${meeting.description}'),
                  Text('Location: ${meeting.location}'),
                  Text('Start: ${meeting.startTime}'),
                  Text('End: ${meeting.endTime}'),
                  Text('Link: ${meeting.meetingLink}'),
                  Text('Participants: ${meeting.participants.join(", ")}'),
                ],
              ),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Close'))
              ],
            ));
  }
}

class Meeting {
  final int id;
  final String title;
  final String description;
  final DateTime startTime;
  final DateTime endTime;
  final List<String> participants;
  final String meetingLink;
  final String location;
  final bool cancelled;

  Meeting({
    required this.id,
    required this.title,
    required this.description,
    required this.startTime,
    required this.endTime,
    required this.participants,
    required this.meetingLink,
    required this.location,
    required this.cancelled,
  });

  factory Meeting.fromJson(Map<String, dynamic> json) {
    try {
      return Meeting(
        id: json['id'] ?? 0,
        title: json['title'] ?? 'Untitled',
        description: json['description']?.toString() ?? '',
        startTime: DateTime.parse(json['start_time']),
        endTime: DateTime.parse(json['end_time']),
        participants: json['participants'] != null
            ? List<String>.from(
                (json['participants'] as List).map((p) => p.toString()))
            : [],
        meetingLink: json['meeting_link']?.toString() ?? '',
        location: json['location']?.toString() ?? '',
        cancelled: json['cancelled'] ?? false,
      );
    } catch (e) {
      print('Error parsing meeting JSON: $e');
      print('JSON data: $json');
      rethrow;
    }
  }
}
