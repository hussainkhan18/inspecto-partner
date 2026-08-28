import 'dart:convert';
import 'package:inspecto_shield_partner/constants/api_constants.dart';
import 'package:inspecto_shield_partner/models/upcoming_inspection_model.dart';
import 'package:http/http.dart' as http;

class UpcomingInspectionService {
  static const Duration _timeout = Duration(seconds: 15);

  /// Fetches weekly pending inspections for a given inspector [userId].
  /// Returns [UpcomingInspectionResponse] on success.
  /// Throws [UpcomingInspectionException] on any failure.
  Future<UpcomingInspectionResponse> fetchWeeklyPending(int userId) async {
    final uri = Uri.parse('${ApiConstants.upcomingInspection}/$userId');

    try {
      final response = await http.get(uri).timeout(_timeout);

      if (response.statusCode == 200) {
        final Map<String, dynamic> json = jsonDecode(response.body);

        if (json['success'] == true) {
          return UpcomingInspectionResponse.fromJson(json);
        } else {
          throw const UpcomingInspectionException(
            'Server returned success: false',
            type: UpcomingInspectionErrorType.serverError,
          );
        }
      } else if (response.statusCode == 404) {
        throw const UpcomingInspectionException(
          'Inspector not found.',
          type: UpcomingInspectionErrorType.notFound,
        );
      } else {
        throw UpcomingInspectionException(
          'Unexpected error: ${response.statusCode}',
          type: UpcomingInspectionErrorType.serverError,
        );
      }
    } on UpcomingInspectionException {
      rethrow;
    } catch (e) {
      throw const UpcomingInspectionException(
        'Network error. Please check your connection.',
        type: UpcomingInspectionErrorType.network,
      );
    }
  }
}

// ─── Custom Exception ────────────────────────────────────────────────────────

enum UpcomingInspectionErrorType { network, serverError, notFound, unknown }

class UpcomingInspectionException implements Exception {
  final String message;
  final UpcomingInspectionErrorType type;

  const UpcomingInspectionException(
    this.message, {
    this.type = UpcomingInspectionErrorType.unknown,
  });

  @override
  String toString() => 'UpcomingInspectionException: $message';
}
