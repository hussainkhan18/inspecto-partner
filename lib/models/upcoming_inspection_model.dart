// ─── Single Inspection Item ──────────────────────────────────────────────────

class UpcomingInspectionItem {
  final String id;
  final String name;
  final String frequency;
  final String areaName;
  final String locationName;
  final String lastInspection;
  final String deadlineDate;
  final String dayName;
  final String status;

  const UpcomingInspectionItem({
    required this.id,
    required this.name,
    required this.frequency,
    required this.areaName,
    required this.locationName,
    required this.lastInspection,
    required this.deadlineDate,
    required this.dayName,
    required this.status,
  });

  factory UpcomingInspectionItem.fromJson(Map<String, dynamic> json) {
    return UpcomingInspectionItem(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? 'Unknown',
      frequency: json['frequency']?.toString() ?? 'N/A',
      areaName: json['area_name']?.toString() ?? 'N/A',
      locationName: json['location_name']?.toString() ?? 'N/A',
      lastInspection: json['last_inspection']?.toString() ?? 'N/A',
      deadlineDate: json['deadline_date']?.toString() ?? 'N/A',
      dayName: json['day_name']?.toString() ?? 'N/A',
      status: json['status']?.toString() ?? 'Pending',
    );
  }
}

// ─── Full API Response ───────────────────────────────────────────────────────

class UpcomingInspectionResponse {
  final bool success;
  final String weekRange;
  final int count;
  final List<UpcomingInspectionItem> data;

  const UpcomingInspectionResponse({
    required this.success,
    required this.weekRange,
    required this.count,
    required this.data,
  });

  factory UpcomingInspectionResponse.fromJson(Map<String, dynamic> json) {
    final List<dynamic> rawList = json['data'] ?? [];
    return UpcomingInspectionResponse(
      success: json['success'] ?? false,
      weekRange: json['week_range']?.toString() ?? '',
      count: json['count'] ?? 0,
      data: rawList
          .map((item) =>
              UpcomingInspectionItem.fromJson(item as Map<String, dynamic>))
          .toList(),
    );
  }
}
