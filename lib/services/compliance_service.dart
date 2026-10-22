import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:inspecto_shield_partner/constants/api_constants.dart';
import 'package:inspecto_shield_partner/models/compliance_models.dart';
import 'package:inspecto_shield_partner/services/secure_storage_service.dart';

class ComplianceService {
  ComplianceService._();

  static Map<String, dynamic>? lastAddons;

  static Future<Map<String, String>> _authHeaders() async {
    final token = await SecureStorageService.getToken();
    return {
      'Accept': 'application/json',
      if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
    };
  }

  static Future<ComplianceScanAreaResult> scanArea(String areaQrCode) async {
    final decoded = await _post(ApiConstants.complianceScanArea, {
      'area_qr_code': areaQrCode,
    });

    final data = decoded['data'] as Map<String, dynamic>? ?? {};
    final equipmentsJson =
        (data['equipments'] as List<dynamic>?) ?? const <dynamic>[];

    final equipments = equipmentsJson
        .whereType<Map<String, dynamic>>()
        .map(ComplianceEquipment.fromJson)
        .toList();
    final complianceTypes = _parseComplianceTypes(data['compliance_types']);

    debugPrint('compliance_types from API: '
        '${complianceTypes.map((t) => "${t.id}:${t.name}").toList()}');

    final shiftData = data['current_shift'];
    final ratingJson = shiftData is Map ? shiftData['rating'] : null;
    final ratingCriteria = _parseRatingCriteria(ratingJson);
    final starsPerCriteria = _positiveInt(
      ratingJson is Map ? ratingJson['stars_per_criteria'] : null,
      1,
    );
    final totalStars = _positiveInt(
      ratingJson is Map ? ratingJson['total_stars'] : null,
      ratingCriteria.length * starsPerCriteria,
    );
    final maxGroupPhotos = _positiveInt(
      ratingJson is Map ? ratingJson['max_group_photos'] : null,
      3,
    );
    ComplianceCurrentShift? currentShift;
    try {
      final shiftJson = data['current_shift'];
      if (shiftJson is Map) {
        currentShift = ComplianceCurrentShift.fromJson(
          Map<String, dynamic>.from(shiftJson),
        );
      }
    } catch (_) {
      currentShift = null;
    }

    return ComplianceScanAreaResult(
      currentShift: currentShift,
      ratingCriteria: ratingCriteria,
      starsPerCriteria: starsPerCriteria,
      totalStars: totalStars,
      maxGroupPhotos: maxGroupPhotos,
      area: ComplianceArea.fromJson(
        (data['area'] as Map<String, dynamic>?) ?? {},
      ),
      totalEquipments: data['total_equipments'] is int
          ? data['total_equipments'] as int
          : equipmentsJson.length,
      equipments: equipments,
      complianceTypes: complianceTypes,
    );
  }

  // Scan an individual Compliance Point (equipment) QR code within an area.
  static Future<ComplianceScanEquipmentResult> scanEquipment(
    String equipmentQrCode, {
    int? areaId,
  }) async {
    final decoded = await _post(ApiConstants.complianceScanEquipment, {
      'equipment_qr_code': equipmentQrCode,
      if (areaId != null) 'area_id': areaId.toString(),
    });

    final data = decoded['data'] as Map<String, dynamic>? ?? {};
    final checklistJson =
        (data['checklists'] as List<dynamic>?) ?? const <dynamic>[];

    return ComplianceScanEquipmentResult(
      equipment: ComplianceEquipment.fromJson(
        (data['equipment'] as Map<String, dynamic>?) ?? {},
      ),
      checklist: checklistJson
          .whereType<Map<String, dynamic>>()
          .map(ComplianceChecklistItem.fromJson)
          .toList(),
    );
  }

