import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:inspecto_shield_partner/Providers/compliance_upcoming_provider.dart';
import 'package:inspecto_shield_partner/Screens/compliance_inspection_screen.dart';
import 'package:inspecto_shield_partner/Screens/widgets/qr_scanner_view.dart';
import 'package:inspecto_shield_partner/models/compliance_models.dart';
import 'package:inspecto_shield_partner/models/compliance_upcoming_model.dart';
import 'package:inspecto_shield_partner/services/compliance_service.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';
import 'package:rflutter_alert/rflutter_alert.dart';

class _AppColors {
  static const teal = Color(0xff0DC5B9);
  static const ink = Color(0xff1A1A2E);
  static const red = Color(0xffE5484D);
  static const amber = Color(0xffE08A00);
  static const bg = Color(0xffF5F7F7);
  static const surface = Colors.white;
  static const textPrimary = Color(0xff1A1A2E);
  static const textSecondary = Color(0xB3000000); // black70
  static const textMuted = Color(0x8A000000); // black54
}

class _AppText {
  static const title = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w700,
    color: _AppColors.textPrimary,
    height: 1.25,
  );
  static const subtitle = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w500,
    color: _AppColors.textSecondary,
    height: 1.3,
  );
  static const meta = TextStyle(
    fontSize: 11.5,
    fontWeight: FontWeight.w500,
    color: _AppColors.textMuted,
    height: 1.3,
  );
  static const sectionHeader = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w800,
    color: _AppColors.ink,
  );
}

enum _Filter { all, overdue, upcoming }

class ComplianceUpcomingScreen extends StatefulWidget {
  const ComplianceUpcomingScreen({super.key});

  @override
  State<ComplianceUpcomingScreen> createState() =>
      _ComplianceUpcomingScreenState();
}

class _ComplianceUpcomingScreenState extends State<ComplianceUpcomingScreen> {
  late final ComplianceUpcomingProvider _provider;
  late final MobileScannerController _scannerController;
  _Filter _filter = _Filter.all;
  bool _isScanning = false;

  @override
  void initState() {
    super.initState();
    _provider = ComplianceUpcomingProvider()..fetch();
    _scannerController = MobileScannerController();
  }

  @override
  void dispose() {
    _scannerController.dispose();
    _provider.dispose();
    super.dispose();
  }

  void _toggleFilter(_Filter f) {
    setState(() => _filter = _filter == f ? _Filter.all : f);
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<ComplianceUpcomingProvider>.value(
      value: _provider,
      child: Scaffold(
        backgroundColor: _AppColors.bg,
        appBar: AppBar(
          title: const Text(
            'Upcoming Compliance',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          ),
          leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new,
              color: Colors.white, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
          backgroundColor: _AppColors.teal,
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        body: Consumer<ComplianceUpcomingProvider>(
          builder: (context, p, _) {
            final days = p.data?.days ?? 7;
            switch (p.state) {
              case ComplianceUpcomingState.initial:
              case ComplianceUpcomingState.loading:
                return const Center(
                  child: CircularProgressIndicator(color: _AppColors.teal),
                );
              case ComplianceUpcomingState.error:
                return _buildMessage(
                  p,
                  icon: Icons.wifi_off_rounded,
                  color: _AppColors.red,
                  title: 'Could not load upcoming compliance',
                  subtitle: p.errorMessage,
                  buttonLabel: 'Try again',
                );
              case ComplianceUpcomingState.empty:
                return _buildMessage(
                  p,
                  icon: Icons.check_circle_outline_rounded,
                  color: _AppColors.teal,
                  title: 'All caught up',
                  subtitle: days == 1
                      ? 'No compliance points are due in the next day.'
                      : 'No compliance points are due in the next $days days.',
                );
              case ComplianceUpcomingState.loaded:
                return _buildList(p);
            }
          },
        ),
      ),
    );
  }

  Widget _buildList(ComplianceUpcomingProvider p) {
    final data = p.data!;
    final showOverdue = _filter != _Filter.upcoming && data.overdue.isNotEmpty;
    final showUpcoming = _filter != _Filter.overdue && data.upcoming.isNotEmpty;

    final children = <Widget>[
      _buildSummary(data),
      const SizedBox(height: 14),
    ];

    if (showOverdue) {
      children.add(_sectionHeader('Overdue', _AppColors.red));
      for (final item in data.overdue) {
        children.add(_InspectionCard(
          item: item,
          onTap: () => _openEquipmentScanner(item),
        ));
      }
    }

    if (showUpcoming) {
      data.upcomingByDay.forEach((day, items) {
        children.add(_sectionHeader(_dayLabel(day), _AppColors.teal));
        for (final item in items) {
          children.add(_InspectionCard(
            item: item,
            onTap: () => _openEquipmentScanner(item),
          ));
        }
      });
    }

    if (!showOverdue && !showUpcoming) {
      children.add(_emptyFilterState(data.days));
    }

    return RefreshIndicator(
      color: _AppColors.teal,
      onRefresh: () => p.fetch(silent: true),
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
        children: children,
      ),
    );
  }

