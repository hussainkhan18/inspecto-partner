
import 'package:inspecto_shield_partner/services/local_database_service.dart';

class EquipmentRepository {
  EquipmentRepository._internal();
  static final EquipmentRepository instance = EquipmentRepository._internal();

  final LocalDatabaseService _db = LocalDatabaseService.instance;

  Future<Map<String, dynamic>?> lookupByReportId(String reportId) async {
    try {
      return await _db.getEquipmentByReportId(reportId);
    } catch (e) {
      return null;
    }
  }

  Future<void> refreshCache(
    List<Map<String, dynamic>> equipmentList, {
    void Function(int done, int total)? onProgress,
  }) async {
    await _db.replaceEquipmentCache(equipmentList, onProgress: onProgress);
  }
}
