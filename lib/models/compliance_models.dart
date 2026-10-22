import 'package:flutter/material.dart';

class ComplianceArea {
  final int id;
  final String name;
  final String qrCode;

  ComplianceArea({required this.id, required this.name, required this.qrCode});

  factory ComplianceArea.fromJson(Map<String, dynamic> json) {
    return ComplianceArea(
      id: _asInt(json['id']),
      name: json['name']?.toString() ?? 'Unknown Area',
      qrCode: json['qr_code']?.toString() ?? '',
    );
  }

  factory ComplianceArea.fromCachedRow(Map<String, dynamic> row) {
    return ComplianceArea(
      id: _asInt(row['area_id']),
      name: row['area_name']?.toString() ?? 'Unknown Area',
      qrCode: row['area_qr_code']?.toString() ?? '',
    );
  }
}

class ComplianceEquipment {
  final int id;
  final String? equipmentQrCode;
  final String name;
  final String imageUrl;
  final String category;
  final String subCategory;
  final int? complianceTypeId;
  final String? complianceTypeName;
  final String type;
  final String area;
  final String location;
  final String inspectionFrequency;
  final bool certificateRequired;
  final String? lastInspectionDate;

  // Session-only UI state (not from API) — tells the Area screen whether
  // this equipment has already been inspected in the current session.
  final bool isCompleted;

  // Session-only UI state: 'complaint' or 'non complaint'
  final String? inspectionResult;

  ComplianceEquipment({
    required this.id,
    this.equipmentQrCode,
    required this.name,
    required this.imageUrl,
    required this.category,
    required this.subCategory,
    required this.type,
    required this.area,
    required this.location,
    required this.inspectionFrequency,
    required this.certificateRequired,
    this.lastInspectionDate,
    this.complianceTypeId,
    this.complianceTypeName,
    this.isCompleted = false,
    this.inspectionResult,
  });

  factory ComplianceEquipment.fromJson(Map<String, dynamic> json) {
    return ComplianceEquipment(
      id: _asInt(json['id']),
      equipmentQrCode: json['equipment_qr_code']?.toString(),
      name: json['name']?.toString() ?? 'Unknown Equipment',
      imageUrl: json['equipment_image_url']?.toString() ?? '',
      category: json['category']?.toString() ?? '',
      subCategory: json['sub_category']?.toString() ?? '',
      type: json['type']?.toString() ?? '',
      area: json['area']?.toString() ?? '',
      location: json['location']?.toString() ?? '',
      inspectionFrequency: json['inspection_frequency']?.toString() ?? '',
      complianceTypeId: json['area_compliance_type_id'] == null
          ? null
          : _asInt(json['area_compliance_type_id']),
      complianceTypeName: _cleanStr(json['compliance_type_name']),
      certificateRequired: json['certificate_required'] == true ||
          json['certificate_required'] == 1,
      lastInspectionDate: json['last_inspection_date']?.toString(),
    );
  }

  factory ComplianceEquipment.fromCachedRow(Map<String, dynamic> row) {
    final localPath = row['local_image_path']?.toString();
    final remoteUrl = row['image_url']?.toString();
    final resolvedImage = (localPath != null && localPath.isNotEmpty)
        ? localPath
        : (remoteUrl ?? '');

        return ComplianceEquipment(
      id: _asInt(row['equipment_id']),
      equipmentQrCode: row['equipment_qr_code']?.toString(),
      name: row['equipment_name']?.toString() ?? 'Unknown Equipment',
      imageUrl: resolvedImage,
      category: row['category']?.toString() ?? '',
      subCategory: row['sub_category']?.toString() ?? '',
      type: row['equipment_type']?.toString() ?? '',
      area: row['area_name']?.toString() ?? '',
      location: row['location']?.toString() ?? '',
      inspectionFrequency: row['inspection_frequency']?.toString() ?? '',
      certificateRequired: row['certificate_required'] == 1 ||
          row['certificate_required'] == true,
      lastInspectionDate: row['last_inspection_date']?.toString(),
      complianceTypeId: row['compliance_type_id'] == null
          ? null
          : _asInt(row['compliance_type_id']),
      complianceTypeName: _cleanStr(row['compliance_type_name']),
    );
  }

