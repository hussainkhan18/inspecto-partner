import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:inspecto_shield_partner/Providers/app_mode_provider.dart';
import 'package:inspecto_shield_partner/Screens/compliance_inspection_screen.dart';
import 'package:inspecto_shield_partner/Screens/widgets/compliance_image.dart';
import 'package:inspecto_shield_partner/Screens/widgets/qr_scanner_view.dart';
import 'package:inspecto_shield_partner/models/compliance_models.dart';
import 'package:inspecto_shield_partner/repositories/compliance_repository.dart';
import 'package:inspecto_shield_partner/services/area_photo_stamper.dart';
import 'package:inspecto_shield_partner/services/compliance_service.dart';
import 'package:inspecto_shield_partner/services/sound_service.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';
import 'package:rflutter_alert/rflutter_alert.dart';

class ComplianceAreaScreen extends StatefulWidget {
  final ComplianceScanAreaResult initialData;

  const ComplianceAreaScreen({super.key, required this.initialData});

  @override
  State<ComplianceAreaScreen> createState() => _ComplianceAreaScreenState();
}

class _ComplianceAreaScreenState extends State<ComplianceAreaScreen> {
  static const Color _teal = Color(0xff0DC5B9);
  static const Color _green = Color(0xFF22C55E);
  static const Color _red = Color(0xFFEF4444);
  static const Color _amber = Color(0xffF59E0B);

  late final MobileScannerController _scannerController;
  late List<ComplianceEquipment> _equipments;
  late int _totalEquipments;
  bool _isScanning = false;

