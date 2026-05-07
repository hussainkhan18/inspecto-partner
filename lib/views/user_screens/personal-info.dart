import 'package:flutter/material.dart';
import 'package:techno_shield/models/user_model.dart';
import 'package:techno_shield/view_models/auth/user_view_model.dart';
import '/helper/style.dart' as style;
import 'package:provider/provider.dart';

class PersonalInfoPage extends StatefulWidget {
  const PersonalInfoPage({super.key});

  @override
  State<PersonalInfoPage> createState() => _PersonalInfoPageState();
}

class _PersonalInfoPageState extends State<PersonalInfoPage> {
  @override
  Widget build(BuildContext context) {
    final userViewModel = Provider.of<UserViewModel>(context);
    final user = userViewModel.currentUser;

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        automaticallyImplyLeading: true,
        iconTheme: const IconThemeData(
          color: style.appColor,
        ),
        title: const Text('Personal Info'),
        centerTitle: false,
        titleTextStyle: style.pageTitle(),
      ),
      body: _buildBody(user),
    );
  }

  Widget _buildBody(User? user) {
    if (user == null) {
      return const Center(child: Text('No user data available'));
    }
    print(user.companyImg);

    return SingleChildScrollView(
      child: Container(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 24),
            Image.network(
              '${user.companyImg}', // Replace with your image URL
              loadingBuilder: (BuildContext context, Widget child,
                  ImageChunkEvent? loadingProgress) {
                if (loadingProgress == null) {
                  return child;
                } else {
                  return Center(
                    child: CircularProgressIndicator(
                      value: loadingProgress.expectedTotalBytes != null
                          ? loadingProgress.cumulativeBytesLoaded /
                              loadingProgress.expectedTotalBytes!
                          : null,
                    ),
                  );
                }
              },
              errorBuilder:
                  (BuildContext context, Object error, StackTrace? stackTrace) {
                return const Text('Failed to load image');
              },
            ),
            _buildRow('Email', user.email),
            _buildRow('Name', user.name),
            _buildRow('Address', user.address),
            // _buildRow('Location', user.location),
            _buildRow('Phone Number', user.phoneNumber),
            _buildRow('Category', user.category),
            _buildRow('ID Card No', user.idCardNo),
            _buildRow('Zone ID', user.zoneId),
          ],
        ),
      ),
    );
  }

  Widget _buildRow(String label, String value) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: style.bottomBorder(),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(value),
        ],
      ),
    );
  }
}
