import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:loading_icon_button/loading_icon_button.dart';
import 'package:provider/provider.dart';
import 'package:techno_shield/routes/app_routes.dart';
import 'package:techno_shield/view_models/staff_task_checklist.dart';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';
import '/helper/style.dart' as style;
import 'package:image/image.dart' as img;

class TechnitianChecklist extends StatefulWidget {
  final String equipmentID;
  final String caseNo;
  final String equipmentName;
  final String EquipmentArea;
  final String EquipmentLocation;
  final String failedChecklistKey;
  final String technician1;
  final String technician2;
  final int status;
  const TechnitianChecklist({
    super.key,
    required this.equipmentID,
    required this.caseNo,
    required this.equipmentName,
    required this.EquipmentArea,
    required this.EquipmentLocation,
    required this.failedChecklistKey,
    required this.technician1,
    required this.technician2,
    required this.status,
  });

  @override
  State<TechnitianChecklist> createState() => _TechnitianChecklistState();
}

class _TechnitianChecklistState extends State<TechnitianChecklist> {
  bool isVisible = false;

  // ─── VOICE RECORDING VARIABLES ───────────────────────
  final AudioRecorder _audioRecorder = AudioRecorder();
  bool _isRecording = false;
  String _recordingDuration = '00:00';
  int _recordingSeconds = 0;
  Timer? _recordingTimer;

  // ─── UNCHANGED: pickImage ────────────────────────────
  Future<void> pickImage(ImageSource source) async {
    final pickedFile = await ImagePicker().pickImage(
      source: source,
      imageQuality: 100,
    );

    if (pickedFile != null) {
      final imageFile = File(pickedFile.path);
      final originalImage = img.decodeImage(await imageFile.readAsBytes());
      if (originalImage != null) {
        final resizedImage = img.copyResize(
          originalImage,
          width: 500,
          height: 500,
        );
        await File(pickedFile.path).writeAsBytes(
          img.encodeJpg(resizedImage, quality: 85),
        );
        setState(() {
          isVisible = true;
        });
      }
    }
  }

