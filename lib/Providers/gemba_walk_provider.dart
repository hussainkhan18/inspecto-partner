import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image/image.dart' as img;
import 'package:inspecto_shield_partner/services/gemba_walk_service.dart';
import 'package:path_provider/path_provider.dart' as path_provider;
import 'package:path/path.dart' as p;

class GembaWalkProvider with ChangeNotifier {
  final ImagePicker _picker = ImagePicker();
  final GembaWalkService _service = GembaWalkService();

  bool _disposed = false;

  void _safeNotify() {
    if (!_disposed) notifyListeners();
  }

  Map<String, dynamic> _gembaData = {};
  Map<String, dynamic> get gembaData => _gembaData;

  bool _isLoadingDetail = true;
  bool get isLoadingDetail => _isLoadingDetail;

  String? _detailError;
  String? get detailError => _detailError;

  bool _canSubmit = false;
  bool get canSubmit => _canSubmit;

  bool _canAddCapa = false;
  bool get canAddCapa => _canAddCapa;

  int _maxPhotosPerPoint = 3;
  int get maxPhotosPerPoint => _maxPhotosPerPoint;

  int _remarksMaxLength = 2000;
  int get remarksMaxLength => _remarksMaxLength;

  bool _isAssigned = true;
  bool get isAssigned => _isAssigned;

  Future<void> initialize({
    required Map<String, dynamic> gembaData,
    required bool isAssigned,
  }) async {
    _gembaData = gembaData;
    _isAssigned = isAssigned;
    _safeNotify();
    await _fetchDetail();
  }

  Future<void> _fetchDetail() async {
    _isLoadingDetail = true;
    _detailError = null;
    _safeNotify();

    final id = _toInt(_gembaData['id']);
    if (id == null || id == 0) {
      _isLoadingDetail = false;
      _detailError = 'Invalid walk id';
      _safeNotify();
      return;
    }

    final result = await _service.fetchWalkDetail(id);

    if (_disposed) return;

    if (result['success'] == true) {
      _canSubmit = result['can_submit'] == true;
      _canAddCapa = result['can_add_capa'] == true;
      _maxPhotosPerPoint = result['max_photos_per_point'] ?? 3;
      _remarksMaxLength = result['remarks_max_length'] ?? 2000;
      _loadQuestionsFromApi(result['checklist'] as List);

      final walkStatus = _gembaData['status']?.toString() ?? '';
      if (walkStatus == 'submitted' || walkStatus == 'closed') {
        _isSubmitted = true;
      }
    } else {
      _detailError = result['message']?.toString() ?? 'Failed to load';
    }

    _isLoadingDetail = false;
    _safeNotify();
  }

  int? _toInt(dynamic v) => v is int ? v : int.tryParse('${v ?? ''}');

  List<Map<String, dynamic>> _questions = [];
  List<Map<String, dynamic>> get questions => _questions;

  final Map<int, String> _complianceStatus = {};
  Map<int, String> get complianceStatus => _complianceStatus;

  final Map<int, TextEditingController> _notesControllers = {};
  Map<int, TextEditingController> get notesControllers => _notesControllers;

  final Map<int, List<File>> _questionImages = {};
  Map<int, List<File>> get questionImages => _questionImages;

  final Map<int, List<String>> _questionImageUrls = {};
  Map<int, List<String>> get questionImageUrls => _questionImageUrls;
  bool _isCompressing = false;
  bool get isCompressing => _isCompressing;

  bool _isSubmitted = false;
  bool get isSubmitted => _isSubmitted;

  bool _isSubmitting = false;
  bool get isSubmitting => _isSubmitting;

  bool get isLocked => _isSubmitted || _isSubmitting;

  int get completedCount {
    if (_isSubmitted) return _questions.length;
    int count = 0;
    for (var q in _questions) {
      final id = q['id'] as int;
      final status = _complianceStatus[id];
      final images = _questionImages[id] ?? [];
      final urls = _questionImageUrls[id] ?? [];
      if (status != null &&
          status != 'pending' &&
          (images.isNotEmpty || urls.isNotEmpty)) {
        count++;
      }
    }
    return count;
  }

  int get totalCount => _questions.length;
  double get progress => totalCount == 0 ? 0 : completedCount / totalCount;

  bool get allMarked {
    if (_complianceStatus.isEmpty) return false;
    for (var q in _questions) {
      final id = q['id'] as int;
      final status = _complianceStatus[id];
      final images = _questionImages[id] ?? [];
      if (status == null || status == 'pending' || images.isEmpty) {
        return false;
      }
    }
    return true;
  }

  bool _showCapaForm = false;
  bool get showCapaForm => _showCapaForm;

  void toggleCapaForm() {
    _showCapaForm = !_showCapaForm;
    _safeNotify();
  }

