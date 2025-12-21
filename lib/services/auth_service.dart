// API calling

import 'dart:convert';
import 'package:http/http.dart' as http;
import '../configs/app_constants.dart';

class AuthService {
  Future<Map<String, dynamic>> login({
    required String emailOrPhone,
    required String password,
  }) async {
    final url = Uri.parse(AppConstants.baseUrl + AppConstants.loginEndpoint);

    final response = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "email": emailOrPhone, 
        "password": password,
      }),
    );

    return {
      "statusCode": response.statusCode,
      "body": jsonDecode(response.body),
    };
  }

Future<Map<String, dynamic>> register({
  required String fullName,
  required String email,
  required String phone,
  required String password,
}) async {
  final url = Uri.parse("${AppConstants.baseUrl}/auth/register");

  final response = await http.post(
    url,
    headers: {"Content-Type": "application/json"},
    body: jsonEncode({
      "user_name": fullName,
      "email": email,
      "phone": phone,
      "password": password,
      "gender": "F",
      "role": "student",
    }),
  );

  return {
    "statusCode": response.statusCode,
    "body": jsonDecode(response.body),
  };
}


}
