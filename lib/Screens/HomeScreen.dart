import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:inspecto_shield_partner/LanguageTranslate/app_localizations.dart';
import 'package:inspecto_shield_partner/Providers/app_mode_provider.dart';
import 'package:inspecto_shield_partner/Providers/upcoming_inspection_provider.dart';
import 'package:inspecto_shield_partner/Screens/Profile.dart';
import 'package:inspecto_shield_partner/Screens/area_location_dialog.dart';
import 'package:inspecto_shield_partner/Screens/complaints_screen.dart';
import 'package:inspecto_shield_partner/Screens/equipment_info.dart';
import 'package:inspecto_shield_partner/Screens/internet_error_popup.dart';
import 'package:inspecto_shield_partner/Screens/login.dart';
import 'package:inspecto_shield_partner/Screens/my_record.dart';
import 'package:inspecto_shield_partner/Screens/new_inspection.dart';
import 'package:inspecto_shield_partner/Screens/upcoming_inspection_screen.dart';
import 'package:inspecto_shield_partner/repositories/equipment_repository.dart';
import 'package:inspecto_shield_partner/repositories/inspection_repository.dart';
import 'package:inspecto_shield_partner/services/auth_service.dart';
import 'package:inspecto_shield_partner/services/equipment_service.dart';
import 'package:inspecto_shield_partner/services/home_service.dart';
import 'package:inspecto_shield_partner/services/notification_service.dart';
import 'package:inspecto_shield_partner/services/offline_equipment_service.dart';
import 'package:internet_connection_checker/internet_connection_checker.dart';
import 'package:loading_icon_button/loading_icon_button.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';
import 'package:rflutter_alert/rflutter_alert.dart';
import 'package:audioplayers/audioplayers.dart';

class HomeScreen extends StatefulWidget {
  final int id;
  final String name;
  final String company;
  final String branch;
  final String email;
  // final String password;
  final String image;
  final String contact;

