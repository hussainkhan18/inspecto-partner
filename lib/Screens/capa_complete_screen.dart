import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image/image.dart' as img;
import 'package:inspecto_shield_partner/models/capa_model.dart';
import 'package:inspecto_shield_partner/services/gemba_walk_service.dart';
import 'package:path_provider/path_provider.dart' as path_provider;
import 'package:path/path.dart' as p;

class CapaCompleteScreen extends StatefulWidget {
  final CapaModel capa;

  const CapaCompleteScreen({super.key, required this.capa});

  @override
  State<CapaCompleteScreen> createState() => _CapaCompleteScreenState();
}

class _CapaCompleteScreenState extends State<CapaCompleteScreen> {
  static const Color _teal = Color(0xff0DC5B9);
  static const Color _ink = Color(0xff1E293B);
  static const Color _muted = Color(0xff64748B);
  static const Color _bg = Color(0xffF8FAFC);
  static const Color _border = Color(0xffE2E8F0);

  final GembaWalkService _service = GembaWalkService();
  final ImagePicker _picker = ImagePicker();
  final TextEditingController _remarksController = TextEditingController();

  final List<File> _photos = [];
  bool _isSubmitting = false;
  bool _isCompressing = false;

  static const int _maxPhotos = 3;

  @override
  void dispose() {
    _remarksController.dispose();
    super.dispose();
  }

