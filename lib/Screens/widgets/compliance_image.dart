import 'dart:io';
import 'package:flutter/material.dart';

class ComplianceImage extends StatelessWidget {
  final String imagePath;
  final double? width;
  final double? height;
  final BoxFit fit;
  final Widget Function(BuildContext context)? placeholderBuilder;

  const ComplianceImage({
    super.key,
    required this.imagePath,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.placeholderBuilder,
  });

  bool get _isNetwork =>
      imagePath.startsWith('http://') || imagePath.startsWith('https://');

  @override
  Widget build(BuildContext context) {
    if (imagePath.isEmpty) return _placeholder(context);

    if (_isNetwork) {
      return Image.network(
        imagePath,
        width: width,
        height: height,
        fit: fit,
        loadingBuilder: (context, child, progress) {
          if (progress == null) return child;
          return SizedBox(
            width: width,
            height: height,
            child: const Center(
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          );
        },
        errorBuilder: (_, __, ___) => _placeholder(context),
      );
    }

    final file = File(imagePath);
    if (!file.existsSync()) return _placeholder(context);

    return Image.file(
      file,
      width: width,
      height: height,
      fit: fit,
      errorBuilder: (_, __, ___) => _placeholder(context),
    );
  }

  Widget _placeholder(BuildContext context) {
    if (placeholderBuilder != null) return placeholderBuilder!(context);
    return Container(
      width: width,
      height: height,
      color: const Color(0xffF0F0F0),
      child:
          const Icon(Icons.image_not_supported, color: Colors.grey, size: 20),
    );
  }
}
