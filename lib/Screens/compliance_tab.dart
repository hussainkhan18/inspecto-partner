import 'package:flutter/material.dart';
import 'package:inspecto_shield_partner/Screens/capa_list_screen.dart';
import 'package:inspecto_shield_partner/Screens/compliance_area_screen.dart';
import 'package:inspecto_shield_partner/Screens/compliance_initiate_screen.dart';
import 'package:inspecto_shield_partner/Screens/compliance_upcoming_screen.dart';
import 'package:inspecto_shield_partner/Screens/gemba_walk_screen.dart';
import 'package:inspecto_shield_partner/Screens/internet_error_popup.dart';
import 'package:inspecto_shield_partner/Screens/widgets/qr_scanner_view.dart';
import 'package:inspecto_shield_partner/models/compliance_models.dart';
import 'package:inspecto_shield_partner/services/compliance_service.dart';
import 'package:loading_icon_button/loading_icon_button.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:rflutter_alert/rflutter_alert.dart';

class ComplianceTab extends StatefulWidget {
  const ComplianceTab({super.key});

  @override
  State<ComplianceTab> createState() => _ComplianceTabState();
}

class _ComplianceTabState extends State<ComplianceTab> {
  static const Color _teal = Color(0xff0DC5B9);

  late final MobileScannerController _scannerController;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _scannerController = MobileScannerController();
  }

  @override
  void dispose() {
    _scannerController.dispose();
    super.dispose();
  }

  void _openAreaQrScanner() {
    if (_isLoading) return;
    bool isNavigated = false;

    Alert(
      context: context,
      title: 'Scan Area QR Code',
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
                      'Ensure the Area QR code is scanned under optimal conditions.'),
                  duration: Duration(seconds: 3),
                ),
              );
              return;
            }

            isNavigated = true;
            Navigator.pop(context);
            await _fetchAreaAndOpen(rawValue);
          },
        ),
      ),
      buttons: [
        DialogButton(
          onPressed: () => Navigator.pop(context),
          color: Colors.red,
          child: const Text('Cancel',
              style: TextStyle(color: Colors.white, fontSize: 18)),
        ),
      ],
    ).show();
  }

  Future<void> _fetchAreaAndOpen(String areaQrCode) async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) =>
          const Center(child: CircularProgressIndicator(color: _teal)),
    );

    try {
      final result = await ComplianceService.scanArea(areaQrCode);

      if (!mounted) return;
      Navigator.of(context, rootNavigator: true).pop();

      ComplianceScanAreaResult toOpen = result;
      if (result.complianceTypes.isNotEmpty) {
        final picked = await _showComplianceTypeDialog(result.complianceTypes);
        if (picked == null || !mounted) return;
        toOpen = result.filteredByType(picked);
      }

      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ComplianceAreaScreen(initialData: toOpen),
        ),
      );
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
            content: Text('Something went wrong. Please try again.')),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<ComplianceType?> _showComplianceTypeDialog(
    List<ComplianceType> types,
  ) {
    return showModalBottomSheet<ComplianceType>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Expanded(
                    child: Text(
                      'Which compliance do you want to inspect?',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: Color(0xff1A1A2E),
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(ctx).pop(),
                    icon: const Icon(Icons.close, size: 20, color: Colors.grey),
                    visualDensity: VisualDensity.compact,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(ctx).size.height * 0.5,
                ),
                child: types.isEmpty
                    ? Padding(
                        padding: const EdgeInsets.symmetric(vertical: 32),
                        child: Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.inbox_outlined,
                                size: 40,
                                color: Colors.grey.shade400,
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'No compliance types found',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    : ListView.separated(
                        shrinkWrap: true,
                        itemCount: types.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (_, i) {
                          final t = types[i];
                          return Material(
                            color: _teal.withOpacity(0.06),
                            borderRadius: BorderRadius.circular(14),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(14),
                              onTap: () => Navigator.of(ctx).pop(t),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 14,
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 30,
                                      height: 30,
                                      alignment: Alignment.center,
                                      decoration: BoxDecoration(
                                        color: _teal.withOpacity(0.12),
                                        shape: BoxShape.circle,
                                      ),
                                      child: Text(
                                        '${i + 1}',
                                        style: const TextStyle(
                                          color: _teal,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 13,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        t.name,
                                        style: const TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w600,
                                          color: Color(0xff1A1A2E),
                                        ),
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: _teal.withOpacity(0.15),
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Text(
                                        '${t.totalPoints} ${t.totalPoints == 1 ? "point" : "points"}',
                                        style: const TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w700,
                                          color: _teal,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Icon(
                                      Icons.chevron_right_rounded,
                                      size: 20,
                                      color: Colors.grey.shade400,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildButton(String label,
      Function(dynamic start, dynamic stop, dynamic state) onTap) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: ArgonButton(
        width: MediaQuery.of(context).size.width * 0.9,
        height: 50,
        borderRadius: 8.0,
        elevation: 6,
        color: Colors.black,
        borderSide: const BorderSide(color: Color(0xff0DC5B9), width: 1.5),
        child: Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 15,
            fontWeight: FontWeight.w500,
          ),
        ),
        onTap: (startLoading, stopLoading, btnState) {
          onTap(startLoading, stopLoading, btnState);
        },
      ),
    );
  }

  Widget _buildComplianceCheckButton() {
    return _buildButton('COMPLIANCE CHECK', (start, stop, state) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ComplianceInitiateScreen(
            onScanPressed: _openAreaQrScanner,
          ),
        ),
      );
    });
  }

  Widget _buildUpcomingButton() {
    return _buildButton('UPCOMING COMPLIANCE', (start, stop, state) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const NetworkWrapper(
            child: ComplianceUpcomingScreen(),
          ),
        ),
      );
    });
  }

  Widget _buildGembaWalkButton() {
    return _buildButton('GEMBA WALK', (start, stop, state) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const NetworkWrapper(
            child: GembaWalkScreen(),
          ),
        ),
      );
    });
  }

  Widget _buildCapaButton() {
    return _buildButton('MY CAPAS', (start, stop, state) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const NetworkWrapper(
            child: CapaListScreen(),
          ),
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        children: [
          _buildComplianceCheckButton(),
          _buildUpcomingButton(),
          _buildGembaWalkButton(),
          _buildCapaButton(),
        ],
      ),
    );
  }
}