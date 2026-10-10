import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:inspecto_shield_partner/Providers/app_mode_provider.dart';
import 'package:provider/provider.dart';

class OfflineModeWrapper extends StatelessWidget {
  final Widget child;
  const OfflineModeWrapper({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Consumer<AppModeProvider>(
      builder: (context, mode, _) {
        final isDimmed = mode.isOfflineMode || mode.isBusy;
        final showBanner = mode.isOfflineMode && !mode.isBusy;

        Widget content = child;

        if (isDimmed) {
          content = ColorFiltered(
            colorFilter: const ColorFilter.matrix(<double>[
              0.2126,
              0.7152,
              0.0722,
              0,
              0,
              0.2126,
              0.7152,
              0.0722,
              0,
              0,
              0.2126,
              0.7152,
              0.0722,
              0,
              0,
              0,
              0,
              0,
              1,
              0,
            ]),
            child: content,
          );
        }

        return AnnotatedRegion<SystemUiOverlayStyle>(
          value: SystemUiOverlayStyle(
            statusBarColor:
                isDimmed ? const Color(0xFF334155) : const Color(0xff0DC5B9),
            statusBarIconBrightness:
                isDimmed ? Brightness.light : Brightness.dark,
            statusBarBrightness: isDimmed ? Brightness.dark : Brightness.light,
          ),
          child: Material(
            type: MaterialType.transparency,
            child: Stack(
              children: [
                Column(
                  children: [
                    AnimatedSize(
                      duration: const Duration(milliseconds: 220),
                      curve: Curves.easeOut,
                      alignment: Alignment.topCenter,
                      child: showBanner
                          ? _statusBar(context, mode.pendingCount,
                              mode.pendingComplianceCount)
                          : const SizedBox(width: double.infinity, height: 0),
                    ),
                    Expanded(child: content),
                  ],
                ),
                if (mode.isBusy) _BusyOverlay(mode: mode),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _statusBar(
      BuildContext context, int pendingCount, int pendingComplianceCount) {
    final topInset = MediaQuery.of(context).padding.top;
    final totalPending = pendingCount + pendingComplianceCount;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.only(top: topInset, bottom: 6),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.black26, Colors.black54],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(14)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.wifi_off_rounded, size: 13, color: Colors.white),
          const SizedBox(width: 6),
          const Text(
            'OFFLINE MODE',
            style: TextStyle(
              color: Colors.white,
              fontSize: 10.5,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.7,
            ),
          ),
          if (totalPending > 0) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Container(width: 1, height: 11, color: Colors.white38),
            ),
            const Icon(Icons.cloud_upload_outlined,
                size: 11, color: Colors.white),
            const SizedBox(width: 4),
            Text(
              pendingComplianceCount > 0
                  ? '$pendingCount insp · $pendingComplianceCount compliance pending'
                  : '$pendingCount pending',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 10.5,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _BusyOverlay extends StatelessWidget {
  final AppModeProvider mode;
  const _BusyOverlay({required this.mode});

  @override
  Widget build(BuildContext context) {
    final isFetching = mode.phase == SyncPhase.fetchingEquipment;
    final progress = isFetching
        ? mode.fetchProgress
        : (mode.syncTotal == 0 ? 0.0 : mode.syncCompleted / mode.syncTotal);
    final title = isFetching ? 'Preparing Offline Data' : 'Syncing Inspections';
    final subtitle = isFetching
        ? 'Downloading equipment for offline use'
        : 'Uploading item ${mode.syncCompleted} of ${mode.syncTotal}';
    return PopScope(
      canPop: false,
      child: Positioned.fill(
        child: AbsorbPointer(
          absorbing: true,
          child: Container(
            color: Colors.black.withOpacity(0.6),
            child: Center(
              child: Container(
                width: 260,
                padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 30,
                      spreadRadius: 4,
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: 76,
                      height: 76,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          SizedBox(
                            width: 76,
                            height: 76,
                            child: CircularProgressIndicator(
                              value: progress,
                              strokeWidth: 6,
                              backgroundColor: Colors.grey.shade200,
                              valueColor: const AlwaysStoppedAnimation(
                                  Color(0xFF0DC5B9)),
                            ),
                          ),
                          Text(
                            '${(progress * 100).clamp(0, 100).toStringAsFixed(0)}%',
                            style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF0F172A)),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),
                    Text(title,
                        style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF0F172A))),
                    const SizedBox(height: 6),
                    Text(subtitle,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            fontSize: 12, color: Colors.grey.shade600)),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