  Widget _emptyFilterState(int days) {
    final (icon, title, subtitle) = switch (_filter) {
      _Filter.overdue => (
          Icons.emoji_events_outlined,
          'No overdue items',
          'Everything is on schedule. Great job!',
        ),
      _Filter.upcoming => (
          Icons.event_available_outlined,
          'No upcoming items',
          days == 1
              ? 'Nothing is due in the next day.'
              : 'Nothing is due in the next $days days.',
        ),
      _Filter.all => (
          Icons.inbox_outlined,
          'Nothing here',
          'Clear the filter and try again.',
        ),
    };

    return Padding(
      padding: const EdgeInsets.only(top: 60),
      child: Column(
        children: [
          Icon(icon, size: 48, color: _AppColors.teal.withValues(alpha: 0.5)),
          const SizedBox(height: 12),
          Text(
            title,
            style: _AppText.title.copyWith(fontSize: 16),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),
          Text(subtitle, style: _AppText.subtitle, textAlign: TextAlign.center),
        ],
      ),
    );
  }

  Widget _buildSummary(ComplianceUpcomingResponse d) {
    final daysLabel = d.days == 1 ? 'Next 1 day' : 'Next ${d.days} days';

    return Row(
      children: [
        Expanded(
          child: _summaryTile(
            label: 'Overdue',
            count: d.overdue.length,
            color: _AppColors.red,
            selected: _filter == _Filter.overdue,
            onTap: () => _toggleFilter(_Filter.overdue),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _summaryTile(
            label: daysLabel,
            count: d.upcoming.length,
            color: _AppColors.teal,
            selected: _filter == _Filter.upcoming,
            onTap: () => _toggleFilter(_Filter.upcoming),
          ),
        ),
      ],
    );
  }

  Widget _summaryTile({
    required String label,
    required int count,
    required Color color,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return Semantics(
      button: true,
      selected: selected,
      label: '$label, $count items',
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color:
                selected ? color.withValues(alpha: 0.06) : _AppColors.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: selected ? color : Colors.transparent,
              width: 1.5,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    '$count',
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      color: color,
                      height: 1.1,
                    ),
                  ),
                  const Spacer(),
                  if (selected)
                    Icon(Icons.check_circle_rounded, size: 18, color: color)
                  else
                    const Icon(
                      Icons.tune_rounded,
                      size: 16,
                      color: Colors.black26,
                    ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: _AppColors.textMuted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionHeader(String title, Color color) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 20, 4, 12),
      child: Row(
        children: [
          Text(
            title,
            style: _AppText.sectionHeader.copyWith(
              color: color == _AppColors.red ? _AppColors.red : _AppColors.ink,
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
    );
  }

  String _dayLabel(DateTime d) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final diff = DateTime(d.year, d.month, d.day).difference(today).inDays;
    if (diff == 0) return 'Today';
    if (diff == 1) return 'Tomorrow';
    return UpcomingFormat.dayMonth(d);
  }

  void _openEquipmentScanner(ComplianceUpcomingItem item) {
    if (_isScanning) return;
    bool handled = false;

    Alert(
      context: context,
      title: 'Scan "${item.name}" QR',
      content: SizedBox(
        height: 400,
        width: 300,
        child: QrScannerView(
          controller: _scannerController,
          onDetect: (BarcodeCapture capture) async {
            if (handled) return;

            final String? raw = capture.barcodes.first.rawValue?.trim();
            if (raw == null || raw.isEmpty) {
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

            handled = true;
            Navigator.pop(context);
            await _verifyAndOpen(raw, item);
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

  Future<void> _verifyAndOpen(
    String rawValue,
    ComplianceUpcomingItem item,
  ) async {
    if (!mounted) return;

    var scannedCode = rawValue;
    if (rawValue.startsWith('{')) {
      try {
        final decoded = json.decode(rawValue);
        if (decoded is Map && decoded['equipment_qr_code'] != null) {
          scannedCode = decoded['equipment_qr_code'].toString();
        }
      } catch (_) {}
    }

    if (item.qrCode.isNotEmpty &&
        scannedCode.trim().toLowerCase() != item.qrCode.trim().toLowerCase()) {
      _showWrongEquipmentAlert(item.name);
      return;
    }

    setState(() => _isScanning = true);
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(
        child: CircularProgressIndicator(color: _AppColors.teal),
      ),
    );

    try {
      final result = await ComplianceService.scanEquipment(
        scannedCode,
        areaId: item.areaId == 0 ? null : item.areaId,
      );

      if (!mounted) return;
      Navigator.of(context, rootNavigator: true).pop();

      if (result.equipment.id != item.equipmentId) {
        _showWrongEquipmentAlert(item.name);
        return;
      }

      final submittedStatus = await Navigator.push<String>(
        context,
        MaterialPageRoute(
          builder: (_) => ComplianceInspectionScreen(
            equipment: result.equipment,
            checklist: result.checklist,
            areaId: item.areaId,
          ),
        ),
      );

      if (submittedStatus != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${item.name} marked as inspected.')),
        );
        _provider.fetch(silent: true); // inspected item should drop off
      }
    } on ComplianceApiException catch (e) {
      if (!mounted) return;
      Navigator.of(context, rootNavigator: true).pop();
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.message)));
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

  void _showWrongEquipmentAlert(String expectedName) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.error_outline_rounded, color: _AppColors.red),
            SizedBox(width: 8),
            Text(
              'Wrong Equipment',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
          ],
        ),
        content: Text(
          'This QR code does not belong to "$expectedName". '
          'Please scan the QR code on this compliance point.',
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

  Widget _buildMessage(
    ComplianceUpcomingProvider p, {
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
    String? buttonLabel,
  }) {
    return RefreshIndicator(
      color: _AppColors.teal,
      onRefresh: () => p.fetch(silent: true),
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 32),
        children: [
          const SizedBox(height: 120),
          Icon(icon, size: 56, color: color.withValues(alpha: 0.8)),
          const SizedBox(height: 16),
          Text(
            title,
            textAlign: TextAlign.center,
            style: _AppText.title.copyWith(fontSize: 17),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: _AppText.subtitle.copyWith(height: 1.4),
          ),
          if (buttonLabel != null) ...[
            const SizedBox(height: 20),
            Center(
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: _AppColors.teal,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () => p.fetch(),
                child: Text(buttonLabel),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _InspectionCard extends StatelessWidget {
  final ComplianceUpcomingItem item;
  final VoidCallback onTap;

  const _InspectionCard({required this.item, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final overdue = item.isOverdue;

    final accent = overdue
        ? _AppColors.red
        : (item.isDueSoon ? _AppColors.amber : _AppColors.teal);

    final statusText = overdue
        ? 'Overdue ${UpcomingFormat.duration(item.overdueNow)}'
        : (item.dueInNow == 0
            ? 'Due now'
            : 'Due in ${UpcomingFormat.duration(item.dueInNow)}');

    final statusIcon = overdue
        ? Icons.error_outline_rounded
        : (item.dueInNow == 0
            ? Icons.schedule_rounded
            : Icons.access_time_rounded);

    final lastText = item.lastInspectedAt == null
        ? 'Never inspected'
        : 'Last inspected ${UpcomingFormat.shortDate(item.lastInspectedAt!)}';

    final typeAndFrequency = [item.typeName, item.frequencyLabel]
        .where((s) => s.isNotEmpty)
        .join(' · ');

    return Semantics(
      button: true,
      label: '${item.name}, $statusText, ${item.areaName}',
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: _AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: Colors.black.withValues(alpha: 0.04),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(14),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(14),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _thumb(),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.name,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: _AppText.title,
                            ),
                            if (item.qrCode.isNotEmpty) ...[
                              const SizedBox(height: 3),
                              Text('QR: ${item.qrCode}', style: _AppText.meta),
                            ],
                            const SizedBox(height: 8),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Padding(
                                  padding: EdgeInsets.only(top: 1),
                                  child: Icon(
                                    Icons.location_on_rounded,
                                    size: 14,
                                    color: _AppColors.teal,
                                  ),
                                ),
                                const SizedBox(width: 5),
                                Expanded(
                                  child: Text(
                                    item.areaName,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: _AppText.subtitle,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 10),
                      _scanButton(),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Container(
                    height: 1,
                    color: Colors.black.withValues(alpha: 0.06),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      _pill(statusText, accent, statusIcon),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          typeAndFrequency,
                          textAlign: TextAlign.end,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: _AppText.meta,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  _detailLine(lastText),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _detailLine(String lastText) {
    if (item.isOverdue) {
      return Text.rich(
        TextSpan(
          style: _AppText.meta,
          children: [
            if (item.missedCycles > 0)
              TextSpan(
                text: '${item.missedCycles} missed',
                style: _AppText.meta.copyWith(
                  color: _AppColors.red,
                  fontWeight: FontWeight.w700,
                ),
              ),
            if (item.missedCycles > 0) const TextSpan(text: '  ·  '),
            TextSpan(text: lastText),
          ],
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      );
    }

    final parts = <String>[
      if (item.dueAt != null) 'Due at ${UpcomingFormat.time(item.dueAt!)}',
      lastText,
    ];
    return Text(
      parts.join('  ·  '),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: _AppText.meta,
    );
  }

  Widget _scanButton() {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: _AppColors.teal.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: const Icon(
        Icons.qr_code_scanner_rounded,
        size: 24,
        color: _AppColors.teal,
      ),
    );
  }

  Widget _pill(String text, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 5),
          Text(
            text,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _thumb() {
    final url = item.imageUrl;
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: SizedBox(
        width: 56,
        height: 56,
        child: (url == null || url.isEmpty)
            ? _placeholder()
            : Image.network(
                url,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _placeholder(),
              ),
      ),
    );
  }

  Widget _placeholder() {
    return Container(
      color: _AppColors.teal.withValues(alpha: 0.08),
      alignment: Alignment.center,
      child: const Icon(
        Icons.fact_check_outlined,
        color: _AppColors.teal,
        size: 24,
      ),
    );
  }
}
