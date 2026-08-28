import 'dart:async';
import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:inspecto_shield_partner/constants/api_constants.dart';
import 'package:inspecto_shield_partner/services/secure_storage_service.dart';

class ComplaintService {
  // ─── Shared Helpers ────────────────────────────────────────

  static Future<Map<String, String>> _buildHeaders() async {
    final token = await SecureStorageService.getToken();
    return {
      'Accept': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  static Map<String, dynamic> _handleError(Object e) {
    if (e is SocketException) {
      return {'success': false, 'message': 'No internet connection.'};
    }
    if (e is TimeoutException) {
      return {
        'success': false,
        'message': 'Request timed out. Please try again.'
      };
    }
    return {'success': false, 'message': 'Unexpected error. Please try again.'};
  }

  // ─── Get Complaints ────────────────────────────────────────

  /// Returns:
  ///   {'success': true,  'data': [...], 'total': N}   on success
  ///   {'success': false, 'message': '...'}             on failure
  static Future<Map<String, dynamic>> getComplaintsList(int userId) async {
    try {
      final token = await SecureStorageService.getToken();

      final response = await http.get(
        Uri.parse('${ApiConstants.getComplaints}?user_id=$userId'),
        headers: {
          'Accept': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final body = json.decode(response.body) as Map<String, dynamic>;
        if (body['success'] == true) {
          return {
            'success': true,
            'data': (body['data'] as List).cast<Map<String, dynamic>>(),
            'total': body['total'] ?? 0,
          };
        }
      }

      if (response.statusCode == 401) {
        return {'success': false, 'message': 'Session expired.'};
      }

      return {'success': false, 'message': 'Failed to load complaints.'};
    } catch (e) {
      return {'success': false, 'message': 'Error: $e'};
    }
  }

  // ─── Submit Complaint ──────────────────────────────────────

  /// Returns:
  ///   {'success': true,  'data': {...}}      on success
  ///   {'success': false, 'message': '...'}   on failure
  static Future<Map<String, dynamic>> submitComplaint({
    required String companyEquipmentId,
    required String priority,
    String? remarks,
    List<File>? images,
    File? voiceNote,
  }) async {
    try {
      final headers = await _buildHeaders();
      final request =
          http.MultipartRequest('POST', Uri.parse(ApiConstants.complaints));
      request.headers.addAll(headers);

      // Fields
      request.fields['company_equipment_id'] = companyEquipmentId;
      request.fields['priority'] = priority;
      if (remarks != null && remarks.trim().isNotEmpty) {
        request.fields['remarks'] = remarks.trim();
      }

      // Images
      if (images != null && images.isNotEmpty) {
        for (final file in images) {
          request.files.add(await http.MultipartFile.fromPath(
            'images[]',
            file.path,
            contentType: MediaType('image', 'jpeg'),
          ));
        }
      }

      // Voice Note
      if (voiceNote != null) {
        request.files.add(await http.MultipartFile.fromPath(
          'voice_note',
          voiceNote.path,
          contentType: MediaType('audio', 'wav'),
        ));
      }

      final response = await http.Response.fromStream(
        await request.send().timeout(const Duration(seconds: 60)),
      );
      final body = json.decode(response.body) as Map<String, dynamic>;

      if (response.statusCode == 200 || response.statusCode == 201) {
        if (body['success'] == true) return {'success': true, 'data': body};
        return {
          'success': false,
          'message': body['message'] ?? 'Submission failed.'
        };
      }

      if (response.statusCode == 422) {
        final errors = body['errors'] as Map<String, dynamic>? ?? {};
        String message = body['message'] ?? 'Validation failed.';
        if (errors.isNotEmpty) {
          final first = errors.values.first;
          if (first is List && first.isNotEmpty)
            message = first.first.toString();
        }
        return {'success': false, 'message': message};
      }

      if (response.statusCode == 401) {
        return {
          'success': false,
          'message': 'Session expired. Please login again.'
        };
      }

      return {
        'success': false,
        'message': body['message'] ?? 'Something went wrong. Try again.'
      };
    } catch (e) {
      return _handleError(e);
    }
  }
}
