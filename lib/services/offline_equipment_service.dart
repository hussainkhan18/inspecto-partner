import 'dart:convert';
import 'package:inspecto_shield_partner/constants/api_constants.dart';
import 'package:inspecto_shield_partner/models/offline_data_model.dart';
import 'package:http/http.dart' as http;

class OfflineEquipmentService {
  // Agar tumhare partner app me token use hota hai to yahan SecureStorage se
  // token add kar do (jaisa Shield me tha). Warna ye headers kaafi hain.
  static Future<Map<String, String>> _headers() async => {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };

  static Future<List<OfflineAreaModel>> fetchOfflineAreas() async {
    try {
      final response = await http
          .get(Uri.parse(ApiConstants.offlineAreas), headers: await _headers())
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);
        if (jsonResponse['success'] == true && jsonResponse['data'] is List) {
          return (jsonResponse['data'] as List)
              .whereType<Map>()
              .map((e) =>
                  OfflineAreaModel.fromJson(Map<String, dynamic>.from(e)))
              .toList();
        }
      }
      return [];
    } catch (e) {
      print('fetchOfflineAreas failed: $e');
      return [];
    }
  }

  static Future<List<OfflineLocationModel>> fetchOfflineLocations(
      String areaId) async {
    try {
      final uri = Uri.parse(ApiConstants.offlineLocations)
          .replace(queryParameters: {'area_id': areaId});
      final response = await http
          .get(uri, headers: await _headers())
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);
        if (jsonResponse['success'] == true && jsonResponse['data'] is List) {
          return (jsonResponse['data'] as List)
              .whereType<Map>()
              .map((e) =>
                  OfflineLocationModel.fromJson(Map<String, dynamic>.from(e)))
              .toList();
        }
      }
      return [];
    } catch (e) {
      print('fetchOfflineLocations failed: $e');
      return [];
    }
  }

  static Future<List<Map<String, dynamic>>> fetchEquipmentForOfflineCache({
    required String areaId,
    String? locationId,
  }) async {
    try {
      final response = await http
          .post(
            Uri.parse(ApiConstants.offlineEquipmentData),
            headers: await _headers(),
            body: json.encode({
              'area_id': areaId,
              if (locationId != null && locationId.isNotEmpty)
                'location_id': locationId,
            }),
          )
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);
        if (jsonResponse['success'] == true && jsonResponse['data'] is List) {
          return (jsonResponse['data'] as List)
              .whereType<Map>()
              .map((e) => Map<String, dynamic>.from(e))
              .toList();
        }
      }
      return [];
    } catch (e) {
      print('fetchEquipmentForOfflineCache failed: $e');
      return [];
    }
  }
}