import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:inspecto_shield_partner/repositories/compliance_repository.dart';
import 'package:inspecto_shield_partner/services/secure_storage_service.dart';

class ComplianceSyncResult {
  final int synced;
  final int failed;
  const ComplianceSyncResult({required this.synced, required this.failed});
}

class _BatchResult {
  final int synced;
  final int failed;
  final bool networkDown;
  const _BatchResult({
    required this.synced,
    required this.failed,
    this.networkDown = false,
  });
}

class ComplianceSyncService {
  ComplianceSyncService._();

  static const String _syncUrl =
      'https://partner.inspectoshield.com/api/offline/sync-compliance-inspections';
  static const Duration _timeout = Duration(seconds: 60);
  static const int _batchSize = 5;

  static Future<ComplianceSyncResult> syncPending() async {
    final repo = ComplianceRepository.instance;
    final pending = await repo.getPendingSubmissions();
    if (pending.isEmpty) {
      return const ComplianceSyncResult(synced: 0, failed: 0);
    }

    int synced = 0;
    int failed = 0;

    final validRows = <Map<String, dynamic>>[];
    for (final row in pending) {
      final localId = row['local_id']?.toString() ?? '';
      if (localId.isEmpty) continue;

      final imagePath = row['proof_image_path']?.toString() ?? '';
      if (imagePath.isEmpty || !await File(imagePath).exists()) {
        await repo.markFailed(localId, 'Proof image file missing');
        failed++;
        continue;
      }
      validRows.add(row);
    }

    for (int i = 0; i < validRows.length; i += _batchSize) {
      final end = (i + _batchSize < validRows.length)
          ? i + _batchSize
          : validRows.length;
      final batch = validRows.sublist(i, end);

      final result = await _sendBatch(repo, batch);
      synced += result.synced;
      failed += result.failed;

      if (result.networkDown) {
        failed += validRows.length - end;
        break;
      }
    }

    return ComplianceSyncResult(synced: synced, failed: failed);
  }

  static Future<_BatchResult> _sendBatch(
    ComplianceRepository repo,
    List<Map<String, dynamic>> rows,
  ) async {
    final localIds = <String>[];
    final imagePaths = <String?>[];
    final payload = <Map<String, dynamic>>[];
    int failed = 0;

    for (final row in rows) {
      final localId = row['local_id'].toString();
      final imagePath = row['proof_image_path']?.toString();

      List<dynamic> decodedAnswers = [];
      try {
        decodedAnswers = jsonDecode(row['answers_json']?.toString() ?? '[]');
      } catch (_) {
        decodedAnswers = [];
      }

      final checklistResponses = decodedAnswers.map((a) {
        final map = a as Map<String, dynamic>;
        final responseType = map['response_type']?.toString() ?? 'yes_no';
        final rawValue = map['response']?.toString() ?? '';
        final value = rawValue.trim().toLowerCase();

        dynamic responseValue;
        if (responseType == 'rating_1_5') {
          responseValue = int.tryParse(rawValue) ?? rawValue;
        } else if (responseType == 'text') {
          responseValue = rawValue;
        } else if (value == 'na') {
          responseValue = 'na';
        } else if (responseType == 'pass_fail') {
          responseValue = (value == 'fail' || value == 'no') ? 'fail' : 'pass';
        } else {
          responseValue = (value == 'yes' || value == 'pass') ? 'yes' : 'no';
        }

        return {'id': map['id'], 'response': responseValue};
      }).toList();

      String base64Image;
      try {
        final bytes = await File(imagePath!).readAsBytes();
        base64Image = 'data:image/jpeg;base64,${base64Encode(bytes)}';
      } catch (_) {
        await repo.markFailed(localId, 'Could not read proof image');
        failed++;
        continue;
      }

      localIds.add(localId);
      imagePaths.add(imagePath);
      payload.add({
        'equipment_id':
            int.tryParse(row['equipment_id']?.toString() ?? '') ?? 0,
        'overall_status': row['overall_status'],
        if ((row['notes']?.toString().trim().isNotEmpty ?? false))
          'remarks': row['notes'],
        'inspected_at': row['created_at'],
        'checklist_responses': checklistResponses,
        'proof_images': [base64Image],
      });
    }

    if (payload.isEmpty) {
      return _BatchResult(synced: 0, failed: failed);
    }

    try {
      final token = await SecureStorageService.getToken();

      final response = await http
          .post(
            Uri.parse(_syncUrl),
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
              if (token != null && token.isNotEmpty)
                'Authorization': 'Bearer $token',
            },
            body: jsonEncode({'inspections': payload}),
          )
          .timeout(_timeout);

      final decoded = _decodeBody(response.body);

      if (response.statusCode < 200 ||
          response.statusCode >= 300 ||
          decoded['success'] != true) {
        final message =
            decoded['message']?.toString() ??
            'Sync failed (HTTP ${response.statusCode})';
        for (final localId in localIds) {
          await repo.markFailed(localId, message);
        }
        return _BatchResult(synced: 0, failed: failed + localIds.length);
      }

      final results = (decoded['results'] as List<dynamic>?) ?? [];
      int synced = 0;

      for (int i = 0; i < localIds.length; i++) {
        final matching = (i < results.length && results[i] is Map)
            ? Map<String, dynamic>.from(results[i] as Map)
            : <String, dynamic>{};

        if (matching['success'] == true) {
          await repo.markSynced(localIds[i]);
          await repo.deleteAfterSync(localIds[i], imagePath: imagePaths[i]);
          synced++;
        } else {
          await repo.markFailed(
            localIds[i],
            matching['message']?.toString() ?? 'Item sync failed',
          );
          failed++;
        }
      }

      return _BatchResult(synced: synced, failed: failed);
    } on SocketException {
      return _BatchResult(
        synced: 0,
        failed: failed + localIds.length,
        networkDown: true,
      );
    } on TimeoutException {
      return _BatchResult(
        synced: 0,
        failed: failed + localIds.length,
        networkDown: true,
      );
    } catch (_) {
      for (final localId in localIds) {
        await repo.markFailed(localId, 'Unexpected error while syncing');
      }
      return _BatchResult(synced: 0, failed: failed + localIds.length);
    }
  }

  static Map<String, dynamic> _decodeBody(String body) {
    try {
      final decoded = jsonDecode(body);
      return decoded is Map<String, dynamic> ? decoded : {};
    } catch (_) {
      return {};
    }
  }
}
