class CompletedTasksModel {
  final int id;
  final String companyEquipmentId;
  final String department;
  final String inspectorName;
  final String area;
  final String location;
  final String technicianId;
  final String badFactorName;
  final String resolveImage;
  final String? voice; // ✅ NEW: Voice recording URL (optional)
  final String inspectionDate;
  final String caseNo;
  final int status;
  final String createdBy;
  final String createdAt;
  final String updatedAt;
  final String technicianName;
  final String? newTechnicianName;
  final String companyEquipmentName;
  final String note;
  final String taskStatus;

  CompletedTasksModel({
    required this.id,
    required this.companyEquipmentId,
    required this.department,
    required this.inspectorName,
    required this.area,
    required this.location,
    required this.technicianId,
    required this.badFactorName,
    required this.resolveImage,
    this.voice, // ✅ NEW: Optional voice parameter
    required this.inspectionDate,
    required this.caseNo,
    required this.status,
    required this.createdBy,
    required this.createdAt,
    required this.updatedAt,
    required this.technicianName,
    required this.newTechnicianName,
    required this.companyEquipmentName,
    required this.note,
    required this.taskStatus,
  });

  factory CompletedTasksModel.fromJson(Map<String, dynamic> json) {
    return CompletedTasksModel(
      id: json['id'],
      department: json['department'] ?? 'Unknown',
      inspectorName: json['inspector_name'] ?? 'Unknown',
      inspectionDate: json['inspection_date'] ?? 'Unknown',
      caseNo: json['case_no'] ?? 'Unknown',
      technicianName: json['technician_name'] ?? 'Unknown',
      newTechnicianName: json['new_technician_name'] ?? 'Unknown',
      companyEquipmentId: json['company_equipment_id'] ?? 'Unknown',
      area: json['area'] ?? 'Unknown',
      location: json['location_id'] ?? 'Unknown',
      technicianId: json['technician_id'] ?? 'Unknown',
      badFactorName: json['bad_factor_name'] ?? 'Unknown',
      resolveImage: json['resolve_image'] ?? 'Unknown',
      voice: json['voice'], // ✅ NEW: Parse voice URL from API
      status: int.parse(json['status'].toString()),
      createdBy: json['created_by'] ?? 'Unknown',
      createdAt: json['created_at'] ?? 'Unknown',
      updatedAt: json['updated_at'] ?? 'Unknown',
      companyEquipmentName: json['company_equipment_name'] ?? 'Unknown',
      note: json['note'] ?? 'Unknown',
      taskStatus: json['task_status'] ?? 'Unknown',
    );
  }
}
