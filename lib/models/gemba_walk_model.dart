class GembaWalkModel {
  final int id;
  final String walkNumber;
  final String purpose;
  final int? purposeId;
  final int? areaId;
  final String area;
  final int? locationId;
  final String location;
  final String scheduledDate;
  final String notes;
  final String status;
  final String statusLabel;
  final String? submittedAt;
  final int totalPoints;
  final int answeredPoints;
  final int nonComplianceCount;
  final int capaCount;

  GembaWalkModel({
    required this.id,
    required this.walkNumber,
    required this.purpose,
    this.purposeId,
    this.areaId,
    required this.area,
    this.locationId,
    required this.location,
    required this.scheduledDate,
    required this.notes,
    required this.status,
    required this.statusLabel,
    this.submittedAt,
    required this.totalPoints,
    required this.answeredPoints,
    required this.nonComplianceCount,
    required this.capaCount,
  });

  factory GembaWalkModel.fromJson(Map<String, dynamic> json) {
    return GembaWalkModel(
      id: _toInt(json['id']) ?? 0,
      walkNumber: json['walk_number']?.toString() ?? '',
      purpose: json['purpose']?.toString() ?? '',
      purposeId: _toInt(json['purpose_id']),
      areaId: _toInt(json['area_id']),
      area: json['area']?.toString() ?? '',
      locationId: _toInt(json['location_id']),
      location: json['location']?.toString() ?? '',
      scheduledDate: json['scheduled_date']?.toString() ?? '',
      notes: json['notes']?.toString() ?? '',
      status: json['status']?.toString() ?? '',
      statusLabel: json['status_label']?.toString() ?? '',
      submittedAt: json['submitted_at']?.toString(),
      totalPoints: _toInt(json['total_points']) ?? 0,
      answeredPoints: _toInt(json['answered_points']) ?? 0,
      nonComplianceCount: _toInt(json['non_compliance_count']) ?? 0,
      capaCount: _toInt(json['capa_count']) ?? 0,
    );
  }

  static int? _toInt(dynamic v) => v is int ? v : int.tryParse('${v ?? ''}');

  Map<String, dynamic> toUiMap() {
    return {
      'id': id,
      'no': id,
      'gemba': walkNumber,
      'area': area,
      'location': location,
      'purpose': purpose,
      'purposeId': purposeId,
      'areaId': areaId,
      'locationId': locationId,
      'status': status,
      'statusLabel': statusLabel,
      'dueDate': _formatDate(scheduledDate),
      'scheduledDate': scheduledDate,
      'notes': notes,
      'totalPoints': totalPoints,
      'answeredPoints': answeredPoints,
      'nonComplianceCount': nonComplianceCount,
      'capaCount': capaCount,
      'submittedAt': submittedAt,
    };
  }

  static String _formatDate(String raw) {
    if (raw.isEmpty) return 'Today';
    try {
      final dt = DateTime.parse(raw);
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final target = DateTime(dt.year, dt.month, dt.day);
      final diff = target.difference(today).inDays;
      if (diff == 0) return 'Today';
      if (diff == 1) return 'Tomorrow';
      if (diff == -1) return 'Yesterday';
      const months = [
        'Jan',
        'Feb',
        'Mar',
        'Apr',
        'May',
        'Jun',
        'Jul',
        'Aug',
        'Sep',
        'Oct',
        'Nov',
        'Dec'
      ];
      return '${dt.day} ${months[dt.month - 1]}';
    } catch (_) {
      return raw;
    }
  }
}
