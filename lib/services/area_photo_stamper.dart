import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';

class AreaPhotoStamper {
  AreaPhotoStamper._();

  static Future<File> stamp(File original, String areaName) async {
    try {
      final bytes = await original.readAsBytes();
      final timestamp =
          DateFormat('dd MMM yyyy   hh:mm:ss a').format(DateTime.now());

      final cleanArea =
          areaName.replaceAll(RegExp(r'[^\x20-\x7E]'), '').trim();
      final shortArea = cleanArea.length > 34
          ? '${cleanArea.substring(0, 33)}...'
          : cleanArea;

      final jpgBytes = await compute(
        _stampIsolate,
        _StampParams(bytes, shortArea.toUpperCase(), timestamp),
      );

      final dir = await getTemporaryDirectory();
      final file = File(
          '${dir.path}/staff_${DateTime.now().microsecondsSinceEpoch}.jpg');
      await file.writeAsBytes(jpgBytes);
      return file;
    } catch (e) {
      debugPrint('Area photo stamp failed: $e');
      return original;
    }
  }
}

class _StampParams {
  final Uint8List bytes;
  final String areaName;
  final String timestamp;
  _StampParams(this.bytes, this.areaName, this.timestamp);
}

Uint8List _stampIsolate(_StampParams p) {
  img.Image? decoded = img.decodeImage(p.bytes);
  if (decoded == null) {
    throw Exception('Image decode fail');
  }
  decoded = img.bakeOrientation(decoded);

  final w = decoded.width;
  final h = decoded.height;
  final hasArea = p.areaName.isNotEmpty;

  final barHeight = (h * (hasArea ? 0.15 : 0.09)).round().clamp(24, 260);
  final barTop = h - barHeight;

  img.fillRect(
    decoded,
    x1: 0,
    y1: barTop,
    x2: w,
    y2: h,
    color: img.ColorRgb8(0, 0, 0),
  );

  final layerHeight = hasArea ? 140 : 80;
  final layer = img.Image(width: 1000, height: layerHeight);
  final white = img.ColorRgb8(255, 255, 255);

  if (hasArea) {
    img.drawString(layer, p.areaName,
        font: img.arial48, x: 10, y: 8, color: white);
    img.drawString(layer, p.timestamp,
        font: img.arial48, x: 10, y: 78, color: white);
  } else {
    img.drawString(layer, p.timestamp,
        font: img.arial48, x: 10, y: 16, color: white);
  }

  final heightScale = (barHeight * 0.8) / layerHeight;
  final widthScale = (w * 0.94) / 1000;
  final scale = heightScale < widthScale ? heightScale : widthScale;
  final targetH = (layerHeight * scale).round().clamp(8, layerHeight);
  final targetW = (1000 * scale).round().clamp(8, 1000);

  final scaled = img.copyResize(
    layer,
    width: targetW,
    height: targetH,
    interpolation: img.Interpolation.average,
  );

  final pasteX = (w * 0.02).round();
  final pasteY = barTop + ((barHeight - targetH) ~/ 2);

  img.compositeImage(decoded, scaled, dstX: pasteX, dstY: pasteY);

  return img.encodeJpg(decoded, quality: 80);
}