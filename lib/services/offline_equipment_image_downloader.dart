import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

class OfflineEquipmentImageDownloader {
  static Future<String?> downloadAndSave(
      String? imageUrl, String reportId) async {
    if (imageUrl == null || imageUrl.isEmpty) return null;

    try {
      final response = await http
          .get(Uri.parse(imageUrl))
          .timeout(const Duration(seconds: 20));
      if (response.statusCode != 200) return null;

      final dir = await getApplicationDocumentsDirectory();
      final imagesDir = Directory(p.join(dir.path, 'offline_equipment_images'));
      if (!await imagesDir.exists()) {
        await imagesDir.create(recursive: true);
      }

      final ext =
          p.extension(imageUrl).isNotEmpty ? p.extension(imageUrl) : '.jpg';
      final filePath = p.join(imagesDir.path, 'equip_$reportId$ext');
      final file = File(filePath);
      await file.writeAsBytes(response.bodyBytes);
      return filePath;
    } catch (e) {
      print('Image download failed for $reportId: $e');
      return null;
    }
  }

  static Future<void> clearAll() async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final imagesDir = Directory(p.join(dir.path, 'offline_equipment_images'));
      if (await imagesDir.exists()) {
        await imagesDir.delete(recursive: true);
      }
    } catch (e) {
      print('Failed to clear old equipment images: $e');
    }
  }
}
