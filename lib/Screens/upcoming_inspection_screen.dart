import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:inspecto_shield_partner/Providers/upcoming_inspection_provider.dart';
import 'package:inspecto_shield_partner/models/upcoming_inspection_model.dart';
import 'package:provider/provider.dart';
import '../services/upcoming_inspection_service.dart';

class UpcomingInspectionScreen extends StatefulWidget {
  final int userId;

  const UpcomingInspectionScreen({super.key, required this.userId});

  @override
  State<UpcomingInspectionScreen> createState() =>
      _UpcomingInspectionScreenState();
}

class _UpcomingInspectionScreenState extends State<UpcomingInspectionScreen> {
  static const Color _teal = Color(0xff0DC5B9);
  static const Color _bgColor = Color(0xffF4F6F8);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context
          .read<UpcomingInspectionProvider>()
          .fetchInspections(widget.userId);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgColor,
      appBar: _buildAppBar(),
      body: Consumer<UpcomingInspectionProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading) {
            return const Center(
              child: CircularProgressIndicator(color: _teal, strokeWidth: 2.5),
            );
          }
          if (provider.hasError) return _buildErrorState(provider);
          if (provider.isEmpty) return _buildEmptyState();
          return _buildLoadedContent(provider);
        },
      ),
    );
  }

  // ─── AppBar ──────────────────────────────────────────────────────────────────
  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      surfaceTintColor: Colors.transparent,
      automaticallyImplyLeading: false,
      titleSpacing: 0,
      title: Row(
        children: [
          CupertinoButton(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
            onPressed: () => Navigator.of(context).pop(),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(CupertinoIcons.chevron_back, size: 25),
                SizedBox(width: 2),
              ],
            ),
          ),
          const Expanded(
            child: Text(
              'Upcoming Inspections',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Color(0xff1A1A2E),
                fontSize: 17,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.2,
              ),
            ),
          ),
          // Right side spacer to keep title centered
          const SizedBox(width: 80),
        ],
      ),
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(height: 1, color: const Color(0xffEEEEEE)),
      ),
    );
  }

  // ─── Loaded ───────────────────────────────────────────────────────────────────
  Widget _buildLoadedContent(UpcomingInspectionProvider provider) {
    return RefreshIndicator(
      color: _teal,
      onRefresh: () => provider.fetchInspections(widget.userId),
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(10, 16, 10, 32),
        itemCount: provider.inspections.length + 1,
        itemBuilder: (context, index) {
          if (index == 0) return _buildWeekHeader(provider);
          return _InspectionCard(item: provider.inspections[index - 1]);
        },
      ),
    );
  }

  // ─── Week Header ──────────────────────────────────────────────────────────────
  Widget _buildWeekHeader(UpcomingInspectionProvider provider) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(9),
            decoration: BoxDecoration(
              color: _teal.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.date_range_rounded, color: _teal, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'THIS WEEK',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: _teal,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  provider.weekRange,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: Color(0xff1A1A2E),
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: _teal.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '${provider.totalCount} Total',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: _teal,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Empty ────────────────────────────────────────────────────────────────────
  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: _teal.withOpacity(0.08),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.event_available_rounded,
                  color: _teal, size: 48),
            ),
            const SizedBox(height: 24),
            const Text(
              'All Clear This Week!',
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Color(0xff1A1A2E)),
            ),
            const SizedBox(height: 8),
            Text(
              'No upcoming inspections scheduled for this week.',
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 14, color: Colors.grey.shade500, height: 1.5),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Error ────────────────────────────────────────────────────────────────────
  Widget _buildErrorState(UpcomingInspectionProvider provider) {
    final isNetwork = provider.errorType == UpcomingInspectionErrorType.network;
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: const Color(0xFFEF4444).withOpacity(0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isNetwork
                    ? Icons.wifi_off_rounded
                    : Icons.error_outline_rounded,
                color: const Color(0xFFEF4444),
                size: 48,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              isNetwork ? 'No Internet Connection' : 'Something Went Wrong',
              style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Color(0xff1A1A2E)),
            ),
            const SizedBox(height: 8),
            Text(
              provider.errorMessage,
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 14, color: Colors.grey.shade500, height: 1.5),
            ),
            const SizedBox(height: 28),
            SizedBox(
              width: 160,
              height: 46,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: _teal,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: const Text('Try Again',
                    style:
                        TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                onPressed: () => provider.retry(widget.userId),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// Inspection Card
// ══════════════════════════════════════════════════════════════════════════════

class _InspectionCard extends StatelessWidget {
  final UpcomingInspectionItem item;

  const _InspectionCard({required this.item});

  _StatusStyle get _statusStyle {
    switch (item.status.toLowerCase()) {
      case 'overdue':
        return _StatusStyle(
            color: const Color(0xFFEF4444),
            icon: Icons.warning_amber_rounded,
            label: item.status);
      case 'due today':
        return _StatusStyle(
            color: const Color(0xFFF59E0B),
            icon: Icons.schedule_rounded,
            label: item.status);
      case 'pending':
        return _StatusStyle(
            color: const Color(0xFF3B82F6),
            icon: Icons.pending_outlined,
            label: item.status);
      case 'completed':
        return _StatusStyle(
            color: const Color(0xFF22C55E),
            icon: Icons.check_circle_outline_rounded,
            label: item.status);
      default:
        return _StatusStyle(
            color: const Color(0xFF94A3B8),
            icon: Icons.help_outline_rounded,
            label: item.status);
    }
  }

  String get _lastInspectionDisplay {
    if (item.lastInspection == 'Never Inspected') return 'Never Inspected';
    return item.lastInspection.contains(' ')
        ? item.lastInspection.split(' ')[0]
        : item.lastInspection;
  }

  @override
  Widget build(BuildContext context) {
    final style = _statusStyle;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xffE2E8F0), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.09),
            blurRadius: 16,
            offset: const Offset(0, 5),
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ════════════════════════
          // HEADER — Name + Status
          // ════════════════════════
          Container(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
            decoration: BoxDecoration(
              color: style.color.withOpacity(0.04),
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(14)),
              border: Border(
                left: BorderSide(color: style.color, width: 4),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(
                    color: style.color.withOpacity(0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(style.icon, color: style.color, size: 16),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    item.name,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: Color(0xff1A1A2E),
                      letterSpacing: 0.1,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 10),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: style.color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                        color: style.color.withOpacity(0.3), width: 1),
                  ),
                  child: Text(
                    style.label,
                    style: TextStyle(
                      fontSize: 11,
                      color: style.color,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.3,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ════════════════════════
          // BODY — Location + Freq
          // ════════════════════════
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Column(
              children: [
                _detailRow(
                  icon: Icons.location_on_outlined,
                  iconColor: const Color(0xff0DC5B9),
                  label: 'Location',
                  value: '${item.areaName}  ·  ${item.locationName}',
                  maxLines: 2,
                ),
                Divider(height: 16, thickness: 1, color: Colors.grey.shade100),
                _detailRow(
                  icon: Icons.repeat_rounded,
                  iconColor: const Color(0xFFA78BFA),
                  label: 'Frequency',
                  value: item.frequency,
                ),
              ],
            ),
          ),

          // ════════════════════════
          // FOOTER — Dates strip
          // ════════════════════════
          Container(
            margin: const EdgeInsets.fromLTRB(12, 4, 12, 12),
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xffF4F6F8),
              borderRadius: BorderRadius.circular(10),
            ),
            child: IntrinsicHeight(
              child: Row(
                children: [
                  Expanded(
                    child: _dateColumn(
                      icon: Icons.history_rounded,
                      iconColor: const Color(0xFF94A3B8),
                      label: 'Last Inspection',
                      value: _lastInspectionDisplay,
                      valueColor: const Color(0xFF475569),
                    ),
                  ),
                  VerticalDivider(
                      width: 1,
                      thickness: 1,
                      color: Colors.grey.shade300,
                      indent: 4,
                      endIndent: 4),
                  Expanded(
                    child: _dateColumn(
                      icon: Icons.event_rounded,
                      iconColor: style.color,
                      label: 'Due Date',
                      value: item.deadlineDate,
                      valueColor: style.color,
                    ),
                  ),
                  VerticalDivider(
                      width: 1,
                      thickness: 1,
                      color: Colors.grey.shade300,
                      indent: 4,
                      endIndent: 4),
                  Expanded(
                    child: _dateColumn(
                      icon: Icons.calendar_today_rounded,
                      iconColor: const Color(0xFF3B82F6),
                      label: 'Day',
                      value: item.dayName,
                      valueColor: const Color(0xFF3B82F6),
                    ),
                  ),
                ],
              ),
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
    int maxLines = 1,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 1),
          child: Icon(icon, size: 15, color: iconColor),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: Colors.grey.shade500,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Color(0xff1A1A2E),
            ),
            textAlign: TextAlign.right,
            maxLines: maxLines,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _dateColumn({
    required IconData icon,
    required Color iconColor,
    required String label,
    required String value,
    required Color valueColor,
  }) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, size: 14, color: iconColor),
        const SizedBox(height: 5),
        Text(
          label,
          style: TextStyle(
            fontSize: 9.5,
            color: Colors.grey.shade500,
            fontWeight: FontWeight.w500,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 3),
        Text(
          value,
          style: TextStyle(
            fontSize: 11.5,
            color: valueColor,
            fontWeight: FontWeight.w700,
          ),
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}

// ─── Status Style ─────────────────────────────────────────────────────────────
class _StatusStyle {
  final Color color;
  final IconData icon;
  final String label;

  const _StatusStyle(
      {required this.color, required this.icon, required this.label});
}
