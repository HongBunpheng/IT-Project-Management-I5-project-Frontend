/// Mock auth service for UI-only development (no API calls).
class AuthService {
  Future<Map<String, dynamic>> login({
    required String emailOrPhone,
    required String password,
  }) async {
    await Future.delayed(const Duration(milliseconds: 400));

    if (emailOrPhone.trim().isEmpty || password.trim().isEmpty) {
      return {
        "statusCode": 400,
        "body": {"message": "Please enter email/phone and password"},
      };
    }

    // Always succeed for now (UI-only mode)
    return {
      "statusCode": 200,
      "body": {
        "message": "Login Successful (mock)",
        "user": {"emailOrPhone": emailOrPhone.trim()},
      },
    };
  }

  Future<Map<String, dynamic>> register({
    required String fullName,
    required String email,
    required String phone,
    required String password,
  }) async {
    await Future.delayed(const Duration(milliseconds: 400));

    if (fullName.trim().isEmpty ||
        email.trim().isEmpty ||
        phone.trim().isEmpty ||
        password.trim().isEmpty) {
      return {
        "statusCode": 400,
        "body": {"message": "Please fill in all fields"},
      };
    }

    // Always succeed for now (UI-only mode)
    return {
      "statusCode": 200,
      "body": {
        "message": "Register Successful (mock)",
        "user": {
          "fullName": fullName.trim(),
          "email": email.trim(),
          "phone": phone.trim(),
        },
      },
    };
  }
}
