class User {
  final int id;
  final String email;
  final String role;
  final bool isVerified;
  final Map<String, dynamic> profile;

  User({required this.id, required this.email, required this.role, required this.isVerified, required this.profile});

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      email: json['email'],
      role: json['role'],
      isVerified: json['is_verified'],
      profile: json['profile'] ?? {},
    );
  }
}
