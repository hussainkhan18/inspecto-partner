/*
  Authors : initappz (Rahul Jograna)
  Website : https://initappz.com/
  App Name : Flutter UI Kit
  This App Template Source code is licensed as per the
  terms found in the Website https://initappz.com/license
  Copyright and Good Faith Purchasers © 2021-present initappz.
*/
import 'package:flutter/material.dart';
import 'package:techno_shield/routes/app_routes.dart';
import 'package:techno_shield/views/login_signup_screens/login.dart';
import 'package:techno_shield/views/login_signup_screens/signup.dart';
import 'package:techno_shield/widgets/simple_btn.dart';
import '../../helper/style.dart' as style;

class WelcomePage extends StatefulWidget {
  const WelcomePage({super.key, Title? title});
  final String title = '';
  static const String page_id = 'Welcome';

  @override
  State<WelcomePage> createState() => _WelcomePageState();
}

class _WelcomePageState extends State<WelcomePage> {
  late double deviceWidth;

  @override
  Widget build(BuildContext context) {
    deviceWidth = MediaQuery.of(context).size.width;
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: style.appColor),
      ),
      body:
          _buildBody(), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }

  Widget _buildBody() {
    return Container(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image.asset(
          //   'assets/images/techno logo.png',
          //   // height: 200,
          //   fit: BoxFit.fill,
          // ),
          Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Image.asset('assets/images/techno logo.png', width: 70),
                const SizedBox(height: 20),
                const Text(
                  'Welcome to  techno',
                  style: TextStyle(fontFamily: 'semi-bold', fontSize: 26),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Shop everything you need without the trip to the supermarket.',
                  style: TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 40),
                SimpleButton(
                  btnName: 'Login',
                  onPressed: () {
                    Navigator.pushNamed(context, AppRoutes.loginPage);
                  },
                ),
                Container(
                    margin: const EdgeInsets.only(bottom: 20),
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: () {
                        Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => SignupPage()));
                      },
                      style: style.outlineButton(),
                      child: Text('Create Account'),
                    ))
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Widget _buildSimpleButton() {
  //   return Container(
  //     width: double.infinity,
  //     margin: EdgeInsets.only(bottom: 24),
  //     child: ElevatedButton(
  //       onPressed: () {
  //         Navigator.push(context,
  //             new MaterialPageRoute(builder: (context) => new LoginPage()));
  //       },
  //       child: Text('Login'),
  //       style: style.simpleButton(),
  //     ),
  //   );
  // }
}
