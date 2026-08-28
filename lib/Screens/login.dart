import 'package:flutter/material.dart';
import 'package:inspecto_shield_partner/LanguageTranslate/app_localizations.dart';
import 'package:inspecto_shield_partner/Screens/HomeScreen.dart';
import 'package:loading_icon_button/loading_icon_button.dart';
import 'package:inspecto_shield_partner/services/auth_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  // Global key for form validation state
  final _formKey = GlobalKey<FormState>();
  bool isGuestLoading = false;

  // Controllers to manage text input and retrieval
  final TextEditingController email = TextEditingController();
  final TextEditingController password = TextEditingController();

  // State to toggle password visibility
  bool _isPasswordVisible = false;

  /// Handles the authentication process via [AuthService]
  Future<void> login() async {
    try {
      final jsonResponse = await AuthService.login(
        email.text.trim(),
        password.text,
      );

      // Check if the API returned a successful status
      if (jsonResponse["success"] == true) {
        // Persist user data and session locally
        await AuthService.saveSession(jsonResponse);

        // Prevent navigation if the widget was removed from the tree during the async gap
        if (!mounted) return;

        _showSnack(
          "${AppLocalizations.of(context)!.translate("Welcome")} ${jsonResponse["user"]["fullname"]}",
          isError: false,
        );

        // Navigate to Home and remove the login screen from the stack
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => HomeScreen(
              id: jsonResponse["user"]["id"],
              name: jsonResponse["user"]["fullname"],
              company: jsonResponse["user"]["company_name"],
              branch: jsonResponse["user"]["branch_name"],
              email: jsonResponse["user"]["email"],
              image: jsonResponse["user"]["profile_img"],
              contact: jsonResponse["user"]["contact_number"],
            ),
          ),
        );
      } else {
        _handleApiError(jsonResponse["message"]);
      }
    } catch (e, stackTrace) {
      print("LOGIN ERROR: $e"); // Debug console mein exact error dekho
      _showSnack("No internet connection. Please try again.");
    }
  }

  // login as a guest
  Future<void> loginAsGuest() async {
    setState(() {
      isGuestLoading = true;
    });

    try {
      final jsonResponse = await AuthService.login(
        'arham@gmail.com',
        '123456',
      );

      if (jsonResponse["success"] == true) {
        await AuthService.saveSession(jsonResponse);

        if (!mounted) return;

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => HomeScreen(
              id: jsonResponse["user"]["id"],
              name: jsonResponse["user"]["fullname"],
              company: jsonResponse["user"]["company_name"],
              branch: jsonResponse["user"]["branch_name"],
              email: jsonResponse["user"]["email"],
              image: jsonResponse["user"]["profile_img"],
              contact: jsonResponse["user"]["contact_number"],
            ),
          ),
        );
      } else {
        _showSnack("Guest login failed. Please try again.");
      }
    } catch (e) {
      _showSnack("No internet connection.");
    }

    setState(() {
      isGuestLoading = false;
    });
  }

  /// Parses error messages from the API response
  /// Supports both simple strings and Map-based validation errors (e.g., Laravel style)
  void _handleApiError(dynamic message) {
    if (message is String) {
      _showSnack(message);
    } else if (message is Map) {
      if (message["email"] != null) {
        _showSnack(message["email"][0]);
      } else if (message["password"] != null) {
        _showSnack(message["password"][0]);
      } else {
        _showSnack("Invalid credentials. Please try again.");
      }
    } else {
      _showSnack("Something went wrong. Please try again.");
    }
  }

  /// Displays a consistent SnackBar for feedback across the screen
  void _showSnack(String message, {bool isError = true}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: isError ? Colors.redAccent : const Color(0xff0DC5B9),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        content: Row(
          children: [
            Icon(
              isError ? Icons.error_outline : Icons.check_circle_outline,
              color: Colors.white,
              size: 18,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(color: Colors.white, fontSize: 13),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA), // Soft background color
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: Column(
              children: [
                // Application Branding
                Image.asset(
                  "assets/icon/logo_name.png",
                  height: size.height * 0.12,
                ),
                const SizedBox(height: 30),

                // Main Authentication Card
                Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  color: Colors.white,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20.0, vertical: 32.0),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            AppLocalizations.of(context)!.translate('Sign In'),
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1A1A1A),
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            "Enter your credentials to continue",
                            textAlign: TextAlign.center,
                            style: TextStyle(
                                color: Colors.grey[500], fontSize: 14),
                          ),
                          const SizedBox(height: 30),

                          // Email Field
                          _buildTextField(
                            controller: email,
                            hint: AppLocalizations.of(context)!
                                .translate('Email'),
                            icon: Icons.email_outlined,
                            keyboardType: TextInputType.emailAddress,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return "Email required";
                              }
                              // Basic regex for email validation
                              if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
                                  .hasMatch(value)) {
                                return "Invalid format";
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),

                          // Password Field
                          _buildTextField(
                            controller: password,
                            hint: AppLocalizations.of(context)!
                                .translate('Password'),
                            icon: Icons.lock_outline_rounded,
                            isPassword: true,
                            obscureText: !_isPasswordVisible,
                            suffixIcon: IconButton(
                              icon: Icon(
                                _isPasswordVisible
                                    ? Icons.visibility
                                    : Icons.visibility_off,
                                color: const Color(0xff0DC5B9),
                              ),
                              onPressed: () => setState(() =>
                                  _isPasswordVisible = !_isPasswordVisible),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return "Password required";
                              }
                              if (value.length < 6) return "Min. 6 characters";
                              return null;
                            },
                          ),
                          const SizedBox(height: 30),

                          // Dynamic Loading Button
                          ArgonButton(
                            width: size.width,
                            height: 55,
                            borderRadius: 12.0,
                            color: const Color(0xFF000000),
                            child: Text(
                              AppLocalizations.of(context)!
                                  .translate('SIGN IN'),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            onTap: (startLoading, stopLoading, btnState) async {
                              if (_formKey.currentState!.validate()) {
                                startLoading();
                                try {
                                  await login();
                                } finally {
                                  // Ensure loading stops even if the login logic fails
                                  stopLoading();
                                }
                              }
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Guest Login Button
                isGuestLoading
                    ? const CircularProgressIndicator(color: Color(0xff0DC5B9))
                    : GestureDetector(
                        onTap: () async {
                          await loginAsGuest();
                        },
                        child: Text(
                          AppLocalizations.of(context)!
                              .translate('Continue as Guest'),
                          style: const TextStyle(
                            color: Color(0xff0DC5B9),
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Reusable helper widget to build stylized TextFormFields
  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    bool isPassword = false,
    bool obscureText = false,
    Widget? suffixIcon,
    TextInputType? keyboardType,
    required String? Function(String?) validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      validator: validator,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
        prefixIcon: Icon(icon, color: const Color(0xff0DC5B9), size: 20),
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: const Color(0xFFF9FAFB),
        contentPadding: const EdgeInsets.symmetric(vertical: 18),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[200]!),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[200]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xff0DC5B9), width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.redAccent, width: 1),
        ),
      ),
    );
  }

  @override
  void dispose() {
    // Clean up controllers when the widget is removed from the tree
    email.dispose();
    password.dispose();
    super.dispose();
  }
}
