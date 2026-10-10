import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

class OfflineImageStorage {
  static Future<File> persistImage(File source, String prefix) async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final offlineDir =
          Directory(p.join(dir.path, 'offline_inspection_images'));
      if (!await offlineDir.exists()) {
        await offlineDir.create(recursive: true);
      }
      final fileName =
          '${prefix}_${DateTime.now().millisecondsSinceEpoch}${p.extension(source.path)}';
      final newPath = p.join(offlineDir.path, fileName);
      return await source.copy(newPath);
    } catch (e) {
      throw Exception('Failed to save image locally: $e');
    }
  }

  static Future<void> deleteIfExists(String? path) async {
    if (path == null || path.isEmpty) return;
    try {
      final f = File(path);
      if (await f.exists()) await f.delete();
    } catch (_) {}
  }
}
