import 'package:inspecto_shield_partner/models/sync_status.dart';
import 'package:inspecto_shield_partner/services/local_database_service.dart';
import 'package:inspecto_shield_partner/services/offline_image_storage.dart';

class InspectionRepository {
  InspectionRepository._internal();
  static final InspectionRepository instance = InspectionRepository._internal();

  final LocalDatabaseService _db = LocalDatabaseService.instance;

  Future<int> getPendingCount() async {
    try {
      return await _db.getPendingCount();
    } catch (e) {
      return 0;
    }
  }

  Future<List<Map<String, dynamic>>> getPendingInspections() async {
    try {
      return await _db.getPendingInspections();
    } catch (e) {
      return [];
    }
  }

  Future<void> markSynced(String localId) async {
    await _db.updateSyncStatus(localId, SyncStatus.synced.value,
        markUploaded: true);
  }

  Future<void> markFailed(String localId, String error,
      {int maxRetries = 3}) async {
    await _db.incrementRetryCount(localId);

    final row = await _db.getInspectionById(localId);
    final retryCount = row?['retry_count'] as int? ?? 0;

    final newStatus = retryCount >= maxRetries
        ? SyncStatus.failed.value
        : SyncStatus.pending.value;

    await _db.updateSyncStatus(localId, newStatus,
        error: error, markRetryAttempt: true);
  }

  Future<void> saveOfflineInspection(Map<String, dynamic> inspection) async {
    await _db.insertOfflineInspection(inspection);
  }

  Future<void> deleteAfterSync(String localId,
      {String? imagePath, String? certificatePath}) async {
    await OfflineImageStorage.deleteIfExists(imagePath);
    await OfflineImageStorage.deleteIfExists(certificatePath);
    await _db.deleteInspection(localId);
  }
}
