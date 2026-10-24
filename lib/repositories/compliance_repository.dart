import 'dart:convert';
import 'dart:io';

import 'package:inspecto_shield_partner/models/compliance_models.dart';
import 'package:inspecto_shield_partner/services/local_database_service.dart';

class ComplianceRepository {
  ComplianceRepository._internal();
  static final ComplianceRepository instance = ComplianceRepository._internal();

  final LocalDatabaseService _db = LocalDatabaseService.instance;

  // ── Equipment cache ──
  Future<void> refreshCache(
    List<Map<String, dynamic>> equipmentList, {
    void Function(int done, int total)? onProgress,
  }) async {
    await _db.replaceComplianceCache(equipmentList, onProgress: onProgress);
  }

  Future<Map<String, dynamic>?> lookupByQr(String qrCode) async {
    try {
      return await _db.getComplianceEquipmentByQr(qrCode);
    } catch (e) {
      return null;
    }
  }

  Future<List<Map<String, dynamic>>> lookupByArea(String areaId) async {
    try {
      return await _db.getComplianceEquipmentByArea(areaId);
    } catch (e) {
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> lookupByAreaQr(String areaQrCode) async {
    try {
      return await _db.getComplianceEquipmentByAreaQrCode(areaQrCode);
    } catch (e) {
      return [];
    }
  }

  Future<void> saveInspection({
    required String equipmentQrCode,
    required int equipmentId,
    int? areaId,
    required String overallStatus,
    required List<ComplianceChecklistItem> checklist,
    required Map<int, String> answers,
    required String proofImagePath,
    String? notes,
    int? inspectorId,
    String? inspectorName,
  }) async {
    final answerEntries = checklist.map((item) {
      return {
        'id': item.id,
        'response': answers[item.id] ?? '',
        'response_type': item.responseType,
      };
    }).toList();

    final localId = 'compliance_${DateTime.now().microsecondsSinceEpoch}';

    await _db.insertComplianceSubmission({
      'local_id': localId,
      'equipment_qr_code': equipmentQrCode,
      'equipment_id': equipmentId.toString(),
      'area_id': areaId?.toString(),
      'overall_status': overallStatus,
      'answers_json': jsonEncode(answerEntries),
      'proof_image_path': proofImagePath,
      'notes': (notes != null && notes.trim().isNotEmpty) ? notes.trim() : null,
      'inspector_id': inspectorId,
      'inspector_name': inspectorName,
      'created_at': DateTime.now().toIso8601String(),
      'sync_status': 'pending',
      'retry_count': 0,
    });
  }

  // ── Offline submissions ──
  Future<void> saveOfflineSubmission(Map<String, dynamic> submission) async {
    await _db.insertComplianceSubmission(submission);
  }

  Future<int> getPendingCount() async {
    try {
      return await _db.getPendingComplianceCount();
    } catch (e) {
      return 0;
    }
  }

  Future<List<Map<String, dynamic>>> getPendingSubmissions() async {
    try {
      return await _db.getPendingComplianceSubmissions();
    } catch (e) {
      return [];
    }
  }

  Future<void> markSynced(String localId) async {
    await _db.updateComplianceSyncStatus(localId, 'synced', markUploaded: true);
  }

  Future<void> markFailed(String localId, String error,
      {int maxRetries = 3}) async {
    await _db.incrementComplianceRetryCount(localId);

    final row = await _db.getComplianceSubmissionById(localId);
    final retryCount = row?['retry_count'] as int? ?? 0;

    // Retry limit cross na ho to 'pending' hi rakho — agli sync try me dobara uthega
    final newStatus = retryCount >= maxRetries ? 'failed' : 'pending';
    await _db.updateComplianceSyncStatus(localId, newStatus,
        error: error, markRetryAttempt: true);
  }

  Future<Set<String>> getPendingSubmittedQrCodes() async {
    try {
      final pending = await _db.getPendingComplianceSubmissions();
      return pending
          .map((row) => row['equipment_qr_code']?.toString() ?? '')
          .where((qr) => qr.isNotEmpty)
          .toSet();
    } catch (e) {
      return {};
    }
  }

  Future<void> deleteAfterSync(String localId, {String? imagePath}) async {
    if (imagePath != null && imagePath.isNotEmpty) {
      try {
        final file = File(imagePath);
        if (await file.exists()) await file.delete();
      } catch (_) {}
    }
    await _db.deleteComplianceSubmission(localId);
  }
}