  Future<void> _pickPhoto() async {
    if (_photos.length >= _maxPhotos) return;

    try {
      final XFile? picked = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1200,
        imageQuality: 85,
      );
      if (picked == null) return;

      setState(() => _isCompressing = true);
      final compressed = await _compressImage(File(picked.path));

      if (!mounted) return;
      setState(() {
        _photos.add(compressed);
        _isCompressing = false;
      });
    } catch (e) {
      debugPrint('pickPhoto error: $e');
      if (mounted) setState(() => _isCompressing = false);
    }
  }

  Future<File> _compressImage(File file) async {
    try {
      final dir = await path_provider.getTemporaryDirectory();
      final targetPath = p.join(
        dir.path,
        "${DateTime.now().millisecondsSinceEpoch}_capa.jpg",
      );
      final resultPath = await compute(_compressWorker, {
        'source': file.path,
        'target': targetPath,
      });
      return File(resultPath);
    } catch (e) {
      debugPrint('compress error: $e');
      return file;
    }
  }

  void _removePhoto(int index) {
    setState(() => _photos.removeAt(index));
  }

  Future<void> _submit() async {
    final remarks = _remarksController.text.trim();

    if (remarks.isEmpty) {
      _snack('Please write completion remarks', Colors.red);
      return;
    }

    setState(() => _isSubmitting = true);

    final result = await _service.completeCapa(
      capaId: widget.capa.id,
      completionRemarks: remarks,
      photos: _photos,
    );

    if (!mounted) return;
    setState(() => _isSubmitting = false);

    if (result['success'] == true) {
      _snack(result['message']?.toString() ?? 'Completed', Colors.green);
      Navigator.pop(context, true);
    } else {
      _snack(result['message']?.toString() ?? 'Failed', Colors.red);
    }
  }

  void _snack(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: color),
    );
  }

  @override
  Widget build(BuildContext context) {
    final capa = widget.capa;

    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _teal,
        foregroundColor: Colors.white,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Complete CAPA',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 17),
            ),
            const SizedBox(height: 4),
            Text(
              capa.capaNumber,
              style: const TextStyle(
                fontSize: 13,
                color: Colors.white70,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new,
              color: Colors.white, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildCapaSummary(capa),
                const SizedBox(height: 20),
                _buildSectionTitle('COMPLETION REMARKS *'),
                const SizedBox(height: 8),
                _buildRemarksField(),
                const SizedBox(height: 20),
                _buildSectionTitle('PHOTOS (${_photos.length}/$_maxPhotos)'),
                const SizedBox(height: 8),
                _buildPhotoRow(),
                const SizedBox(height: 24),
                _buildSubmitButton(),
                const SizedBox(height: 20),
              ],
            ),
          ),
          if (_isCompressing)
            Container(
              color: Colors.black38,
              child: const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(color: _teal),
                    SizedBox(height: 12),
                    Text(
                      'Compressing image...',
                      style: TextStyle(color: Colors.white, fontSize: 13),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCapaSummary(CapaModel capa) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            capa.checklistItemText,
            style: const TextStyle(
              fontSize: 13.5,
              fontWeight: FontWeight.w600,
              color: _ink,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            capa.description,
            style: const TextStyle(
              fontSize: 12.5,
              color: _muted,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 10),
          const Divider(height: 1, color: _border),
          const SizedBox(height: 10),
          Row(
            children: [
              const Icon(Icons.location_on_outlined, size: 13, color: _muted),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  capa.location.isNotEmpty
                      ? '${capa.area} · ${capa.location}'
                      : capa.area,
                  style: const TextStyle(
                    fontSize: 12,
                    color: _muted,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRemarksField() {
    return TextField(
      controller: _remarksController,
      maxLines: 4,
      enabled: !_isSubmitting,
      style: const TextStyle(fontSize: 13, color: _ink),
      decoration: InputDecoration(
        hintText: 'What action was taken to resolve this issue?',
        hintStyle: const TextStyle(fontSize: 12, color: _muted),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.all(12),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: _border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: _teal, width: 1.5),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: _border),
        ),
      ),
    );
  }

  Widget _buildPhotoRow() {
    return Row(
      children: [
        ..._photos.asMap().entries.map((entry) {
          return Expanded(
            child: Padding(
              padding: const EdgeInsets.only(right: 6),
              child: AspectRatio(
                aspectRatio: 1,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Image.file(
                        entry.value,
                        width: double.infinity,
                        height: double.infinity,
                        fit: BoxFit.cover,
                        cacheWidth: 300,
                      ),
                    ),
                    if (!_isSubmitting)
                      Positioned(
                        top: -6,
                        right: -6,
                        child: GestureDetector(
                          onTap: () => _removePhoto(entry.key),
                          child: Container(
                            padding: const EdgeInsets.all(5),
                            decoration: const BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.close,
                                size: 14, color: Colors.white),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          );
        }),
        ...List.generate(_maxPhotos - _photos.length, (index) {
          final isFirstEmpty = index == 0;
          return Expanded(
            child: Padding(
              padding: EdgeInsets.only(
                right: index < (_maxPhotos - _photos.length) - 1 ? 6 : 0,
              ),
              child: AspectRatio(
                aspectRatio: 1,
                child: isFirstEmpty && !_isSubmitting
                    ? GestureDetector(
                        onTap: _pickPhoto,
                        child: Container(
                          decoration: BoxDecoration(
                            color: _bg,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: _teal, width: 1.5),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.add_a_photo_outlined,
                                  color: _teal, size: 24),
                              const SizedBox(height: 4),
                              Text(
                                '${_photos.length}/$_maxPhotos',
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: _teal,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    : Container(
                        decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: Colors.grey.shade200,
                            width: 1,
                          ),
                        ),
                      ),
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton.icon(
        onPressed: _isSubmitting ? null : _submit,
        icon: _isSubmitting
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : const Icon(Icons.check_circle_rounded, size: 20),
        label: Text(
          _isSubmitting ? 'SUBMITTING...' : 'MARK AS COMPLETE',
          style: const TextStyle(
            fontSize: 13.5,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.5,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: _teal,
          foregroundColor: Colors.white,
          disabledBackgroundColor: Colors.grey.shade400,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w800,
        color: _muted,
        letterSpacing: 1.0,
      ),
    );
  }
}

Future<String> _compressWorker(Map<String, String> params) async {
  try {
    final bytes = await File(params['source']!).readAsBytes();
    final img.Image? decoded = img.decodeImage(bytes);
    if (decoded == null) return params['source']!;
    final resized = img.copyResize(decoded, width: 1024);
    final compressed = img.encodeJpg(resized, quality: 70);
    final file = File(params['target']!);
    await file.writeAsBytes(compressed);
    return params['target']!;
  } catch (e) {
    debugPrint("compress worker error: $e");
    return params['source']!;
  }
}