  const HomeScreen({
    super.key,
    required this.id,
    required this.name,
    required this.company,
    required this.branch,
    required this.email,
    // required this.password,
    required this.image,
    required this.contact,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // final MobileScannerController _controller = MobileScannerController();
  final MobileScannerController controller = MobileScannerController();
  StreamSubscription<Object?>? _subscription;
  String? scannedCode;
  String? code;

  final AudioPlayer _audioPlayer = AudioPlayer();

  @override
  void initState() {
    super.initState();
    _initAudio();
    _setupNotificationListener();
  }

  Future<void> _initAudio() async {
    await AudioPlayer.global.setAudioContext(
      AudioContext(
        android: const AudioContextAndroid(
          isSpeakerphoneOn: false,
          stayAwake: false,
          contentType: AndroidContentType.music,
          usageType: AndroidUsageType.alarm,
          audioFocus: AndroidAudioFocus.gain,
        ),
        iOS: AudioContextIOS(
          category: AVAudioSessionCategory.playback,
          options: const {AVAudioSessionOptions.mixWithOthers},
        ),
      ),
    );
  }

  void _setupNotificationListener() {
    NotificationService().onNotificationClick = (data) {
      print('HomeScreen received notification data: $data');
      if (mounted && (data.containsKey('is_emergency') || data.isNotEmpty)) {
        _showPendingInspectionsPopup();
      }
    };
    Future.delayed(const Duration(milliseconds: 500), () {
      NotificationService().deliverPendingNotification();
    });
  }

  Future<Map<String, dynamic>?> _fetchPendingInspections() async {
    try {
      return await HomeService.getPendingInspections(widget.id);
    } catch (e) {
      print('Error fetching pending inspections: $e');
      return null;
    }
  }

  void _showPendingInspectionsPopup() async {
    try {
      await _audioPlayer.stop();
      await _audioPlayer.setVolume(0.4);
      await _audioPlayer.setReleaseMode(ReleaseMode.loop);
      await _audioPlayer.play(AssetSource('sounds/alarm.mp3'));
    } catch (e) {
      print('Sound play error: $e');
    }

    showDialog(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black.withOpacity(0.6),
      builder: (BuildContext context) {
        return _AlarmPopup(
          fetchPendingInspections: _fetchPendingInspections,
          onClose: () {
            _audioPlayer.stop();
            Navigator.pop(context);
          },
          buildCard: _buildInspectionCard,
        );
      },
    ).then((_) {
      _audioPlayer.stop();
    });
  }

  Widget _buildInspectionCard(Map<String, dynamic> inspection, int index) {
    final status = inspection['status'] ?? 'Pending';

    Color statusColor;
    Color statusBg;
    IconData statusIcon;

    switch (status.toLowerCase()) {
      case 'overdue':
        statusColor = const Color(0xFFEF4444);
        statusBg = const Color(0xFFEF4444);
        statusIcon = Icons.error_outline_rounded;
        break;
      case 'pending':
        statusColor = const Color(0xFFF59E0B);
        statusBg = const Color(0xFFF59E0B);
        statusIcon = Icons.schedule_rounded;
        break;
      case 'completed':
        statusColor = const Color(0xFF22C55E);
        statusBg = const Color(0xFF22C55E);
        statusIcon = Icons.check_circle_outline_rounded;
        break;
      default:
        statusColor = const Color(0xFF64748B);
        statusBg = const Color(0xFF64748B);
        statusIcon = Icons.help_outline_rounded;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: statusColor.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.06),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                Icon(statusIcon, color: statusColor, size: 17),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    inspection['name'] ?? 'Unknown Equipment',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.1,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 9,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: statusBg.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: statusBg.withOpacity(0.35),
                      width: 1,
                    ),
                  ),
                  child: Text(
                    status,
                    style: TextStyle(
                      fontSize: 11,
                      color: statusColor,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
            child: Column(
              children: [
                _detailRow(
                  icon: Icons.location_on_rounded,
                  iconColor: const Color(0xFF3B82F6),
                  label: 'Location',
                  value:
                      '${inspection['area_name'] ?? 'N/A'}  ·  ${inspection['location_name'] ?? 'N/A'}',
                ),
                const SizedBox(height: 8),
                _detailRow(
                  icon: Icons.repeat_rounded,
                  iconColor: const Color(0xFFA78BFA),
                  label: 'Frequency',
                  value: inspection['frequency'] ?? 'N/A',
                ),
                const SizedBox(height: 8),
                const Divider(
                  color: Color(0xFF334155),
                  height: 1,
                  thickness: 1,
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: _dateBadge(
                        label: 'Last Inspection',
                        value: inspection['last_inspection']
                                ?.toString()
                                .split(' ')[0] ??
                            'N/A',
                        icon: Icons.history_rounded,
                        color: const Color(0xFF64748B),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _dateBadge(
                        label: 'Due Date',
                        value: inspection['deadline_date'] ?? 'N/A',
                        icon: Icons.event_rounded,
                        color: statusColor,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _detailRow({
    required IconData icon,
    required Color iconColor,
    required String label,
    required String value,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 15, color: iconColor),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: const TextStyle(
            fontSize: 12,
            color: Color(0xFF64748B),
            fontWeight: FontWeight.w500,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFFCBD5E1),
              fontWeight: FontWeight.w500,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _dateBadge({
    required String label,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 12, color: color),
              const SizedBox(width: 5),
              Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  color: color.withOpacity(0.8),
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 12,
              color: color,
              fontWeight: FontWeight.w700,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  void _showError(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), duration: const Duration(seconds: 3)),
    );
    Navigator.pop(context);
  }

  Future<void> _handleModeToggle(BuildContext context, bool goOffline) async {
    final mode = Provider.of<AppModeProvider>(context, listen: false);

    if (goOffline) {
      final selection = await showAreaLocationDialog(context);
      if (selection == null) return;

      mode.startFetchingEquipment(
        areaId: selection['areaId']!,
        areaName: selection['areaName']!,
        locationId: selection['locationId'],
        locationName: selection['locationName'],
      );

      final equipment =
          await OfflineEquipmentService.fetchEquipmentForOfflineCache(
        areaId: selection['areaId']!,
        locationId: selection['locationId'],
      );

      if (equipment.isEmpty) {
        mode.failFetch('No equipment found for this area.');
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No equipment found for this area.')),
          );
        }
        return;
      }

      try {
        await EquipmentRepository.instance.refreshCache(
          equipment,
          onProgress: (done, total) {
            if (total > 0) mode.updateFetchProgress(done / total);
          },
        );
        await mode.completeFetchSuccess();
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('You are now on Offline Mode')),
          );
        }
      } catch (e) {
        mode.failFetch('Failed to save equipment locally.');
      }
    } else {
      await _runManualSync(context, mode);
    }
  }

  Future<void> _runManualSync(
      BuildContext context, AppModeProvider mode) async {
    final repository = InspectionRepository.instance;

    final hasInternet = await InternetConnectionChecker().hasConnection;
    if (!hasInternet) {
      await mode.completeSyncPartial(
          'No internet connection. Try again when online.');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text(
                  'No internet connection. Your inspections are still saved and pending.')),
        );
      }
      return;
    }

