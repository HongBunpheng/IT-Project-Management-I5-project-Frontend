import 'package:flutter/material.dart';
import '../configs/app_colors.dart';
import 'login_screen.dart';
import '../screens/attendance/attendance_screen.dart';
import '../repositories/auth_repository.dart';
import '../utils/helpers.dart';
import '../utils/validators.dart';

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

    if (res["statusCode"] == 200) {
      Helpers.showSnackBar(context, "Register Successful!");

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const AttendanceScreen()),
      );
    } else {
      Helpers.showSnackBar(
        context,
        res["body"]["message"] ?? "Registration failed",
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
                          "Sign Up",
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
                              label: "Full Name",
                              controller: _nameController,
                              hint: "Enter your name",
                              validator: Validators.validateName,
                            ),

                            // EMAIL
                            buildField(
                              label: "Email",
                              controller: _emailController,
                              hint: "Enter your email",
                              validator: Validators.validateEmail,
                            ),

                            // PHONE
                            buildField(
                              label: "Phone Number",
                              controller: _phoneController,
                              hint: "Enter your phone",
                              validator: Validators.validatePhone,
                            ),

                            // PASSWORD
                            buildField(
                              label: "Set Password",
                              controller: _passwordController,
                              hint: "Enter your password",
                              obscure: _hidePassword,
                              validator: Validators.validatePassword,
                              toggle: () {
                                setState(() => _hidePassword = !_hidePassword);
                              },
                            ),

                            const SizedBox(height: 30),

                            // REGISTER BUTTON
                            SizedBox(
                              width: double.infinity,
                              height: 50,
                              child: ElevatedButton(
                                onPressed: _isLoading ? null : _handleRegister,
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
                                    : const Text(
                                        "Register",
                                        style: TextStyle(
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
                                const Text("Already have an account? "),
                                TextButton(
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => const LoginScreen(),
                                      ),
                                    );
                                  },
                                  child: const Text(
                                    "Login",
                                    style: TextStyle(
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
