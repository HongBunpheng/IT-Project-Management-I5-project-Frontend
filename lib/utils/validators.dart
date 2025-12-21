class Validators {
  static String? validateEmailOrPhone(String? value) {
    if (value == null || value.isEmpty) return "Please enter email or phone";
    return null;
  }

  static String? validatePassword(String? value) {
    if (value == null || value.isEmpty) return "Please enter password";
    if (value.length < 6) return "Password must be at least 6 characters";
    return null;
  }
}
