import 'package:flutter/material.dart';
import '../../configs/app_colors.dart';
import '../../utils/localization_helper.dart';
import 'login_screen.dart';
import '../repository/auth_repository.dart';
import '../../utils/snackbar.dart';
import '../../utils/validators.dart';
import '../../dashboard/screen/dashboard_screen.dart';
import '../../services/token_storage.dart';
import '../../account/service/account_service.dart';
import '../../utils/json_utils.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _hidePassword = true;
  bool _isLoading = false;

  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();

  final AuthRepository _authRepo = AuthRepository();

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final res = await _authRepo.register(
      fullName: _nameController.text.trim(),
      email: _emailController.text.trim(),
      phone: _phoneController.text.trim(),
      password: _passwordController.text.trim(),
    );

    setState(() => _isLoading = false);

    if (!mounted) return;

    final statusCode = res["statusCode"];
    if (statusCode is int && statusCode >= 200 && statusCode < 300) {
      // Verify user data is stored before navigating
      final tokenStorage = TokenStorage();
      var userId = await tokenStorage.readUserId();
      var fullName = await tokenStorage.readFullName();
      var email = await tokenStorage.readEmail();

      // If user ID is still missing, wait a bit more and try to fetch
      if (userId == null || userId.isEmpty) {
        await Future.delayed(const Duration(milliseconds: 1000));
        final profile = await AccountService().getProfile();
        if (profile != null) {
          final data = asMap(profile['data']) ?? profile;
          final user = asMap(data['user']) ?? data;
          final fetchedUserId = readString(user, const ['id', 'user_id', 'userId']);
          final fetchedGroupId = readString(user, const ['group_id', 'groupId']);
          final fetchedFullName = readString(
            user,
            const ['full_name', 'fullName', 'name', 'user_name', 'userName'],
          );
          final fetchedEmail = readString(user, const ['email']);

          if (fetchedUserId != null && fetchedUserId.isNotEmpty) {
            await tokenStorage.writeUserId(fetchedUserId);
          }
          if (fetchedGroupId != null && fetchedGroupId.isNotEmpty) {
            await tokenStorage.writeGroupId(fetchedGroupId);
          }
          if (fetchedFullName != null && fetchedFullName.isNotEmpty) {
            await tokenStorage.writeFullName(fetchedFullName);
          }
          if (fetchedEmail != null && fetchedEmail.isNotEmpty) {
            await tokenStorage.writeEmail(fetchedEmail);
          }
        }
        userId = await tokenStorage.readUserId();
        fullName = await tokenStorage.readFullName();
        email = await tokenStorage.readEmail();
      }

      // Ensure full name and email are stored (use form values as fallback)
      if (fullName == null || fullName.isEmpty) {
        await tokenStorage.writeFullName(_nameController.text.trim());
      }
      if (email == null || email.isEmpty) {
        await tokenStorage.writeEmail(_emailController.text.trim());
      }

      CustomSnackBar.success(
        title: safeLocaleString(
          context,
          'register_successful',
          fallback: "Register Successful!",
        ),
      );

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const DashboardView()),
      );
    } else {
      final body = res["body"];
      String errorMessage = '';

      if (body is Map) {
        // Try to get message
        final message = body["message"];
        if (message != null) {
          errorMessage = message.toString();
        }

        // Try to get errors object (Laravel-style validation errors)
        final errors = body["errors"];
        if (errors is Map) {
          final errorList = <String>[];
          errors.forEach((key, value) {
            if (value is List && value.isNotEmpty) {
              errorList.add('${value.first}');
            } else if (value is String) {
              errorList.add(value);
            }
          });
          if (errorList.isNotEmpty) {
            errorMessage = errorList.join('. ');
          }
        }
      }

      CustomSnackBar.error(
        title: safeLocaleString(
          context,
          'registration_failed',
          fallback: "Registration failed",
        ),
        message: errorMessage,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Always use light mode for signup screen
    return Theme(
      data: ThemeData.light(),
      child: Scaffold(
        backgroundColor: Colors.white,
        body: Stack(
          children: [
            // BLUE CURVE HEADER (same as login)
            ClipPath(
              clipper: _TopCurveClipper(),
              child: Container(
                height: 520,
                width: double.infinity,
                color: AppColors.primaryBlue,
              ),
            ),

            SingleChildScrollView(
              child: Column(
                children: [
                  const SizedBox(height: 80),

                  // LOGO
                  Center(
                    child: Image.asset("assets/images/logo.png", height: 110),
                  ),

                  const SizedBox(height: 20),

                  // WHITE CARD WITH SHADOW (same as login)
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 25),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 30,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.08),
                          spreadRadius: 1,
                          blurRadius: 10,
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // TITLE
                        Center(
                          child: Text(
                            safeLocaleString(
                              context,
                              'signup',
                              fallback: 'Sign Up',
                            ),
                            style: TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primaryBlue,
                            ),
                          ),
                        ),

                        const SizedBox(height: 25),

                        Form(
                          key: _formKey,
                          child: Column(
                            children: [
                              // FULL NAME FIELD
                              buildField(
                                label: safeLocaleString(
                                  context,
                                  'full_name',
                                  fallback: 'Full Name',
                                ),
                                controller: _nameController,
                                hint: safeLocaleString(
                                  context,
                                  'enter_your_name',
                                  fallback: 'Enter your name',
                                ),
                                validator: Validators.validateName,
                              ),

                              // EMAIL
                              buildField(
                                label: safeLocaleString(
                                  context,
                                  'email',
                                  fallback: 'Email',
                                ),
                                controller: _emailController,
                                hint: safeLocaleString(
                                  context,
                                  'enter_your_email',
                                  fallback: 'Enter your email',
                                ),
                                validator: Validators.validateEmail,
                              ),

                              // PHONE
                              buildField(
                                label: safeLocaleString(
                                  context,
                                  'phone_number',
                                  fallback: 'Phone Number',
                                ),
                                controller: _phoneController,
                                hint: safeLocaleString(
                                  context,
                                  'enter_your_phone',
                                  fallback: 'Enter your phone',
                                ),
                                validator: Validators.validatePhone,
                              ),

                              // PASSWORD
                              buildField(
                                label: safeLocaleString(
                                  context,
                                  'password',
                                  fallback: 'Password',
                                ),
                                controller: _passwordController,
                                hint: safeLocaleString(
                                  context,
                                  'enter_password',
                                  fallback: 'Enter your password',
                                ),
                                obscure: _hidePassword,
                                validator: Validators.validatePassword,
                                toggle: () {
                                  setState(
                                    () => _hidePassword = !_hidePassword,
                                  );
                                },
                              ),

                              const SizedBox(height: 30),

                              // REGISTER BUTTON
                              SizedBox(
                                width: double.infinity,
                                height: 50,
                                child: ElevatedButton(
                                  onPressed: _isLoading
                                      ? null
                                      : _handleRegister,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.primaryBlue,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  child: _isLoading
                                      ? const CircularProgressIndicator(
                                          color: Colors.white,
                                        )
                                      : Text(
                                          safeLocaleString(
                                            context,
                                            'sign_up',
                                            fallback: 'Register',
                                          ),
                                          style: const TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.w600,
                                            color: Colors.white,
                                          ),
                                        ),
                                ),
                              ),

                              const SizedBox(height: 20),

                              // BOTTOM "Already have account?"
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    safeLocaleString(
                                      context,
                                      'already_have_account',
                                      fallback: "Already have an account? ",
                                    ),
                                  ),
                                  TextButton(
                                    onPressed: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => const LoginScreen(),
                                        ),
                                      );
                                    },
                                    child: Text(
                                      safeLocaleString(
                                        context,
                                        'login',
                                        fallback: 'Login',
                                      ),
                                      style: const TextStyle(
                                        color: AppColors.primaryBlue,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 50),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // SAME FIELD STYLE AS LOGIN SCREEN
  Widget buildField({
    required String label,
    required TextEditingController controller,
    required String hint,
    bool obscure = false,
    String? Function(String?)? validator,
    VoidCallback? toggle,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            color: Colors.grey,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          obscureText: obscure,
          validator: validator,
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.white,
            hintText: hint,
            hintStyle: const TextStyle(color: Colors.grey, fontSize: 16),
            suffixIcon: toggle != null
                ? IconButton(
                    icon: Icon(
                      obscure ? Icons.visibility_off : Icons.visibility,
                      color: Colors.grey,
                    ),
                    onPressed: toggle,
                  )
                : null,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.grey),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: AppColors.primaryBlue,
                width: 1.5,
              ),
            ),
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }
}

// SAME CURVE CLIPPER AS LOGIN
class _TopCurveClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    Path path = Path();
    path.lineTo(0, size.height - 90);
    path.quadraticBezierTo(
      size.width / 2,
      size.height,
      size.width,
      size.height - 90,
    );
    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => true;
}