  int get _maxStaffPhotos => widget.initialData.maxGroupPhotos;
  final ImagePicker _picker = ImagePicker();
  final List<File> _staffPhotos = [];
  bool _isCapturingPhoto = false;
  bool _isSubmitting = false;
  final Map<int, Set<int>> _selectedCriteria = {};
  final TextEditingController _remarksController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _scannerController = MobileScannerController();
    _equipments = List.of(widget.initialData.equipments);
    _totalEquipments = widget.initialData.totalEquipments;
  }

  @override
  void dispose() {
    _scannerController.dispose();
    _remarksController.dispose();
    super.dispose();
  }

  int get _completedCount => _equipments.where((e) => e.isCompleted).length;

  double get _progress =>
      _totalEquipments == 0 ? 0 : _completedCount / _totalEquipments;

  void _openEquipmentQrScanner(ComplianceEquipment expectedEquipment) {
    if (_isScanning) return;
    bool isNavigated = false;

    Alert(
      context: context,
      title: 'Scan "${expectedEquipment.name}" QR',
      content: SizedBox(
        height: 400,
        width: 300,
        child: QrScannerView(
          controller: _scannerController,
          onDetect: (BarcodeCapture barcodeCapture) async {
            if (isNavigated) return;

            final String? rawValue =
                barcodeCapture.barcodes.first.rawValue?.trim();

            if (rawValue == null || rawValue.isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                    'Ensure the QR code is scanned under optimal conditions.',
                  ),
                  duration: Duration(seconds: 3),
                ),
              );
              return;
            }

            isNavigated = true;
            Navigator.pop(context);
            await _fetchEquipmentAndOpen(rawValue, expectedEquipment);
          },
        ),
      ),
      buttons: [
        DialogButton(
          onPressed: () => Navigator.pop(context),
          color: Colors.red,
          child: const Text(
            'Cancel',
            style: TextStyle(color: Colors.white, fontSize: 18),
          ),
        ),
      ],
    ).show();
  }

  Future<void> _fetchEquipmentAndOpen(
    String rawValue,
    ComplianceEquipment expectedEquipment,
  ) async {
    if (!mounted) return;

    String scannedCode = rawValue;
    if (rawValue.startsWith('{')) {
      try {
        final decoded = json.decode(rawValue);
        if (decoded is Map && decoded['equipment_qr_code'] != null) {
          scannedCode = decoded['equipment_qr_code'].toString();
        }
      } catch (_) {}
    }

    final expectedCode = expectedEquipment.equipmentQrCode?.trim();
    if (expectedCode != null &&
        expectedCode.isNotEmpty &&
        scannedCode.trim().toLowerCase() != expectedCode.toLowerCase()) {
      _showEquipmentMismatchAlert(expectedEquipment.name);
      return;
    }

    setState(() => _isScanning = true);
    _showLoadingDialog();

    final isOffline = context.read<AppModeProvider>().isOfflineMode;

    try {
      ComplianceScanEquipmentResult result;

      if (isOffline) {
        final row = await ComplianceRepository.instance.lookupByQr(scannedCode);

        if (row == null) {
          if (!mounted) return;
          Navigator.of(context, rootNavigator: true).pop();
          _showEquipmentMismatchAlert(expectedEquipment.name);
          return;
        }

        final checklistRaw = (row['checklist'] as List<dynamic>?) ?? const [];
        final checklist = checklistRaw
            .whereType<Map>()
            .map(
              (e) => ComplianceChecklistItem.fromJson(
                Map<String, dynamic>.from(e),
              ),
            )
            .toList();

        result = ComplianceScanEquipmentResult(
          equipment: ComplianceEquipment.fromCachedRow(row),
          checklist: checklist,
        );
      } else {
        result = await ComplianceService.scanEquipment(
          scannedCode,
          areaId: widget.initialData.area.id,
        );
      }

      if (!mounted) return;
      Navigator.of(context, rootNavigator: true).pop();
      if (result.equipment.id != expectedEquipment.id) {
        _showEquipmentMismatchAlert(expectedEquipment.name);
        return;
      }

      SoundService.playBeep();

      final submittedStatus = await Navigator.push<String>(
        context,
        MaterialPageRoute(
          builder: (context) => ComplianceInspectionScreen(
            equipment: result.equipment,
            checklist: result.checklist,
            areaId: widget.initialData.area.id,
          ),
        ),
      );

      if (submittedStatus != null && mounted) {
        _markEquipmentCompleted(result.equipment, submittedStatus);
      }
    } on ComplianceApiException catch (e) {
      if (!mounted) return;
      Navigator.of(context, rootNavigator: true).pop();
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.message)));
    } catch (_) {
      if (!mounted) return;
      Navigator.of(context, rootNavigator: true).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Something went wrong. Please try again.'),
        ),
      );
    } finally {
      if (mounted) setState(() => _isScanning = false);
    }
  }

  void _showEquipmentMismatchAlert(String expectedName) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.error_outline_rounded, color: _red),
            SizedBox(width: 8),
            Text(
              'Wrong Equipment',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
          ],
        ),
        content: Text(
          'This QR code does not belong to "$expectedName". Please scan the correct QR code for this equipment.',
          style: const TextStyle(fontSize: 13.5, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _markEquipmentCompleted(ComplianceEquipment scanned, String status) {
    setState(() {
      final index = _equipments.indexWhere(
        (e) =>
            e.id == scanned.id ||
            (scanned.equipmentQrCode != null &&
                e.equipmentQrCode == scanned.equipmentQrCode),
      );

      if (index != -1) {
        _equipments[index] = _equipments[index].copyWith(
          isCompleted: true,
          inspectionResult: status,
        );
      } else {
        _equipments.add(
          scanned.copyWith(isCompleted: true, inspectionResult: status),
        );
        _totalEquipments += 1;
      }
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${scanned.name} marked as inspected.')),
    );
  }

  void _showLoadingDialog() {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) =>
          const Center(child: CircularProgressIndicator(color: _teal)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final area = widget.initialData.area;

    return Scaffold(
      backgroundColor: const Color(0xffF5F6FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          area.name.toUpperCase(),
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          children: [
            _buildShiftBanner(),
            _buildProgressCard(),
            Expanded(
              child: _equipments.isEmpty
                  ? _buildEmptyState()
                  : ListView(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                      children: [
                        const Text(
                          'All Compliance Points',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: Color(0xff1A1A2E),
                          ),
                        ),
                        const SizedBox(height: 10),
                        ..._equipments.map(_buildEquipmentCard),
                        ..._buildVisitSections(),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _shiftIcon(String name) {
    final n = name.toLowerCase();
    if (n.contains('morning')) return Icons.wb_sunny_rounded;
    if (n.contains('evening') || n.contains('afternoon')) {
      return Icons.wb_twilight_rounded;
    }
    if (n.contains('night')) return Icons.nights_stay_rounded;
    return Icons.schedule_rounded;
  }

  Widget _buildShiftBanner() {
    final current = widget.initialData.currentShift;
    final shift = current?.shift;
    if (current == null || shift == null) return const SizedBox.shrink();

    final timeText = shift.timeRange.isNotEmpty
        ? shift.timeRange
        : '${shift.startTime} - ${shift.endTime}';

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF26D0CE), Color(0xFF0DC5B9)],
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: _teal.withOpacity(0.25),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(11),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(_shiftIcon(shift.name), color: Colors.white, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'CURRENT SHIFT',
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1,
                    color: Colors.white.withOpacity(0.8),
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  shift.name.isNotEmpty ? shift.name : 'Shift',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(
                      Icons.access_time_rounded,
                      size: 14,
                      color: Colors.white,
                    ),
                    const SizedBox(width: 5),
                    Flexible(
                      child: Text(
                        timeText,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
                if (current.serverTime12h.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    'As of ${current.serverTime12h}',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.white.withOpacity(0.75),
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (shift.overnight)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text(
                'OVERNIGHT',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.6,
                  color: Colors.white,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildOperatorAvatar(ComplianceEmployee emp, {double size = 52}) {
    final trimmed = emp.name.trim();
    final initial = trimmed.isNotEmpty ? trimmed[0].toUpperCase() : '?';

    final fallback = Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: _teal.withOpacity(0.10),
        shape: BoxShape.circle,
      ),
      child: Text(
        initial,
        style: TextStyle(
          fontSize: size * 0.4,
          fontWeight: FontWeight.w800,
          color: _teal,
        ),
      ),
    );

    final url = emp.photoUrl;
    if (url == null) return fallback;

    return ClipOval(
      child: Image.network(
        url,
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => fallback,
        loadingBuilder: (context, child, progress) {
          if (progress == null) return child;
          return Container(
            width: size,
            height: size,
            alignment: Alignment.center,
            color: const Color(0xffF1F5F9),
            child: const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2, color: _teal),
            ),
          );
        },
      ),
    );
  }

  BoxDecoration _cardDecoration() => BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      );

  Widget _buildSectionHeader(IconData icon, String title, {String? badge}) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: _teal.withOpacity(0.10),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: _teal, size: 18),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: Color(0xff1A1A2E),
            ),
          ),
        ),
        if (badge != null)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
            decoration: BoxDecoration(
              color: _teal.withOpacity(0.10),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              badge,
              style: const TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w800,
                color: _teal,
              ),
            ),
          ),
      ],
    );
  }

  List<Widget> _buildVisitSections() {
    final isOffline = context.read<AppModeProvider>().isOfflineMode;
    return [
      if (!isOffline) _buildStaffPhotoCard(),
      _buildOperatorsCard(),
      if (!isOffline) ..._buildSubmitSection(),
    ];
  }

  void _toggleCriterion(int employeeId, int criterionId) {
    setState(() {
      final set = _selectedCriteria.putIfAbsent(employeeId, () => <int>{});
      if (!set.add(criterionId)) set.remove(criterionId);
    });
  }

  Future<void> _captureStaffPhoto() async {
    if (_isCapturingPhoto || _staffPhotos.length >= _maxStaffPhotos) return;
    try {
      final picked = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 20,
        maxWidth: 500,
        maxHeight: 500,
      );
      if (picked == null || !mounted) return;

      setState(() => _isCapturingPhoto = true);
      final stamped = await AreaPhotoStamper.stamp(
        File(picked.path),
        widget.initialData.area.name,
      );
      if (!mounted) return;
      setState(() => _staffPhotos.add(stamped));
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not capture the photo.')),
        );
      }
    } finally {
      if (mounted) setState(() => _isCapturingPhoto = false);
    }
  }

  Future<void> _submitAreaVisit() async {
    if (_isSubmitting) return;

    final ratings = <int, List<int>>{};
    _selectedCriteria.forEach((employeeId, ids) {
      if (ids.isNotEmpty) ratings[employeeId] = (ids.toList()..sort());
    });

    setState(() => _isSubmitting = true);
    try {
      await ComplianceService.submitAreaVisit(
        areaId: widget.initialData.area.id,
        employeeCriteria: ratings,
        groupPhotos: List.of(_staffPhotos),
        remarks: _remarksController.text,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Area visit submitted successfully.')),
      );
      Navigator.of(context).pop();
    } on ComplianceApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.message)));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Something went wrong. Please try again.')),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Widget _buildStaffPhotoCard() {
    final canAdd = _staffPhotos.length < _maxStaffPhotos;
    return Container(
      margin: const EdgeInsets.only(top: 18),
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(
            Icons.photo_camera_rounded,
            'Site Staff Picture',
            badge: '${_staffPhotos.length}/$_maxStaffPhotos',
          ),
          const SizedBox(height: 6),
          Text(
            'You can capture up to $_maxStaffPhotos photos.',
            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              for (int i = 0; i < _staffPhotos.length; i++) _buildPhotoThumb(i),
              if (_isCapturingPhoto)
                _buildPhotoLoadingTile()
              else if (canAdd)
                _buildAddPhotoTile(),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPhotoThumb(int index) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.file(
            _staffPhotos[index],
            width: 88,
            height: 88,
            fit: BoxFit.cover,
            cacheWidth: 264,
          ),
        ),
        Positioned(
          top: -6,
          right: -6,
          child: GestureDetector(
            onTap: _isSubmitting
                ? null
                : () => setState(() => _staffPhotos.removeAt(index)),
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: _red,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 1.5),
              ),
              child: const Icon(Icons.close_rounded,
                  size: 13, color: Colors.white),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAddPhotoTile() {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: _isSubmitting ? null : _captureStaffPhoto,
      child: Container(
        width: 88,
        height: 88,
        decoration: BoxDecoration(
          color: _teal.withOpacity(0.06),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _teal.withOpacity(0.4)),
        ),
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add_a_photo_rounded, color: _teal, size: 24),
            SizedBox(height: 4),
            Text(
              'Add Photo',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: _teal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPhotoLoadingTile() {
    return Container(
      width: 88,
      height: 88,
      decoration: BoxDecoration(
        color: const Color(0xffF1F5F9),
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Center(
        child: SizedBox(
          width: 22,
          height: 22,
          child: CircularProgressIndicator(strokeWidth: 2.5, color: _teal),
        ),
      ),
    );
  }

  Widget _buildOperatorsCard() {
    final current = widget.initialData.currentShift;
    if (current == null) return const SizedBox.shrink();

    final employees = current.employees;
    final criteria = widget.initialData.ratingCriteria;

    return Container(
      margin: const EdgeInsets.only(top: 14),
      padding: const EdgeInsets.fromLTRB(12, 16, 12, 12),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: _buildSectionHeader(
              Icons.groups_rounded,
              'Area Operators',
              badge: '${employees.length}',
            ),
          ),
          const SizedBox(height: 12),
          if (employees.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Row(
                children: [
                  Icon(Icons.people_outline_rounded,
                      color: Colors.grey.shade400, size: 22),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'No operators on duty in this area right now.',
                      style:
                          TextStyle(fontSize: 13, color: Colors.grey.shade600),
                    ),
                  ),
                ],
              ),
            )
          else
            _buildRatingTable(employees, criteria),
        ],
      ),
    );
  }

  static const double _kLeftColW = 72;
  static const double _kTotalColW = 46;
  static const double _kHeaderH = 118;
  static const double _kRowH = 80;
  static const Color _lineColor = Color(0xffE2E8F0);

  Widget _buildRatingTable(
    List<ComplianceEmployee> employees,
    List<ComplianceRatingCriterion> criteria,
  ) {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: const Color(0xffF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _lineColor),
      ),
      child: Column(
        children: [
          _buildTableHeader(criteria),
          ...employees.map((e) => _buildEmployeeRow(e, criteria)),
        ],
      ),
    );
  }

  Widget _buildTableHeader(List<ComplianceRatingCriterion> criteria) {
    const labelStyle = TextStyle(
      fontSize: 9.5,
      fontWeight: FontWeight.w800,
      letterSpacing: 0.5,
      color: _teal,
    );

    return Container(
      height: _kHeaderH,
      color: _teal.withOpacity(0.08),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(
            width: _kLeftColW,
            child: Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: EdgeInsets.only(bottom: 8),
                child: Text('OPERATOR', style: labelStyle),
              ),
            ),
          ),
          ...criteria.map(
            (c) => Expanded(
              child: Tooltip(
                message: c.title,
                child: Container(
                  alignment: Alignment.center,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 2, vertical: 6),
                  decoration: BoxDecoration(
                    border: Border(
                      left: BorderSide(color: _teal.withOpacity(0.15)),
                    ),
                  ),
                  child: RotatedBox(
                    quarterTurns: 3,
                    child: Text(
                      c.title,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 11,
                        height: 1.15,
                        fontWeight: FontWeight.w800,
                        color: _teal,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(
            width: _kTotalColW,
            child: Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: EdgeInsets.only(bottom: 8),
                child: Text('TOTAL', style: labelStyle),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmployeeRow(
    ComplianceEmployee e,
    List<ComplianceRatingCriterion> criteria,
  ) {
    final selected = _selectedCriteria[e.id] ?? const <int>{};
    final earned = selected.length * widget.initialData.starsPerCriteria;
    final total = widget.initialData.totalStars;

    return Container(
      height: _kRowH,
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: _lineColor)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: _kLeftColW,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildOperatorAvatar(e, size: 40),
                  const SizedBox(height: 3),
                  Text(
                    e.name,
                    maxLines: 1,
                    textAlign: TextAlign.center,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                      color: Color(0xff1A1A2E),
                    ),
                  ),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      'ID ${e.employeeCode ?? e.id}',
                      style: const TextStyle(
                        fontSize: 9.5,
                        fontWeight: FontWeight.w700,
                        color: _teal,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          ...criteria.map((c) {
            final isSelected = selected.contains(c.id);
            return Expanded(
              child: InkWell(
                onTap:
                    _isSubmitting ? null : () => _toggleCriterion(e.id, c.id),
                child: Container(
                  alignment: Alignment.center,
                  padding: const EdgeInsets.symmetric(horizontal: 2),
                  decoration: const BoxDecoration(
                    border: Border(left: BorderSide(color: _lineColor)),
                  ),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Icon(
                      isSelected
                          ? Icons.star_rounded
                          : Icons.star_outline_rounded,
                      size: 30,
                      color: isSelected ? _amber : const Color(0xffCBD5E1),
                    ),
                  ),
                ),
              ),
            );
          }),
          SizedBox(
            width: _kTotalColW,
            child: Center(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.star_rounded, color: _amber, size: 16),
                    const SizedBox(height: 1),
                    Text(
                      '$earned/$total',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: Color(0xff1A1A2E),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildSubmitSection() {
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: Color(0xffDDE1E7)),
    );

    return [
      const SizedBox(height: 14),
      TextField(
        controller: _remarksController,
        enabled: !_isSubmitting,
        minLines: 1,
        maxLines: 2,
        decoration: InputDecoration(
          hintText: 'Remarks (optional)',
          hintStyle: const TextStyle(fontSize: 13, color: Color(0xffAAAAAA)),
          filled: true,
          fillColor: Colors.white,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          border: border,
          enabledBorder: border,
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: _teal, width: 1.5),
          ),
        ),
      ),
      const SizedBox(height: 14),
      SizedBox(
        width: double.infinity,
        height: 52,
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: _teal,
            foregroundColor: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          onPressed: (_isSubmitting || _isScanning || _isCapturingPhoto)
              ? null
              : _submitAreaVisit,
          child: _isSubmitting
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                      strokeWidth: 2.5, color: Colors.white),
                )
              : const Text(
                  'SUBMIT AREA VISIT',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.1,
                  ),
                ),
        ),
      ),
    ];
  }

  Widget _buildProgressCard() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.fact_check_rounded, color: _teal, size: 20),
              const SizedBox(width: 8),
              const Text(
                'Inspection Progress',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: Color(0xff1A1A2E),
                ),
              ),
              const Spacer(),
              Text(
                '$_completedCount / $_totalEquipments',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: _teal,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: LinearProgressIndicator(
              value: _progress,
              minHeight: 8,
              backgroundColor: const Color(0xffE2E8F0),
              valueColor: AlwaysStoppedAnimation<Color>(
                _progress >= 1 ? _green : _teal,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.inbox_rounded, size: 48, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            const Text(
              'No compliance points found',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 6),
            Text(
              'This area has no compliance equipment registered yet.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEquipmentCard(ComplianceEquipment eq) {
    final Color statusColor = eq.inspectionResult == 'failed' ? _red : _green;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: eq.isCompleted
              ? statusColor.withOpacity(0.3)
              : const Color(0xffE2E8F0),
        ),
      ),
      child: Row(
        children: [
          Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: ComplianceImage(
                  imagePath: eq.imageUrl,
                  width: 52,
                  height: 52,
                  fit: BoxFit.cover,
                ),
              ),
              if (eq.isCompleted)
                Positioned(
                  right: -2,
                  bottom: -2,
                  child: Container(
                    padding: const EdgeInsets.all(1.5),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.check_circle_rounded,
                      color: statusColor,
                      size: 16,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              eq.name,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 14.5,
                fontWeight: FontWeight.w700,
                color: Color(0xff1A1A2E),
              ),
            ),
          ),
          const SizedBox(width: 8),
          if (eq.isCompleted)
            Container(
              padding: const EdgeInsets.all(9),
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.10),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(Icons.check_rounded, color: statusColor, size: 20),
            )
          else
            Material(
              color: _teal.withOpacity(0.10),
              borderRadius: BorderRadius.circular(10),
              child: InkWell(
                borderRadius: BorderRadius.circular(10),
                onTap: _isScanning ? null : () => _openEquipmentQrScanner(eq),
                child: const Padding(
                  padding: EdgeInsets.all(9),
                  child: Icon(
                    Icons.qr_code_scanner_rounded,
                    color: _teal,
                    size: 20,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
