import 'dart:convert';
import 'package:inspecto_shield_partner/constants/api_constants.dart';
import 'package:inspecto_shield_partner/services/secure_storage_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:inspecto_shield_partner/services/notification_service.dart';

class AuthService {
  // ── LOGIN ──────────────────────────────────────────────────
  // Bilkul same logic jo login.dart mein tha
  static Future<Map<String, dynamic>> login(
      String email, String password) async {
    String? fcmToken = await NotificationService().getToken();

    final response = await http.post(
      Uri.parse(ApiConstants.login),
      headers: {
        "Accept": "application/json", // ye add karo
      },
      body: {
        "email": email,
        "password": password,
        if (fcmToken != null) "fcm_token": fcmToken,
      },
    );

    // Debug ke liye — status code aur raw body dekho
    print("STATUS CODE: ${response.statusCode}");
    print("RAW BODY: ${response.body}");

    if (response.body.isEmpty) {
      throw Exception("Server returned empty response");
    }

    return jsonDecode(response.body);
  }

  // ── SAVE SESSION ───────────────────────────────────────────
  // Bilkul same logic jo login.dart mein saveUserLogin() tha
  static Future<void> saveSession(Map jsonResponse) async {
    await SecureStorageService.saveToken(jsonResponse["access_token"]);
    await SecureStorageService.setLoggedIn(true);

    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setInt("id", jsonResponse["user"]["id"]);
    await prefs.setString("name", jsonResponse["user"]["fullname"]);
    await prefs.setString("email", jsonResponse["user"]["email"]);
    await prefs.setString("image", jsonResponse["user"]["profile_img"]);
    await prefs.setString("contact", jsonResponse["user"]["contact_number"]);
    await prefs.setString("company", jsonResponse["user"]["company_name"]);
    await prefs.setString("branch", jsonResponse["user"]["branch_name"]);
  }

  // ── PROFILE UPDATE ─────────────────────────────────────────
  // Bilkul same logic jo Profile.dart mein profileUpdate() tha
  static Future<Map<String, dynamic>> updateProfile({
    required int id,
    required String name,
    required String email,
    required String contact,
    required String password,
    required String imagePath,
  }) async {
    var request = http.MultipartRequest(
      'POST',
      Uri.parse(ApiConstants.profileUpdate),
    );

    var image = await http.MultipartFile.fromPath('profile_img', imagePath);
    request.files.add(image);

    request.fields['id'] = id.toString();
    request.fields['fullname'] = name;
    request.fields['email'] = email;
    request.fields['contact_number'] = contact;
    request.fields['password'] = password;
    request.fields['confirm_password'] = password;

    var response = await request.send();
    var responseString = await response.stream.bytesToString();
    return jsonDecode(responseString);
  }

  // ── LOGOUT ─────────────────────────────────────────────────
  static Future<void> logout() async {
    try {
      await NotificationService().deleteToken();
    } catch (e) {
      print("FCM token delete error: $e");
    }
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    await SecureStorageService.clearAll();
  }
}
