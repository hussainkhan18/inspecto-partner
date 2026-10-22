import 'package:flutter/material.dart';
import 'package:inspecto_shield_partner/models/compliance_models.dart';
import 'package:inspecto_shield_partner/models/compliance_upcoming_model.dart';
import 'package:inspecto_shield_partner/services/compliance_upcoming_service.dart';
enum ComplianceUpcomingState { initial, loading, loaded, empty, error }

class ComplianceUpcomingProvider extends ChangeNotifier {
  final ComplianceUpcomingService _service;

  ComplianceUpcomingProvider({ComplianceUpcomingService? service})
      : _service = service ?? ComplianceUpcomingService();

  ComplianceUpcomingState _state = ComplianceUpcomingState.initial;
  ComplianceUpcomingResponse? _data;
  String _errorMessage = '';
  bool _disposed = false;

  ComplianceUpcomingState get state => _state;
  ComplianceUpcomingResponse? get data => _data;
  String get errorMessage => _errorMessage;

 Future<void> fetch({bool silent = false}) async {
    final hasData = _data != null;
    if (!(silent && hasData)) {
      _state = ComplianceUpcomingState.loading;
      _errorMessage = '';
      _notify();
    }

    try {
      final result = await _service.fetch();
      _data = result;
      _state = result.isEmpty
          ? ComplianceUpcomingState.empty
          : ComplianceUpcomingState.loaded;
    } on ComplianceApiException catch (e) {
      if (!(silent && hasData)) {
        _errorMessage = e.message;
        _state = ComplianceUpcomingState.error;
      }
    } catch (_) {
      if (!(silent && hasData)) {
        _errorMessage = 'Something went wrong. Please try again.';
        _state = ComplianceUpcomingState.error;
      }
    }

    _notify();
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}