import 'package:flutter/material.dart';
import 'package:techno_shield/routes/app_routes.dart';
import 'package:techno_shield/view_models/auth/user_view_model.dart';
import 'package:techno_shield/view_models/staff_view_model.dart';
import 'package:provider/provider.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key, Title? title});
  final String title = '';
  static const String page_id = 'Login';

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  String? _errorMessage;
  bool isGuestLoading = false;
  bool isLoginLoading = false;

  @override
  void initState() {
    super.initState();
    _checkLoginStatus();
  }

  Future<void> _checkLoginStatus() async {
    final userViewModel = Provider.of<UserViewModel>(context, listen: false);
    final staffViewModel = Provider.of<StaffViewModel>(context, listen: false);

    await userViewModel.loadUserFromPreferences();
    if (userViewModel.currentUser != null) {
      Navigator.pushReplacementNamed(context, AppRoutes.userTabs);
      return;
    }

    await staffViewModel.loadStaffFromPreferences();
    if (staffViewModel.currentStaff != null) {
      Navigator.pushReplacementNamed(context, AppRoutes.deliveryTabs);
      return;
    }
  }

  Future<void> loginUser() async {
    setState(() {
      _errorMessage = null;
      isLoginLoading = true;
    });

    final email = emailController.text.trim();
    final password = passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      setState(() {
        _errorMessage = 'Enter both email and password';
        isLoginLoading = false;
      });
      return;
    }

    final userViewModel = Provider.of<UserViewModel>(context, listen: false);
    final result = await userViewModel.loginUser(email, password);

    if (result['status'] == 'success') {
      Navigator.pushReplacementNamed(context, AppRoutes.userTabs);
    } else {
      setState(() {
        _errorMessage = result['message'];
        isLoginLoading = false;
      });
    }
  }

  Future<void> loginStaff() async {
    setState(() {
      _errorMessage = null;
      isLoginLoading = true;
    });

    final email = emailController.text.trim();
    final password = passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      setState(() {
        _errorMessage = 'Enter both email and password';
        isLoginLoading = false;
      });
      return;
    }

    final staffViewModel = Provider.of<StaffViewModel>(context, listen: false);
    final result = await staffViewModel.loginStaff(email, password);

    if (result['status'] == 'success') {
      Navigator.pushReplacementNamed(context, AppRoutes.deliveryTabs);
    } else {
      setState(() {
        _errorMessage = result['message'];
        isLoginLoading = false;
      });
    }
  }

  Future<void> loginAsGuest() async {
    setState(() {
      isGuestLoading = true;
      _errorMessage = null;
    });

    final staffViewModel = Provider.of<StaffViewModel>(context, listen: false);

    final result = await staffViewModel.loginStaff(
      'tech.asif@gmail.com',
      '123456',
    );

    if (result['status'] == 'success') {
      Navigator.pushReplacementNamed(context, AppRoutes.deliveryTabs);
    } else {
      setState(() {
        _errorMessage = result['message'];
      });
    }

    setState(() {
      isGuestLoading = false;
    });
  }

  static const _dark = Color(0xFF1A1A2E);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    return SingleChildScrollView(
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: Column(
            children: [
              const SizedBox(height: 16),

              // 🔥 LOGO OUTSIDE CARD
              Center(
                child: Image.asset(
                  'assets/images/techno_logo.png',
                  width: 110,
                ),
              ),

              const SizedBox(height: 24),

              // ─── MAIN CARD ────────────────────────────
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(24, 32, 24, 28),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: const Color(0xFFEEEEEE),
                    width: 1,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ─── TITLES ──────────────────────────
                    const Text(
                      'Sign in',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: _dark,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Enter your credentials to continue',
                      style: TextStyle(
                        fontSize: 13,
                        color: Color(0xFFBDBDBD),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // EMAIL
                    const _FieldLabel(label: 'Email'),
                    const SizedBox(height: 6),
                    _InputField(
                      controller: emailController,
                      hint: 'Enter your email',
                      icon: Icons.email_outlined,
                      keyboardType: TextInputType.emailAddress,
                    ),

                    const SizedBox(height: 16),

                    // PASSWORD
                    const _FieldLabel(label: 'Password'),
                    const SizedBox(height: 6),
                    _InputField(
                      controller: passwordController,
                      hint: 'Enter your password',
                      icon: Icons.lock_outline,
                      obscureText: true,
                    ),

                    const SizedBox(height: 20),

                    if (_errorMessage != null)
                      Container(
                        width: double.infinity,
                        margin: const EdgeInsets.only(bottom: 16),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFF0F0),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: const Color(0xFFFFCDD2),
                            width: 1,
                          ),
                        ),
                        child: Text(
                          _errorMessage!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Color(0xFFE53935),
                            fontSize: 13,
                          ),
                        ),
                      ),

                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: isLoginLoading ? null : () => loginStaff(),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _dark,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: isLoginLoading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.white,
                                  ),
                                ),
                              )
                            : const Text('Login'),
                      ),
                    ),

                    const SizedBox(height: 20),

                    Row(
                      children: [
                        Expanded(child: Divider()),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: Text('or'),
                        ),
                        Expanded(child: Divider()),
                      ],
                    ),

                    const SizedBox(height: 20),

                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: isGuestLoading
                          ? const Center(child: CircularProgressIndicator())
                          : OutlinedButton(
                              onPressed: loginAsGuest,
                              child: const Text('Continue as Guest'),
                            ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── REUSABLE ─────────────────

class _FieldLabel extends StatelessWidget {
  final String label;
  const _FieldLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: Color(0xFF444444),
      ),
    );
  }
}

class _InputField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final IconData icon;
  final bool obscureText;
  final TextInputType? keyboardType;

  const _InputField({
    required this.controller,
    required this.hint,
    required this.icon,
    this.obscureText = false,
    this.keyboardType,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      style: const TextStyle(
        fontSize: 14,
        color: Color(0xFF1A1A2E),
      ),
      decoration: InputDecoration(
        // ✅ YE HI PLACEHOLDER HAI
        hintText: hint,

        hintStyle: const TextStyle(
          color: Color(0xFFBDBDBD), // light grey (placeholder feel)
          fontSize: 12,
          fontWeight: FontWeight.w300,
        ),

        prefixIcon: Icon(
          icon,
          size: 18,
          color: const Color(0xFFBDBDBD),
        ),

        filled: true,
        fillColor: const Color(0xFFF9F9F9),

        contentPadding: const EdgeInsets.symmetric(vertical: 14),

        enabledBorder: OutlineInputBorder(
          borderSide: const BorderSide(
            color: Color(0xFFEEEEEE),
          ),
          borderRadius: BorderRadius.circular(12),
        ),

        focusedBorder: OutlineInputBorder(
          borderSide: const BorderSide(
            color: Color(0xFF1A1A2E),
            width: 1.3,
          ),
          borderRadius: BorderRadius.circular(12),
        ),

        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }
}