  static Future<ComplianceSubmitResult> submitInspection({
    required int equipmentId,
    int? areaId,
    required String overallStatus,
    required Map<int, String> checklistAnswers,
    required File proofImage,
    String? notes,
  }) async {
    try {
      final request = http.MultipartRequest(
        'POST',
        Uri.parse(ApiConstants.complianceSubmitInspection),
      )
        ..headers.addAll(await _authHeaders())
        ..fields['compliance_equipment_id'] = equipmentId.toString()
        ..fields['overall_status'] = overallStatus
        ..fields['checklist_responses'] = jsonEncode(
          checklistAnswers.entries
              .map((entry) => {'id': entry.key, 'response': entry.value})
              .toList(),
        );

      if (notes != null && notes.trim().isNotEmpty) {
        request.fields['remarks'] = notes.trim();
      }

      debugPrint('COMPLIANCE SUBMIT → fields: ${request.fields}');
      debugPrint(
        'COMPLIANCE SUBMIT → files: ${request.files.map((f) => f.field).toList()}',
      );

      if (!await proofImage.exists()) {
        throw ComplianceApiException(
          'Proof image file is missing. Please retake the photo.',
        );
      }

      request.files.add(
        await http.MultipartFile.fromPath('proof_images[]', proofImage.path),
      );

      debugPrint(
        'Proof image path: ${proofImage.path}, exists: ${await proofImage.exists()}, size: ${await proofImage.length()}',
      );

      final streamed = await request.send().timeout(_timeout);
      final response = await http.Response.fromStream(streamed);
      final decoded = _decodeBody(response.body);

      if (decoded['addons'] != null) {
        lastAddons = Map<String, dynamic>.from(decoded['addons'] as Map);
      }
      if (response.statusCode == 401) {
        throw ComplianceApiException('Session expired. Please log in again.');
      }

      if (response.statusCode < 200 ||
          response.statusCode >= 300 ||
          decoded['status'] != true) {
        debugPrint('Compliance submit status: ${response.statusCode}');
        debugPrint('Compliance submit response: ${response.body}');

        final errors = decoded['errors'];

        if (errors is Map) {
          final errorMessages = errors.values
              .expand(
                (value) => value is List
                    ? value.map((item) => item.toString())
                    : [value.toString()],
              )
              .join('\n');

          throw ComplianceApiException(
            errorMessages.isNotEmpty
                ? errorMessages
                : decoded['message']?.toString() ??
                    'Failed to submit inspection.',
          );
        }

        throw ComplianceApiException(
          decoded['message']?.toString() ?? 'Failed to submit inspection.',
        );
      }

      return ComplianceSubmitResult.fromJson(
        (decoded['data'] as Map<String, dynamic>?) ?? {},
      );
    } on ComplianceApiException {
      rethrow;
    } on TimeoutException {
      throw ComplianceApiException('Request timed out. Please try again.');
    } on SocketException {
      throw ComplianceApiException('No internet connection. Please try again.');
    } catch (_) {
      throw ComplianceApiException(
        'Something went wrong while submitting the inspection.',
      );
    }
  }

  static List<ComplianceRatingCriterion> _parseRatingCriteria(dynamic rating) {
    try {
      if (rating is! Map) return [];
      final list = rating['criteria'];
      if (list is! List) return [];
      return list
          .whereType<Map>()
          .map((e) =>
              ComplianceRatingCriterion.fromJson(Map<String, dynamic>.from(e)))
          .where((c) => c.id != 0)
          .toList();
    } catch (_) {
      return [];
    }
  }

  static int _positiveInt(dynamic value, int fallback) {
    final n = int.tryParse(value?.toString() ?? '');
    return (n != null && n > 0) ? n : fallback;
  }

  static List<ComplianceType> _parseComplianceTypes(dynamic raw) {
    try {
      if (raw is! List) return [];
      return raw
          .whereType<Map>()
          .map((e) => ComplianceType.fromJson(Map<String, dynamic>.from(e)))
          .where((t) => t.id != 0)
          .toList();
    } catch (_) {
      return [];
    }
  }

