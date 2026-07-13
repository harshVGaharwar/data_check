// part of 'package:vizualizer/presentation/widgets/layout/sidebar.dart';

// // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// // JOIN PALETTE ITEM — locked until all source nodes are confirmed
// // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

// class JoinPaletteItem extends StatefulWidget {
//   final PipelineController ctrl;
//   const JoinPaletteItem({super.key, required this.ctrl});

//   @override
//   State<JoinPaletteItem> createState() => JoinPaletteItemState();
// }

// class JoinPaletteItemState extends State<JoinPaletteItem>
//     with SingleTickerProviderStateMixin {
//   late final AnimationController _pulseCtrl;
//   late final Animation<double> _pulseAnim;
//   bool _lastUnlocked = false;

//   @override
//   void initState() {
//     super.initState();
//     _pulseCtrl = AnimationController(
//       vsync: this,
//       duration: const Duration(milliseconds: 800),
//     );
//     _pulseAnim = Tween<double>(
//       begin: 0.0,
//       end: 1.0,
//     ).animate(CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));
//     _lastUnlocked = widget.ctrl.shouldAnimateJoin;
//     if (_lastUnlocked) _pulseCtrl.repeat(reverse: true);
//   }

//   void _syncAnimation(bool shouldAnimate) {
//     if (shouldAnimate && !_pulseCtrl.isAnimating) {
//       _pulseCtrl.repeat(reverse: true);
//     } else if (!shouldAnimate && _pulseCtrl.isAnimating) {
//       _pulseCtrl.stop();
//       _pulseCtrl.value = 0;
//     }
//     _lastUnlocked = shouldAnimate;
//   }

//   @override
//   void dispose() {
//     _pulseCtrl.dispose();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     final unlocked = widget.ctrl.allSourceNodesConfirmed;
//     final shouldAnimate = widget.ctrl.shouldAnimateJoin;
//     WidgetsBinding.instance.addPostFrameCallback((_) {
//       if (mounted) _syncAnimation(shouldAnimate);
//     });
//     const type = NodeType.join;
//     const color = AppColors.blue;

