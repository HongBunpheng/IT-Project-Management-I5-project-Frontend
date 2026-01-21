import '../services/auth_service.dart';

class AuthRepository {
  final AuthService _auth = AuthService();

  Future<Map<String, dynamic>> login(String emailOrPhone, String password) {
    return _auth.login(emailOrPhone: emailOrPhone, password: password);
  }

  Future<Map<String, dynamic>> register({
    required String fullName,
    required String email,
    required String phone,
    required String password,
  }) {
    return _auth.register(
      fullName: fullName,
      email: email,
      phone: phone,
      password: password,
    );
  }
}
