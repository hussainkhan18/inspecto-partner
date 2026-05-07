import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:techno_shield/services/api_service.dart';
import '/models/user_model.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class UserViewModel extends ChangeNotifier {
  final ApiService apiService =
      ApiService(baseUrl: 'https://jalmanagementsystem.com/api');
  User? _currentUser;

  User? get currentUser => _currentUser;

  Future<void> loadUserFromPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    final userData = prefs.getString('userData');
    if (userData != null) {
      _currentUser = User.fromJson(json.decode(userData));
      notifyListeners();
    }
  }

  Future<void> saveUserToPreferences(User user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('userData', json.encode(user.toJson()));
  }

  Future<void> clearUserPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('userData');
  }

  Future<Map<String, dynamic>> loginUser(String email, String password) async {
    final response = await http.post(
      Uri.parse('https://jalmanagementsystem.com/api/customer_login'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode({
        'email': email,
        'password': password,
      }),
    );

    if (response.statusCode == 200) {
      final responseData = json.decode(response.body);
      if (responseData['success'] == true) {
        _currentUser = User.fromJson(responseData['user']);
        await saveUserToPreferences(_currentUser!);
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

  Future<List<Item>> fetchProducts(String referralCode) async {
    try {
      final response = await apiService.getProducts(referralCode);
      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);
        if (jsonData['data'] is List) {
          return (jsonData['data'] as List)
              .map((item) => Item.fromJson(item))
              .toList();
        } else {
          throw Exception('Failed to load products: Invalid data format');
        }
      } else {
        throw Exception('Failed to load products: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('An error occurred: $e');
    }
  }

  Future<List<BannerItem>> fetchBanners(String referralCode) async {
    try {
      final response = await apiService.getBanners(referralCode);
      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);
        if (jsonData['data'] is List) {
          return (jsonData['data'] as List)
              .map((item) => BannerItem.fromJson(item))
              .toList();
        } else {
          throw Exception('Failed to load banners: Invalid data format');
        }
      } else {
        throw Exception('Failed to load banners: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('An error occurred: $e');
    }
  }

  // Future<String> registerUser(User user) async {
  //   final response = await http.post(
  //     Uri.parse('https://jalmanagementsystem.com/api/customer_register'),
  //     headers: <String, String>{
  //       'Content-Type': 'application/json; charset=UTF-8',
  //     },
  //     body: jsonEncode(user.toJson()),
  //   );

  //   if (response.statusCode == 200) {
  //     return "Registration successful";
  //   } else {
  //     Map<String, dynamic> responseBody = jsonDecode(response.body);
  //     if (responseBody['message'] != null &&
  //         responseBody['message']['email'] != null) {
  //       return responseBody['message']['email'][0];
  //     }
  //     return "An error occurred";
  //   }
  // }

  Future<String> registerUser(User user, XFile? profileImage) async {
    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('https://jalmanagementsystem.com/api/customer_register'),
      );

      request.headers.addAll({
        'Content-Type': 'multipart/form-data',
      });

      // Add text fields to request
      request.fields['name'] = user.name;
      request.fields['address'] = user.address;
      request.fields['phone_number'] = user.phoneNumber;
      request.fields['category'] = user.category;
      request.fields['id_card_no'] = user.idCardNo;
      request.fields['email'] = user.email;
      request.fields['password'] = user.password ?? '';
      request.fields['confirm_password'] = user.confirmPassword ?? '';
      request.fields['refrel_code'] = user.referralCode ?? '';
      request.fields['zone_id'] = user.zoneId;
      request.fields['latitude'] = user.latitude ?? '';
      request.fields['longitude'] = user.longitude ?? '';

      // Conditionally add image if selected
      if (profileImage != null) {
        print('Image path: ${profileImage.path}');

        request.files.add(
          await http.MultipartFile.fromPath(
            'profile_image', // Correct field name based on the error message
            profileImage.path,
          ),
        );
      }

      var response = await request.send();
      var responseBody = await http.Response.fromStream(response);

      if (response.statusCode == 200) {
        print(response.statusCode);

        return "Registration successful";
      } else {
        print('Error response body: ${responseBody.body}');
        print(
            'Error response body: ${responseBody.body}'); // Log the response body

        Map<String, dynamic> jsonResponse = jsonDecode(responseBody.body);

        if (jsonResponse['message'] != null &&
            jsonResponse['message']['email'] != null) {
          return jsonResponse['message']['email'][0];
        }
        return "An error occurred: ${jsonResponse['message'] ?? responseBody.body}";
      }
    } catch (e) {
      return "An exception occurred: $e";
    }
  }

  Future<void> logoutUser() async {
    _currentUser = null;
    await clearUserPreferences();
    notifyListeners();
  }
}
