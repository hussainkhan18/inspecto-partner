import 'dart:convert';
import 'package:inspecto_shield_partner/constants/api_constants.dart';
import 'package:http/http.dart' as http;

class RecordService {
 static Future<List<dynamic>> getRecordList(int userId) async {
  final response = await http.get(
    Uri.parse('${ApiConstants.myRecords}/$userId'),
  );

  if (response.statusCode == 200) {
    final jsonResponse = jsonDecode(response.body);
  
    List<dynamic> records = [];
    if (jsonResponse["data"] != null && jsonResponse["data"] is List) {
      for (var i in jsonResponse["data"]) {
        records.add(i); 
      }
    }
    return records;
  } else {
    throw Exception('Failed to load records');
  }
}
}