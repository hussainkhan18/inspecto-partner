class ApiConstants {
  static const String baseUrl = 'https://partner.inspectoshield.com/api';

  // Authentication & User
  static const String login = '$baseUrl/login';
  // profile update
  static const String profileUpdate = '$baseUrl/profile_update';
  // My Records
  static const String myRecords = '$baseUrl/my_records';
  // Generate report or new inspection
  static const String generate = '$baseUrl/generate';
  // Inspections (save checklist)
  static const String inspection = '$baseUrl/equipment_inspection';
  // Certificate
  static const String certificate = '$baseUrl/equipment_certificate';
  // Pending Inspections for popup
  static const String pending = '$baseUrl/inspector/pending-inspections';
  //certificate download
  static const String getCertificate = '$baseUrl/certificate';
  //upcoming inspection
  static const String upcomingInspection = '$baseUrl/inspector/weekly-pending';
  // post Complaints
  static const String complaints = '$baseUrl/complaints';
  // Get Complaints
  static const String getComplaints = '$baseUrl/get_complaints';
  // Compliance
  static const String complianceScanArea = '$baseUrl/compliance/scan-area';
  static const String complianceScanEquipment =
      '$baseUrl/compliance/scan-equipment';
  static const String complianceSubmitInspection =
      '$baseUrl/compliance/submit-inspection';
  static const String complianceSubmitAreaVisit =
      '$baseUrl/compliance/submit-area-visit';
  static const String complianceUpcoming = '$baseUrl/compliance/upcoming';
  // Gemba Walks
  static const String gembaWalks = '$baseUrl/gemba-walks';
  static String gembaWalkDetail(int id) => '$baseUrl/gemba-walks/$id';
  static String gembaWalkSubmit(int id) => '$baseUrl/gemba-walks/$id/submit';
  static String gembaCapaOptions(int id) =>
      '$baseUrl/gemba-walks/$id/capa-options';
  static String gembaCapasCreate(int id) => '$baseUrl/gemba-walks/$id/capas';
  static const String gembaCapas = '$baseUrl/gemba-capas';
  static String gembaCapaComplete(int id) =>
      '$baseUrl/gemba-capas/$id/complete';

  // Offline Mode
  static const String offlineAreas = '$baseUrl/offline/areas';
  static const String offlineLocations = '$baseUrl/offline/locations';
  static const String offlineEquipmentData = '$baseUrl/offline/equipment-data';
}
