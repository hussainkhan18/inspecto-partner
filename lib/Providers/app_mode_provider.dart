import 'package:flutter/material.dart';
import 'package:inspecto_shield_partner/repositories/compliance_repository.dart';
import 'package:inspecto_shield_partner/repositories/inspection_repository.dart';

enum SyncPhase {
  idle,
  fetchingEquipment,
  fetchingCompliance,
  syncingInspections
}

class AppModeProvider extends ChangeNotifier {
  final InspectionRepository _inspectionRepository;

  AppModeProvider({InspectionRepository? inspectionRepository})
      : _inspectionRepository =
            inspectionRepository ?? InspectionRepository.instance;

  bool _isOfflineMode = false;
  SyncPhase _phase = SyncPhase.idle;

  double _fetchProgress = 0.0;

  int _syncTotal = 0;
  int _syncCompleted = 0;

  // Selected area/location
  String? selectedAreaId;
  String? selectedAreaName;
  String? selectedLocationId;
  String? selectedLocationName;

  int _pendingCount = 0;
  String? _lastError;

  double _complianceFetchProgress = 0.0;
  int _pendingComplianceCount = 0;

  // Getters

  bool get isOfflineMode => _isOfflineMode;
  SyncPhase get phase => _phase;
  bool get isBusy => _phase != SyncPhase.idle;
  double get fetchProgress => _fetchProgress;
  int get syncTotal => _syncTotal;
  int get syncCompleted => _syncCompleted;
  int get pendingCount => _pendingCount;
  String? get lastError => _lastError;
  double get complianceFetchProgress => _complianceFetchProgress;
  int get pendingComplianceCount => _pendingComplianceCount;

  void startFetchingEquipment({
    required String areaId,
    required String areaName,
    String? locationId,
    String? locationName,
  }) {
    selectedAreaId = areaId;
    selectedAreaName = areaName;
    selectedLocationId = locationId;
    selectedLocationName = locationName;
    _phase = SyncPhase.fetchingEquipment;
    _fetchProgress = 0.0;
    _lastError = null;
    notifyListeners();
  }

  void updateFetchProgress(double value) {
    _fetchProgress = value.clamp(0.0, 1.0);
    notifyListeners();
  }

  Future<void> completeFetchSuccess() async {
    _phase = SyncPhase.idle;
    _isOfflineMode = true;
    _fetchProgress = 1.0;
    _complianceFetchProgress = 1.0;
    await refreshPendingCount();
    await refreshPendingComplianceCount();
    notifyListeners();
  }

  void failFetch(String error) {
    _phase = SyncPhase.idle;
    _isOfflineMode = false;
    _lastError = error;
    notifyListeners();
  }

  void startSyncing(int total) {
    _phase = SyncPhase.syncingInspections;
    _syncTotal = total;
    _syncCompleted = 0;
    _lastError = null;
    notifyListeners();
  }

  void updateSyncProgress(int completed) {
    _syncCompleted = completed;
    notifyListeners();
  }

Future<void> completeSyncSuccess() async {
    _phase = SyncPhase.idle;
    _isOfflineMode = false;
    selectedAreaId = null;
    selectedAreaName = null;
    selectedLocationId = null;
    selectedLocationName = null;
    await refreshPendingCount();
    await refreshPendingComplianceCount();
    notifyListeners();
  }

  Future<void> completeSyncPartial(String error) async {
    _phase = SyncPhase.idle;
    _lastError = error;
    await refreshPendingCount();
    await refreshPendingComplianceCount();
    notifyListeners();
  }

  Future<void> refreshPendingCount() async {
    _pendingCount = await _inspectionRepository.getPendingCount();
    notifyListeners();
  }

  void clearError() {
    _lastError = null;
    notifyListeners();
  }

  void startFetchingCompliance() {
    _phase = SyncPhase.fetchingCompliance;
    _complianceFetchProgress = 0.0;
    notifyListeners();
  }

  void updateComplianceFetchProgress(double value) {
    _complianceFetchProgress = value.clamp(0.0, 1.0);
    notifyListeners();
  }

  Future<void> refreshPendingComplianceCount() async {
    _pendingComplianceCount =
        await ComplianceRepository.instance.getPendingCount();
    notifyListeners();
  }
}
