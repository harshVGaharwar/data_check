import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// A button with a sweeping shimmer animation and pulsing border.
///
/// Pass [animating] = true to play the shimmer; false to pause it cleanly.
class ShimmerButton extends StatefulWidget {
  final String label;
  final IconData? icon;
  final Color color;
  final bool animating;
  final VoidCallback? onTap;
  final Duration duration;

  const ShimmerButton({
    super.key,
    required this.label,
    this.icon,
    this.color = AppColors.blue,
    this.animating = true,
    this.onTap,
    this.duration = const Duration(milliseconds: 1600),
  });

  @override
  State<ShimmerButton> createState() => _ShimmerButtonState();
}

class _ShimmerButtonState extends State<ShimmerButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: widget.duration);
    if (widget.animating) _ctrl.repeat();
  }

  @override
  void didUpdateWidget(ShimmerButton old) {
    super.didUpdateWidget(old);
    if (old.duration != widget.duration) {
      _ctrl.duration = widget.duration;
    }
    if (widget.animating && !_ctrl.isAnimating) {
      _ctrl.repeat();
    } else if (!widget.animating && _ctrl.isAnimating) {
      _ctrl.reset();
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.color;

    return GestureDetector(
      onTap: widget.onTap,
      child: AnimatedBuilder(
        animation: _ctrl,
        builder: (_, __) {
          final t = _ctrl.value;
          final isRunning = _ctrl.isAnimating;
          final sweepPos = -1.5 + t * 4.0;
          final borderAlpha =
              isRunning ? 0.25 + 0.45 * math.sin(t * math.pi) : 0.25;

          return ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(6),
                color: color.withValues(alpha: 0.06),
                border: Border.all(
                  color: color.withValues(alpha: borderAlpha),
                  width: 1.2,
                ),
              ),
              child: Stack(
                children: [
                  if (isRunning)
                    Positioned.fill(
                      child: IgnorePointer(
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(6),
                            gradient: LinearGradient(
                              begin: Alignment(sweepPos - 1, 0),
                              end: Alignment(sweepPos + 1, 0),
                              colors: [
                                color.withValues(alpha: 0.0),
                                color.withValues(alpha: 0.18),
                                color.withValues(alpha: 0.0),
                              ],
                              stops: const [0.0, 0.5, 1.0],
                            ),
                          ),
                        ),
                      ),
                    ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (widget.icon != null) ...[
                        Icon(widget.icon, color: color, size: 12),
                        const SizedBox(width: 5),
                      ],
                      Text(
                        widget.label,
                        style: TextStyle(
                          color: color,
                          fontSize: 10.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