//     Widget content({double glowAlpha = 0, double borderAlpha = 1}) => Container(
//       margin: const EdgeInsets.only(bottom: 6),
//       padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
//       decoration: BoxDecoration(
//         borderRadius: BorderRadius.circular(8),
//         border: Border.all(
//           color: unlocked
//               ? color.withValues(alpha: 0.4 + borderAlpha * 0.6)
//               : AppColors.border2,
//           width: unlocked ? 1.8 : 1.0,
//         ),
//         color: unlocked
//             ? color.withValues(alpha: 0.04 + glowAlpha * 0.08)
//             : AppColors.surface2,
//         boxShadow: unlocked && glowAlpha > 0
//             ? [
//                 BoxShadow(
//                   color: color.withValues(alpha: glowAlpha * 0.35),
//                   blurRadius: 8 + glowAlpha * 10,
//                   spreadRadius: glowAlpha * 2,
//                 ),
//               ]
//             : null,
//       ),
//       child: Row(
//         children: [
//           Container(
//             width: 28,
//             height: 28,
//             decoration: BoxDecoration(
//               borderRadius: BorderRadius.circular(6),
//               color: color.withValues(
//                 alpha: unlocked ? 0.12 + glowAlpha * 0.1 : 0.07,
//               ),
//             ),
//             child: Icon(
//               unlocked ? type.icon : Icons.lock_outline_rounded,
//               color: unlocked ? color : AppColors.textMuted,
//               size: 14,
//             ),
//           ),
//           const SizedBox(width: 8),
//           Expanded(
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Text(
//                   type.label,
//                   style: TextStyle(
//                     color: unlocked ? AppColors.text : AppColors.textMuted,
//                     fontSize: 12,
//                     fontWeight: FontWeight.w600,
//                   ),
//                 ),
//                 Text(
//                   unlocked ? '✦ Ready to drag' : 'Confirm all sources first',
//                   style: TextStyle(
//                     color: unlocked
//                         ? color.withValues(alpha: 0.8)
//                         : AppColors.textMuted,
//                     fontSize: 10,
//                     fontWeight: unlocked ? FontWeight.w600 : FontWeight.normal,
//                   ),
//                 ),
//               ],
//             ),
//           ),
//           if (unlocked)
//             AnimatedBuilder(
//               animation: _pulseAnim,
//               builder: (_, __) => Icon(
//                 Icons.arrow_forward_rounded,
//                 color: color.withValues(alpha: 0.4 + _pulseAnim.value * 0.6),
//                 size: 14,
//               ),
//             ),
//         ],
//       ),
//     );

//     if (!unlocked) {
//       return GestureDetector(
//         onTap: () {
//           final sources = widget.ctrl.nodes
//               .where((n) => n.type.isSource)
//               .toList();
//           final required = widget.ctrl.requiredSourceCount;
//           final confirmed = sources
//               .where((n) => n.confirmState == NodeConfirmState.confirmed)
//               .length;
//           final String msg;
//           if (required > 0 && sources.length < required) {
//             msg =
//                 'Add all $required required source nodes first'
//                 ' (${sources.length}/$required added).';
//           } else {
//             msg =
//                 'Configure all source nodes first'
//                 ' ($confirmed/${sources.length} confirmed).';
//           }
//           ScaffoldMessenger.of(context).showSnackBar(
//             SnackBar(content: Text(msg), backgroundColor: Colors.orange),
//           );
//         },
//         child: Opacity(opacity: 0.5, child: content()),
//       );
//     }

//     return AnimatedBuilder(
//       animation: _pulseAnim,
//       builder: (context, _) => Draggable<DragNodeData>(
//         data: DragNodeData(type),
//         feedback: Material(
//           color: Colors.transparent,
//           child: Container(
//             padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
//             decoration: BoxDecoration(
//               color: AppColors.surface,
//               borderRadius: BorderRadius.circular(10),
//               border: Border.all(color: color),
//               boxShadow: [
//                 BoxShadow(color: color.withValues(alpha: 0.4), blurRadius: 16),
//               ],
//             ),
//             child: Row(
//               mainAxisSize: MainAxisSize.min,
//               children: [
//                 Icon(type.icon, color: color, size: 16),
//                 const SizedBox(width: 8),
//                 Text(
//                   type.label,
//                   style: const TextStyle(
//                     color: AppColors.text,
//                     fontSize: 12,
//                     fontWeight: FontWeight.w600,
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         ),
//         childWhenDragging: Opacity(opacity: 0.3, child: content()),
//         child: content(
//           glowAlpha: _pulseAnim.value,
//           borderAlpha: _pulseAnim.value,
//         ),
//       ),
//     );
//   }
// }

// // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// // STEP HIGHLIGHT — animated glowing border + bg around a sidebar section
// // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━



// // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// // TEMPLATE CONFIG BADGE
// // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━



// // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// // CONFIG ROW — single row inside TemplateConfigBadge card
// // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━







//SIDE BAR WIDGET //


part of 'package:vizualizer/presentation/widgets/layout/sidebar.dart';

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// JOIN PALETTE ITEM — locked until all source nodes are confirmed
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

class JoinPaletteItem extends StatefulWidget {
  final PipelineController ctrl;
  const JoinPaletteItem({super.key, required this.ctrl});

  @override
  State<JoinPaletteItem> createState() => JoinPaletteItemState();
}

