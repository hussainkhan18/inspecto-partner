import 'dart:io';
import 'package:flutter/material.dart';
import 'package:inspecto_shield_partner/Providers/gemba_walk_provider.dart';
import 'package:inspecto_shield_partner/Screens/capa_form.dart';
import 'package:provider/provider.dart';

class GembaWalkDetailScreen extends StatefulWidget {
  final Map<String, dynamic> gembaData;
  final bool isAssigned;

  const GembaWalkDetailScreen({
    super.key,
    required this.gembaData,
    required this.isAssigned,
  });

  @override
  State<GembaWalkDetailScreen> createState() => _GembaWalkDetailScreenState();
}

class _GembaWalkDetailScreenState extends State<GembaWalkDetailScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<GembaWalkProvider>().initialize(
            gembaData: widget.gembaData,
            isAssigned: widget.isAssigned,
          );
    });
  }

  @override
  Widget build(BuildContext context) {
    return const _GembaWalkDetailView();
  }
}

class _GembaWalkDetailView extends StatelessWidget {
  const _GembaWalkDetailView();

  static const Color _teal = Color(0xff0DC5B9);
  static const Color _ink = Color(0xff1E293B);
  static const Color _muted = Color(0xff64748B);
  static const Color _bg = Color(0xffF8FAFC);
  static const Color _border = Color(0xffE2E8F0);

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<GembaWalkProvider>();
    final data = provider.gembaData;
    final gembaId = data['gemba']?.toString() ?? 'GW-00';
    final area = data['area']?.toString() ?? 'General Area';