  // ─── UNCHANGED: VOICE RECORDING METHODS ─────────────
  Future<void> _startRecording() async {
    try {
      final hasPermission = await _audioRecorder.hasPermission();
      if (!hasPermission) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Microphone permission denied')),
        );
        return;
      }
      final dir = await getTemporaryDirectory();
      final path =
          '${dir.path}/voice_${DateTime.now().millisecondsSinceEpoch}.wav';
      await _audioRecorder.start(
        const RecordConfig(encoder: AudioEncoder.wav),
        path: path,
      );
      setState(() {
        _isRecording = true;
        _recordingSeconds = 0;
        _recordingDuration = '00:00';
      });
      _startTimer();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  void _startTimer() {
    _recordingTimer?.cancel();
    _recordingTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted || !_isRecording) {
        _recordingTimer?.cancel();
        return;
      }
      setState(() {
        _recordingSeconds++;
        final m = (_recordingSeconds ~/ 60).toString().padLeft(2, '0');
        final s = (_recordingSeconds % 60).toString().padLeft(2, '0');
        _recordingDuration = '$m:$s';
      });
    });
  }

  Future<void> _stopRecording() async {
    try {
      final path = await _audioRecorder.stop();
      if (path != null && path.isNotEmpty) {
        final file = File(path);
        if (!mounted) return;
        Provider.of<ChecklistProvider>(context, listen: false)
            .setVoiceFile(file);
        setState(() => _isRecording = false);
      }
    } catch (e) {
      setState(() => _isRecording = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  void _deleteVoiceNote() {
    Provider.of<ChecklistProvider>(context, listen: false).clearVoiceFile();
    setState(() {
      _recordingSeconds = 0;
      _recordingDuration = '00:00';
    });
  }

  Future<void> _toggleRecording() async {
    if (_isRecording) {
      await _stopRecording();
    } else {
      await _startRecording();
    }
  }

  // ─── UNCHANGED: API CALL ─────────────────────────────
  Future<bool> postData(
    String status,
    File resolveImage,
    File? voiceFile,
  ) async {
    try {
      final request = http.MultipartRequest(
        'POST',
        Uri.parse(
            'https://inspecto-partner.stageserverofbss.com/api/submit_task'),
      );
      request.fields['company_equipment_id'] = widget.equipmentID;
      request.fields['case_no'] = widget.caseNo;
      request.fields['status'] = status == 'Resolved' ? '1' : '2';
      request.fields['note'] = noteController.text;
      request.files.add(
        await http.MultipartFile.fromPath('resolve_image', resolveImage.path),
      );
      if (voiceFile != null) {
        request.files.add(
          await http.MultipartFile.fromPath('voice', voiceFile.path),
        );
      }
      final response = await request.send();
      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Data posted successfully')),
        );
        return true;
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to post data')),
        );
        return false;
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('An error occurred: $e')),
      );
      return false;
    }
  }

  // ─── UNCHANGED: showPreviousTechnician ──────────────
  showPreviousTechnician(status, technician1) {
    if (status == 4) {
      return technician1;
    } else {
      return 'No Previous Technician';
    }
  }

  TextEditingController noteController = TextEditingController();

  // ─── UNCHANGED: dispose ──────────────────────────────
  @override
  void dispose() {
    _recordingTimer?.cancel();
    _audioRecorder.dispose();
    noteController.dispose();
    super.dispose();
  }

  // ─── DESIGN CONSTANTS ────────────────────────────────
  static const _teal = Color(0xff0DC5B9);
  static const _green = Colors.green;
  static const _red = Color(0xFFEF4444);
  static const _sectionGap = 14.0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        automaticallyImplyLeading: true,
        iconTheme: const IconThemeData(color: _teal),
        title: const Text('Checklist'),
        centerTitle: false,
        titleTextStyle: style.pageTitle(),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: const Color(0xFFEEEEEE), height: 1),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Consumer<ChecklistProvider>(
          builder: (context, checklistProvider, child) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ─── EQUIPMENT DETAILS CARD ──────────────
                _SectionCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _cardSectionTitle('Equipment Details'),
                      const SizedBox(height: 8),
                      _InfoRow(
                        label: 'Equipment Name',
                        value: widget.equipmentName,
                      ),
                      _InfoRow(
                        label: 'Area',
                        value: widget.EquipmentArea,
                      ),
                      _InfoRow(
                        label: 'Location',
                        value: widget.EquipmentLocation,
                      ),
                      _InfoRow(
                        label: 'Failed Checklist',
                        value: widget.failedChecklistKey,
                        valueColor: _red,
                      ),
                      _InfoRow(
                        label: 'Prev. Technician',
                        value: showPreviousTechnician(
                          widget.status,
                          widget.technician2,
                        ),
                        isLast: true,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: _sectionGap),

                // ─── POST WORK CHECKLIST ─────────────────
                _SectionCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _cardSectionTitle('Post Work Checklist'),
                      const SizedBox(height: 4),
                      const Text(
                        'Select the resolution status',
                        style: TextStyle(
                          fontSize: 12,
                          color: Color(0xFF9E9E9E),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: _StatusPill(
                              label: 'Resolved',
                              value: 'Resolved',
                              selected: checklistProvider.status,
                              activeColor: _green,
                              onTap: () =>
                                  checklistProvider.setStatus('Resolved'),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _StatusPill(
                              label: 'Not Resolved',
                              value: 'Not Resolved',
                              selected: checklistProvider.status,
                              activeColor: _red,
                              onTap: () =>
                                  checklistProvider.setStatus('Not Resolved'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: _sectionGap),

                // ─── NOTES ───────────────────────────────
                _SectionCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _cardSectionTitle('Notes'),
                      const SizedBox(height: 10),
                      TextField(
                        controller: noteController,
                        maxLines: 3,
                        style: const TextStyle(fontSize: 14),
                        decoration: InputDecoration(
                          hintText: 'Add a note about the work done...',
                          hintStyle: const TextStyle(
                            color: Color(0xFFBDBDBD),
                            fontSize: 14,
                          ),
                          filled: true,
                          fillColor: const Color(0xFFF9F9F9),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 12,
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderSide: const BorderSide(
                              color: _teal,
                              width: 1.5,
                            ),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderSide: const BorderSide(
                              color: Color(0xFFE0E0E0),
                              width: 1,
                            ),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: _sectionGap),

                // ─── VOICE NOTE ──────────────────────────
                _SectionCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          _cardSectionTitle('Voice Note'),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 7,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF0F0F0),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Text(
                              'Optional',
                              style: TextStyle(
                                fontSize: 11,
                                color: Color(0xFF9E9E9E),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      _buildVoiceNoteSection(checklistProvider),
                    ],
                  ),
                ),

                const SizedBox(height: _sectionGap),

                // ─── IMAGE UPLOAD ────────────────────────
                _SectionCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          _cardSectionTitle('Equipment Image'),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 7,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFF0F0),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Text(
                              'Required',
                              style: TextStyle(
                                fontSize: 11,
                                color: Color(0xFFE53935),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      checklistProvider.resolveImage == null
                          ? Container(
                              width: double.infinity,
                              height: 110,
                              decoration: BoxDecoration(
                                color: const Color(0xFFF9F9F9),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: const Color(0xFFE0E0E0),
                                  width: 1,
                                  style: BorderStyle.solid,
                                ),
                              ),
                              child: const Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.image_outlined,
                                    size: 30,
                                    color: Color(0xFFBDBDBD),
                                  ),
                                  SizedBox(height: 6),
                                  Text(
                                    'No image selected',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: Color(0xFFBDBDBD),
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: Image.file(
                                checklistProvider.resolveImage!,
                                height: 160,
                                width: double.infinity,
                                fit: BoxFit.cover,
                              ),
                            ),
                      const SizedBox(height: 12),
                      LayoutBuilder(
                        builder: (context, constraints) => ArgonButton(
                          width: constraints.maxWidth,
                          height: 46,
                          borderRadius: 10,
                          elevation: 0,
                          color: _teal,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: const [
                              Icon(
                                Icons.upload_rounded,
                                color: Colors.white,
                                size: 18,
                              ),
                              SizedBox(width: 8),
                              Text(
                                'Upload Image',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                          onTap: (startLoading, stopLoading, btnState) async {
                            final pickedFile = await ImagePicker().pickImage(
                              source: ImageSource.gallery,
                            );
                            if (pickedFile != null) {
                              checklistProvider.setResolveImage(
                                File(pickedFile.path),
                              );
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // ─── SUBMIT BUTTON ───────────────────────
                LayoutBuilder(
                  builder: (context, constraints) => ArgonButton(
                    width: constraints.maxWidth,
                    height: 52,
                    borderRadius: 12,
                    elevation: 0,
                    color: const Color(0xFF1A1A2E),
                    loader: Container(
                      padding: const EdgeInsets.all(10),
                      child: const CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        strokeWidth: 2,
                      ),
                    ),
                    onTap: (startLoading, stopLoading, btnState) async {
                      if (checklistProvider.status == null ||
                          checklistProvider.resolveImage == null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Please complete the form (Status & Image required)',
                            ),
                          ),
                        );
                        return;
                      }
                      startLoading();
                      final isSuccess = await postData(
                        checklistProvider.status!,
                        checklistProvider.resolveImage!,
                        checklistProvider.voiceFile,
                      );
                      stopLoading();
                      if (isSuccess) {
                        checklistProvider.reset();
                        Navigator.popAndPushNamed(
                          context,
                          AppRoutes.deliveryTabs,
                        );
                      }
                    },
                    child: const Text(
                      'Submit',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 24),
              ],
            );
          },
        ),
      ),
    );
  }

  // ─── HELPER: section title ───────────────────────────
  Widget _cardSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: Color(0xFF1A1A2E),
      ),
    );
  }

  // ─── VOICE NOTE UI (logic unchanged) ────────────────
  Widget _buildVoiceNoteSection(ChecklistProvider checklistProvider) {
    if (checklistProvider.voiceFile != null) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xff0DC5B9).withOpacity(0.06),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: const Color(0xff0DC5B9).withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: const Color(0xff0DC5B9).withOpacity(0.12),
                borderRadius: BorderRadius.circular(9),
              ),
              child: const Icon(
                Icons.mic_rounded,
                color: Color(0xff0DC5B9),
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Voice Note Recorded',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1A1A2E),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Duration: $_recordingDuration',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF9E9E9E),
                    ),
                  ),
                ],
              ),
            ),
            GestureDetector(
              onTap: _deleteVoiceNote,
              child: Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: const Color(0xFFEF4444).withOpacity(0.08),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.delete_outline_rounded,
                  color: Color(0xFFEF4444),
                  size: 18,
                ),
              ),
            ),
          ],
        ),
      );
    }

    // ─── Recording button (logic unchanged) ─────────────
    return GestureDetector(
      onTap: _toggleRecording,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 15),
        decoration: BoxDecoration(
          color: _isRecording
              ? const Color(0xFFEF4444).withOpacity(0.06)
              : const Color(0xff0DC5B9).withOpacity(0.05),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: _isRecording
                ? const Color(0xFFEF4444).withOpacity(0.35)
                : const Color(0xff0DC5B9).withOpacity(0.35),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _isRecording ? Icons.stop_circle_rounded : Icons.mic_rounded,
              color: _isRecording
                  ? const Color(0xFFEF4444)
                  : const Color(0xff0DC5B9),
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              _isRecording
                  ? 'Recording... $_recordingDuration  (Tap to Stop)'
                  : 'Tap to Record Voice Note',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: _isRecording
                    ? const Color(0xFFEF4444)
                    : const Color(0xff0DC5B9),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── UNCHANGED: showPickerDialog ─────────────────────
  void showPickerDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Select Image Source'),
          actions: <Widget>[
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                pickImage(ImageSource.camera);
              },
              child: const Text('Camera'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                pickImage(ImageSource.gallery);
              },
              child: const Text('Gallery'),
            ),
          ],
        );
      },
    );
  }
}