  void _loadQuestionsFromApi(List checklist) {
    for (var c in _notesControllers.values) {
      c.dispose();
    }
    _notesControllers.clear();
    _complianceStatus.clear();
    _questionImages.clear();
    _questionImageUrls.clear();
    _questions = [];

    for (final raw in checklist) {
      final map = Map<String, dynamic>.from(raw as Map);
      final id = _toInt(map['checklist_item_id']) ?? 0;
      if (id == 0) continue;

      _questions.add({
        'id': id,
        'question': map['item']?.toString() ?? '',
        'sort_order': map['sort_order'] ?? 0,
        'raw_response': map['response'],
      });

      final resp = map['response'];
      if (resp is Map) {
        _complianceStatus[id] = resp['response']?.toString() ?? 'pending';
        _notesControllers[id] = TextEditingController(
          text: resp['remarks']?.toString() ?? '',
        );

        final rawPhotos = resp['photos'];
        if (rawPhotos is List) {
          _questionImageUrls[id] = rawPhotos.map((e) => e.toString()).toList();
        } else {
          _questionImageUrls[id] = [];
        }
      } else {
        _complianceStatus[id] = 'pending';
        _notesControllers[id] = TextEditingController();
        _questionImageUrls[id] = [];
      }
      _questionImages[id] = [];
    }

    _questions.sort(
        (a, b) => (a['sort_order'] as int).compareTo(b['sort_order'] as int));
  }

  void setComplianceStatus(int questionId, String status) {
    if (_isSubmitted) return;
    _complianceStatus[questionId] = status;
    _safeNotify();
  }

  Future<void> pickImage(int questionId) async {
    if (_isSubmitted) return;
    final current = _questionImages[questionId] ?? [];
    if (current.length >= 3) {
      return;
    }

    try {
      final XFile? picked = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1200,
        imageQuality: 85,
      );

      if (picked == null) return;

      _isCompressing = true;
      _safeNotify();

      final compressed = await _compressImage(File(picked.path));

      if (_disposed) return;
      _questionImages[questionId]!.add(compressed);
    } catch (e) {
      debugPrint("Error picking image: $e");
    } finally {
      _isCompressing = false;
      _safeNotify();
    }
  }

  Future<File> _compressImage(File file) async {
    try {
      final dir = await path_provider.getTemporaryDirectory();
      final targetPath = p.join(
        dir.path,
        "${DateTime.now().millisecondsSinceEpoch}_gemba_compressed.jpg",
      );
      final resultPath = await compute(_compressGembaImageWorker, {
        'source': file.path,
        'target': targetPath,
      });

      return File(resultPath);
    } catch (e) {
      debugPrint("Compression fallback error: $e");
      return file;
    }
  }

  void removeImage(int questionId, int index) {
    if (_isSubmitted) return;
    if (_questionImages[questionId] != null &&
        index >= 0 &&
        index < _questionImages[questionId]!.length) {
      _questionImages[questionId]!.removeAt(index);
      _safeNotify();
    }
  }

  Future<Map<String, dynamic>> submitWalk() async {
    if (_isSubmitting) {
      return {'success': false, 'message': 'Please wait, submitting...'};
    }
    if (!allMarked) {
      return {'success': false, 'message': 'Please mark all questions first'};
    }

    _isSubmitting = true;
    _safeNotify();

    try {
      final responses = <Map<String, dynamic>>[];
      for (var q in _questions) {
        final id = q['id'] as int;
        final status = _complianceStatus[id];
        if (status == null || status == 'pending') continue;
        responses.add({
          'id': id,
          'response': status,
          'remarks': _notesControllers[id]?.text ?? '',
        });
      }

      final result = await _service.submitWalk(
        walkId: _gembaData['id'],
        responses: responses,
        photos: _questionImages,
      );

      if (result['success'] == true) {
        applySubmitResponse(result['data'] as Map<String, dynamic>? ?? {});
      }
      _safeNotify();
      return result;
    } finally {
      _isSubmitting = false;
      _safeNotify();
    }
  }

  List<int> get nonCompliantIds => _complianceStatus.entries
      .where((e) => e.value == 'non_compliance')
      .map((e) => e.key)
      .toList();

  void applySubmitResponse(Map<String, dynamic> data) {
    final newData = data['data'];
    if (newData is Map) {
      _gembaData = {
        ..._gembaData,
        ...Map<String, dynamic>.from(newData),
      };
    }
    _canSubmit = false;
    _canAddCapa = data['can_add_capa'] == true;
    _isSubmitted = true;
    _safeNotify();
  }

  void reset() {
    for (var c in _notesControllers.values) {
      c.dispose();
    }
    _notesControllers.clear();
    _questionImages.clear();
    _questionImageUrls.clear();
    _complianceStatus.clear();
    _questions = [];
    _isSubmitted = false;
    _isSubmitting = false;
    _isCompressing = false;
    _gembaData = {};
    _safeNotify();
  }

  @override
  void dispose() {
    _disposed = true;
    for (var c in _notesControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> retryDetail() async {
    await _fetchDetail();
  }
}

Future<String> _compressGembaImageWorker(Map<String, String> params) async {
  try {
    final bytes = await File(params['source']!).readAsBytes();
    final img.Image? decoded = img.decodeImage(bytes);

    if (decoded == null) return params['source']!;

    final img.Image resized = img.copyResize(decoded, width: 1024);

    final List<int> compressed = img.encodeJpg(resized, quality: 70);

    final file = File(params['target']!);
    await file.writeAsBytes(compressed);
    return params['target']!;
  } catch (e) {
    debugPrint("Isolate compression error: $e");
    return params['source']!;
  }
}
