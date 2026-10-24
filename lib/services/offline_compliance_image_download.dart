import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

class OfflineComplianceImageDownloader {
  static Future<String?> downloadAndSave(
      String? imageUrl, String equipmentQrCode) async {
    if (imageUrl == null || imageUrl.isEmpty) return null;

    try {
      final response = await http
          .get(Uri.parse(imageUrl))
          .timeout(const Duration(seconds: 20));
      if (response.statusCode != 200) return null;

      final dir = await getApplicationDocumentsDirectory();
      final imagesDir =
          Directory(p.join(dir.path, 'offline_compliance_images'));
      if (!await imagesDir.exists()) {
        await imagesDir.create(recursive: true);
      }

      final ext =
          p.extension(imageUrl).isNotEmpty ? p.extension(imageUrl) : '.jpg';
      final safeName = equipmentQrCode.replaceAll(RegExp(r'[^\w\-]'), '_');
      final filePath = p.join(imagesDir.path, 'compliance_$safeName$ext');
      final file = File(filePath);
      await file.writeAsBytes(response.bodyBytes);
      return filePath;
    } catch (e) {
      print('Compliance image download failed for $equipmentQrCode: $e');
      return null;
    }
  }

  static Future<void> clearAll() async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final imagesDir =
          Directory(p.join(dir.path, 'offline_compliance_images'));
      if (await imagesDir.exists()) {
        await imagesDir.delete(recursive: true);
      }
    } catch (e) {
      print('Failed to clear old compliance images: $e');
    }
  }
}
