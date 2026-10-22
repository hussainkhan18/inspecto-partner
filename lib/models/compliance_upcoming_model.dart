import 'dart:math' as math;

class ComplianceUpcomingItem {
  final int equipmentId;
  final String qrCode;
  final String name;
  final String categoryType;
  final String? imageUrl;
  final int areaId;
  final String areaName;
  final String areaQrCode;
  final String typeName;
  final String frequencyLabel;
  final DateTime? dueAt;
  final DateTime? lastInspectedAt;
  final DateTime? commissionedAt;
  final bool isOverdue;
  final int dueInMinutes;
  final int overdueMinutes;
  final int missedCycles;
  final DateTime fetchedAt;

  const ComplianceUpcomingItem({
    required this.equipmentId,
    required this.qrCode,
    required this.name,
    required this.categoryType,
    required this.imageUrl,
    required this.areaId,
    required this.areaName,
    required this.areaQrCode,
    required this.typeName,
    required this.frequencyLabel,
    required this.dueAt,
    required this.lastInspectedAt,
    required this.commissionedAt,
    required this.isOverdue,
    required this.dueInMinutes,
    required this.overdueMinutes,
    required this.missedCycles,
    required this.fetchedAt,
    
  });

  static int _int(dynamic v) => int.tryParse(v?.toString() ?? '') ?? 0;

  static Map<String, dynamic> _map(dynamic v) =>
      v is Map ? Map<String, dynamic>.from(v) : <String, dynamic>{};

  factory ComplianceUpcomingItem.fromJson(
    Map<String, dynamic> j,
    DateTime fetchedAt,
  ) {
    final area = _map(j['area']);
    final type = _map(j['compliance_type']);

    String? img = j['equipment_image_url']?.toString();
    if (img != null) {
      img = img.trim().isEmpty ? null : img.replaceFirst('http://', 'https://');
    }

    return ComplianceUpcomingItem(
      equipmentId: _int(j['equipment_id']),
      qrCode: j['equipment_qr_code']?.toString() ?? '',
      name: j['name']?.toString() ?? '',
      categoryType: j['category_type']?.toString() ?? '',
      imageUrl: img,
      areaId: _int(area['id']),
      areaName: area['name']?.toString() ?? '',
      areaQrCode: area['qr_code']?.toString() ?? '',
      typeName: type['name']?.toString() ?? '',
      frequencyLabel: type['frequency_label']?.toString() ??
          type['frequency']?.toString() ??
          '',
      dueAt: DateTime.tryParse(j['due_at']?.toString() ?? ''),
      lastInspectedAt:
          DateTime.tryParse(j['last_inspected_at']?.toString() ?? ''),
      commissionedAt:
          DateTime.tryParse(j['commissioned_at']?.toString() ?? ''),
      isOverdue: j['is_overdue'] == true,
      dueInMinutes: _int(j['due_in_minutes']),
      overdueMinutes: _int(j['overdue_minutes']),
      missedCycles: _int(j['missed_cycles']),
      fetchedAt: fetchedAt,
    );
  }

  int get _elapsedMinutes => DateTime.now().difference(fetchedAt).inMinutes;

  int get dueInNow => math.max(0, dueInMinutes - _elapsedMinutes);

  int get overdueNow => overdueMinutes + _elapsedMinutes;

  bool get isDueSoon => !isOverdue && dueInNow <= 24 * 60;
}

class ComplianceUpcomingResponse {
  final int days;
  final int totalUpcoming;
  final int totalOverdue;
  final List<ComplianceUpcomingItem> upcoming;
  final List<ComplianceUpcomingItem> overdue;

  const ComplianceUpcomingResponse({
    required this.days,
    required this.totalUpcoming,
    required this.totalOverdue,
    required this.upcoming,
    required this.overdue,
  });

  bool get isEmpty => upcoming.isEmpty && overdue.isEmpty;

  factory ComplianceUpcomingResponse.fromJson(Map<String, dynamic> body) {
    final data = body['data'] is Map
        ? Map<String, dynamic>.from(body['data'] as Map)
        : <String, dynamic>{};
    final fetchedAt = DateTime.now();

    List<ComplianceUpcomingItem> parse(dynamic raw) {
      if (raw is! List) return [];
      return raw
          .whereType<Map>()
          .map((e) => ComplianceUpcomingItem.fromJson(
                Map<String, dynamic>.from(e),
                fetchedAt,
              ))
          .toList();
    }

    final upcoming = parse(data['upcoming'])
      ..sort((a, b) => a.dueInMinutes.compareTo(b.dueInMinutes));
    final overdue = parse(data['overdue'])
      ..sort((a, b) => b.overdueMinutes.compareTo(a.overdueMinutes));

    return ComplianceUpcomingResponse(
      days: ComplianceUpcomingItem._int(data['days']) == 0
          ? 7
          : ComplianceUpcomingItem._int(data['days']),
      totalUpcoming: ComplianceUpcomingItem._int(data['total_upcoming']),
      totalOverdue: ComplianceUpcomingItem._int(data['total_overdue']),
      upcoming: upcoming,
      overdue: overdue,
    );
  }

  Map<DateTime, List<ComplianceUpcomingItem>> get upcomingByDay {
    final map = <DateTime, List<ComplianceUpcomingItem>>{};
    for (final item in upcoming) {
      final d = item.dueAt ?? DateTime.now();
      final key = DateTime(d.year, d.month, d.day);
      map.putIfAbsent(key, () => []).add(item);
    }
    return map;
  }
}

class UpcomingFormat {
  UpcomingFormat._();

  static const _days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
  static const _months = [
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
    'Dec',
  ];

  static String duration(int minutes) {
    if (minutes < 1) return '0m';
    final d = minutes ~/ (60 * 24);
    final h = (minutes % (60 * 24)) ~/ 60;
    final m = minutes % 60;
    if (d > 0) return h > 0 ? '${d}d ${h}h' : '${d}d';
    if (h > 0) return m > 0 ? '${h}h ${m}m' : '${h}h';
    return '${m}m';
  }

  static String dayMonth(DateTime d) =>
      '${_days[d.weekday - 1]}, ${d.day} ${_months[d.month - 1]}';

  static String shortDate(DateTime d) => '${d.day} ${_months[d.month - 1]}';

  static String time(DateTime d) {
    final h = d.hour % 12 == 0 ? 12 : d.hour % 12;
    final m = d.minute.toString().padLeft(2, '0');
    return '$h:$m ${d.hour >= 12 ? 'PM' : 'AM'}';
  }
}
