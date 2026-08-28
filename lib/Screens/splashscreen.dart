import 'package:flutter/material.dart';
import 'package:inspecto_shield_partner/Screens/internet_error_popup.dart';
import 'package:inspecto_shield_partner/Screens/login.dart';
import 'package:inspecto_shield_partner/Screens/HomeScreen.dart';
import 'package:inspecto_shield_partner/services/secure_storage_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkSessionAndNavigate();
  }

  Future<void> _checkSessionAndNavigate() async {
    final results = await Future.wait([
      Future.delayed(const Duration(seconds: 7)),
      _loadSessionData(),
    ]);

    if (!mounted) return;

    final sessionData = results[1] as Map<String, dynamic>?;

    if (sessionData != null) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => NetworkWrapper(
            child: HomeScreen(
              id: sessionData['id'],
              name: sessionData['name'],
              company: sessionData['company'],
              branch: sessionData['branch'],
              email: sessionData['email'],
              image: sessionData['image'],
              contact: sessionData['contact'],
            ),
          ),
        ),
      );
      return;
    }

    // No valid session → go to login
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => const NetworkWrapper(child: LoginScreen()),
      ),
    );
  }

  Future<Map<String, dynamic>?> _loadSessionData() async {
    final String? token = await SecureStorageService.getToken();
    final bool isLoggedIn = await SecureStorageService.isLoggedIn();

    if (token == null || token.isEmpty || !isLoggedIn) return null;

    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final int? id = prefs.getInt('id');

    if (id == null || id <= 0) return null;

    return {
      'id': id,
      'name': prefs.getString('name') ?? '',
      'email': prefs.getString('email') ?? '',
      'image': prefs.getString('image') ?? '',
      'contact': prefs.getString('contact') ?? '',
      'company': prefs.getString('company') ?? '',
      'branch': prefs.getString('branch') ?? '',
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SizedBox(
        height: double.infinity,
        width: double.infinity,
        child: Image.asset(
          "assets/inspecto_partner_splash.gif",
          fit: BoxFit.fill,
        ),
      ),
    );
  }
}
