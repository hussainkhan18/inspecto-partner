import 'dart:convert';
import 'package:inspecto_shield_partner/constants/api_constants.dart';
import 'package:http/http.dart' as http;

class RecordService {
  // ── GET MY RECORDS ─────────────────────────────────────────
  // Pehle: my_record.dart mein directly tha
  static Future<List<dynamic>> getRecordList(int userId) async {
    final response = await http.get(
      Uri.parse('${ApiConstants.myRecords}/$userId'),
    );

    if (response.statusCode == 200) {
      final jsonResponse = jsonDecode(response.body);
      List<dynamic> records = [];
      for (Map i in jsonResponse["data"]) {
        records.add([
          i["equipment_name"],
          i["updated_at"],
          i["location_description"],
          i["location_name"],
          i["area"],
        ]);
      }
      return records;
    } else {
      throw Exception('Failed to load records');
    }
  }
}
