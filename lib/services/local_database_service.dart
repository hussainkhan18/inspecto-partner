import 'dart:convert';
import 'package:inspecto_shield_partner/services/offline_equipment_image_downloader.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class LocalDbException implements Exception {
  final String message;
  final Object? cause;
  LocalDbException(this.message, [this.cause]);
  @override
  String toString() =>
      'LocalDbException: $message${cause != null ? " ($cause)" : ""}';
}

class LocalDatabaseService {
  LocalDatabaseService._internal();
  static final LocalDatabaseService instance = LocalDatabaseService._internal();

  static Database? _db;

  static const String tableEquipment = 'cached_equipment';
  static const String tableInspections = 'offline_inspections';

  Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await _initDb();
    return _db!;
  }

  Future<Database> _initDb() async {
    try {
      final dbPath = await getDatabasesPath();
      final path = join(dbPath, 'inspecto_partner_offline.db');
      return await openDatabase(path, version: 1, onCreate: _onCreate);
    } catch (e) {
      throw LocalDbException('Failed to open local database', e);
    }
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE $tableEquipment (
        report_id TEXT PRIMARY KEY,
        equipment_id TEXT,
        equipment_name TEXT,
        area TEXT,
        area_id TEXT,
        location_id TEXT,
        location TEXT,
        location_description TEXT,
        description TEXT,
        equipment_type TEXT,
        equipment_category TEXT,
        equipment_sub_category TEXT,
        checklist TEXT,
        certificate_permission TEXT,
        checklist_id TEXT,
        tags_json TEXT,
        equipment_img TEXT,
        local_image_path TEXT,
        certificate_img TEXT,
        issuance_date TEXT,
        expiry_date TEXT,
        purchase_date TEXT,
        purchase_price TEXT,
        warranty_expiry_date TEXT,
        last_inspection_date TEXT,
        created_by TEXT,
        cached_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE $tableInspections (
        local_id TEXT PRIMARY KEY,
        report_id TEXT NOT NULL,
        equipment_id TEXT,
        equipment_name TEXT,
        area TEXT,
        location_id TEXT,
        location_name TEXT,
        location_description TEXT,
        checklist_id TEXT,
        inspector_id INTEGER,
        inspector_name TEXT,
        issuance_date TEXT,
        expiry_date TEXT,
        notes TEXT,
        checklist_json TEXT NOT NULL,
        image_path TEXT NOT NULL,
        certificate_path TEXT,
        created_at TEXT NOT NULL,
        sync_status TEXT NOT NULL DEFAULT 'pending',
        sync_error TEXT,
        retry_count INTEGER NOT NULL DEFAULT 0,
        uploaded_at TEXT,
        last_retry_at TEXT
      )
    ''');
    await db.execute(
        'CREATE INDEX idx_inspection_sync_status ON $tableInspections(sync_status)');
  }

  // ───────── EQUIPMENT CACHE ─────────
  Future<void> replaceEquipmentCache(
    List<Map<String, dynamic>> equipmentList, {
    void Function(int done, int total)? onProgress,
  }) async {
    try {
      final db = await database;
      final now = DateTime.now().toIso8601String();
      final total = equipmentList.length;

      await OfflineEquipmentImageDownloader.clearAll();

      final localImagePaths = <String, String?>{};
      for (int i = 0; i < equipmentList.length; i++) {
        final e = equipmentList[i];
        final reportId = e['report_id']?.toString();
        if (reportId == null || reportId.isEmpty) continue;
        localImagePaths[reportId] =
            await OfflineEquipmentImageDownloader.downloadAndSave(
                e['equipment_img']?.toString(), reportId);
        onProgress?.call(i + 1, total);
      }

      await db.transaction((txn) async {
        await txn.delete(tableEquipment);
        for (final e in equipmentList) {
          final reportId = e['report_id']?.toString();
          if (reportId == null || reportId.isEmpty) continue;

          await txn.insert(
            tableEquipment,
            {
              'report_id': reportId,
              'equipment_id': e['equipment_id']?.toString(),
              'equipment_name': e['equipment_name']?.toString(),
              'area': e['area']?.toString(),
              'area_id': e['area_id']?.toString(),
              'location_id': e['location_id']?.toString(),
              'location': e['location']?.toString(),
              'location_description': e['location_description']?.toString(),
              'description': e['description']?.toString(),
              'equipment_type': e['equipment_type']?.toString(),
              'equipment_category': e['equipment_category']?.toString(),
              'equipment_sub_category': e['equipment_sub_category']?.toString(),
              'checklist': e['checklist']?.toString(),
              'certificate_permission': e['certificate_permission']?.toString(),
              'checklist_id': e['checklist_id']?.toString(),
              'tags_json': jsonEncode(e['tags'] ?? []),
              'equipment_img': e['equipment_img']?.toString(),
              'local_image_path': localImagePaths[reportId],
              'certificate_img': e['certificate_img']?.toString(),
              'issuance_date': e['issuance_date']?.toString(),
              'expiry_date': e['expiry_date']?.toString(),
              'purchase_date': e['purchase_date']?.toString(),
              'purchase_price': e['purchase_price']?.toString(),
              'warranty_expiry_date': e['warranty_expiry_date']?.toString(),
              'last_inspection_date': e['last_inspection_date']?.toString(),
              'created_by': e['created_by']?.toString(),
              'cached_at': now,
            },
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
        }
      });
    } catch (e) {
      throw LocalDbException('Failed to refresh equipment cache', e);
    }
  }

  List<dynamic> _safeDecodeTags(String? tagsJson) {
    if (tagsJson == null || tagsJson.isEmpty) return [];
    try {
      final decoded = jsonDecode(tagsJson);
      return decoded is List ? decoded : [];
    } catch (_) {
      return [];
    }
  }

  Future<Map<String, dynamic>?> getEquipmentByReportId(String reportId) async {
    try {
      final db = await database;
      final rows = await db.query(tableEquipment,
          where: 'report_id = ?', whereArgs: [reportId], limit: 1);
      if (rows.isEmpty) return null;
      final row = Map<String, dynamic>.from(rows.first);
      row['tags'] = _safeDecodeTags(row['tags_json'] as String?);
      return row;
    } catch (e) {
      throw LocalDbException('Failed to look up equipment $reportId', e);
    }
  }

  // ───────── OFFLINE INSPECTIONS ─────────
  Future<void> insertOfflineInspection(Map<String, dynamic> inspection) async {
    try {
      final db = await database;
      await db.insert(tableInspections, inspection,
          conflictAlgorithm: ConflictAlgorithm.replace);
    } catch (e) {
      throw LocalDbException('Failed to save offline inspection', e);
    }
  }

  Future<List<Map<String, dynamic>>> getPendingInspections() async {
    try {
      final db = await database;
      return await db.query(tableInspections,
          where: 'sync_status = ?',
          whereArgs: ['pending'],
          orderBy: 'created_at ASC');
    } catch (e) {
      throw LocalDbException('Failed to fetch pending inspections', e);
    }
  }

  Future<int> getPendingCount() async {
    try {
      final db = await database;
      final result = await db.rawQuery(
          "SELECT COUNT(*) as count FROM $tableInspections WHERE sync_status = 'pending'");
      return Sqflite.firstIntValue(result) ?? 0;
    } catch (e) {
      throw LocalDbException('Failed to count pending inspections', e);
    }
  }

  Future<void> updateSyncStatus(
    String localId,
    String status, {
    String? error,
    bool markRetryAttempt = false,
    bool markUploaded = false,
  }) async {
    try {
      final db = await database;
      final now = DateTime.now().toIso8601String();
      final values = <String, Object?>{
        'sync_status': status,
        'sync_error': error,
      };
      if (markRetryAttempt) values['last_retry_at'] = now;
      if (markUploaded) values['uploaded_at'] = now;
      await db.update(tableInspections, values,
          where: 'local_id = ?', whereArgs: [localId]);
    } catch (e) {
      throw LocalDbException('Failed to update sync status for $localId', e);
    }
  }

  Future<void> incrementRetryCount(String localId) async {
    try {
      final db = await database;
      await db.rawUpdate(
        'UPDATE $tableInspections SET retry_count = retry_count + 1, last_retry_at = ? WHERE local_id = ?',
        [DateTime.now().toIso8601String(), localId],
      );
    } catch (e) {
      throw LocalDbException('Failed to increment retry count for $localId', e);
    }
  }

  Future<void> deleteInspection(String localId) async {
    try {
      final db = await database;
      await db.delete(tableInspections,
          where: 'local_id = ?', whereArgs: [localId]);
    } catch (e) {
      throw LocalDbException('Failed to delete inspection $localId', e);
    }
  }

  Future<Map<String, dynamic>?> getInspectionById(String localId) async {
    try {
      final db = await database;
      final rows = await db.query(tableInspections,
          where: 'local_id = ?', whereArgs: [localId], limit: 1);
      return rows.isEmpty ? null : Map<String, dynamic>.from(rows.first);
    } catch (e) {
      throw LocalDbException('Failed to fetch inspection $localId', e);
    }
  }
}