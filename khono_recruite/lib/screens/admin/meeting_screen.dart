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
    final primaryRed = const Color.fromRGBO(151, 18, 8, 1);

    return Scaffold(
      // 🌆 Dynamic background implementation
      body: Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage(themeProvider.backgroundImage),
            fit: BoxFit.cover,
          ),
        ),
        child: Scaffold(
          backgroundColor: Colors.transparent,
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(themeProvider, primaryRed),
                  const SizedBox(height: 20),
                  Expanded(
                      child: _buildMeetingsSection(themeProvider, primaryRed)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(ThemeProvider themeProvider, Color primaryRed) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            IconButton(
              onPressed: () => Navigator.pop(context),
              icon: Icon(
                Icons.arrow_back,
                color: themeProvider.isDarkMode
                    ? Colors.white
                    : AppColors.textDark,
              ),
            ),
            Text(
              'Meetings',
              style: GoogleFonts.poppins(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: themeProvider.isDarkMode
                    ? Colors.white
                    : AppColors.textDark,
              ),
            ),
          ],
        ),

        // New Meeting Button
        ElevatedButton.icon(
          onPressed: () => _showMeetingForm(),
          icon: const Icon(Icons.video_call, size: 20),
          label: Text(
            'New Meeting',
            style: GoogleFonts.inter(),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: primaryRed,
            foregroundColor: Colors.white,
          ),
        ),
      ],
    );
  }

  Widget _buildMeetingsSection(ThemeProvider themeProvider, Color primaryRed) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color:
            (themeProvider.isDarkMode ? const Color(0xFF14131E) : Colors.white)
                .withOpacity(0.9),
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
          // Tabs
          Row(
            children: [
              _buildTab('Upcoming', 0, themeProvider, primaryRed),
              const SizedBox(width: 8),
              _buildTab('Past', 1, themeProvider, primaryRed),
              const SizedBox(width: 8),
              _buildTab('All', 2, themeProvider, primaryRed),
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
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: Colors.grey.shade300,
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: Colors.grey.shade300,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: primaryRed,
                        width: 2,
                      ),
                    ),
                    fillColor: (themeProvider.isDarkMode
                            ? const Color(0xFF14131E)
                            : Colors.grey.shade50)
                        .withOpacity(0.9),
                    filled: true,
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    hintStyle: GoogleFonts.inter(
                      color: themeProvider.isDarkMode
                          ? Colors.grey.shade400
                          : Colors.grey.shade600,
                    ),
                  ),
                  style: GoogleFonts.inter(
                    color: themeProvider.isDarkMode
                        ? Colors.white
                        : Colors.black87,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: _isLoading
                ? Center(
                    child: CircularProgressIndicator(
                      color: primaryRed,
                    ),
                  )
                : _meetings.isEmpty
                    ? Center(
                        child: Text('No meetings found',
                            style: GoogleFonts.inter(
                              color: themeProvider.isDarkMode
                                  ? Colors.grey.shade400
                                  : Colors.grey.shade600,
                            )),
                      )
                    : ListView.builder(
                        itemCount: _meetings.length,
                        itemBuilder: (context, index) {
                          final meeting = _meetings[index];
                          return _buildMeetingCard(
                              meeting, themeProvider, primaryRed);
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildTab(
      String text, int index, ThemeProvider themeProvider, Color primaryRed) {
    final isSelected = _selectedTab == index;
    return GestureDetector(
      onTap: () {
        setState(() => _selectedTab = index);
        _loadMeetings();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? primaryRed : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? primaryRed
                : themeProvider.isDarkMode
                    ? Colors.grey.shade800
                    : Colors.grey.shade300,
          ),
        ),
        child: Text(
          text,
          style: GoogleFonts.inter(
            color: isSelected
                ? Colors.white
                : themeProvider.isDarkMode
                    ? Colors.grey.shade400
                    : Colors.grey.shade600,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildMeetingCard(
      Meeting meeting, ThemeProvider themeProvider, Color primaryRed) {
    final isPast = meeting.endTime.isBefore(DateTime.now());
    final isCancelled = meeting.cancelled;

    return Card(
      color: (themeProvider.isDarkMode ? const Color(0xFF14131E) : Colors.white)
          .withOpacity(0.9),
      margin: const EdgeInsets.symmetric(vertical: 6),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        title: Text(meeting.title,
            style: GoogleFonts.inter(
              fontWeight: FontWeight.bold,
              color: themeProvider.isDarkMode ? Colors.white : Colors.black87,
              decoration: isCancelled ? TextDecoration.lineThrough : null,
            )),
        subtitle: Text(
            '${DateFormat('MMM dd, yyyy – hh:mm a').format(meeting.startTime)}',
            style: GoogleFonts.inter(
              color: themeProvider.isDarkMode
                  ? Colors.grey.shade400
                  : Colors.grey.shade600,
            )),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!isCancelled && !isPast)
              IconButton(
                  onPressed: () => _showMeetingForm(meeting: meeting),
                  icon: Icon(Icons.edit, color: primaryRed)),
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
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    final primaryRed = const Color.fromRGBO(151, 18, 8, 1);

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
          backgroundColor: (themeProvider.isDarkMode
                  ? const Color(0xFF14131E)
                  : Colors.white)
              .withOpacity(0.95),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(meeting != null ? 'Edit Meeting' : 'Create Meeting',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w600,
                color: themeProvider.isDarkMode ? Colors.white : Colors.black87,
              )),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleController,
                  decoration: InputDecoration(
                    labelText: 'Title *',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: (themeProvider.isDarkMode
                            ? const Color(0xFF14131E)
                            : Colors.grey.shade50)
                        .withOpacity(0.9),
                    labelStyle: GoogleFonts.inter(
                      color: themeProvider.isDarkMode
                          ? Colors.grey.shade400
                          : Colors.black87,
                    ),
                  ),
                  style: GoogleFonts.inter(
                    color: themeProvider.isDarkMode
                        ? Colors.white
                        : Colors.black87,
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: descController,
                  maxLines: 3,
                  decoration: InputDecoration(
                    labelText: 'Description',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: (themeProvider.isDarkMode
                            ? const Color(0xFF14131E)
                            : Colors.grey.shade50)
                        .withOpacity(0.9),
                    labelStyle: GoogleFonts.inter(
                      color: themeProvider.isDarkMode
                          ? Colors.grey.shade400
                          : Colors.black87,
                    ),
                  ),
                  style: GoogleFonts.inter(
                    color: themeProvider.isDarkMode
                        ? Colors.white
                        : Colors.black87,
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: linkController,
                  decoration: InputDecoration(
                    labelText: 'Meeting Link',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: (themeProvider.isDarkMode
                            ? const Color(0xFF14131E)
                            : Colors.grey.shade50)
                        .withOpacity(0.9),
                    labelStyle: GoogleFonts.inter(
                      color: themeProvider.isDarkMode
                          ? Colors.grey.shade400
                          : Colors.black87,
                    ),
                  ),
                  style: GoogleFonts.inter(
                    color: themeProvider.isDarkMode
                        ? Colors.white
                        : Colors.black87,
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: locationController,
                  decoration: InputDecoration(
                    labelText: 'Location',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: (themeProvider.isDarkMode
                            ? const Color(0xFF14131E)
                            : Colors.grey.shade50)
                        .withOpacity(0.9),
                    labelStyle: GoogleFonts.inter(
                      color: themeProvider.isDarkMode
                          ? Colors.grey.shade400
                          : Colors.black87,
                    ),
                  ),
                  style: GoogleFonts.inter(
                    color: themeProvider.isDarkMode
                        ? Colors.white
                        : Colors.black87,
                  ),
                ),
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
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryRed,
                          foregroundColor: Colors.white,
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
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryRed,
                          foregroundColor: Colors.white,
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
              child: Text(
                'Cancel',
                style: GoogleFonts.inter(
                  color:
                      themeProvider.isDarkMode ? Colors.white : Colors.black87,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                if (titleController.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Title is required'),
                      backgroundColor: primaryRed,
                    ),
                  );
                  return;
                }

                if (startTime == null || endTime == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Start and end times are required'),
                      backgroundColor: primaryRed,
                    ),
                  );
                  return;
                }

                if (endTime!.isBefore(startTime!) ||
                    endTime!.isAtSameMomentAs(startTime!)) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('End time must be after start time'),
                      backgroundColor: primaryRed,
                    ),
                  );
                  return;
                }

                if (startTime!.isBefore(DateTime.now())) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Start time cannot be in the past'),
                      backgroundColor: primaryRed,
                    ),
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
                      backgroundColor: primaryRed,
                      duration: const Duration(seconds: 4),
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryRed,
                foregroundColor: Colors.white,
              ),
              child: Text(meeting != null ? 'Update' : 'Create'),
            ),
          ],
        ),
      ),
    );
  }

  void _cancelMeeting(Meeting meeting) async {
    final primaryRed = const Color.fromRGBO(151, 18, 8, 1);
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
    final primaryRed = const Color.fromRGBO(151, 18, 8, 1);
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
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    final primaryRed = const Color.fromRGBO(151, 18, 8, 1);

    showDialog(
        context: context,
        builder: (context) => AlertDialog(
              backgroundColor: (themeProvider.isDarkMode
                      ? const Color(0xFF14131E)
                      : Colors.white)
                  .withOpacity(0.95),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              title: Text(
                meeting.title,
                style: GoogleFonts.poppins(
                  color:
                      themeProvider.isDarkMode ? Colors.white : Colors.black87,
                ),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Description: ${meeting.description}',
                    style: GoogleFonts.inter(
                      color: themeProvider.isDarkMode
                          ? Colors.white
                          : Colors.black87,
                    ),
                  ),
                  Text(
                    'Location: ${meeting.location}',
                    style: GoogleFonts.inter(
                      color: themeProvider.isDarkMode
                          ? Colors.white
                          : Colors.black87,
                    ),
                  ),
                  Text(
                    'Start: ${meeting.startTime}',
                    style: GoogleFonts.inter(
                      color: themeProvider.isDarkMode
                          ? Colors.white
                          : Colors.black87,
                    ),
                  ),
                  Text(
                    'End: ${meeting.endTime}',
                    style: GoogleFonts.inter(
                      color: themeProvider.isDarkMode
                          ? Colors.white
                          : Colors.black87,
                    ),
                  ),
                  Text(
                    'Link: ${meeting.meetingLink}',
                    style: GoogleFonts.inter(
                      color: themeProvider.isDarkMode
                          ? Colors.white
                          : Colors.black87,
                    ),
                  ),
                  Text(
                    'Participants: ${meeting.participants.join(", ")}',
                    style: GoogleFonts.inter(
                      color: themeProvider.isDarkMode
                          ? Colors.white
                          : Colors.black87,
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                    'Close',
                    style: GoogleFonts.inter(
                      color: themeProvider.isDarkMode
                          ? Colors.white
                          : Colors.black87,
                    ),
                  ),
                )
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