    if (provider.isLoadingDetail) {
      return Scaffold(
        backgroundColor: _bg,
        appBar: AppBar(
          backgroundColor: _teal,
          foregroundColor: Colors.white,
          title: const Text('Gemba Walk',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new,
                color: Colors.white, size: 18),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: const Center(
          child: CircularProgressIndicator(color: _teal),
        ),
      );
    }

    if (provider.detailError != null) {
      return Scaffold(
        backgroundColor: _bg,
        appBar: AppBar(
          backgroundColor: _teal,
          foregroundColor: Colors.white,
          title: const Text('Gemba Walk',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
              leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new,
              color: Colors.white, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.wifi_off_rounded, size: 44, color: _muted),
                const SizedBox(height: 12),
                Text(
                  provider.detailError!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 13, color: _muted),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => provider.retryDetail(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _teal,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      );
    }

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
              'Gemba Walk',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
            ),
            const SizedBox(height: 4),
            Text(
              '$gembaId · $area',
              style: const TextStyle(
                  fontSize: 14,
                  color: Colors.white70,
                  fontWeight: FontWeight.w500),
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
          Column(
            children: [
              const SizedBox(height: 5),
              _buildProgressBar(provider),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHeaderCard(data),
                      const SizedBox(height: 20),
                      _buildSectionTitle('INSPECTION CHECKLIST'),
                      const SizedBox(height: 10),
                      _buildChecklist(context, provider),
                      const SizedBox(height: 24),
                      if (provider.canSubmit && !provider.isSubmitted)
                        _buildSubmitButton(context, provider),
                      const SizedBox(height: 10),
                      if (provider.canAddCapa ||
                          data['can_add_capa'] == true) ...[
                        _buildSectionTitle(
                            'CORRECTIVE & PREVENTIVE ACTIONS (CAPA)'),
                        const SizedBox(height: 13),
                        _buildCapaSection(context, provider),
                      ],
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ],
          ),
          if (provider.isCompressing)
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

  Widget _buildProgressBar(GembaWalkProvider provider) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${provider.completedCount} of ${provider.totalCount} completed',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: _muted,
                ),
              ),
              Text(
                '${(provider.progress * 100).toInt()}%',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: _teal,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: provider.progress,
              backgroundColor: Colors.grey.shade200,
              valueColor: const AlwaysStoppedAnimation<Color>(_teal),
              minHeight: 6,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderCard(Map<String, dynamic> data) {
    final String purpose = data['purpose']?.toString() ?? 'Gemba Walk';
    final dueDate = data['dueDate']?.toString() ?? 'Today';
    final totalPoints = data['totalPoints'] ?? 0;
    final notes = data['notes']?.toString() ?? '';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: _teal.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(_getPurposeIcon(purpose), color: _teal, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Walk Type:',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: _muted,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      purpose,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: _ink,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(height: 1, color: _border),
          const SizedBox(height: 10),
          Row(
            children: [
              const Icon(Icons.schedule, size: 14, color: _muted),
              const SizedBox(width: 5),
              Text(
                'Due: $dueDate · $totalPoints points',
                style: const TextStyle(
                  fontSize: 12.5,
                  color: _muted,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          if (notes.isNotEmpty) ...[
            const SizedBox(height: 10),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.notes_rounded, size: 14, color: _muted),
                const SizedBox(width: 5),
                Expanded(
                  child: Text(
                    notes,
                    style: const TextStyle(
                      fontSize: 12.5,
                      color: _muted,
                      fontWeight: FontWeight.w500,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildChecklist(BuildContext context, GembaWalkProvider provider) {
    return Column(
      children: provider.questions.map((q) {
        final qId = q['id'] as int;
        final status = provider.complianceStatus[qId] ?? 'pending';
        final isNonCompliant = status == 'non_compliance';
        final isCompliant = status == 'compliance';
        final images = provider.questionImages[qId] ?? [];
        final imageUrls = provider.questionImageUrls[qId] ?? [];
        final isSubmitted = provider.isSubmitted;

        return Container(
          margin: const EdgeInsets.only(bottom: 14),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: _border,
              width: isNonCompliant || isCompliant ? 1.5 : 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                q['question'] as String,
                style: const TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w600,
                  color: _ink,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildStatusToggle(
                      label: 'Compliant',
                      icon: Icons.check_circle_outline_rounded,
                      isSelected: isCompliant,
                      color: Colors.green.shade600,
                      enabled: !isSubmitted && !provider.isLocked,
                      onTap: () =>
                          provider.setComplianceStatus(qId, 'compliance'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildStatusToggle(
                      label: 'Non-Compliant',
                      icon: Icons.cancel_outlined,
                      isSelected: isNonCompliant,
                      color: Colors.red.shade600,
                      enabled: !provider.isLocked,
                      onTap: () =>
                          provider.setComplianceStatus(qId, 'non_compliance'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Divider(height: 1, color: _border),
              const SizedBox(height: 10),
              TextField(
                controller: provider.notesControllers[qId],
                enabled: !isSubmitted && !provider.isLocked,
                maxLines: 2,
                style: const TextStyle(fontSize: 13, color: _ink),
                decoration: InputDecoration(
                  hintText: 'Add notes / observations (optional)',
                  hintStyle: const TextStyle(fontSize: 12, color: _muted),
                  filled: true,
                  fillColor: _bg,
                  contentPadding: const EdgeInsets.all(10),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: _teal, width: 1.5),
                  ),
                  disabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Colors.grey.shade400),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              if (!isSubmitted)
                _buildImageRow(context, provider, qId, images)
              else if (imageUrls.isNotEmpty)
                _buildReadOnlyImages(context, imageUrls),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildImageRow(BuildContext context, GembaWalkProvider provider,
      int qId, List<File> images) {
    const int totalSlots = 3;
    final int emptySlots = totalSlots - images.length;

    return Row(
      children: [
        ...images.asMap().entries.map((entry) {
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
                    Positioned(
                      top: -6,
                      right: -6,
                      child: GestureDetector(
                        onTap: () => provider.removeImage(qId, entry.key),
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
        ...List.generate(emptySlots, (index) {
          final isFirstEmpty = index == 0;
          return Expanded(
            child: Padding(
              padding: EdgeInsets.only(
                right: index < emptySlots - 1 ? 6 : 0,
              ),
              child: AspectRatio(
                aspectRatio: 1,
                child: isFirstEmpty && !provider.isLocked
                    ? GestureDetector(
                        onTap: () => provider.pickImage(qId),
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
                                '${images.length}/3',
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

   Widget _buildReadOnlyImages(BuildContext context, List<String> urls) {
    const int totalSlots = 3;
    final int emptySlots = totalSlots - urls.length;

    return Row(
      children: [
        ...urls.asMap().entries.map((entry) {
          return Expanded(
            child: Padding(
              padding: const EdgeInsets.only(right: 6),
              child: AspectRatio(
                aspectRatio: 1,
                child: GestureDetector(
                  onTap: () => _showImageDialog(context, entry.value),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.network(
                      entry.value,
                      width: double.infinity,
                      height: double.infinity,
                      fit: BoxFit.cover,
                      loadingBuilder: (context, child, progress) {
                        if (progress == null) return child;
                        return Container(
                          color: _bg,
                          child: const Center(
                            child: SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: _teal,
                              ),
                            ),
                          ),
                        );
                      },
                      errorBuilder: (_, __, ___) => Container(
                        color: _bg,
                        child: const Icon(
                          Icons.broken_image_outlined,
                          color: _muted,
                          size: 24,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        }),
        ...List.generate(emptySlots, (index) {
          return Expanded(
            child: Padding(
              padding: EdgeInsets.only(
                right: index < emptySlots - 1 ? 6 : 0,
              ),
              child: AspectRatio(
                aspectRatio: 1,
                child: Container(
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

  void _showImageDialog(BuildContext context, String url) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.black,
        insetPadding: const EdgeInsets.all(12),
        child: Stack(
          children: [
            InteractiveViewer(
              child: Image.network(
                url,
                fit: BoxFit.contain,
                loadingBuilder: (context, child, progress) {
                  if (progress == null) return child;
                  return const Center(
                    child: CircularProgressIndicator(color: _teal),
                  );
                },
                errorBuilder: (_, __, ___) => const Center(
                  child: Icon(Icons.broken_image_outlined,
                      color: Colors.white, size: 40),
                ),
              ),
            ),
            Positioned(
              top: 8,
              right: 8,
              child: GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: const BoxDecoration(
                    color: Colors.white24,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.close, color: Colors.white, size: 20),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusToggle({
    required String label,
    required IconData icon,
    required bool isSelected,
    required Color color,
    required VoidCallback onTap,
    bool enabled = true,
  }) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? color.withValues(alpha: 0.12) : Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? color : _border,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Opacity(
          opacity: enabled ? 1.0 : 0.5,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 16, color: isSelected ? color : _muted),
              const SizedBox(width: 5),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: isSelected ? color : _muted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSubmitButton(BuildContext context, GembaWalkProvider provider) {
    final isSubmitting = provider.isSubmitting;

    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton.icon(
        onPressed: provider.isLocked
            ? null
            : () async {
                final result = await provider.submitWalk();
                if (!context.mounted) return;

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(result['message'] ?? ''),
                    backgroundColor:
                        result['success'] == true ? Colors.green : Colors.red,
                  ),
                );

                if (result['success'] == true) {
                  Navigator.pop(context, true);
                }
              },
        icon: isSubmitting
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
          isSubmitting ? 'SUBMITTING...' : 'SUBMIT GEMBA WALK',
          style: const TextStyle(
            fontSize: 13.5,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.5,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: _teal,
          foregroundColor: Colors.white,
          disabledBackgroundColor: Colors.grey.shade300,
          disabledForegroundColor: Colors.grey.shade600,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  Widget _buildCapaSection(BuildContext context, GembaWalkProvider provider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: double.infinity,
          height: 50,
          child: OutlinedButton.icon(
            onPressed: () => provider.toggleCapaForm(),
            icon: Icon(
              provider.showCapaForm
                  ? Icons.keyboard_arrow_up_rounded
                  : Icons.add_circle_outline_rounded,
              size: 20,
            ),
            label: Text(
              provider.showCapaForm ? 'HIDE CAPA FORM' : 'ADD CAPA',
              style: const TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5,
              ),
            ),
            style: OutlinedButton.styleFrom(
              foregroundColor: _teal,
              side: const BorderSide(color: _teal, width: 1.5),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
        if (provider.showCapaForm) ...[
          const SizedBox(height: 16),
          InlineCapaForm(
            gembaData: provider.gembaData,
            questions: provider.questions,
            nonCompliantIds: provider.nonCompliantIds,
          ),
        ],
      ],
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

  IconData _getPurposeIcon(String purpose) {
    final p = purpose.toLowerCase();
    if (p.contains('safety')) return Icons.health_and_safety_rounded;
    if (p.contains('fire')) return Icons.local_fire_department_rounded;
    if (p.contains('maintenance')) return Icons.build_rounded;
    if (p.contains('hvac')) return Icons.ac_unit_rounded;
    if (p.contains('asset')) return Icons.inventory_2_rounded;
    if (p.contains('quality') || p.contains('qa'))
      return Icons.fact_check_rounded;
    if (p.contains('employee')) return Icons.groups_rounded;
    return Icons.assignment_outlined;
  }
}
