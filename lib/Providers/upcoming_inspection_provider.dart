import 'package:flutter/material.dart';
import 'package:inspecto_shield_partner/models/upcoming_inspection_model.dart';
import '../services/upcoming_inspection_service.dart';

enum UpcomingInspectionState { initial, loading, loaded, empty, error }

class UpcomingInspectionProvider extends ChangeNotifier {
  final UpcomingInspectionService _service;

  UpcomingInspectionProvider({UpcomingInspectionService? service})
      : _service = service ?? UpcomingInspectionService();

  // ─── State ──────────────────────────────────────────────────────────────────
  UpcomingInspectionState _state = UpcomingInspectionState.initial;
  List<UpcomingInspectionItem> _inspections = [];
  String _weekRange = '';
  int _totalCount = 0;
  String _errorMessage = '';
  UpcomingInspectionErrorType _errorType = UpcomingInspectionErrorType.unknown;

  // ─── Getters ─────────────────────────────────────────────────────────────────
  UpcomingInspectionState get state => _state;
  List<UpcomingInspectionItem> get inspections => _inspections;
  String get weekRange => _weekRange;
  int get totalCount => _totalCount;
  String get errorMessage => _errorMessage;
  UpcomingInspectionErrorType get errorType => _errorType;

  bool get isLoading => _state == UpcomingInspectionState.loading;
  bool get hasError => _state == UpcomingInspectionState.error;
  bool get isEmpty => _state == UpcomingInspectionState.empty;
  bool get isLoaded => _state == UpcomingInspectionState.loaded;

  // ─── Fetch ───────────────────────────────────────────────────────────────────
  Future<void> fetchInspections(int userId) async {
    _state = UpcomingInspectionState.loading;
    _errorMessage = '';
    notifyListeners();

    try {
      final response = await _service.fetchWeeklyPending(userId);

      if (response.data.isEmpty) {
        _state = UpcomingInspectionState.empty;
      } else {
        _inspections = response.data;
        _weekRange = response.weekRange;
        _totalCount = response.count;
        _state = UpcomingInspectionState.loaded;
      }
    } on UpcomingInspectionException catch (e) {
      _errorMessage = e.message;
      _errorType = e.type;
      _state = UpcomingInspectionState.error;
    } catch (_) {
      _errorMessage = 'Something went wrong. Please try again.';
      _errorType = UpcomingInspectionErrorType.unknown;
      _state = UpcomingInspectionState.error;
    }

    notifyListeners();
  }

  /// Call this to retry after an error
  Future<void> retry(int userId) => fetchInspections(userId);

  /// Reset state (e.g. when leaving the screen)
  void reset() {
    _state = UpcomingInspectionState.initial;
    _inspections = [];
    _weekRange = '';
    _totalCount = 0;
    _errorMessage = '';
    notifyListeners();
  }
}
