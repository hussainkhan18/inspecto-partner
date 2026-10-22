import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:inspecto_shield_partner/Screens/widgets/compliance_image.dart';
import 'package:inspecto_shield_partner/models/compliance_models.dart';
import 'package:inspecto_shield_partner/services/area_photo_stamper.dart';
import 'package:inspecto_shield_partner/services/compliance_service.dart';
import 'package:lottie/lottie.dart';

class ComplianceInspectionScreen extends StatefulWidget {
  final ComplianceEquipment equipment;
  final List<ComplianceChecklistItem> checklist;
  final int? areaId;

  const ComplianceInspectionScreen({
    super.key,
    required this.equipment,
    required this.checklist,
    this.areaId,
  });

  @override
  State<ComplianceInspectionScreen> createState() =>
      _ComplianceInspectionScreenState();
}

class _ComplianceInspectionScreenState
    extends State<ComplianceInspectionScreen> {
  static const Color _teal = Color(0xff0DC5B9);
  static const Color _green = Color(0xFF22C55E);
  static const Color _red = Color(0xFFEF4444);

  final Map<int, String> _answers = {};
  final Map<int, TextEditingController> _textControllers = {};
  final TextEditingController _notesController = TextEditingController();

  File? _proofImage;
  bool _isSubmitting = false;
  bool _isPickingImage = false;

  @override
  void dispose() {
    _notesController.dispose();
    for (final controller in _textControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _pickImage() async {
    if (_isPickingImage) return;
    setState(() => _isPickingImage = true);

    try {
      final picked = await ImagePicker().pickImage(
        source: ImageSource.camera,
        imageQuality: 20,
        maxHeight: 800,
        maxWidth: 800,
      );

      if (picked == null) return;

      final stampedFile = await AreaPhotoStamper.stamp(
        File(picked.path),
        widget.equipment.area ?? '',
      );

      if (!mounted) return;
      setState(() => _proofImage = stampedFile);
    } catch (e) {
      debugPrint('Could not capture proof image: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not open camera. Please try again.'),
        ),
      );
    } finally {
      if (mounted) setState(() => _isPickingImage = false);
    }
  }

  bool _validate() {
    if (_proofImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please upload a proof image first.')),
      );
      return false;
    }

    for (final item in widget.checklist) {
      final answer = _answers[item.id];
      if (answer == null || answer.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content:
                  Text('Please answer all checklist items before saving.')),
        );
        return false;
      }
    }
    return true;
  }

  Future<void> _submit(String overallStatus) async {
    if (_isSubmitting) return;
    if (!_validate()) return;

    setState(() => _isSubmitting = true);

    try {
      await ComplianceService.submitInspection(
        equipmentId: widget.equipment.id,
        areaId: widget.areaId,
        overallStatus: overallStatus,
        checklistAnswers: _answers,
        proofImage: _proofImage!,
        notes: _notesController.text,
      );

      if (!mounted) return;
      await _showSuccessDialog(overallStatus);
      if (!mounted) return;
      Navigator.of(context).pop(overallStatus);
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

  Future<void> _showSuccessDialog(String overallStatus) {
    final isCompliant = overallStatus == 'completed';
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                height: 130,
                child: Lottie.asset('assets/animations/success.json',
                    repeat: false),
              ),
              const SizedBox(height: 8),
              Text(
                isCompliant ? 'Marked as Compliant' : 'Marked as Non-Compliant',
                textAlign: TextAlign.center,
                style:
                    const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(
                widget.equipment.name,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
              ),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _teal,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                  child: const Text('Done'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final eq = widget.equipment;

    return Scaffold(
      backgroundColor: const Color(0xffF5F6FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: _isSubmitting ? null : () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'COMPLIANCE INSPECTION',
          style: TextStyle(
              fontSize: 15, fontWeight: FontWeight.w600, letterSpacing: 0.5),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Stack(
          children: [
            SingleChildScrollView(
              padding: const EdgeInsets.only(bottom: 100),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                      width: double.infinity,
                      margin: const EdgeInsets.all(16),
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
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: ComplianceImage(
                          imagePath: eq.imageUrl,
                          width: double.infinity,
                          height: MediaQuery.of(context).size.height * 0.22,
                          fit: BoxFit.contain,
                          placeholderBuilder: (context) => Container(
                            height: MediaQuery.of(context).size.height * 0.22,
                            color: const Color(0xffF0F0F0),
                            child: const Icon(Icons.image_not_supported,
                                color: Colors.grey, size: 48),
                          ),
                        ),
                      )),
                  _buildInfoCard(eq),
                  _buildChecklistCard(),
                  _buildProofImageCard(),
                  _buildNotesCard(),
                ],
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 12,
                      offset: const Offset(0, -3),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: _statusButton(
                        label: 'NON-COMPLIANT',
                        icon: Icons.cancel_rounded,
                        color: _red,
                        onTap: () => _submit('failed'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _statusButton(
                        label: 'COMPLIANT',
                        icon: Icons.check_circle_rounded,
                        color: _green,
                        onTap: () => _submit('completed'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (_isSubmitting)
              Positioned.fill(
                child: Container(
                  color: Colors.black.withOpacity(0.25),
                  child: const Center(
                    child: CircularProgressIndicator(color: Colors.white),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _statusButton({
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return SizedBox(
      height: 45,
      child: ElevatedButton.icon(
        onPressed: _isSubmitting ? null : onTap,
        icon: Icon(icon, size: 16),
        label: Text(
          label,
          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          disabledBackgroundColor: color.withOpacity(0.4),
          elevation: 2,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }

  Widget _buildInfoCard(ComplianceEquipment eq) {
    final fields = <List<String>>[
      ['EQUIPMENT NAME', eq.name],
      ['CATEGORY', eq.category],
      ['SUB CATEGORY', eq.subCategory],
      ['TYPE', eq.type],
      ['AREA', eq.area],
      ['LOCATION', eq.location],
      ['FREQUENCY', eq.inspectionFrequency],
      ['CERTIFICATE REQUIRED', eq.certificateRequired ? 'Yes' : 'No'],
      ['LAST INSPECTION', eq.lastInspectionDate ?? 'Not yet inspected'],
    ];

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 12,
              offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        children: List.generate(fields.length, (i) {
          final isLast = i == fields.length - 1;
          final value = fields[i][1].trim().isEmpty ? 'N/A' : fields[i][1];
          return Column(
            children: [
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: MediaQuery.of(context).size.width * 0.38,
                      child: Text(
                        fields[i][0],
                        style: const TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                          color: Color(0xff555555),
                          letterSpacing: 0.3,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        value,
                        style: const TextStyle(
                            fontSize: 14, color: Color(0xff1A1A2E)),
                      ),
                    ),
                  ],
                ),
              ),
              if (!isLast) const Divider(height: 1, indent: 16, endIndent: 16),
            ],
          );
        }),
      ),
    );
  }

  Widget _buildChecklistCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 12,
              offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Row(
              children: [
                Container(
                  width: 4,
                  height: 22,
                  decoration: BoxDecoration(
                    color: _teal,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(width: 10),
                const Text(
                  'Checklist',
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xff1A1A2E)),
                ),
                const Spacer(),
                Text(
                  '${_answers.length}/${widget.checklist.length}',
                  style: TextStyle(fontSize: 12.5, color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
          const Divider(height: 1, indent: 16, endIndent: 16),
          widget.checklist.isEmpty
              ? const Padding(
                  padding: EdgeInsets.all(32),
                  child: Center(
                    child: Text('No checklist items found for this equipment.',
                        style: TextStyle(color: Colors.grey)),
                  ),
                )
              : ListView.separated(
                  itemCount: widget.checklist.length,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  separatorBuilder: (_, __) =>
                      const Divider(height: 1, indent: 16, endIndent: 16),
                  itemBuilder: (context, index) {
                    final item = widget.checklist[index];
                    return Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      child: _ChecklistResponseTile(
                        index: index,
                        item: item,
                        selectedValue: _answers[item.id],
                        onSelect: (value) =>
                            setState(() => _answers[item.id] = value),
                        textController: item.responseType == 'text'
                            ? (_textControllers[item.id] ??=
                                TextEditingController(
                                    text: _answers[item.id] ?? ''))
                            : null,
                        onTextChanged: (value) {
                          if (value.trim().isEmpty) {
                            _answers.remove(item.id);
                          } else {
                            _answers[item.id] = value;
                          }
                          setState(() {});
                        },
                      ),
                    );
                  },
                ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildProofImageCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 12,
              offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 4,
                height: 22,
                decoration: BoxDecoration(
                    color: _teal, borderRadius: BorderRadius.circular(4)),
              ),
              const SizedBox(width: 10),
              const Text('Proof Image',
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xff1A1A2E))),
            ],
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            height: 46,
            child: ElevatedButton.icon(
              onPressed: _isPickingImage ? null : _pickImage,
              icon: _isPickingImage
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.camera_alt_outlined, size: 18),
              label: Text(
                _isPickingImage
                    ? 'Processing image...'
                    : (_proofImage == null
                        ? 'Upload Equipment Image'
                        : 'Retake Photo'),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: _teal,
                foregroundColor: Colors.white,
                disabledBackgroundColor: _teal.withOpacity(0.6),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ),
          if (_proofImage != null) ...[
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Image.file(
                _proofImage!,
                height: MediaQuery.of(context).size.height * 0.18,
                width: double.infinity,
                fit: BoxFit.contain,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildNotesCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 12,
              offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 4,
                height: 22,
                decoration: BoxDecoration(
                    color: _teal, borderRadius: BorderRadius.circular(4)),
              ),
              const SizedBox(width: 10),
              const Text('Remarks',
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xff1A1A2E))),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xffF0F0F0),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text('Optional',
                    style: TextStyle(fontSize: 11, color: Color(0xff888888))),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _notesController,
            maxLines: 3,
            minLines: 2,
            decoration: InputDecoration(
              hintText: 'Add remarks, especially for non-compliance...',
              hintStyle:
                  const TextStyle(color: Color(0xffAAAAAA), fontSize: 13),
              filled: true,
              fillColor: const Color(0xffF5F6FA),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: Color(0xffDDE1E7)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: Color(0xffDDE1E7)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: _teal, width: 1.5),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ChecklistResponseTile extends StatelessWidget {
  final int index;
  final ComplianceChecklistItem item;
  final String? selectedValue;
  final ValueChanged<String> onSelect;
  final TextEditingController? textController;
  final ValueChanged<String>? onTextChanged;

  const _ChecklistResponseTile({
    required this.index,
    required this.item,
    required this.selectedValue,
    required this.onSelect,
    this.textController,
    this.onTextChanged,
  });

  static const Color _accent = Color(0xff0DC5B9);
  static const Color _idle = Color(0xff777777);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${index + 1}.',
                style: const TextStyle(
                    fontSize: 14, fontWeight: FontWeight.w700, color: _accent)),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                item.question,
                style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xff1A1A2E)),
              ),
            ),
            if (item.isCritical)
              Container(
                margin: const EdgeInsets.only(left: 6),
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xff64748B).withOpacity(0.10),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text('CRITICAL',
                    style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        color: Color(0xff64748B))),
              ),
          ],
        ),
        const SizedBox(height: 8),
        _buildResponseInput(),
      ],
    );
  }

  Widget _buildResponseInput() {
    switch (item.responseType) {
      case 'text':
        return TextField(
          controller: textController,
          onChanged: onTextChanged,
          maxLines: 2,
          minLines: 1,
          style: const TextStyle(fontSize: 13.5),
          decoration: InputDecoration(
            hintText: 'Type your answer...',
            hintStyle: const TextStyle(color: Color(0xffAAAAAA), fontSize: 13),
            filled: true,
            fillColor: const Color(0xffF5F6FA),
            isDense: true,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xffDDE1E7)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xffDDE1E7)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: _accent, width: 1.5),
            ),
          ),
        );

      case 'pass_fail':
        return _optionRow(const [
          {'label': 'Pass', 'value': 'pass', 'icon': Icons.check_rounded},
          {'label': 'Fail', 'value': 'fail', 'icon': Icons.close_rounded},
          {
            'label': 'N/A',
            'value': 'na',
            'icon': Icons.remove_circle_outline_rounded
          },
        ]);

      case 'rating_1_5':
        return _ratingRow();

      case 'yes_no':
      default:
        return _optionRow(const [
          {'label': 'Yes', 'value': 'pass', 'icon': Icons.check_rounded},
          {'label': 'No', 'value': 'fail', 'icon': Icons.close_rounded},
          {
            'label': 'N/A',
            'value': 'na',
            'icon': Icons.remove_circle_outline_rounded
          },
        ]);
    }
  }

  Widget _ratingRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: List.generate(5, (i) {
        final value = (i + 1).toString();
        final isSelected = selectedValue == value;
        return GestureDetector(
          onTap: () => onSelect(value),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            width: 44,
            height: 44,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isSelected ? _accent : const Color(0xffF5F6FA),
              border: Border.all(
                color: isSelected ? _accent : const Color(0xffDDE1E7),
                width: 1.4,
              ),
            ),
            child: Text(
              value,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: isSelected ? Colors.white : _idle,
              ),
            ),
          ),
        );
      }),
    );
  }

  Widget _optionRow(List<Map<String, dynamic>> options) {
    return Row(
      children: options.map((opt) {
        final isSelected = selectedValue == opt['value'];
        return Expanded(
          child: GestureDetector(
            onTap: () => onSelect(opt['value'] as String),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(vertical: 9),
              decoration: BoxDecoration(
                color: isSelected
                    ? _accent.withOpacity(0.10)
                    : const Color(0xffF5F6FA),
                border: Border.all(
                  color: isSelected ? _accent : const Color(0xffDDE1E7),
                  width: isSelected ? 1.8 : 1.2,
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    opt['icon'] as IconData,
                    color: isSelected ? _accent : const Color(0xffBDBDBD),
                    size: 16,
                  ),
                  const SizedBox(width: 5),
                  Text(
                    opt['label'] as String,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight:
                          isSelected ? FontWeight.w700 : FontWeight.w500,
                      color: isSelected ? _accent : _idle,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