// ─── REUSABLE WIDGETS ─────────────────────────────────

class _SectionCard extends StatelessWidget {
  final Widget child;
  const _SectionCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: const Color(0xFFEEEEEE),
          width: 1,
        ),
      ),
      child: child,
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;
  final bool isLast;

  const _InfoRow({
    required this.label,
    required this.value,
    this.valueColor,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 9),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 4,
                child: Text(
                  label,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF9E9E9E),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 5,
                child: Text(
                  value,
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: valueColor ?? const Color(0xFF1A1A2E),
                  ),
                ),
              ),
            ],
          ),
        ),
        if (!isLast) const Divider(height: 1, color: Color(0xFFF0F0F0)),
      ],
    );
  }
}

class _StatusPill extends StatelessWidget {
  final String label;
  final String value;
  final String? selected;
  final Color activeColor;
  final VoidCallback onTap;

  const _StatusPill({
    required this.label,
    required this.value,
    required this.selected,
    required this.activeColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isActive = selected == value;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(vertical: 11),
        decoration: BoxDecoration(
          color: isActive ? activeColor.withOpacity(0.07) : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isActive
                ? activeColor.withOpacity(0.5)
                : const Color(0xFFE0E0E0),
            width: isActive ? 1.5 : 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isActive ? activeColor : const Color(0xFFE0E0E0),
              ),
            ),
            const SizedBox(width: 7),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isActive ? activeColor : const Color(0xFF9E9E9E),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
