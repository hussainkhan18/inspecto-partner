import 'dart:io';
import 'package:flutter/material.dart';
import 'package:inspecto_shield_partner/services/complaints_service.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';
import 'package:inspecto_shield_partner/services/equipment_service.dart';

class ComplaintsScreen extends StatefulWidget {
  final Map data;

  const ComplaintsScreen({super.key, required this.data});

  @override
  State<ComplaintsScreen> createState() => _ComplaintsScreenState();
}

class _ComplaintsScreenState extends State<ComplaintsScreen> {
  // ─── Colors ───────────────────────────────────────────────
  static const Color _teal = Color(0xff0DC5B9);

  // ─── Equipment Data ────────────────────────────────────────
  bool _isLoadingEquipment = true;
  Map<String, dynamic>? _equipmentData;

  // ─── Form State ────────────────────────────────────────────
  String _selectedPriority = 'medium';
  final TextEditingController _remarksController = TextEditingController();

  // ─── Images ────────────────────────────────────────────────
  final List<File> _selectedImages = [];
  final ImagePicker _imagePicker = ImagePicker();

  // ─── Voice Recording ───────────────────────────────────────
  final AudioRecorder _audioRecorder = AudioRecorder();
  bool _isRecording = false;
  File? _voiceNoteFile;
  String _recordingDuration = '00:00';
  int _recordingSeconds = 0;

  // ─── Submit ────────────────────────────────────────────────
  bool _isSubmitting = false;

  // ─── Priority Options ──────────────────────────────────────
  final List<Map<String, dynamic>> _priorities = [
    {'value': 'low', 'label': 'Low', 'color': const Color(0xFF22C55E)},
    {'value': 'medium', 'label': 'Medium', 'color': const Color(0xFFF59E0B)},
    {'value': 'high', 'label': 'High', 'color': const Color(0xFFEF4444)},
  ];

  @override
  void initState() {
    super.initState();
    _fetchEquipmentData();
  }

  @override
  void dispose() {
    _remarksController.dispose();
    _audioRecorder.dispose();
    super.dispose();
  }

