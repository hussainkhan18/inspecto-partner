class TaskModel {
  final int? id;

  final String equipmentName;
  final String equipmentArea;
  final String equipmentLocatoin;
  final String failedChecklistKey;
  final String department;
  final String inspectorName;
  final String inspectionDate;
  final String caseNo;
  final String technicianName;
  final String? newtechnicianName;
  final int status;

  TaskModel({
    this.id,
    required this.newtechnicianName,
    required this.equipmentName,
    required this.equipmentArea,
    required this.equipmentLocatoin,
    required this.failedChecklistKey,
    required this.department,
    required this.inspectorName,
    required this.inspectionDate,
    required this.caseNo,
    required this.technicianName,
    required this.status,
  });

  factory TaskModel.fromJson(Map<String, dynamic> json) {
    return TaskModel(
      id: json['id'],
      equipmentName: json['company_equipment_name'] ?? 'Unknown',
      equipmentArea: json['area'] ?? 'Unknown',
      equipmentLocatoin: json['location_id'] ?? 'Unknown',
      failedChecklistKey: json['bad_factor_name'] ?? 'Unknown',
      department: json['department'] ?? 'Unknown',
      inspectorName: json['inspector_name'] ?? 'Unknown',
      inspectionDate: json['inspection_date'] ?? 'Unknown',
      caseNo: json['case_no'] ?? 'Unknown',
      technicianName: json['technician_name'] ?? 'Unknown',
      newtechnicianName: json['new_technician_name'] ?? '',
      status: int.parse(json['status'].toString()),
    );
  }
}
