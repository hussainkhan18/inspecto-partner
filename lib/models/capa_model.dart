class CapaModel {
  final int id;
  final String capaNumber;
  final int? gembaWalkId;
  final String walkNumber;
  final String purpose;
  final String checklistItemText;
  final String description;
  final int? areaId;
  final String area;
  final int? locationId;
  final String location;
  final String assignMode;
  final int? assignedTo;
  final String? assignedToName;
  final int? raisedBy;
  final String raisedByName;
  final String? dueDate;
  final String status;
  final String statusLabel;
  final String? completionRemarks;
  final List<String> completionPhotos;
  final String? completedAt;
  final String createdAt;

  CapaModel({
    required this.id,
    required this.capaNumber,
    this.gembaWalkId,
    required this.walkNumber,
    required this.purpose,
    required this.checklistItemText,
    required this.description,
    this.areaId,
    required this.area,
    this.locationId,
    required this.location,
    required this.assignMode,
    this.assignedTo,
    this.assignedToName,
    this.raisedBy,
    required this.raisedByName,
    this.dueDate,
    required this.status,
    required this.statusLabel,
    this.completionRemarks,
    required this.completionPhotos,
    this.completedAt,
    required this.createdAt,
  });

  factory CapaModel.fromJson(Map<String, dynamic> json) {
    final rawPhotos = json['completion_photos'];
    final photos = rawPhotos is List
        ? rawPhotos.map((e) => e.toString()).toList()
        : <String>[];

    return CapaModel(
      id: _toInt(json['id']) ?? 0,
      capaNumber: json['capa_number']?.toString() ?? '',
      gembaWalkId: _toInt(json['gemba_walk_id']),
      walkNumber: json['walk_number']?.toString() ?? '',
      purpose: json['purpose']?.toString() ?? '',
      checklistItemText: json['checklist_item_text']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      areaId: _toInt(json['area_id']),
      area: json['area']?.toString() ?? '',
      locationId: _toInt(json['location_id']),
      location: json['location']?.toString() ?? '',
      assignMode: json['assign_mode']?.toString() ?? '',
      assignedTo: _toInt(json['assigned_to']),
      assignedToName: json['assigned_to_name']?.toString(),
      raisedBy: _toInt(json['raised_by']),
      raisedByName: json['raised_by_name']?.toString() ?? '',
      dueDate: json['due_date']?.toString(),
      status: json['status']?.toString() ?? '',
      statusLabel: json['status_label']?.toString() ?? '',
      completionRemarks: json['completion_remarks']?.toString(),
      completionPhotos: photos,
      completedAt: json['completed_at']?.toString(),
      createdAt: json['created_at']?.toString() ?? '',
    );
  }

  static int? _toInt(dynamic v) => v is int ? v : int.tryParse('${v ?? ''}');

  bool get isCompleted => status == 'completed';
  bool get isPendingAssignment => status == 'pending_assignment';
  bool get isOpen => status == 'open';

  bool get isOverdue {
    if (dueDate == null || dueDate!.isEmpty) return false;
    if (isCompleted) return false;
    final d = DateTime.tryParse(dueDate!);
    if (d == null) return false;
    final n = DateTime.now();
    return DateTime(d.year, d.month, d.day)
        .isBefore(DateTime(n.year, n.month, n.day));
  }
}
