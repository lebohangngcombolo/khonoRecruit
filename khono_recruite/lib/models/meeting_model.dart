class Meeting {
  final int id;
  final String title;
  final DateTime startTime;
  final DateTime endTime;
  final List<String> participants;
  final String? location;
  final String? description;

  Meeting({
    required this.id,
    required this.title,
    required this.startTime,
    required this.endTime,
    required this.participants,
    this.location,
    this.description,
  });

  factory Meeting.fromJson(Map<String, dynamic> json) {
    return Meeting(
      id: json['id'] ?? 0,
      title: json['title']?.toString() ?? 'Untitled Meeting',
      startTime: json['start_time'] != null
          ? DateTime.tryParse(json['start_time'].toString()) ?? DateTime.now()
          : DateTime.now(),
      endTime: json['end_time'] != null
          ? DateTime.tryParse(json['end_time'].toString()) ?? DateTime.now()
          : DateTime.now(),
      participants: (json['participants'] as List<dynamic>?)?.map((p) {
            if (p is String) return p;
            if (p is Map && p.containsKey('name')) return p['name'].toString();
            return p.toString();
          }).toList() ??
          [],
      location: json['location']?.toString(),
      description: json['description']?.toString(),
    );
  }
}
