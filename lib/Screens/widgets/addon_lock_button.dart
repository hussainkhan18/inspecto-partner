import 'package:flutter/material.dart';

class AddonLockButton extends StatefulWidget {
  final String label;
  final bool isLimitReached;
  final VoidCallback onTap;

  /// Optional overrides — defaults match original behavior exactly,
  /// so existing callers (TBT / Safety Violation / Work Permit) are
  /// completely unaffected unless they explicitly pass these.
  final double fontSize;
  final int maxLines;

  final double iconTextSpacing;
  final double horizontalPadding;

  const AddonLockButton({
    super.key,
    required this.label,
    required this.onTap,
    this.isLimitReached = false,
    this.fontSize = 15,
    this.maxLines = 1,
    this.iconTextSpacing = 8,
    this.horizontalPadding = 16,
  });

  @override
  State<AddonLockButton> createState() => _AddonLockButtonState();
}

class _AddonLockButtonState extends State<AddonLockButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _shimmerController;

  static const Color _teal = Color(0xFF0DC5B9);
  static const Color _tealLight = Color(0xFF5DE0D7);
  static const Color _background = Color(0xFF101718);
  static const Color _backgroundSecondary = Color(0xFF182021);

  // Reserved horizontal space (both sides) so long labels ellipsize
  // before reaching under the top-right ADDON/LIMIT badge.
  static const double _badgeReserve = 90;

  @override
  void initState() {
    super.initState();
    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat();
  }

  @override
  void dispose() {
    _shimmerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width * 0.9;

    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: widget.onTap,
          borderRadius: BorderRadius.circular(12),
          child: SizedBox(
            width: width,
            height: 50,
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8.0),
                gradient: const LinearGradient(
                  colors: [_backgroundSecondary, _background],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                border: Border.all(color: _teal.withOpacity(0.75), width: 1.2),
                boxShadow: [
                  BoxShadow(
                    color: _teal.withOpacity(0.12),
                    blurRadius: 10,
                    spreadRadius: 0.2,
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(11),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Center(
                      child: Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: widget.horizontalPadding,
                          vertical: 8,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Icon(
                              widget.isLimitReached
                                  ? Icons.hourglass_bottom_rounded
                                  : Icons.lock_rounded,
                              color: _tealLight,
                              size: 16,
                            ),
                            SizedBox(width: widget.iconTextSpacing),
                            Flexible(
                              child: Text(
                                widget.label,
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: widget.fontSize,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 0.15,
                                  height: 1.15,
                                ),
                                maxLines: widget.maxLines,
                                overflow: TextOverflow.ellipsis,
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    AnimatedBuilder(
                      animation: _shimmerController,
                      builder: (context, child) {
                        final t = _shimmerController.value;
                        return IgnorePointer(
                          child: Transform.translate(
                            offset: Offset(-width + (2 * width * t), 0),
                            child: Container(
                              width: width * 0.30,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.centerLeft,
                                  end: Alignment.centerRight,
                                  colors: [
                                    _teal.withOpacity(0.0),
                                    _teal.withOpacity(0.08),
                                    _teal.withOpacity(0.0),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                    Positioned(
                      top: 6,
                      right: 10,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 7, vertical: 2.5),
                        decoration: BoxDecoration(
                          color: _teal.withOpacity(0.14),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: _teal.withOpacity(0.55),
                            width: 0.8,
                          ),
                        ),
                        child: Text(
                          widget.isLimitReached ? 'LIMIT' : 'ADDON',
                          style: const TextStyle(
                            color: _tealLight,
                            fontSize: 8.5,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.6,
                          ),
                        ),
                      ),
                    ),
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
