import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:inspecto_shield_partner/constants/api_constants.dart';
import 'package:inspecto_shield_partner/models/capa_model.dart';
import 'package:inspecto_shield_partner/models/gemba_walk_model.dart';
import 'package:inspecto_shield_partner/services/secure_storage_service.dart';

class GembaWalkService {
  Future<List<GembaWalkModel>> fetchAssignedWalks(String token) async {
    try {
      final response = await http.get(
        Uri.parse(ApiConstants.gembaWalks),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final dynamic decoded = jsonDecode(response.body);
        final List list = (decoded is Map && decoded.containsKey('data'))
            ? (decoded['data'] ?? [])
            : (decoded is List ? decoded : []);
        return list
            .whereType<Map>()
            .map((e) => GembaWalkModel.fromJson(Map<String, dynamic>.from(e)))
            .toList();
      }
      throw Exception('Failed to load gemba walks (${response.statusCode})');
    } catch (e) {
      debugPrint('Error fetchAssignedWalks: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> fetchWalkDetail(int id) async {
    final token = await SecureStorageService.getToken();
    if (token == null || token.isEmpty) {
      return {'success': false, 'message': 'Session expired'};
    }

    try {
      final res = await http.get(
        Uri.parse(ApiConstants.gembaWalkDetail(id)),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 30));

      if (res.statusCode == 200) {
        final body = jsonDecode(res.body);
        return {
          'success': true,
          'data': body['data'],
          'checklist': body['checklist'] ?? [],
          'response_options': body['response_options'] ?? [],
          'max_photos_per_point': body['max_photos_per_point'] ?? 3,
          'remarks_max_length': body['remarks_max_length'] ?? 2000,
          'capas': body['capas'] ?? [],
          'can_submit': body['can_submit'] ?? false,
          'can_add_capa': body['can_add_capa'] ?? false,
        };
      }
      return {
        'success': false,
        'message': 'Server error: ${res.statusCode}',
      };
    } catch (e) {
      debugPrint('fetchWalkDetail error: $e');
      return {
        'success': false,
        'message': 'Network error. Check your internet connection.'
      };
    }
  }

  Future<Map<String, dynamic>> submitWalk({
    required int walkId,
    required List<Map<String, dynamic>> responses,
    required Map<int, List<File>> photos,
  }) async {
    final token = await SecureStorageService.getToken();
    if (token == null || token.isEmpty) {
      return {'success': false, 'message': 'Session expired'};
    }

    final req = http.MultipartRequest(
      'POST',
      Uri.parse(ApiConstants.gembaWalkSubmit(walkId)),
    )..headers.addAll({
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      });

    for (int i = 0; i < responses.length; i++) {
      req.fields['responses[$i][checklist_item_id]'] = '${responses[i]['id']}';
      req.fields['responses[$i][response]'] = responses[i]['response'];
      req.fields['responses[$i][remarks]'] = responses[i]['remarks'] ?? '';
    }

    for (final e in photos.entries) {
      for (final f in e.value) {
        req.files.add(
          await http.MultipartFile.fromPath('photos[${e.key}][]', f.path),
        );
      }
    }

    try {
      final streamed = await req.send().timeout(const Duration(seconds: 90));
      final res = await http.Response.fromStream(streamed);

      if (res.statusCode == 200 || res.statusCode == 201) {
        final body = jsonDecode(res.body);
        return {
          'success': true,
          'message': body['message'] ?? 'Submitted successfully!',
          'data': body,
        };
      }

      debugPrint('Submit failed: ${res.statusCode} — ${res.body}');
      return {
        'success': false,
        'message': 'Server error: ${res.statusCode}',
      };
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  Future<Map<String, dynamic>> fetchCapas({
    String scope = 'assigned',
    String? status,
  }) async {
    final token = await SecureStorageService.getToken();
    if (token == null || token.isEmpty) {
      return {'success': false, 'message': 'Session expired'};
    }

    try {
      final uri = Uri.parse(ApiConstants.gembaCapas).replace(
        queryParameters: {
          'scope': scope,
          if (status != null && status.isNotEmpty) 'status': status,
        },
      );

      final res = await http.get(
        uri,
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 30));

      if (res.statusCode == 200) {
        final body = jsonDecode(res.body);
        final list = (body['data'] as List? ?? [])
            .whereType<Map>()
            .map((e) => CapaModel.fromJson(Map<String, dynamic>.from(e)))
            .toList();
        return {
          'success': true,
          'data': list,
        };
      }
      return {'success': false, 'message': 'Server error: ${res.statusCode}'};
    } catch (e) {
      debugPrint('fetchCapas error: $e');
      return {
        'success': false,
        'message': 'Network error. Check your internet connection.'
      };
    }
  }

  Future<Map<String, dynamic>> fetchCapaOptions(int walkId) async {
    final token = await SecureStorageService.getToken();
    if (token == null || token.isEmpty) {
      return {'success': false, 'message': 'Session expired'};
    }

    try {
      final res = await http.get(
        Uri.parse(ApiConstants.gembaCapaOptions(walkId)),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 30));

      if (res.statusCode == 200) {
        return {'success': true, 'data': jsonDecode(res.body)};
      }
      return {'success': false, 'message': 'Server error: ${res.statusCode}'};
    } catch (e) {
      debugPrint('fetchCapaOptions error: $e');
      return {
        'success': false,
        'message': 'Network error. Check your internet connection.'
      };
    }
  }

  Future<Map<String, dynamic>> submitCapas({
    required int walkId,
    required List<Map<String, dynamic>> capas,
  }) async {
    final token = await SecureStorageService.getToken();
    if (token == null || token.isEmpty) {
      return {'success': false, 'message': 'Session expired'};
    }

    try {
      final res = await http
          .post(
            Uri.parse(ApiConstants.gembaCapasCreate(walkId)),
            headers: {
              'Accept': 'application/json',
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
            body: jsonEncode({'capas': capas}),
          )
          .timeout(const Duration(seconds: 60));

      if (res.statusCode == 200 || res.statusCode == 201) {
        final body = jsonDecode(res.body);
        return {
          'success': true,
          'message': body['message'] ?? 'CAPA submitted',
          'data': body,
        };
      }
      return {
        'success': false,
        'message': 'Server error: ${res.statusCode}',
      };
    } catch (e) {
      debugPrint('submitCapas error: $e');
      return {
        'success': false,
        'message': 'Network error. Check your internet connection.'
      };
    }
  }

  Future<Map<String, dynamic>> completeCapa({
    required int capaId,
    required String completionRemarks,
    required List<File> photos,
  }) async {
    final token = await SecureStorageService.getToken();
    if (token == null || token.isEmpty) {
      return {'success': false, 'message': 'Session expired'};
    }

    try {
      final req = http.MultipartRequest(
        'POST',
        Uri.parse(ApiConstants.gembaCapaComplete(capaId)),
      )..headers.addAll({
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        });

      req.fields['completion_remarks'] = completionRemarks;

      for (final f in photos) {
        req.files.add(
          await http.MultipartFile.fromPath('photos[]', f.path),
        );
      }

      final streamed = await req.send().timeout(const Duration(seconds: 90));
      final res = await http.Response.fromStream(streamed);

      if (res.statusCode == 200 || res.statusCode == 201) {
        final body = jsonDecode(res.body);
        return {
          'success': true,
          'message': body['message'] ?? 'CAPA completed',
          'data': body['data'],
        };
      }

      debugPrint('completeCapa failed: ${res.statusCode} — ${res.body}');
      return {
        'success': false,
        'message': 'Server error: ${res.statusCode}',
      };
    } catch (e) {
      debugPrint('completeCapa error: $e');
      return {'success': false, 'message': 'Network error. Check internet.'};
    }
  }
}
