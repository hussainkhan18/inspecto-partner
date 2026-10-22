import 'package:flutter/material.dart';
import 'package:inspecto_shield_partner/Providers/gemba_walk_provider.dart';
import 'package:inspecto_shield_partner/Screens/gemba_walk_detail_screen.dart';
import 'package:inspecto_shield_partner/services/gemba_walk_service.dart';
import 'package:inspecto_shield_partner/services/secure_storage_service.dart';
import 'package:provider/provider.dart';

class GembaWalkScreen extends StatefulWidget {
  const GembaWalkScreen({super.key});

  @override
  State<GembaWalkScreen> createState() => _GembaWalkScreenState();
}

class _GembaWalkScreenState extends State<GembaWalkScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  final GembaWalkService _service = GembaWalkService();

  List<Map<String, dynamic>> _assignedGembaData = [];

  bool _isLoading = true;
  String? _errorMessage;

  static const Color _teal = Color(0xff0DC5B9);
  static const Color _ink = Color(0xff1E293B);
  static const Color _muted = Color(0xff64748B);
  static const Color _bg = Color(0xffF8FAFC);

  IconData _purposeIcon(String purpose) {
    final p = purpose.toLowerCase();
    if (p.contains('safety')) return Icons.health_and_safety_rounded;
    if (p.contains('maintenance')) return Icons.build_rounded;
    if (p.contains('fire')) return Icons.local_fire_department_rounded;
    return Icons.assignment_outlined;
  }

  bool _isOverdue(Map<String, dynamic> item) {
    final d = DateTime.tryParse(item['scheduledDate']?.toString() ?? '');
    if (d == null || item['status'] != 'assigned') return false;
    final n = DateTime.now();
    return DateTime(d.year, d.month, d.day)
        .isBefore(DateTime(n.year, n.month, n.day));
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadAssignedWalks();
  }

  Future<void> _loadAssignedWalks() async {
    if (mounted) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
    }

    try {
      final token = await SecureStorageService.getToken();

      if (token == null || token.isEmpty) {
        if (!mounted) return;
        setState(() {
          _errorMessage = 'Your session has expired. Please sign in again.';
          _isLoading = false;
        });
        return;
      }

      final walks = await _service.fetchAssignedWalks(token);

      if (!mounted) return;
      setState(() {
        _assignedGembaData = walks.map((w) => w.toUiMap()).toList();
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Failed to load assigned gemba walks: $e');
      if (!mounted) return;
      setState(() {
        _errorMessage =
            'Unable to load Gemba walks. Please check your connection and try again.';
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Gemba Walk',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 17,
                letterSpacing: 0.2,
              ),
            ),
            SizedBox(height: 2),
            Text(
              'Floor Inspections & Audits',
              style: TextStyle(
                fontSize: 13,
                color: Colors.white70,
                fontWeight: FontWeight.normal,
              ),
            ),
          ],
        ),
        backgroundColor: _teal,
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new,
              color: Colors.white, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Container(
            color: _teal,
            child: TabBar(
              controller: _tabController,
              indicatorColor: Colors.white,
              indicatorWeight: 3,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white70,
              labelStyle: const TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 13,
                letterSpacing: 0.3,
              ),
              tabs: const [
                Tab(text: 'ASSIGNED WALKS'),
                Tab(text: 'FOLLOW UPS'),
              ],
            ),
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildGembaList(_assignedGembaData, isAssigned: true),
          _buildFollowUpsTab(),
        ],
      ),
    );
  }

  Widget _buildGembaList(List<Map<String, dynamic>> data,
      {required bool isAssigned}) {
    if (isAssigned && _isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: _teal),
      );
    }

    if (isAssigned && _errorMessage != null) {
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
                onPressed: _loadAssignedWalks,
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
    if (data.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.check_circle_outline_rounded,
                size: 50, color: _teal.withValues(alpha: 0.6)),
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
            Text(
              isAssigned
                  ? 'No Gemba walks assigned right now.'
                  : 'No pending follow-ups found.',
              style: const TextStyle(fontSize: 12.5, color: _muted),
            ),
          ],
        ),
      );
    }

    final items = [...data];

    return RefreshIndicator(
      color: _teal,
      onRefresh: isAssigned ? _loadAssignedWalks : () async {},
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (_, i) =>
            _buildGembaCard(items[i], isAssigned: isAssigned),
      ),
    );
  }

  Widget _buildFollowUpsTab() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
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
              'No Follow Ups Yet',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: _ink,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Follow-up walks will appear here when assigned to you.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12.5, color: _muted, height: 1.4),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGembaCard(Map<String, dynamic> item,
      {required bool isAssigned}) {
    final status = item['status'] as String;
    final String purpose = item['purpose']?.toString() ?? 'Gemba Walk';
    final int totalPoints = (item['totalPoints'] as int?) ?? 0;
    final bool overdue = _isOverdue(item);
    final String gembaId = item['gemba']?.toString() ?? 'GW-00';
    final String area = item['area']?.toString() ?? 'General Area';
    final String location = item['location']?.toString() ?? '';
    final String dueDate = item['dueDate']?.toString() ?? 'Today';
    final Color accent = isAssigned ? _teal : _statusColor(status);
    final bool isClosed = status.toUpperCase() == 'CLOSED';

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xffE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
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
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: const Color(0xffF1F5F9),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            gembaId,
                            style: const TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w700,
                              color: _muted,
                              letterSpacing: 0.3,
                            ),
                          ),
                        ),
                        _statusChip(
                            item['statusLabel']?.toString() ?? status, status)
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: _teal.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            _purposeIcon(purpose),
                            color: _teal,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                purpose,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: _ink,
                                ),
                              ),
                              const SizedBox(height: 5),
                              Row(
                                children: [
                                  const Icon(Icons.location_on_outlined,
                                      size: 14, color: _muted),
                                  const SizedBox(width: 3),
                                  Expanded(
                                    child: Text(
                                      location.isNotEmpty
                                          ? '$area · $location'
                                          : area,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontSize: 12.5,
                                        color: _muted,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Divider(height: 1, color: Color(0xffF1F5F9)),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.schedule, size: 13, color: _muted),
                            const SizedBox(width: 4),
                            Text('$dueDate · $totalPoints points',
                                style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                    color: overdue
                                        ? Colors.red.shade700
                                        : _muted)),
                          ],
                        ),
                        if (!isClosed)
                          ElevatedButton.icon(
                            onPressed: () =>
                                _onAction(item, isAssigned: isAssigned),
                            icon: Icon(
                              _buttonIconForStatus(status),
                              size: 16,
                            ),
                            label: Text(
                              _buttonLabelForStatus(status),
                              style: const TextStyle(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _teal,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 6),
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          )
                        else
                          const Text(
                            'Closed',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: _muted,
                            ),
                          ),
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

  Widget _statusChip(String label, String status) {
    final color = _statusColor(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Text(label,
          style: TextStyle(
              fontSize: 11, fontWeight: FontWeight.w700, color: color)),
    );
  }

  Future<void> _onAction(Map<String, dynamic> item,
      {required bool isAssigned}) async {
    context.read<GembaWalkProvider>().reset();

    final needsRefresh = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) =>
            GembaWalkDetailScreen(gembaData: item, isAssigned: isAssigned),
      ),
    );

    if (!mounted) return;

    if (needsRefresh == true) {
      _loadAssignedWalks();
    }
  }

  String _buttonLabelForStatus(String status) {
    switch (status.toLowerCase()) {
      case 'submitted':
        return 'View Walk';
      case 'closed':
        return 'View';
      case 'assigned':
      default:
        return 'Start Walk';
    }
  }

  IconData _buttonIconForStatus(String status) {
    switch (status.toLowerCase()) {
      case 'submitted':
        return Icons.add_task_rounded;
      case 'closed':
        return Icons.visibility_rounded;
      case 'assigned':
      default:
        return Icons.play_arrow_rounded;
    }
  }

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'assigned':
        return _teal;
      case 'submitted':
      case 'completed':
        return const Color(0xff16A34A);
      case 'open':
        return const Color(0xffEA580C);
      case 'pending_assignment':
        return const Color(0xff64748B);
      default:
        return const Color(0xff64748B);
    }
  }
}
