import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:inspecto_shield_partner/constants/api_constants.dart';
import 'package:inspecto_shield_partner/models/compliance_models.dart';
import 'package:inspecto_shield_partner/models/compliance_upcoming_model.dart';
import 'package:inspecto_shield_partner/services/secure_storage_service.dart';

class ComplianceUpcomingService {
  static const Duration _timeout = Duration(seconds: 30);

  Future<ComplianceUpcomingResponse> fetch({int days = 7}) async {
    try {
      final token = await SecureStorageService.getToken();
      final uri = Uri.parse(ApiConstants.complianceUpcoming)
          .replace(queryParameters: {'days': days.toString()});

      final response = await http.get(
        uri,
        headers: {
          'Accept': 'application/json',
          if (token != null && token.isNotEmpty)
            'Authorization': 'Bearer $token',
        },
      ).timeout(_timeout);

      if (response.statusCode == 401) {
        throw ComplianceApiException('Session expired. Please log in again.');
      }

      Map<String, dynamic> decoded = {};
      try {
        final d = jsonDecode(response.body);
        if (d is Map<String, dynamic>) decoded = d;
      } catch (_) {}

      if (response.statusCode != 200 || decoded['status'] != true) {
        throw ComplianceApiException(
          decoded['message']?.toString() ??
              'Could not load upcoming inspections. Please try again.',
        );
      }

      return ComplianceUpcomingResponse.fromJson(decoded);
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
}