  ComplianceEquipment copyWith({
    bool? isCompleted,
    String? inspectionResult,
  }) {
    return ComplianceEquipment(
      id: id,
      equipmentQrCode: equipmentQrCode,
      name: name,
      imageUrl: imageUrl,
      category: category,
      subCategory: subCategory,
      type: type,
      area: area,
      location: location,
      inspectionFrequency: inspectionFrequency,
      complianceTypeId: complianceTypeId,
      complianceTypeName: complianceTypeName,
      certificateRequired: certificateRequired,
      lastInspectionDate: lastInspectionDate,
      isCompleted: isCompleted ?? this.isCompleted,
      inspectionResult: inspectionResult ?? this.inspectionResult,
    );
  }
}

class ComplianceChecklistItem {
  final int id;
  final String question;
  final String responseType;
  final bool isCritical;

  ComplianceChecklistItem({
    required this.id,
    required this.question,
    required this.responseType,
    required this.isCritical,
  });

  factory ComplianceChecklistItem.fromJson(Map<String, dynamic> json) {
    return ComplianceChecklistItem(
      id: _asInt(json['id']),
      question: json['checkpoint_question']?.toString() ?? '',
      responseType: json['response_type']?.toString() ?? 'yes_no',
      isCritical: json['is_critical'] == 1 || json['is_critical'] == true,
    );
  }
}

class ComplianceType {
  final int id;
  final String name;
  final int totalPoints;

  ComplianceType({
    required this.id,
    required this.name,
    this.totalPoints = 0,
  });

  factory ComplianceType.fromJson(Map<String, dynamic> json) {
    return ComplianceType(
      id: _asInt(json['id']),
      name: _cleanStr(json['name']) ?? 'Unknown',
      totalPoints: _asInt(json['total_points']),
    );
  }
}

String? _cleanStr(dynamic value) {
  final s = value?.toString().trim();
  return (s == null || s.isEmpty || s == 'null') ? null : s;
}

class ComplianceEmployee {
  final int id;
  final String name;
  final String? employeeCode;
  final String? phone;
  final String? photoUrl;
  final String? bloodGroup;

  ComplianceEmployee({
    required this.id,
    required this.name,
    this.employeeCode,
    this.phone,
    this.photoUrl,
    this.bloodGroup,
  });

  factory ComplianceEmployee.fromJson(Map<String, dynamic> json) {
    return ComplianceEmployee(
      id: _asInt(json['id']),
      name: _cleanStr(json['name']) ?? 'Unknown',
      employeeCode: _cleanStr(json['employee_code']),
      phone: _cleanStr(json['phone']),
      photoUrl: _cleanStr(json['photo_url']),
      bloodGroup: _cleanStr(json['blood_group']),
    );
  }
}

class ComplianceShiftInfo {
  final String name;
  final String startTime;
  final String endTime;
  final String timeRange;
  final bool overnight;

  ComplianceShiftInfo({
    required this.name,
    required this.startTime,
    required this.endTime,
    required this.timeRange,
    required this.overnight,
  });

  factory ComplianceShiftInfo.fromJson(Map<String, dynamic> json) {
    return ComplianceShiftInfo(
      name: _cleanStr(json['name']) ?? '',
      startTime: _cleanStr(json['start_time']) ?? '',
      endTime: _cleanStr(json['end_time']) ?? '',
      timeRange: _cleanStr(json['time_range']) ?? '',
      overnight: json['overnight'] == true || json['overnight'] == 1,
    );
  }
}

class ComplianceCurrentShift {
  final String serverTime12h;
  final String timezone;
  final ComplianceShiftInfo? shift;
  final List<ComplianceEmployee> employees;

  ComplianceCurrentShift({
    required this.serverTime12h,
    required this.timezone,
    required this.shift,
    required this.employees,
  });

