import 'dart:convert';
import 'dart:io';
import 'package:inspecto_shield_partner/constants/api_constants.dart';
import 'package:http/http.dart' as http;

class EquipmentService {
  // ── FETCH EQUIPMENT DATA ───────────────────────────────────

  static Future<Map<String, dynamic>?> fetchEquipmentData(
      String reportId) async {
    final response = await http.get(
      Uri.parse('${ApiConstants.generate}/$reportId'),
    );
    if (response.statusCode == 200) {
      return json.decode(response.body)["data"];
    } else {
      throw Exception('Failed to load equipment data');
    }
  }

  // ── GET CERTIFICATE DATA ───────────────────────────────────

  static Future<String?> getCertificateData(String reportId) async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConstants.getCertificate}/$reportId'),
      );
      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        return jsonResponse["data"]["certificate_img"];
      }
      return null;
    } catch (e) {
      print('Error getting certificate: $e');
      return null;
    }
  }

  // ── POST CERTIFICATE ───────────────────────────────────────

  static Future<bool> postCertificate({
    required String reportId,
    required File certificateImg,
    required String issuanceDate,
    required String expiryDate,
  }) async {
    var request = http.MultipartRequest(
      'POST',
      Uri.parse('${ApiConstants.certificate}/$reportId'),
    );
    request.files.add(
      await http.MultipartFile.fromPath('certificate_img', certificateImg.path),
    );
    request.fields['issuance_date'] = issuanceDate;
    request.fields['expiry_date'] = expiryDate;

    var streamedResponse = await request.send();
    var response = await http.Response.fromStream(streamedResponse);
    return response.statusCode == 200;
  }

  // ── SAVE CHECKLIST ─────────────────────────────────────────

  static Future<Map<String, dynamic>> saveCheckList({
    required Map<String, dynamic> equipmentData,
    required File imageFile,
    File? certificateFile,
    required String reportId,
    required int inspectorId,
    required String inspectorName,
    required String issuanceDate,
    required String expiryDate,
    required Map<String, String> checklistItems,
    String? notes,
  }) async {
    var request = http.MultipartRequest(
      'POST',
      Uri.parse(ApiConstants.inspection),
    );

    // Images
    request.files.add(
      await http.MultipartFile.fromPath('current_img', imageFile.path),
    );
    if (certificateFile != null && certificateFile.path.isNotEmpty) {
      request.files.add(
        await http.MultipartFile.fromPath(
            'certificate_img', certificateFile.path),
      );
    }

    // Fields — bilkul same jo new_inspection.dart mein the
    request.fields['equipment_id'] = equipmentData["equipment_id"].toString();
    request.fields['report_id'] = reportId;
    request.fields['checklist_id'] =
        equipmentData["checklist_id"]?.toString() ?? '';
    request.fields['issuance_date'] = issuanceDate;
    request.fields['expiry_date'] = expiryDate;
    request.fields['inspector_name'] = inspectorName;
    request.fields['area'] = equipmentData["area"];
    request.fields['location_id'] = equipmentData["location_id"];
    request.fields['location_description'] =
        equipmentData["location_description"] ?? '';
    request.fields['location_name'] = equipmentData["location"] ?? '';
    request.fields['created_by'] = inspectorId.toString();
    request.fields['equipment_name'] = equipmentData["equipment_name"] ?? '';

    if (notes != null && notes.trim().isNotEmpty) {
      request.fields['notes'] = notes.trim();
    }

    // Checklist tags
    int index = 1;
    checklistItems.forEach((key, value) {
      request.fields['tag$index'] = value;
      index++;
    });

    var response = await request.send();
    var responseString = await response.stream.bytesToString();
    return {
      'statusCode': response.statusCode,
      'body': jsonDecode(responseString),
    };
  }
}
