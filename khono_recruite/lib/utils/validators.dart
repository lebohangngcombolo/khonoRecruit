class Validators {
  static String? email(String? value) {
    if (value == null || !value.contains('@')) return "Enter valid email";
    return null;
  }

  static String? password(String? value) {
    if (value == null || value.length < 6) return "Password must be at least 6 characters";
    return null;
  }

  static String? requiredField(String? value) {
    if (value == null || value.isEmpty) return "This field is required";
    return null;
  }
}