    final pending = await repository.getPendingInspections();

    if (pending.isEmpty) {
      await mode.completeSyncSuccess();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('You are back to Online Mode')),
        );
      }
      return;
    }

    mode.startSyncing(pending.length);

    int succeeded = 0;
    int stillPending = 0;

    for (final inspection in pending) {
      try {
        final checklistItems = Map<String, String>.from(
          jsonDecode(inspection['checklist_json'] as String) as Map,
        );
        final imageFile = File(inspection['image_path'] as String);

        if (!await imageFile.exists()) {
          await repository.markFailed(
              inspection['local_id'] as String, 'Image file missing');
          stillPending++;
        } else {
          File? certFile;
          final certPath = inspection['certificate_path'] as String?;
          if (certPath != null && certPath.isNotEmpty) {
            final f = File(certPath);
            if (await f.exists()) certFile = f;
          }

          final result = await EquipmentService.saveCheckList(
            equipmentData: {
              'equipment_id': inspection['equipment_id'],
              'checklist_id': inspection['checklist_id'],
              'area': inspection['area'],
              'location_id': inspection['location_id'],
              'location_description': inspection['location_description'],
              'location': inspection['location_name'],
              'equipment_name': inspection['equipment_name'],
            },
            imageFile: imageFile,
            certificateFile: certFile,
            reportId: inspection['report_id'].toString(),
            inspectorId: inspection['inspector_id'] as int,
            inspectorName: inspection['inspector_name'].toString(),
            issuanceDate: inspection['issuance_date']?.toString() ?? '',
            expiryDate: inspection['expiry_date']?.toString() ?? '',
            checklistItems: checklistItems,
            notes: inspection['notes']?.toString(),
          );

          if (result['statusCode'] == 200) {
            await repository.deleteAfterSync(
              inspection['local_id'] as String,
              imagePath: inspection['image_path'] as String?,
              certificatePath: inspection['certificate_path'] as String?,
            );
            succeeded++;
          } else {
            await repository.markFailed(
                inspection['local_id'] as String, result['body'].toString());
            stillPending++;
          }
        }
      } catch (e) {
        await repository.markFailed(
            inspection['local_id'] as String, e.toString());
        stillPending++;
      }
      mode.updateSyncProgress(succeeded + stillPending);
    }

    if (stillPending > 0) {
      await mode
          .completeSyncPartial('$succeeded synced, $stillPending will retry.');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  'Synced $succeeded items. $stillPending pending retry.')),
        );
      }
    } else {
      await mode.completeSyncSuccess();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  'All $succeeded items synced! You are back to Online Mode.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Stack(children: [
          SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 40, bottom: 30),
                  child: Image.asset("assets/icon/logo.png",
                      width: 100, height: 100),
                ),

                // ─── NEW INSPECTION ───────────────────────────────────
                Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: ArgonButton(
                    width: MediaQuery.of(context).size.width,
                    height: 50,
                    borderRadius: 8.0,
                    elevation: 10,
                    color: Colors.black,
                    borderSide: const BorderSide(color: Colors.teal),
                    child: Text(
                      AppLocalizations.of(context)!.translate('NEW INSPECTION'),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    onTap: (startLoading, stopLoading, btnState) async {
                      bool isNavigated = false;

                      Alert(
                        context: context,
                        title: "Scan QR Code",
                        content: SizedBox(
                          height: 400,
                          width: 300,
                          child: MobileScanner(
                            controller:
                                controller, // Pass the controller to the MobileScanner
                            onDetect: (BarcodeCapture barcodeCapture) async {
                              if (isNavigated) return;
                              isNavigated = true;

                              final String? code =
                                  barcodeCapture.barcodes.first.rawValue;
                              print('Raw QR Code Data: $code');

                              if (code != null && code.trim().startsWith('{')) {
                                try {
                                  final decodedData = json.decode(code);

                                  if (decodedData is Map) {
                                    final mode = Provider.of<AppModeProvider>(
                                        context,
                                        listen: false);
                                    final reportId =
                                        decodedData["report_id"]?.toString();
                                    Map<String, dynamic>? prefetchedData;

                                    if (mode.isOfflineMode) {
                                      if (reportId == null ||
                                          reportId.isEmpty) {
                                        Navigator.pop(context);
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          const SnackBar(
                                              content: Text(
                                                  'Invalid QR code data.')),
                                        );
                                        return;
                                      }

                                      prefetchedData = await EquipmentRepository
                                          .instance
                                          .lookupByReportId(reportId);

                                      if (!mounted) return;

                                      if (prefetchedData == null) {
                                        Navigator.pop(context);
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          const SnackBar(
                                              content: Text(
                                                  'This equipment is not available in offline data.')),
                                        );
                                        return;
                                      }
                                    }

                                    Widget screen = NewInspection(
                                      data: decodedData,
                                      id: widget.id,
                                      name: widget.name,
                                      branch: widget.branch,
                                      company: widget.company,
                                      email: widget.email,
                                      image: widget.image,
                                      contact: widget.contact,
                                      isOfflineMode: mode.isOfflineMode,
                                      prefetchedEquipmentData: prefetchedData,
                                    );

                                    if (!mode.isOfflineMode)
                                      screen = NetworkWrapper(child: screen);

                                    Navigator.pop(context);
                                    Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                            builder: (context) => screen));
                                  } else {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content:
                                            Text('Unexpected QR code format.'),
                                        duration: Duration(seconds: 3),
                                      ),
                                    );
                                  }
                                } catch (e) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                          'Failed to decode QR code data.'),
                                      duration: Duration(seconds: 3),
                                    ),
                                  );
                                }
                              } else {
                                print("Invalid QR code format.");
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Ensure QR code is scanned under optimal conditions.',
                                    ),
                                    duration: Duration(seconds: 5),
                                  ),
                                );
                              }
                            },
                          ),
                        ),
                        buttons: [
                          DialogButton(
                            onPressed: () => Navigator.pop(context),
                            color: Colors.red,
                            child: const Text(
                              "Cancel",
                              style:
                                  TextStyle(color: Colors.white, fontSize: 18),
                            ),
                          ),
                        ],
                      ).show();
                    },
                  ),
                ),

                // ─── EQUIPMENT INFO ───────────────────────────────────
                Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: ArgonButton(
                    width: MediaQuery.of(context).size.width,
                    height: 50,
                    borderRadius: 8.0,
                    elevation: 10,
                    color: Colors.black,
                    borderSide: const BorderSide(color: Colors.teal),
                    child: Text(
                      AppLocalizations.of(context)!.translate('EQUIPMENT INFO'),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    onTap: (startLoading, stopLoading, btnState) async {
                      Alert(
                        context: context,
                        title: "Scan QR Code",
                        content: SizedBox(
                          height: 400,
                          width: 300,
                          child: MobileScanner(
                            controller:
                                controller, // Pass the controller to the MobileScanner
                            onDetect: (BarcodeCapture barcodeCapture) {
                              final String? code =
                                  barcodeCapture.barcodes.first.rawValue;
                              print('Raw QR Code Data: $code');

                              if (code != null && code.trim().startsWith('{')) {
                                try {
                                  final decodedData = json.decode(code);

                                  if (decodedData is Map) {
                                    Navigator.pop(context);
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => NetworkWrapper(
                                          child: EquipementInfo(
                                            data: decodedData,
                                          ),
                                        ),
                                      ),
                                    );
                                  } else {
                                    _showError(
                                        context, 'Unexpected QR code format.');
                                  }
                                } catch (e) {
                                  _showError(context,
                                      'Failed to decode QR code data.');
                                }
                              } else {
                                _showError(context, 'Invalid QR code format.');
                              }
                            },
                          ),
                        ),
                        buttons: [
                          DialogButton(
                            onPressed: () => Navigator.pop(context),
                            color: Colors.red,
                            child: const Text(
                              "Cancel",
                              style:
                                  TextStyle(color: Colors.white, fontSize: 18),
                            ),
                          ),
                        ],
                      ).show();
                    },
                  ),
                ),

                // ─── COMPLAINTS ───────────────────────────────────
                Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: ArgonButton(
                    width: MediaQuery.of(context).size.width,
                    height: 50,
                    borderRadius: 8.0,
                    elevation: 10,
                    color: Colors.black,
                    borderSide: const BorderSide(color: Colors.teal),
                    child: Text(
                      AppLocalizations.of(context)!.translate('COMPLAINTS'),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    onTap: (startLoading, stopLoading, btnState) async {
                      bool isNavigated = false;

                      Alert(
                        context: context,
                        title: "Scan QR Code",
                        content: SizedBox(
                          height: 400,
                          width: 300,
                          child: MobileScanner(
                            controller: controller,
                            onDetect: (BarcodeCapture barcodeCapture) {
                              if (isNavigated) return;
                              isNavigated = true;

                              final String? code =
                                  barcodeCapture.barcodes.first.rawValue;

                              if (code != null && code.trim().startsWith('{')) {
                                try {
                                  final decodedData = json.decode(code);

                                  if (decodedData is Map) {
                                    Navigator.pop(context);
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => NetworkWrapper(
                                          child: ComplaintsScreen(
                                            data: decodedData,
                                          ),
                                        ),
                                      ),
                                    );
                                  } else {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content:
                                            Text('Unexpected QR code format.'),
                                        duration: Duration(seconds: 3),
                                      ),
                                    );
                                  }
                                } catch (e) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                          'Failed to decode QR code data.'),
                                      duration: Duration(seconds: 3),
                                    ),
                                  );
                                }
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Ensure QR code is scanned under optimal conditions.',
                                    ),
                                    duration: Duration(seconds: 5),
                                  ),
                                );
                              }
                            },
                          ),
                        ),
                        buttons: [
                          DialogButton(
                            onPressed: () => Navigator.pop(context),
                            color: Colors.red,
                            child: const Text(
                              "Cancel",
                              style:
                                  TextStyle(color: Colors.white, fontSize: 18),
                            ),
                          ),
                        ],
                      ).show();
                    },
                  ),
                ),

                // ─── UPCOMING INSPECTION ──────────────────────────────
                Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: ArgonButton(
                    width: MediaQuery.of(context).size.width,
                    height: 50,
                    borderRadius: 8.0,
                    elevation: 10,
                    color: Colors.black,
                    borderSide: const BorderSide(color: Colors.teal),
                    child: Text(
                      AppLocalizations.of(context)!
                          .translate('UPCOMING INSPECTION'),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    onTap: (startLoading, stopLoading, btnState) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => NetworkWrapper(
                            child: ChangeNotifierProvider(
                              create: (_) => UpcomingInspectionProvider(),
                              child: UpcomingInspectionScreen(
                                userId: widget.id,
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),

                // ─── MY RECORD ────────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: ArgonButton(
                    width: MediaQuery.of(context).size.width,
                    height: 50,
                    borderRadius: 8.0,
                    elevation: 10,
                    color: Colors.black,
                    borderSide: const BorderSide(color: Colors.teal),
                    child: Text(
                      AppLocalizations.of(context)!.translate('MY RECORD'),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    onTap: (startLoading, stopLoading, btnState) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              NetworkWrapper(child: MyRecords(id: widget.id)),
                        ),
                      );
                    },
                  ),
                ),

                // ─── MY ACCOUNT ───────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: ArgonButton(
                    width: MediaQuery.of(context).size.width,
                    height: 50,
                    borderRadius: 8.0,
                    elevation: 10,
                    color: Colors.black,
                    borderSide: const BorderSide(color: Colors.teal),
                    child: Text(
                      AppLocalizations.of(context)!.translate('MY ACCOUNT'),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    onTap: (startLoading, stopLoading, btnState) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => NetworkWrapper(
                            child: Profile(
                              id: widget.id,
                              name: widget.name,
                              company: widget.company,
                              branch: widget.branch,
                              email: widget.email,
                              // password: widget.password,
                              image: widget.image,
                              contact: widget.contact,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),

                // ─── LOGOUT ───────────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: ArgonButton(
                    width: MediaQuery.of(context).size.width,
                    height: 50,
                    borderRadius: 8.0,
                    elevation: 10,
                    color: Colors.black,
                    borderSide: const BorderSide(color: Colors.teal),
                    child: Text(
                      AppLocalizations.of(context)!.translate('LOGOUT'),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    onTap: (startLoading, stopLoading, btnState) async {
                      startLoading();
                      await AuthService.logout();
                      stopLoading();
                      if (context.mounted) {
                        Navigator.pushAndRemoveUntil(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const LoginScreen()),
                          (route) => false,
                        );
                      }
                    },
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            top: 8,
            right: 8,
            child: Consumer<AppModeProvider>(
              builder: (context, mode, _) {
                final isOffline = mode.isOfflineMode;
                final color = isOffline
                    ? const Color(0xFFF59E0B)
                    : const Color(0xff0DC5B9);

                return GestureDetector(
                  onTap: mode.isBusy
                      ? null
                      : () => _handleModeToggle(context, !isOffline),
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: color.withOpacity(0.3)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          isOffline
                              ? Icons.wifi_off_rounded
                              : Icons.wifi_rounded,
                          size: 13,
                          color: color,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          isOffline
                              ? 'Offline'
                              : 'Online',
                          style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: color),
                        ),
                        const SizedBox(width: 4),
                        Icon(
                          isOffline
                              ? Icons.toggle_off_outlined
                              : Icons.toggle_on_outlined,
                          size: 19,
                          color: const Color(0xff0DC5B9),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ]),
      ),
    );
  }

  @override
  void dispose() {
    _subscription?.cancel();
    controller.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// ✅ ALARM POPUP WIDGET
// ══════════════════════════════════════════════════════════════════════════════

class _AlarmPopup extends StatelessWidget {
  final Future<Map<String, dynamic>?> Function() fetchPendingInspections;
  final VoidCallback onClose;
  final Widget Function(Map<String, dynamic>, int) buildCard;

  const _AlarmPopup({
    required this.fetchPendingInspections,
    required this.onClose,
    required this.buildCard,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.85,
        ),
        decoration: BoxDecoration(
          color: const Color(0xFF0F172A),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFF1E293B), width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.5),
              blurRadius: 30,
              spreadRadius: 5,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ─── Header ───────────────────────────────────────────
            Container(
              padding: const EdgeInsets.fromLTRB(20, 22, 20, 18),
              decoration: const BoxDecoration(
                color: Color(0xFF1E293B),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              child: Column(
                children: [
                  Image.asset(
                    'assets/alarm_light.gif',
                    width: 90,
                    height: 90,
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEF4444).withOpacity(0.15),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.pending_actions_rounded,
                          color: Color(0xFFEF4444),
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Pending Inspections',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 17,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.3,
                              ),
                            ),
                            SizedBox(height: 2),
                            Text(
                              'Action required',
                              style: TextStyle(
                                color: Color(0xFF94A3B8),
                                fontSize: 12,
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                          ],
                        ),
                      ),
                      GestureDetector(
                        onTap: onClose,
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: const Color(0xFF334155),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.close_rounded,
                            color: Color(0xFF94A3B8),
                            size: 18,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // ─── Content ──────────────────────────────────────────
            Flexible(
              child: FutureBuilder<Map<String, dynamic>?>(
                future: fetchPendingInspections(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(vertical: 50),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CircularProgressIndicator(
                            color: Color(0xFF3B82F6),
                            strokeWidth: 2.5,
                          ),
                          SizedBox(height: 16),
                          Text(
                            'Fetching inspections...',
                            style: TextStyle(
                              color: Color(0xFF64748B),
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  if (snapshot.hasError || !snapshot.hasData) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(vertical: 40),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.wifi_off_rounded,
                            color: Color(0xFF475569),
                            size: 40,
                          ),
                          SizedBox(height: 12),
                          Text(
                            'Could not load inspections',
                            style: TextStyle(
                              color: Color(0xFF64748B),
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  final data = snapshot.data!;
                  final inspections = data['data'] ?? [];
                  final count = data['count'] ?? 0;

                  if (inspections.isEmpty) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 40),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: const Color(0xFF22C55E).withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.check_circle_outline_rounded,
                              color: Color(0xFF22C55E),
                              size: 36,
                            ),
                          ),
                          const SizedBox(height: 14),
                          const Text(
                            'All caught up!',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'No pending inspections found.',
                            style: TextStyle(
                              color: Color(0xFF64748B),
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  return SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 10),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEF4444).withOpacity(0.08),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: const Color(0xFFEF4444).withOpacity(0.25),
                            ),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.info_outline_rounded,
                                color: Color(0xFFEF4444),
                                size: 16,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '$count inspection${count == 1 ? '' : 's'} require your attention',
                                style: const TextStyle(
                                  color: Color(0xFFEF4444),
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 14),
                        ...List.generate(
                          inspections.length,
                          (index) => buildCard(inspections[index], index),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),

            // ─── Footer ───────────────────────────────────────────
            Container(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              decoration: const BoxDecoration(
                color: Color(0xFF1E293B),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(20),
                  bottomRight: Radius.circular(20),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextButton(
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        backgroundColor: const Color(0xFF334155),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      onPressed: onClose,
                      child: const Text(
                        'Dismiss',
                        style: TextStyle(
                          color: Color(0xFF94A3B8),
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
