class User {
  final int id;
  final String name;
  final String email;
  final String role;
  final int? applicationId;
  final String phone;
  final String? cvUrl; // ✅ Cloudinary CV URL
  final Map<String, dynamic>? profile; // ✅ Candidate profile info

  User({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.applicationId,
    required this.phone,
    this.cvUrl,
    this.profile,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] ?? 0,
      name: json['name'] ?? 'Unknown',
      email: json['email'] ?? 'no-email@example.com',
      role: json['role'] ?? 'user',
      applicationId: json['application_id'],
      phone: json['phone'] ?? '',
      cvUrl: json['cv_url'], // parse Cloudinary URL
      profile: json['profile'] != null
          ? Map<String, dynamic>.from(json['profile'])
          : {},
    );
  }

  /// Converts User object to Map for form submission or updates
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'role': role,
      'application_id': applicationId,
      'phone': phone,
      'cv_url': cvUrl,
      'profile': profile,
    };
  }
}
