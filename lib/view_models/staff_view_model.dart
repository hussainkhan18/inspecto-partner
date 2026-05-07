import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:techno_shield/models/staff_model.dart';

class StaffViewModel extends ChangeNotifier {
  Staff? _currentStaff;

  Staff? get currentStaff => _currentStaff;

  Future<void> loadStaffFromPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    final staffData = prefs.getString('staffData');
    print("staffData: $staffData"); // Debug print
    if (staffData != null) {
      _currentStaff = Staff.fromJson(json.decode(staffData));
      notifyListeners();
    } else {
      print("No staff data found in preferences.");
    }
  }

  // Save image URL to SharedPreferences
  //   Future<void> saveCompanyImageUrl(String imageUrl) async {
  //     SharedPreferences prefs = await SharedPreferences.getInstance();
  //     await prefs.setString('companyImageUrl', imageUrl);
  //   }
  //   Future<File> downloadAndSaveImage(String url, String fileName) async {
  //   final response = await http.get(Uri.parse(url));
  //   final documentDirectory = await getApplicationDocumentsDirectory();
  //   final file = File('${documentDirectory.path}/$fileName');
  //   file.writeAsBytesSync(response.bodyBytes);
  //   return file;
  // }

  // Get the local file path for the image
  // Future<String> getLocalImagePath(String fileName) async {
  //   final documentDirectory = await getApplicationDocumentsDirectory();
  //   return '${documentDirectory.path}/$fileName';
  // }

  // Retrieve image URL from SharedPreferences
  // Future<String?> getCompanyImageUrl() async {
  //   SharedPreferences prefs = await SharedPreferences.getInstance();
  //   return prefs.getString('companyImageUrl');
  // }

  Future<void> saveStaffToPreferences(Staff staff) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('staffData', json.encode(staff.toJson()));
    print("Staff data saved: ${json.encode(staff.toJson())}"); // Debug print
  }

  Future<void> clearStaffPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('staffData');
  }

  Future<Map<String, dynamic>> loginStaff(String email, String password) async {
    final response = await http.post(
      Uri.parse(
        'https://inspecto-partner.stageserverofbss.com/api/technician_login',
      ),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode({'email': email, 'password': password}),
    );

    if (response.statusCode == 200) {
      final responseData = json.decode(response.body);
      if (responseData['success'] == true) {
        // Assuming responseData['user'] contains the staff user details
        // Replace with your actual Staff model parsing logic
        _currentStaff = Staff.fromJson(responseData['user']);
        await saveStaffToPreferences(_currentStaff!);
        notifyListeners();
        return {'status': 'success', 'message': 'Login successful'};
      } else {
        return {'status': 'error', 'message': responseData['message']};
      }
    } else {
      Map<String, dynamic> responseBody = jsonDecode(response.body);
      String errorMessage = responseBody['message'];
      return {'status': 'error', 'message': errorMessage};
    }
  }

  Future<void> logoutStaff() async {
    _currentStaff = null;
    await clearStaffPreferences();
    notifyListeners();
  }
}
