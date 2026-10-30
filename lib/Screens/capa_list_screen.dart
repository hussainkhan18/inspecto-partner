import 'package:flutter/material.dart';
import 'package:inspecto_shield_partner/Screens/capa_complete_screen.dart';
import 'package:inspecto_shield_partner/models/capa_model.dart';
import 'package:inspecto_shield_partner/services/gemba_walk_service.dart';

class CapaListScreen extends StatefulWidget {
  const CapaListScreen({super.key});

  @override
  State<CapaListScreen> createState() => _CapaListScreenState();
}

class _CapaListScreenState extends State<CapaListScreen> {
  static const Color _teal = Color(0xff0DC5B9);
  static const Color _ink = Color(0xff0F172A);
  static const Color _muted = Color(0xff64748B);
  static const Color _bg = Color(0xffF8FAFC);
  static const Color _border = Color(0xffE2E8F0);

  final GembaWalkService _service = GembaWalkService();

     List<CapaModel> _capas = [];
  bool _isLoading = true;
  String? _errorMessage;
  int? _justUpdatedCapaId;

  @override
  void initState() {
    super.initState();
    _loadCapas();
  }

  Future<void> _loadCapas() async {
    if (mounted) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
    }

    try {
      final result = await _service.fetchCapas(scope: 'assigned');
      if (!mounted) return;

      if (result['success'] == true) {
        setState(() {
          _capas = (result['data'] as List).cast<CapaModel>();
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = result['message']?.toString() ??
              'Unable to load CAPAs. Please try again.';
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('loadCapas error: $e');
      if (!mounted) return;
      setState(() {
        _errorMessage =
            'Unable to load CAPAs. Please check your connection and try again.';
        _isLoading = false;
      });
    }
  }

  Future<void> _onCompleteCapa(CapaModel capa) async {
    final completed = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => CapaCompleteScreen(capa: capa),
      ),
    );

    if (!mounted) return;
    if (completed == true) {
      setState(() => _justUpdatedCapaId = capa.id);
      await _loadCapas();
    }
  }

  @override
  Widget build(BuildContext context) {
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
              'My CAPAs',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 17,
                letterSpacing: 0.2,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              _capas.isEmpty
                  ? 'Assigned to you'
                  : '${_capas.length} assigned to you',
              style: const TextStyle(
                fontSize: 13,
                color: Color.fromARGB(220, 255, 255, 255),
                fontWeight: FontWeight.normal,
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
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: _teal),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.wifi_off_rounded, size: 44, color: _muted),
              const SizedBox(height: 12),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 13, color: _muted),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loadCapas,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _teal,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    if (_capas.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.check_circle_outline_rounded,
              size: 50,
              color: _teal.withValues(alpha: 0.6),
            ),
            const SizedBox(height: 12),
            const Text(
              'All Caught Up!',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: _ink,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'No CAPAs assigned to you right now.',
              style: TextStyle(fontSize: 12.5, color: _muted),
            ),
          ],
        ),
      );
    }

    final items = [..._capas];
    items.sort((a, b) {
      if (a.id == _justUpdatedCapaId) return -1;
      if (b.id == _justUpdatedCapaId) return 1;

      if (a.isOverdue != b.isOverdue) return a.isOverdue ? -1 : 1;

      if (a.isCompleted != b.isCompleted) return a.isCompleted ? 1 : -1;

      final ad = a.dueDate ?? '9999-12-31';
      final bd = b.dueDate ?? '9999-12-31';
      return ad.compareTo(bd);
    });

    return RefreshIndicator(
      color: _teal,
      onRefresh: _loadCapas,
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (_, i) => _buildCapaCard(items[i]),
      ),
    );
  }

  bool _isNew(CapaModel capa) {
    if (capa.isCompleted) return false;
    final created = DateTime.tryParse(capa.createdAt);
    if (created == null) return false;
    return DateTime.now().difference(created).inHours < 24;
  }

  Widget _buildCapaCard(CapaModel capa) {
    final accent = _statusColor(capa.status);
    final dueText = capa.dueDate == null || capa.dueDate!.isEmpty
        ? 'No due date'
        : capa.dueDate!;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _border),
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(width: 4, color: accent),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xffF1F5F9),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            capa.capaNumber,
                            style: const TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w700,
                              color: _muted,
                              letterSpacing: 0.3,
                            ),
                          ),
                        ),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (_isNew(capa)) ...[
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 7,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: _teal.withOpacity(0.12),
                                  border: Border.all(
                                    color: _teal.withOpacity(0.4),
                                    width: 1.0,
                                  ),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: const Text(
                                  'NEW',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800,
                                    color: _teal,
                                    letterSpacing: 0.4,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 6),
                            ],
                            _statusChip(capa.statusLabel, capa.status),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      capa.checklistItemText,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: _ink,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      capa.description,
                      style: const TextStyle(
                        fontSize: 12,
                        color: _muted,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        const Icon(
                          Icons.location_on_outlined,
                          size: 13,
                          color: _muted,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            capa.location.isNotEmpty
                                ? '${capa.area} · ${capa.location}'
                                : capa.area,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 12,
                              color: _muted,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    const Divider(height: 1, color: Color(0xffF1F5F9)),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Icons.schedule,
                              size: 13,
                              color: _muted,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              dueText,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: capa.isOverdue
                                    ? Colors.red.shade700
                                    : _muted,
                              ),
                            ),
                          ],
                        ),
                        _buildActionButton(capa),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton(CapaModel capa) {
    if (capa.isOpen) {
      return ElevatedButton(
        onPressed: () => _onCompleteCapa(capa),
        style: ElevatedButton.styleFrom(
          backgroundColor: _teal,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 6,
          ),
          minimumSize: Size.zero,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        child: const Text(
          'Mark Complete',
          style: TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w600,
          ),
        ),
      );
    }

    if (capa.isPendingAssignment) {
      return const Text(
        'Waiting for admin',
        style: TextStyle(
          fontSize: 11.5,
          fontWeight: FontWeight.w600,
          color: _muted,
        ),
      );
    }

    if (capa.isCompleted) {
      return const Text(
        'Completed',
        style: TextStyle(
          fontSize: 11.5,
          fontWeight: FontWeight.w600,
          color: Color(0xff16A34A),
        ),
      );
    }

    return const SizedBox.shrink();
  }

  Widget _statusChip(String label, String status) {
    final color = _statusColor(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'open':
        return const Color(0xffEA580C);
      case 'pending_assignment':
        return _muted;
      case 'completed':
        return const Color(0xff16A34A);
      default:
        return _muted;
    }
  }
}
