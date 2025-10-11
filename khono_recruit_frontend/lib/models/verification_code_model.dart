class VerificationCode {
  final String email;
  final String code;

  VerificationCode({required this.email, required this.code});

  factory VerificationCode.fromJson(Map<String, dynamic> json) {
    return VerificationCode(
      email: json['email'],
      code: json['code'],
    );
  }
}
