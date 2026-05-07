import 'package:flutter/material.dart';
import 'package:techno_shield/models/staff_model.dart';
import 'package:techno_shield/view_models/staff_view_model.dart';
import '/helper/style.dart' as style;
import 'package:provider/provider.dart';

class StaffPersonalInfoPage extends StatefulWidget {
  const StaffPersonalInfoPage({super.key});

  @override
  State<StaffPersonalInfoPage> createState() => _PersonalInfoPageState();
}

class _PersonalInfoPageState extends State<StaffPersonalInfoPage> {
  @override
  Widget build(BuildContext context) {
    final staffViewModel = Provider.of<StaffViewModel>(context, listen: false);
    final staff = staffViewModel.currentStaff;
    print(" staff id $staff");

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        automaticallyImplyLeading: true,
        iconTheme: const IconThemeData(
          color: style.appColor,),
        title: const Text('Personal Info'),
        centerTitle: false,
        titleTextStyle: style.pageTitle(),
        ),  

          body: _buildBody(staff),);}

  Widget _buildBody(Staff? staff) {
    if (staff == null) {
      return const Center(child: Text('No user data available'));
    }

    return SingleChildScrollView(
      child: Container(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Center(
              child: Container(
                width: 150,
                height: 150,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  image: DecorationImage(
                    image: NetworkImage(staff.profileImg),
                    fit: BoxFit.cover,
                  ),
                ),
              ),),

            _buildRow('User Name', staff.userName),
            _buildRow('Email', staff.email),
            _buildRow('Name', staff.name),
              _buildRow('Department', staff.department_name),
            
            _buildRow('Contact', staff.contact),

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
