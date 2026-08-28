import 'dart:io';
import 'package:flutter/material.dart';
import 'package:inspecto_shield_partner/LanguageTranslate/app_localizations.dart';
import 'package:inspecto_shield_partner/Providers/edit_Profile_Provider.dart';
import 'package:inspecto_shield_partner/Screens/HomeScreen.dart';
import 'package:image_picker/image_picker.dart';
import 'package:loading_icon_button/loading_icon_button.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'package:inspecto_shield_partner/services/auth_service.dart';

class Profile extends StatefulWidget {
  int id;
  String name;
  String company;
  String branch;
  String email;
  // String password;
  String image;
  String contact;

  Profile({
    super.key,
    required this.id,
    required this.name,
    required this.company,
    required this.branch,
    required this.email,
    // required this.password,
    required this.image,
    required this.contact,
  });

  @override
  State<Profile> createState() => _ProfileState();
}

class _ProfileState extends State<Profile> {
  // ─── Controllers ─────────────────────────────────────────────────────────────
  TextEditingController name = TextEditingController();
  TextEditingController company = TextEditingController();
  TextEditingController branch = TextEditingController();
  TextEditingController contact = TextEditingController();
  TextEditingController email = TextEditingController();
  TextEditingController password = TextEditingController();

  File? _imageFile;
  final picker = ImagePicker();
  bool imageChanged = false;
  bool isLoading = false;
  bool _obscurePassword = true;

  // ─── Brand color ──────────────────────────────────────────────────────────────
  static const Color _teal = Color(0xff0DC5B9);
  static const Color _bgColor = Color(0xffF4F6F8);

  @override
  void initState() {
    print(widget.image);
    downloadImageFromURL(widget.image);
    name.text = widget.name;
    company.text = widget.company;
    branch.text = widget.branch;
    contact.text = widget.contact;
    email.text = widget.email;
    // password.text = widget.password;
    super.initState();
  }

  // ─── All original logic — untouched ──────────────────────────────────────────

  Future<void> downloadImageFromURL(String imageUrl) async {
    try {
      var response = await http.get(Uri.parse(imageUrl));
      if (response.statusCode == 200) {
        var tempDir = Directory.systemTemp;
        var tempImagePath = '${tempDir.path}/temp_image.jpg';
        var file = File(tempImagePath);
        await file.writeAsBytes(response.bodyBytes);
        Provider.of<EditProfileProvider>(context, listen: false)
            .changePath(file.path);
      } else {
        print('Failed to download image');
      }
    } catch (e) {
      print('Error downloading image: $e');
    }
  }