  // ─── Fetch Equipment Info ──────────────────────────────────
  Future<void> _fetchEquipmentData() async {
    try {
      final reportId = widget.data["report_id"]?.toString() ?? '';
      final data = await EquipmentService.fetchEquipmentData(reportId);
      if (mounted) {
        setState(() {
          _equipmentData = data;
          _isLoadingEquipment = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingEquipment = false);
      }
    }
  }

  // ─── Pick Images ───────────────────────────────────────────
  Future<void> _pickImages(ImageSource source) async {
    try {
      if (source == ImageSource.gallery) {
        final List<XFile> picked = await _imagePicker.pickMultiImage();
        if (picked.isNotEmpty) {
          setState(() {
            _selectedImages.addAll(picked.map((x) => File(x.path)));
          });
        }
      } else {
        final XFile? picked =
            await _imagePicker.pickImage(source: ImageSource.camera);
        if (picked != null) {
          setState(() => _selectedImages.add(File(picked.path)));
        }
      }
    } catch (e) {
      _showSnackBar('Could not pick image. Please try again.', isError: true);
    }
  }

  void _removeImage(int index) {
    setState(() => _selectedImages.removeAt(index));
  }

  // ─── Image Source Bottom Sheet ─────────────────────────────
  void _showImageSourceSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: _teal.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.camera_alt_rounded, color: _teal),
                ),
                title: const Text('Take Photo',
                    style: TextStyle(fontWeight: FontWeight.w600)),
                subtitle: const Text('Open camera'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImages(ImageSource.camera);
                },
              ),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: _teal.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.photo_library_rounded, color: _teal),
                ),
                title: const Text('Choose from Gallery',
                    style: TextStyle(fontWeight: FontWeight.w600)),
                subtitle: const Text('Select multiple photos'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImages(ImageSource.gallery);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Voice Recording ───────────────────────────────────────
  Future<void> _toggleRecording() async {
    if (_isRecording) {
      await _stopRecording();
    } else {
      await _startRecording();
    }
  }

  Future<void> _startRecording() async {
    try {
      final hasPermission = await _audioRecorder.hasPermission();
      if (!hasPermission) {
        _showSnackBar('Microphone permission denied.', isError: true);
        return;
      }

      final dir = await getTemporaryDirectory();
      final path =
          '${dir.path}/voice_note_${DateTime.now().millisecondsSinceEpoch}.wav';

      await _audioRecorder.start(
        const RecordConfig(
          encoder: AudioEncoder.wav,
        ),
        path: path,
      );
      setState(() {
        _isRecording = true;
        _voiceNoteFile = null;
        _recordingSeconds = 0;
        _recordingDuration = '00:00';
      });

      _startTimer();
    } catch (e) {
      _showSnackBar('Could not start recording. Please try again.',
          isError: true);
    }
  }

  void _startTimer() {
    Future.doWhile(() async {
      await Future.delayed(const Duration(seconds: 1));
      if (!mounted || !_isRecording) return false;
      setState(() {
        _recordingSeconds++;
        final m = (_recordingSeconds ~/ 60).toString().padLeft(2, '0');
        final s = (_recordingSeconds % 60).toString().padLeft(2, '0');
        _recordingDuration = '$m:$s';
      });
      return _isRecording;
    });
  }

  Future<void> _stopRecording() async {
    try {
      final path = await _audioRecorder.stop();
      if (path != null) {
        setState(() {
          _isRecording = false;
          _voiceNoteFile = File(path);
        });
      }
    } catch (e) {
      setState(() => _isRecording = false);
      _showSnackBar('Recording stopped with an error.', isError: true);
    }
  }

  void _deleteVoiceNote() {
    setState(() {
      _voiceNoteFile = null;
      _recordingSeconds = 0;
      _recordingDuration = '00:00';
    });
  }

  // ─── Submit ────────────────────────────────────────────────
  Future<void> _submitComplaint() async {
    if (_isRecording) {
      _showSnackBar('Please stop recording before submitting.', isError: true);
      return;
    }

    setState(() => _isSubmitting = true);

    final companyEquipmentId =
        widget.data["company_equipment_id"]?.toString() ??
            widget.data["report_id"]?.toString() ??
            '';

    final result = await ComplaintService.submitComplaint(
      companyEquipmentId: companyEquipmentId,
      priority: _selectedPriority,
      remarks: _remarksController.text,
      images: _selectedImages.isNotEmpty ? _selectedImages : null,
      voiceNote: _voiceNoteFile,
    );

    if (!mounted) return;
    setState(() => _isSubmitting = false);

    if (result['success'] == true) {
      final complaintNumber = result['data']?['complaint_number'] ?? '';
      _showSuccessDialog(complaintNumber);
    } else {
      _showSnackBar(
        result['message'] ?? 'Something went wrong. Please try again.',
        isError: true,
      );
    }
  }

  // ─── Success Dialog ────────────────────────────────────────
  void _showSuccessDialog(String complaintNumber) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _teal.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check_circle_rounded,
                    color: _teal, size: 40),
              ),
              const SizedBox(height: 16),
              const Text(
                'Complaint Submitted!',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Color(0xff1A1A2E),
                ),
              ),
              if (complaintNumber.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  complaintNumber,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade500,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _teal,
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: () {
                    Navigator.pop(context); // close dialog
                    Navigator.pop(context); // go back to home
                  },
                  child: const Text(
                    'Done',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Snackbar ──────────────────────────────────────────────
  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? const Color(0xFFEF4444) : _teal,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════
  // BUILD
  // ══════════════════════════════════════════════════════════

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffF7F8FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: Color(0xff1A1A2E), size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Submit Complaint',
          style: TextStyle(
            color: Color(0xff1A1A2E),
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Divider(height: 1, color: Colors.grey.shade200),
        ),
      ),
      body: _isLoadingEquipment
          ? const Center(
              child: CircularProgressIndicator(
                color: _teal,
                strokeWidth: 2.5,
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ─── Equipment Info ──────────────────────
                  _buildEquipmentCard(),
                  const SizedBox(height: 16),

                  // ─── Priority ────────────────────────────
                  _buildSectionCard(
                    icon: Icons.flag_rounded,
                    title: 'Priority',
                    child: _buildPrioritySelector(),
                  ),
                  const SizedBox(height: 16),

                  // ─── Remarks ─────────────────────────────
                  _buildSectionCard(
                    icon: Icons.edit_note_rounded,
                    title: 'Remarks',
                    child: _buildRemarksField(),
                  ),
                  const SizedBox(height: 16),

                  // ─── Images ──────────────────────────────
                  _buildSectionCard(
                    icon: Icons.photo_library_rounded,
                    title: 'Images',
                    child: _buildImagesSection(),
                  ),
                  const SizedBox(height: 16),

                  // ─── Voice Note ──────────────────────────
                  _buildSectionCard(
                    icon: Icons.mic_rounded,
                    title: 'Voice Note',
                    child: _buildVoiceNoteSection(),
                  ),
                  const SizedBox(height: 28),

                  // ─── Submit ──────────────────────────────
                  _buildSubmitButton(),
                  const SizedBox(height: 24),
                ],
              ),
            ),
    );
  }

  // ─── Equipment Card ────────────────────────────────────────
  Widget _buildEquipmentCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.build_circle_rounded, color: _teal, size: 18),
              SizedBox(width: 8),
              Text(
                'Equipment Details',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: _teal,
                  letterSpacing: 0.2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Divider(height: 1, color: Colors.grey.shade100),
          const SizedBox(height: 12),

// Equipment Image
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Image.network(
              _equipmentData?['equipment_img'] ??
                  'https://hashbaqala.bssstageserverforpanels.xyz/upload/profileImage/user.png',
              height: 140,
              width: double.infinity,
              fit: BoxFit.contain,
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return const SizedBox(
                  height: 140,
                  child: Center(
                    child: CircularProgressIndicator(
                      color: _teal,
                      strokeWidth: 2,
                    ),
                  ),
                );
              },
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  height: 140,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Center(
                    child: Icon(Icons.image_not_supported_rounded,
                        color: Colors.grey, size: 40),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 12),
          Divider(height: 1, color: Colors.grey.shade100),
          const SizedBox(height: 12),
          _buildInfoRow('Equipment', _equipmentData?['equipment_name']),
          _buildInfoRow('Location', _equipmentData?['location_description']),
          _buildInfoRow('Category', _equipmentData?['equipment_sub_category']),
          _buildInfoRow(
              'Last Inspection', _equipmentData?['last_inspection_date']),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String? value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade500,
                letterSpacing: 0.3,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value ?? '—',
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: Color(0xff1A1A2E),
              ),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }

  // ─── Section Card Wrapper ──────────────────────────────────
  Widget _buildSectionCard({
    required IconData icon,
    required String title,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: _teal, size: 18),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: _teal,
                  letterSpacing: 0.2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }

  // ─── Priority Selector ─────────────────────────────────────
  Widget _buildPrioritySelector() {
    return Row(
      children: _priorities.map((p) {
        final isSelected = _selectedPriority == p['value'];
        final color = p['color'] as Color;
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: GestureDetector(
              onTap: () =>
                  setState(() => _selectedPriority = p['value'] as String),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: isSelected
                      ? color.withOpacity(0.12)
                      : Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isSelected ? color : Colors.grey.shade200,
                    width: isSelected ? 1.5 : 1,
                  ),
                ),
                child: Column(
                  children: [
                    Icon(
                      Icons.flag_rounded,
                      color: isSelected ? color : Colors.grey.shade400,
                      size: 20,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      p['label'] as String,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight:
                            isSelected ? FontWeight.w700 : FontWeight.w500,
                        color: isSelected ? color : Colors.grey.shade500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  // ─── Remarks Field ─────────────────────────────────────────
  Widget _buildRemarksField() {
    return TextField(
      controller: _remarksController,
      maxLines: 4,
      style: const TextStyle(fontSize: 14, color: Color(0xff1A1A2E)),
      decoration: InputDecoration(
        hintText: 'Describe the issue in detail...',
        hintStyle: TextStyle(fontSize: 14, color: Colors.grey.shade400),
        filled: true,
        fillColor: Colors.grey.shade50,
        contentPadding: const EdgeInsets.all(14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: _teal, width: 1.5),
        ),
      ),
    );
  }

  // ─── Images Section ────────────────────────────────────────
  Widget _buildImagesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: _showImageSourceSheet,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 14),
            decoration: BoxDecoration(
              color: _teal.withOpacity(0.05),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: _teal.withOpacity(0.3)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.add_photo_alternate_rounded,
                    color: _teal, size: 20),
                const SizedBox(width: 8),
                Text(
                  _selectedImages.isEmpty ? 'Add Images' : 'Add More Images',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: _teal,
                  ),
                ),
              ],
            ),
          ),
        ),
        if (_selectedImages.isNotEmpty) ...[
          const SizedBox(height: 12),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _selectedImages.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
            ),
            itemBuilder: (_, index) {
              return Stack(
                fit: StackFit.expand,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.file(
                      _selectedImages[index],
                      fit: BoxFit.cover,
                    ),
                  ),
                  Positioned(
                    top: 4,
                    right: 4,
                    child: GestureDetector(
                      onTap: () => _removeImage(index),
                      child: Container(
                        padding: const EdgeInsets.all(3),
                        decoration: const BoxDecoration(
                          color: Color(0xFFEF4444),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.close_rounded,
                            color: Colors.white, size: 12),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ],
    );
  }

  // ─── Voice Note Section ────────────────────────────────────
  Widget _buildVoiceNoteSection() {
    if (_voiceNoteFile != null) {
      return Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: _teal.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.mic_rounded, color: _teal, size: 22),
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
                    color: Color(0xff1A1A2E),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Duration: $_recordingDuration',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: _deleteVoiceNote,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFEF4444).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.delete_outline_rounded,
                  color: Color(0xFFEF4444), size: 18),
            ),
          ),
        ],
      );
    }

    return GestureDetector(
      onTap: _toggleRecording,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: _isRecording
              ? const Color(0xFFEF4444).withOpacity(0.06)
              : _teal.withOpacity(0.05),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: _isRecording
                ? const Color(0xFFEF4444).withOpacity(0.3)
                : _teal.withOpacity(0.3),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _isRecording ? Icons.stop_circle_rounded : Icons.mic_rounded,
              color: _isRecording ? const Color(0xFFEF4444) : _teal,
              size: 22,
            ),
            const SizedBox(width: 10),
            Text(
              _isRecording
                  ? 'Recording... $_recordingDuration  (Tap to Stop)'
                  : 'Tap to Record Voice Note',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: _isRecording ? const Color(0xFFEF4444) : _teal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Submit Button ─────────────────────────────────────────
  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: _teal,
          elevation: 4,
          shadowColor: _teal.withOpacity(0.3),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        onPressed: _isSubmitting ? null : _submitComplaint,
        child: _isSubmitting
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2.5,
                ),
              )
            : const Text(
                'Submit Complaint',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.3,
                ),
              ),
      ),
    );
  }
}