  static Future<int> submitAreaVisit({
    required int areaId,
    required Map<int, List<int>> employeeCriteria,
    required List<File> groupPhotos,
    String? remarks,
  }) async {
    try {
      final request = http.MultipartRequest(
        'POST',
        Uri.parse(ApiConstants.complianceSubmitAreaVisit),
      )
        ..headers.addAll(await _authHeaders())
        ..fields['area_id'] = areaId.toString();

      if (remarks != null && remarks.trim().isNotEmpty) {
        request.fields['remarks'] = remarks.trim();
      }

      if (employeeCriteria.isNotEmpty) {
        request.fields['ratings'] = jsonEncode(
          employeeCriteria.entries
              .map((e) => {'employee_id': e.key, 'criteria_ids': e.value})
              .toList(),
        );
      }

      for (final photo in groupPhotos) {
        if (!await photo.exists()) continue;
        request.files.add(
          await http.MultipartFile.fromPath('group_photos[]', photo.path),
        );
      }

      final streamed = await request.send().timeout(
            const Duration(seconds: 60),
          );
      final response = await http.Response.fromStream(streamed);
      final decoded = _decodeBodyLenient(response.body);

      if (response.statusCode == 401) {
        throw ComplianceApiException('Session expired. Please log in again.');
      }

      if (response.statusCode < 200 ||
          response.statusCode >= 300 ||
          decoded['status'] != true) {
        debugPrint('Area visit status: ${response.statusCode}');
        debugPrint('Area visit response: ${response.body}');

        final errors = decoded['errors'];
        if (errors is Map) {
          final msg = errors.values
              .expand(
                (v) => v is List ? v.map((i) => i.toString()) : [v.toString()],
              )
              .join('\n');
          if (msg.isNotEmpty) throw ComplianceApiException(msg);
        }
        throw ComplianceApiException(
          decoded['message']?.toString() ?? 'Failed to submit area visit.',
        );
      }

      final data = decoded['data'];
      return data is Map
          ? (int.tryParse(data['visit_id']?.toString() ?? '') ?? 0)
          : 0;
    } on ComplianceApiException {
      rethrow;
    } on TimeoutException {
      throw ComplianceApiException('Request timed out. Please try again.');
    } on SocketException {
      throw ComplianceApiException('No internet connection. Please try again.');
    } catch (_) {
      throw ComplianceApiException(
        'Something went wrong while submitting the area visit.',
      );
    }
  }

  static Map<String, dynamic> _decodeBodyLenient(String body) {
    final start = body.indexOf('{');
    if (start < 0) return {};
    return _decodeBody(body.substring(start));
  }

  static Future<Map<String, dynamic>> _post(
    String url,
    Map<String, String> fields,
  ) async {
    try {
      final response = await http
          .post(Uri.parse(url), headers: await _authHeaders(), body: fields)
          .timeout(_timeout);

      final decoded = _decodeBody(response.body);

      if (response.statusCode == 401) {
        throw ComplianceApiException('Session expired. Please log in again.');
      }

      if (response.statusCode != 200 || decoded['status'] != true) {
        throw ComplianceApiException(
          decoded['message']?.toString() ??
              'Something went wrong. Please try again.',
        );
      }
      return decoded;
    } on ComplianceApiException {
      rethrow;
    } on TimeoutException {
      throw ComplianceApiException(
        'Request timed out. Please check your internet connection.',
      );
    } on SocketException {
      throw ComplianceApiException('No internet connection. Please try again.');
    } catch (_) {
      throw ComplianceApiException('Something went wrong. Please try again.');
    }
  }

  static Map<String, dynamic> _decodeBody(String body) {
    try {
      final decoded = jsonDecode(body);
      if (decoded is Map<String, dynamic>) return decoded;
      return {};
    } catch (_) {
      return {};
    }
  }

  static const Duration _timeout = Duration(seconds: 30);
}