class JoinPaletteItemState extends State<JoinPaletteItem>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseCtrl;
  late final Animation<double> _pulseAnim;
  bool _lastUnlocked = false;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _pulseAnim = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));
    _lastUnlocked = widget.ctrl.shouldAnimateJoin;
    if (_lastUnlocked) _pulseCtrl.repeat(reverse: true);
  }

  void _syncAnimation(bool shouldAnimate) {
    if (shouldAnimate && !_pulseCtrl.isAnimating) {
      _pulseCtrl.repeat(reverse: true);
    } else if (!shouldAnimate && _pulseCtrl.isAnimating) {
      _pulseCtrl.stop();
      _pulseCtrl.value = 0;
    }
    if (shouldAnimate && !_lastUnlocked && mounted) {
      Scrollable.ensureVisible(context,
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeOutCubic,
          alignment: 0.5);
    }
    _lastUnlocked = shouldAnimate;
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final unlocked = widget.ctrl.allSourceNodesConfirmed;
    final shouldAnimate = widget.ctrl.shouldAnimateJoin;
    final alreadyAdded = widget.ctrl.hasJoinNode;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _syncAnimation(shouldAnimate);
    });
    const type = NodeType.join;
    const color = AppColors.blue;

    Widget content({double glowAlpha = 0, double borderAlpha = 1}) => Container(
          margin: const EdgeInsets.only(bottom: 6),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: unlocked
                  ? color.withValues(alpha: 0.4 + borderAlpha * 0.6)
                  : AppColors.border2,
              width: unlocked ? 1.8 : 1.0,
            ),
            color: unlocked
                ? color.withValues(alpha: 0.04 + glowAlpha * 0.08)
                : AppColors.surface2,
            boxShadow: unlocked && glowAlpha > 0
                ? [
                    BoxShadow(
                      color: color.withValues(alpha: glowAlpha * 0.35),
                      blurRadius: 8 + glowAlpha * 10,
                      spreadRadius: glowAlpha * 2,
                    ),
                  ]
                : null,
          ),
          child: Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(6),
                  color: color.withValues(
                    alpha: unlocked ? 0.12 + glowAlpha * 0.1 : 0.07,
                  ),
                ),
                child: Icon(
                  unlocked ? type.icon : Icons.lock_outline_rounded,
                  color: unlocked ? color : AppColors.textMuted,
                  size: 14,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      type.label,
                      style: TextStyle(
                        color: unlocked ? AppColors.text : AppColors.textMuted,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      unlocked
                          ? '✦ Ready to drag'
                          : 'Confirm all sources first',
                      style: TextStyle(
                        color: unlocked
                            ? color.withValues(alpha: 0.8)
                            : AppColors.textMuted,
                        fontSize: 10,
                        fontWeight:
                            unlocked ? FontWeight.w600 : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              ),
              if (unlocked)
                AnimatedBuilder(
                  animation: _pulseAnim,
                  builder: (_, __) => Icon(
                    Icons.arrow_forward_rounded,
                    color:
                        color.withValues(alpha: 0.4 + _pulseAnim.value * 0.6),
                    size: 14,
                  ),
                ),
            ],
          ),
        );

    if (!unlocked) {
      return GestureDetector(
        onTap: () {
          final sources =
              widget.ctrl.nodes.where((n) => n.type.isSource).toList();
          final required = widget.ctrl.requiredSourceCount;
          final confirmed = sources
              .where((n) => n.confirmState == NodeConfirmState.confirmed)
              .length;
          final String msg;
          if (required > 0 && sources.length < required) {
            msg = 'Add all $required required source nodes first'
                ' (${sources.length}/$required added).';
          } else {
            msg = 'Configure all source nodes first'
                ' ($confirmed/${sources.length} confirmed).';
          }
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(msg), backgroundColor: Colors.orange),
          );
        },
        child: Opacity(opacity: 0.5, child: content()),
      );
    }
    if (!unlocked || alreadyAdded) {
      return Opacity(
        opacity: 0.5,
        child: content(),
      );
    }

    return AnimatedBuilder(
      animation: _pulseAnim,
      builder: (context, _) => Draggable<DragNodeData>(
        data: DragNodeData(type),
        feedback: Material(
          color: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: color),
              boxShadow: [
                BoxShadow(color: color.withValues(alpha: 0.4), blurRadius: 16),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(type.icon, color: color, size: 16),
                const SizedBox(width: 8),
                Text(
                  type.label,
                  style: const TextStyle(
                    color: AppColors.text,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
        childWhenDragging: Opacity(opacity: 0.3, child: content()),
        child: content(
          glowAlpha: _pulseAnim.value,
          borderAlpha: _pulseAnim.value,
        ),
      ),
    );
  }
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// STEP HIGHLIGHT — animated glowing border + bg around a sidebar section
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━



// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// TEMPLATE CONFIG BADGE
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━



// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// CONFIG ROW — single row inside TemplateConfigBadge card
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
