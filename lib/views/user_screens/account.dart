import 'package:flutter/material.dart';
import 'package:techno_shield/models/user_model.dart';
import 'package:techno_shield/routes/app_routes.dart';
import 'package:techno_shield/view_models/auth/user_view_model.dart';
import 'package:provider/provider.dart';

class AccountPage extends StatefulWidget {
  const AccountPage({super.key, Title? title});
  final String title = '';
  static const String page_id = 'Account';

  @override
  State<AccountPage> createState() => _AccountPageState();
}

class _AccountPageState extends State<AccountPage> {
  @override
  Widget build(BuildContext context) {
    final userViewModel = Provider.of<UserViewModel>(context);
    final user = userViewModel.currentUser;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        automaticallyImplyLeading: false,
        iconTheme: const IconThemeData(color: Colors.black),
        title: const Text('Account'),
        centerTitle: false,
      ),
      body: _buildBody(user),
    );
  }

  Widget _buildBody(User? user) {
    if (user == null) {
      return const Center(child: Text('No user data available'));
    }
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: () {
              Navigator.pushNamed(context, AppRoutes.personalInfoPage);
            },
            child: _buildRow('Personal Info'),
          ),
          InkWell(
            onTap: () {},
            child: _buildRow('About'),
          ),
          InkWell(
            onTap: () {},
            child: _buildRow('Help'),
          ),
          InkWell(
            onTap: () async {
              final userViewModel =
                  Provider.of<UserViewModel>(context, listen: false);
              await userViewModel.logoutUser();
              Navigator.pushNamedAndRemoveUntil(
                context,
                AppRoutes.loginPage,
                (route) => false,
              );
            },
            child: _buildRow('Logout'),
          ),
        ],
      ),
    );
  }

  Widget _buildRow(String val) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Colors.grey.shade300),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(val),
          const Icon(Icons.keyboard_arrow_right, color: Colors.grey)
        ],
      ),
    );
  }
}
