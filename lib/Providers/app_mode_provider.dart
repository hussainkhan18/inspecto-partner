import 'package:flutter/foundation.dart';
import 'package:inspecto_shield_partner/repositories/inspection_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum AppModeStatus { online, fetching, offline, syncing }
enum SyncPhase { idle, fetchingEquipment, syncing }

class AppModeProvider extends ChangeNotifier {
  static const _kOffline = 'partner_offline_mode';
  static const _kAreaName = 'partner_offline_area_name';
  static const _kLocationName = 'partner_offline_location_name';

  AppModeStatus _status = AppModeStatus.online;
  double _fetchProgress = 0;
  int _syncTotal = 0;
  int _syncDone = 0;
  int _pendingCount = 0;
  String? _areaId;
  String? _areaName;
  String? _locationId;
  String? _locationName;
  String? _message;

  AppModeStatus get status => _status;
  bool get isOfflineMode => _status == AppModeStatus.offline;
  bool get isFetching => _status == AppModeStatus.fetching;
  bool get isSyncing => _status == AppModeStatus.syncing;
  bool get isBusy => isFetching || isSyncing;
  double get fetchProgress => _fetchProgress;
  int get syncTotal => _syncTotal;
  int get syncDone => _syncDone;
  int get pendingCount => _pendingCount;
  String? get areaName => _areaName;
  String? get locationName => _locationName;
  String? get message => _message;
    SyncPhase get phase => isFetching
      ? SyncPhase.fetchingEquipment
      : (isSyncing ? SyncPhase.syncing : SyncPhase.idle);
  int get syncCompleted => _syncDone;
  int get pendingComplianceCount => 0; 

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool(_kOffline) ?? false) {
      _status = AppModeStatus.offline;
      _areaName = prefs.getString(_kAreaName);
      _locationName = prefs.getString(_kLocationName);
    }
    await refreshPendingCount();
    notifyListeners();
  }

  // ───── Go offline (fetch) ─────
  void startFetchingEquipment({
    required String areaId,
    required String areaName,
    String? locationId,
    String? locationName,
  }) {
    _areaId = areaId;
    _areaName = areaName;
    _locationId = locationId;
    _locationName = locationName;
    _fetchProgress = 0;
    _message = null;
    _status = AppModeStatus.fetching;
    notifyListeners();
  }

  void updateFetchProgress(double p) {
    _fetchProgress = p.clamp(0.0, 1.0);
    notifyListeners();
  }

  void failFetch(String msg) {
    _message = msg;
    _status = AppModeStatus.online;
    notifyListeners();
  }

  Future<void> completeFetchSuccess() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kOffline, true);
    await prefs.setString(_kAreaName, _areaName ?? '');
    await prefs.setString(_kLocationName, _locationName ?? '');
    _status = AppModeStatus.offline;
    await refreshPendingCount();
    notifyListeners();
  }

  // ───── Back online (sync) ─────
  void startSyncing(int total) {
    _syncTotal = total;
    _syncDone = 0;
    _message = null;
    _status = AppModeStatus.syncing;
    notifyListeners();
  }

  void updateSyncProgress(int done) {
    _syncDone = done;
    notifyListeners();
  }

  Future<void> completeSyncSuccess() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kOffline);
    await prefs.remove(_kAreaName);
    await prefs.remove(_kLocationName);
    _status = AppModeStatus.online;
    _pendingCount = 0;
    notifyListeners();
  }

  /// Kuch items sync nahi hue / internet nahi: offline mode me hi raho
  Future<void> completeSyncPartial(String msg) async {
    _message = msg;
    _status = AppModeStatus.offline;
    await refreshPendingCount();
    notifyListeners();
  }

  Future<void> refreshPendingCount() async {
    _pendingCount = await InspectionRepository.instance.getPendingCount();
    notifyListeners();
  }
}