  Future<void> pickImage() async {
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
        widget.image = _imageFile!.path;
        imageChanged = true;
      });
    }
  }

  // REMOVE poora login() method aur REPLACE:
  Future<void> login() async {
    try {
      final jsonResponse = await AuthService.login(
        email.text,
        password.text,
      );
      if (!mounted) return;

      if (jsonResponse["success"] == true) {
        await AuthService.saveSession(jsonResponse);
        if (!mounted) return;
        Navigator.of(context).pushAndRemoveUntil(
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
          (Route<dynamic> route) => false,
        );
      } else {
        _showSnack(jsonResponse["message"] is String
            ? jsonResponse["message"]
            : "Login failed. Please try again.");
      }
    } catch (e) {
      _showSnack("Connection error. Please try again.");
    }
  }

  // REMOVE poora profileUpdate() aur REPLACE:
  Future<void> profileUpdate() async {
    if (name.text.isEmpty) {
      _showSnack(
          AppLocalizations.of(context)!.translate("Name Field is required"));
      return;
    }
    if (contact.text.isEmpty) {
      _showSnack(
          AppLocalizations.of(context)!.translate("Contact Field is required"));
      return;
    }
    if (password.text.isEmpty) {
      _showSnack(AppLocalizations.of(context)!
          .translate("Password Field is required"));
      return;
    }

    try {
      final imagePath = imageChanged
          ? widget.image
          : Provider.of<EditProfileProvider>(context, listen: false).path;

      final jsonResponse = await AuthService.updateProfile(
        id: widget.id,
        name: name.text,
        email: email.text,
        contact: contact.text,
        password: password.text,
        imagePath: imagePath,
      );
      if (!mounted) return;

      if (jsonResponse["success"] == true ||
          jsonResponse["status_code"] == 200) {
        _showSnack(
          AppLocalizations.of(context)!
              .translate("Profile Updated Successfully"),
          isError: false,
        );
        await login();
      } else {
        final msg = jsonResponse["message"];
        if (msg is String) {
          _showSnack(msg);
        } else if (msg is Map) {
          if (msg["email"] != null) {
            _showSnack(msg["email"][0]);
          } else if (msg["password"] != null) {
            _showSnack(msg["password"][0]);
          }
        }
      }
    } catch (e) {
      _showSnack("Connection error. Please try again.");
    }
  }

  void _showSnack(String message, {bool isError = true}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: isError ? Colors.redAccent : _teal,
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

  // ─── Build ────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgColor,
      body: SingleChildScrollView(
        child: Column(
          children: [
            // ════════════════════════════════════════
            // HEADER — Gradient banner + Avatar + Info
            // ════════════════════════════════════════
            Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.bottomCenter,
              children: [
                // Gradient banner
                Container(
                  height: 200,
                  width: double.infinity,
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xff0DC5B9), Color(0xff089990)],
                    ),
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(36),
                      bottomRight: Radius.circular(36),
                    ),
                  ),
                  child: Stack(
                    children: [
                      // Decorative circles
                      Positioned(
                        top: -30,
                        right: -30,
                        child: Container(
                          width: 130,
                          height: 130,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withOpacity(0.07),
                          ),
                        ),
                      ),
                      Positioned(
                        top: 40,
                        right: 50,
                        child: Container(
                          width: 55,
                          height: 55,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withOpacity(0.07),
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: 30,
                        left: -15,
                        child: Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withOpacity(0.05),
                          ),
                        ),
                      ),
                      // Back + Title
                      SafeArea(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              GestureDetector(
                                onTap: () => Navigator.pop(context),
                                child: Container(
                                  padding: const EdgeInsets.all(9),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.18),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: const Icon(
                                    Icons.arrow_back_ios_new_rounded,
                                    color: Colors.white,
                                    size: 17,
                                  ),
                                ),
                              ),
                              const Spacer(),
                              Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    AppLocalizations.of(context)!
                                        .translate('USER ACCOUNT'),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 17,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 0.4,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Container(
                                    width: 30,
                                    height: 2.5,
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.45),
                                      borderRadius: BorderRadius.circular(2),
                                    ),
                                  ),
                                ],
                              ),
                              const Spacer(),
                              const SizedBox(width: 36),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Avatar overlapping
                Positioned(
                  bottom: -54,
                  child: GestureDetector(
                    onTap: pickImage,
                    child: Stack(
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 4),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xff0DC5B9).withOpacity(0.3),
                                blurRadius: 22,
                                offset: const Offset(0, 8),
                              ),
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 8,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: CircleAvatar(
                            radius: 52,
                            backgroundColor: Colors.grey.shade200,
                            backgroundImage: imageChanged != true
                                ? NetworkImage(widget.image)
                                : FileImage(File(_imageFile!.path))
                                    as ImageProvider,
                          ),
                        ),
                        Positioned(
                          bottom: 3,
                          right: 3,
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: const Color(0xff1A1A2E),
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2),
                            ),
                            child: const Icon(Icons.camera_alt_rounded,
                                color: Colors.white, size: 12),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 70),

            // Name
            Text(
              widget.name,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: Color(0xff1A1A2E),
                letterSpacing: 0.2,
              ),
            ),
            const SizedBox(height: 4),
            // Email
            Text(
              widget.email,
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey.shade500,
                fontWeight: FontWeight.w400,
              ),
            ),
            const SizedBox(height: 12),
            // Company + Branch pills
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _infoPill(Icons.business_outlined, widget.company),
                const SizedBox(width: 8),
                _infoPill(Icons.account_tree_outlined, widget.branch),
              ],
            ),

            const SizedBox(height: 28),

            // ════════════════════════════════════════
            // SECTION 1 — Edit Personal Info
            // ════════════════════════════════════════
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _buildCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _sectionLabel(Icons.edit_outlined, 'Edit Information'),
                    const SizedBox(height: 16),
                    _buildInputField(
                      label: 'Full Name',
                      controller: name,
                      icon: Icons.person_outline_rounded,
                      keyboardType: TextInputType.name,
                    ),
                    const SizedBox(height: 14),
                    _buildInputField(
                      label: 'Contact Number',
                      controller: contact,
                      icon: Icons.phone_outlined,
                      keyboardType: TextInputType.phone,
                    ),
                    const SizedBox(height: 14),
                    _buildPasswordField(),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // ════════════════════════════════════════
            // SECTION 2 — Account Info (display only)
            // ════════════════════════════════════════
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _buildCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _sectionLabel(Icons.badge_outlined, 'Account Details'),
                    const SizedBox(height: 14),
                    _infoRow(
                      icon: Icons.email_outlined,
                      label: 'Email',
                      value: widget.email,
                    ),
                    _divider(),
                    _infoRow(
                      icon: Icons.business_outlined,
                      label: 'Company',
                      value: widget.company,
                    ),
                    _divider(),
                    _infoRow(
                      icon: Icons.account_tree_outlined,
                      label: 'Branch',
                      value: widget.branch,
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 28),

            // ════════════════════════════════════════
            // SAVE BUTTON
            // ════════════════════════════════════════
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: ArgonButton(
                width: MediaQuery.of(context).size.width,
                height: 52,
                borderRadius: 12.0,
                elevation: 0,
                color: _teal,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.check_rounded,
                        color: Colors.white, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      AppLocalizations.of(context)!.translate('SAVE'),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
                onTap: (startLoading, stopLoading, btnState) async {
                  startLoading();
                  await profileUpdate();
                  stopLoading();
                },
              ),
            ),

            const SizedBox(height: 36),
          ],
        ),
      ),
    );
  }

  // ─── White card container ────────────────────────────────────────────────────
  Widget _buildCard({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xffEEF0F3), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 18,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }

  // ─── Section label ────────────────────────────────────────────────────────────
  Widget _sectionLabel(IconData icon, String text) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: _teal.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 14, color: _teal),
        ),
        const SizedBox(width: 10),
        Text(
          text,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: Color(0xff1A1A2E),
            letterSpacing: 0.2,
          ),
        ),
      ],
    );
  }

  // ─── Info row (display only — no text field) ─────────────────────────────────
  Widget _infoRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 13),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xffF4F6F8),
              borderRadius: BorderRadius.circular(9),
            ),
            child: Icon(icon, size: 17, color: Colors.grey.shade500),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey.shade500,
                    letterSpacing: 0.2,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xff1A1A2E),
                  ),
                ),
              ],
            ),
          ),
          Icon(Icons.lock_outline_rounded,
              size: 14, color: Colors.grey.shade300),
        ],
      ),
    );
  }

  Widget _divider() =>
      Divider(height: 1, thickness: 1, color: Colors.grey.shade100);

  // ─── Editable input field ────────────────────────────────────────────────────
  Widget _buildInputField({
    required String label,
    required TextEditingController controller,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 11.5,
            fontWeight: FontWeight.w600,
            color: Colors.grey.shade500,
            letterSpacing: 0.3,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          height: 50,
          decoration: BoxDecoration(
            color: const Color(0xffFAFBFC),
            border: Border.all(color: const Color(0xffDDE1E7), width: 1.2),
            borderRadius: BorderRadius.circular(11),
          ),
          child: Row(
            children: [
              const SizedBox(width: 14),
              Icon(icon, size: 18, color: _teal),
              const SizedBox(width: 10),
              Expanded(
                child: TextField(
                  controller: controller,
                  keyboardType: keyboardType,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Color(0xff1A1A2E),
                  ),
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ─── Password field with show/hide ───────────────────────────────────────────
  Widget _buildPasswordField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Password',
          style: TextStyle(
            fontSize: 11.5,
            fontWeight: FontWeight.w600,
            color: Colors.grey.shade500,
            letterSpacing: 0.3,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          height: 50,
          decoration: BoxDecoration(
            color: const Color(0xffFAFBFC),
            border: Border.all(color: const Color(0xffDDE1E7), width: 1.2),
            borderRadius: BorderRadius.circular(11),
          ),
          child: Row(
            children: [
              const SizedBox(width: 14),
              Icon(Icons.lock_outline_rounded, size: 18, color: _teal),
              const SizedBox(width: 10),
              Expanded(
                child: TextField(
                  controller: password,
                  obscureText: _obscurePassword,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Color(0xff1A1A2E),
                  ),
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ),
              GestureDetector(
                onTap: () =>
                    setState(() => _obscurePassword = !_obscurePassword),
                child: Padding(
                  padding: const EdgeInsets.only(right: 14),
                  child: Icon(
                    _obscurePassword
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                    size: 18,
                    color: Colors.grey.shade400,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ─── Info pill ────────────────────────────────────────────────────────────────
  Widget _infoPill(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xff0DC5B9).withOpacity(0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
            color: const Color(0xff0DC5B9).withOpacity(0.2), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: const Color(0xff0DC5B9)),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Color(0xff0DC5B9),
            ),
          ),
        ],
      ),
    );
  }
}
