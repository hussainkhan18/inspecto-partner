import 'package:flutter/material.dart';
import 'package:techno_shield/views/login_signup_screens/login.dart';
import 'package:techno_shield/views/splash_and_welcome_screen/welcome.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _navigateToWelcomePage();
  }

  Future<void> _navigateToWelcomePage() async {
    await Future.delayed(const Duration(seconds: 5));
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => LoginPage()),
    );
  }
    
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            "assets/images/techno_splash.gif",
            fit: BoxFit.fill,
          ),
        ],
      ),
    );
  }
}