  factory ComplianceCurrentShift.fromJson(Map<String, dynamic> json) {
    final shiftJson = json['shift'];
    final employeesJson = json['employees'];

    return ComplianceCurrentShift(
      serverTime12h: _cleanStr(json['server_time_12h']) ?? '',
      timezone: _cleanStr(json['timezone']) ?? '',
      shift: shiftJson is Map
          ? ComplianceShiftInfo.fromJson(Map<String, dynamic>.from(shiftJson))
          : null,
      employees: employeesJson is List
          ? employeesJson
              .whereType<Map>()
              .map((e) =>
                  ComplianceEmployee.fromJson(Map<String, dynamic>.from(e)))
              .toList()
          : <ComplianceEmployee>[],
    );
  }
}

class ComplianceRatingCriterion {
  final int id;
  final String title;
  final String? description;

  ComplianceRatingCriterion({
    required this.id,
    required this.title,
    this.description,
  });

  factory ComplianceRatingCriterion.fromJson(Map<String, dynamic> json) {
    final id = _asInt(json['id']);
    return ComplianceRatingCriterion(
      id: id,
      title: _cleanStr(json['name']) ??
          _cleanStr(json['title']) ??
          _cleanStr(json['label']) ??
          'Point $id',
      description: _cleanStr(json['description']),
    );
  }
}

class ComplianceScanAreaResult {
  final ComplianceArea area;
  final int totalEquipments;
  final List<ComplianceEquipment> equipments;
  final ComplianceCurrentShift? currentShift;
  final List<ComplianceRatingCriterion> ratingCriteria;
  final int starsPerCriteria;
  final int totalStars;
  final int maxGroupPhotos;
  final List<ComplianceType> complianceTypes;

  ComplianceScanAreaResult({
    required this.area,
    required this.totalEquipments,
    required this.equipments,
    this.currentShift,
    this.ratingCriteria = const [],
    this.starsPerCriteria = 1,
    this.totalStars = 0,
    this.maxGroupPhotos = 3,
    this.complianceTypes = const [],
  });

  ComplianceScanAreaResult filteredByType(ComplianceType type) {
    debugPrint('===== COMPLIANCE TYPE FILTER =====');
    debugPrint('Selected type -> id: ${type.id}, name: ${type.name}');

    final filtered = equipments.where((e) {
      final match = e.complianceTypeId == type.id;
      debugPrint(
        'Equipment id:${e.id} "${e.name}" '
        '-> area_compliance_type_id: ${e.complianceTypeId} '
        '| match: $match',
      );
      return match;
    }).toList();

    debugPrint('Matched ${filtered.length} of ${equipments.length} equipments');
    debugPrint('==================================');

    return ComplianceScanAreaResult(
      area: area,
      totalEquipments: filtered.length,
      equipments: filtered,
      currentShift: currentShift,
      ratingCriteria: ratingCriteria,
      starsPerCriteria: starsPerCriteria,
      totalStars: totalStars,
      maxGroupPhotos: maxGroupPhotos,
      complianceTypes: complianceTypes,
    );
  }
}

class ComplianceScanEquipmentResult {
  final ComplianceEquipment equipment;
  final List<ComplianceChecklistItem> checklist;

  ComplianceScanEquipmentResult({
    required this.equipment,
    required this.checklist,
  });
}

class ComplianceSubmitResult {
  final int inspectionId;
  final String status;

  ComplianceSubmitResult({required this.inspectionId, required this.status});

  factory ComplianceSubmitResult.fromJson(Map<String, dynamic> json) {
    return ComplianceSubmitResult(
      inspectionId: _asInt(json['inspection_id']),
      status: json['status']?.toString() ?? 'completed',
    );
  }
}

class ComplianceApiException implements Exception {
  final String message;
  ComplianceApiException(this.message);

  @override
  String toString() => message;
}

int _asInt(dynamic value) {
  if (value is int) return value;
  if (value is String) return int.tryParse(value) ?? 0;
  return 0;
}
