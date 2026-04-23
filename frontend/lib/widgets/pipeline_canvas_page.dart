import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../models/pipeline_models.dart';
import '../controllers/pipeline_controller.dart';
import 'edge_painter.dart';
import 'nodes/source_node_body.dart';
import 'nodes/output_node_body.dart';
import 'nodes/join_node_body.dart';
import 'top_bar.dart';
import 'sidebar.dart';
import 'config_panel.dart';
import 'source_preview_sidebar.dart';
import 'status_bar.dart';

class PipelineCanvasPage extends StatefulWidget {
  const PipelineCanvasPage({super.key});

  @override
  State<PipelineCanvasPage> createState() => _PipelineCanvasPageState();
}

class _PipelineCanvasPageState extends State<PipelineCanvasPage>
    with TickerProviderStateMixin {
  final _transformCtrl = TransformationController();
  late final AnimationController _pulseCtrl;
  late final Animation<double> _pulseAnim;

  @override
  void initState() {
    super.initState();
    // Empty canvas — user drags sources from sidebar
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 0.25, end: 1.0).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    _transformCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const TopBar(),
        Expanded(
          child: Row(
            children: [
              const Flexible(flex: 0, child: Sidebar()),
              Expanded(child: _buildCanvas()),
              Consumer<PipelineController>(
                builder: (_, ctrl, __) => ctrl.selectedNodeId != null
                    ? const Flexible(flex: 0, child: ConfigPanel())
                    : const SizedBox.shrink(),
              ),
              const Flexible(flex: 0, child: SourcePreviewSidebar()),
            ],
          ),
        ),
        const StatusBar(),
      ],
    );
  }

  Widget _buildCanvas() {
    return Consumer<PipelineController>(
      builder: (context, ctrl, _) {
        final edgePainter = EdgePainter(ctrl);
        final isConnecting = ctrl.portDragFromNodeId != null;

        return Stack(
          children: [
            // ── 1. Canvas ──
            DragTarget<DragNodeData>(
              onWillAcceptWithDetails: (details) {
                debugPrint('[CANVAS] DragTarget: node hovering → type=${details.data.type} name=${details.data.sourceName}');
                return true;
              },
              onAcceptWithDetails: (details) {
                final box = context.findRenderObject() as RenderBox;
                final localPos = box.globalToLocal(details.offset);
                final inv = Matrix4.inverted(_transformCtrl.value);
                final canvasPos = MatrixUtils.transformPoint(inv, localPos);
                debugPrint('[CANVAS] DROP accepted → type=${details.data.type} name=${details.data.sourceName} screenPos=$localPos canvasPos=$canvasPos');
                ctrl.addNode(
                  details.data.type,
                  canvasPos,
                  sourceTypeValue: details.data.sourceValue,
                  sourceTypeId: details.data.sourceTypeId,
                  sourceTypeName: details.data.sourceName,
                  name: '',
                );
                debugPrint('[CANVAS] Node added → total nodes=${ctrl.nodes.length}');
              },
              onLeave: (_) => debugPrint('[CANVAS] DragTarget: node left canvas area'),
              builder: (ctx2, _, __) {
                return GestureDetector(
                  onTapDown: isConnecting
                      ? null
                      : (d) {
                          final box = ctx2.findRenderObject() as RenderBox;
                          final lp = box.globalToLocal(d.globalPosition);
                          final cp = MatrixUtils.transformPoint(
                            Matrix4.inverted(_transformCtrl.value),
                            lp,
                          );
                          debugPrint('[CANVAS] Tap → screenPos=$lp canvasPos=$cp');
                          final did = edgePainter.hitTestDisconnect(cp);
                          if (did != null) {
                            debugPrint('[CANVAS] Tap hit DISCONNECT button → edgeId=$did');
                            ctrl.removeEdge(did);
                            return;
                          }
                          final eid = edgePainter.hitTestEdge(cp);
                          if (eid != null) {
                            debugPrint('[CANVAS] Tap hit EDGE → edgeId=$eid');
                            ctrl.selectEdge(eid);
                            return;
                          }
                          debugPrint('[CANVAS] Tap hit empty canvas → deselectAll');
                          ctrl.deselectAll();
                        },
                  child: Container(
                    color: AppColors.bg,
                    child: InteractiveViewer(
                      transformationController: _transformCtrl,
                      minScale: 0.3,
                      maxScale: 2.0,
                      constrained: false,
                      boundaryMargin: const EdgeInsets.all(2000),
                      panEnabled: !isConnecting,
                      scaleEnabled: !isConnecting,
                      child: SizedBox(
                        width: 3000,
                        height: 2000,
                        child: Stack(
                          clipBehavior: Clip.none,
                          children: [
                            CustomPaint(
                              size: const Size(3000, 2000),
                              painter: _GridPainter(),
                            ),
                            CustomPaint(
                              size: const Size(3000, 2000),
                              painter: edgePainter,
                            ),
                            ...ctrl.nodes.map(
                              (n) => _CanvasNode(
                                key: ValueKey(n.id),
                                node: n,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),

            // ── 2. SCREEN-SPACE PORT OVERLAY ──
            // Rebuilt only when _transformCtrl changes, NOT the InteractiveViewer
            AnimatedBuilder(
              animation: _transformCtrl,
              builder: (_, __) => Stack(
                children: _buildPortOverlay(ctrl),
              ),
            ),

            // ── 3. Connection banner ──
            if (isConnecting)
              Positioned(
                top: 8,
                left: 0,
                right: 0,
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.amber.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: AppColors.amber.withValues(alpha: 0.4),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.cable,
                          color: AppColors.amber,
                          size: 16,
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'Tap green IN port to connect',
                          style: TextStyle(
                            color: AppColors.amber,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(width: 12),
                        InkWell(
                          onTap: () => ctrl.cancelPortDrag(),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(5),
                              border: Border.all(
                                color: AppColors.amber.withValues(alpha: 0.4),
                              ),
                            ),
                            child: const Text(
                              'Cancel',
                              style: TextStyle(
                                color: AppColors.amber,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  /// Screen-space port dots — OUTSIDE InteractiveViewer so taps always register
  List<Widget> _buildPortOverlay(PipelineController ctrl) {
    final matrix = _transformCtrl.value;
    final connecting = ctrl.portDragFromNodeId != null;
    final dots = <Widget>[];

    // Glow hint: confirmed source node + join node on canvas + no outgoing edge yet
    final hasJoinNode = ctrl.nodes.any((n) => n.type == NodeType.join);

    for (final node in ctrl.nodes) {
      // ── OUT port (blue dot, right side) ──
      {
        final sp = MatrixUtils.transformPoint(matrix, node.outPortCenter);
        final isActive = ctrl.portDragFromNodeId == node.id;
        final alreadyConnected =
            ctrl.edges.any((e) => e.fromNodeId == node.id);
        final shouldGlow = !isActive &&
            hasJoinNode &&
            node.type.isSource &&
            node.confirmState == NodeConfirmState.confirmed &&
            !alreadyConnected;

        dots.add(
          Positioned(
            left: sp.dx - 18,
            top: sp.dy - 18,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () {
                debugPrint('OUT-PORT: ${node.name}');
                if (isActive) {
                  ctrl.cancelPortDrag();
                } else {
                  ctrl.startPortDrag(node.id, Offset.zero);
                }
              },
              child: Container(
                width: 36,
                height: 36,
                color: Colors.transparent,
                child: Center(
                  child: shouldGlow
                      ? AnimatedBuilder(
                          animation: _pulseAnim,
                          builder: (_, __) {
                            final glow = _pulseAnim.value;
                            return Container(
                              width: 14 + glow * 6,
                              height: 14 + glow * 6,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: AppColors.blue,
                                border: Border.all(
                                    color: AppColors.bg, width: 2),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.blue
                                        .withValues(alpha: glow * 0.8),
                                    blurRadius: 10 + glow * 10,
                                    spreadRadius: 2 + glow * 4,
                                  ),
                                  BoxShadow(
                                    color: AppColors.blue
                                        .withValues(alpha: glow * 0.4),
                                    blurRadius: 20 + glow * 16,
                                    spreadRadius: glow * 6,
                                  ),
                                ],
                              ),
                            );
                          },
                        )
                      : Container(
                          width: isActive ? 20 : 14,
                          height: isActive ? 20 : 14,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isActive ? AppColors.amber : AppColors.blue,
                            border: Border.all(color: AppColors.bg, width: 2),
                            boxShadow: isActive
                                ? [
                                    BoxShadow(
                                      color: AppColors.amber
                                          .withValues(alpha: 0.7),
                                      blurRadius: 12,
                                      spreadRadius: 3,
                                    ),
                                  ]
                                : null,
                          ),
                        ),
                ),
              ),
            ),
          ),
        );
      }

      // ── IN port (green dot, left side) ──
      {
        final sp = MatrixUtils.transformPoint(matrix, node.inPortCenter);
        final isTarget = connecting && ctrl.portDragFromNodeId != node.id;
        dots.add(
          Positioned(
            left: sp.dx - 18,
            top: sp.dy - 18,
            child: IgnorePointer(
              ignoring: !connecting,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () {
                  debugPrint(
                    'IN-PORT: ${node.name} | from=${ctrl.portDragFromNodeId}',
                  );
                  if (ctrl.portDragFromNodeId != null) {
                    ctrl.endPortDrag(node.id);
                  }
                },
                child: Container(
                  width: 36,
                  height: 36,
                  color: Colors.transparent,
                  child: Center(
                    child: Container(
                      width: isTarget ? 20 : 14,
                      height: isTarget ? 20 : 14,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.green,
                        border: Border.all(color: AppColors.bg, width: 2),
                        boxShadow: isTarget
                            ? [
                                BoxShadow(
                                  color: AppColors.green.withValues(alpha: 0.7),
                                  blurRadius: 12,
                                  spreadRadius: 3,
                                ),
                              ]
                            : null,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      }
    }
    return dots;
  }
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// GRID PAINTER (same as HTML background-image radial-gradient dots)
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFCBD5E1).withValues(alpha: 0.5)
      ..style = PaintingStyle.fill;
    for (double x = 0; x < size.width; x += 24) {
      for (double y = 0; y < size.height; y += 24) {
        canvas.drawCircle(Offset(x, y), 1, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// CANVAS NODE (Positioned node with drag + port dots)
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

class _CanvasNode extends StatefulWidget {
  final PipelineNode node;
  const _CanvasNode({super.key, required this.node});

  @override
  State<_CanvasNode> createState() => _CanvasNodeState();
}

class _CanvasNodeState extends State<_CanvasNode>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseCtrl;
  late final Animation<double> _pulseAnim;

  // Track locally because PipelineNode is mutable — old.node and widget.node
  // are the SAME object after a mutation, so comparing them always returns equal.
  late NodeConfirmState _lastConfirmState;

  @override
  void initState() {
    super.initState();
    _lastConfirmState = widget.node.confirmState;
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _pulseAnim = Tween<double>(begin: 0.15, end: 0.55).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut),
    );
    _maybeStartPulse();
  }

  @override
  void didUpdateWidget(_CanvasNode old) {
    super.didUpdateWidget(old);
    final current = widget.node.confirmState;
    if (_lastConfirmState != current) {
      _lastConfirmState = current;
      _maybeStartPulse();
    }
  }

  void _maybeStartPulse() {
    if (widget.node.confirmState == NodeConfirmState.editing) {
      if (!_pulseCtrl.isAnimating) _pulseCtrl.repeat(reverse: true);
    } else {
      _pulseCtrl.stop();
      _pulseCtrl.value = 0;
    }
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ctrl = context.watch<PipelineController>();
    final node = widget.node;
    final isSelected = ctrl.selectedNodeId == node.id;
    final color = node.type.color;

    final isConfirmed = node.confirmState == NodeConfirmState.confirmed;
    final isEditing = node.confirmState == NodeConfirmState.editing;

    Color staticBorderColor;
    if (isConfirmed) {
      staticBorderColor = AppColors.green;
    } else if (isEditing) {
      staticBorderColor = AppColors.amber;
    } else if (isSelected) {
      staticBorderColor = color;
    } else {
      staticBorderColor = AppColors.border2;
    }

    bool nodeDragged = false;

    return Positioned(
      left: node.position.dx,
      top: node.position.dy,
      child: GestureDetector(
        onPanStart: ctrl.portDragFromNodeId == null
            ? (_) {
                nodeDragged = false;
                debugPrint('[NODE-DRAG] START → id=${node.id} name=${node.name} pos=${node.position}');
              }
            : null,
        onPanUpdate: ctrl.portDragFromNodeId == null
            ? (d) {
                nodeDragged = true;
                ctrl.moveNode(node.id, d.delta);
                debugPrint('[NODE-DRAG] UPDATE → id=${node.id} delta=${d.delta} newPos=${node.position}');
              }
            : null,
        onPanEnd: ctrl.portDragFromNodeId == null
            ? (_) {
                debugPrint('[NODE-DRAG] END → id=${node.id} finalPos=${node.position}');
                Future.delayed(
                  const Duration(milliseconds: 100),
                  () => nodeDragged = false,
                );
              }
            : null,
        child: AnimatedBuilder(
          animation: _pulseAnim,
          builder: (context, child) {
            final glowAlpha =
                isEditing ? _pulseAnim.value : (isSelected || isConfirmed ? 0.2 : 0.0);
            final borderColor = isEditing
                ? AppColors.amber.withValues(
                    alpha: 0.5 + _pulseAnim.value * 0.9,
                  )
                : staticBorderColor;

            return Stack(
              clipBehavior: Clip.none,
              children: [
                GestureDetector(
                  onTap: () {
                    if (!nodeDragged && node.type != NodeType.join) {
                      debugPrint('[NODE] TAP → id=${node.id} name=${node.name} type=${node.type}');
                      ctrl.selectNode(node.id);
                    } else {
                      debugPrint('[NODE] TAP ignored → dragged=$nodeDragged type=${node.type}');
                    }
                  },
                  child: Container(
                    width: node.nodeWidth,
                    decoration: BoxDecoration(
                      color: node.type == NodeType.join
                          ? AppColors.surface2
                          : AppColors.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: borderColor,
                        width: isConfirmed || isEditing ? 2.0 : 1.5,
                      ),
                      boxShadow: glowAlpha > 0
                          ? [
                              BoxShadow(
                                color: staticBorderColor.withValues(
                                  alpha: glowAlpha,
                                ),
                                blurRadius: isEditing
                                    ? 8 + _pulseAnim.value * 16
                                    : 12,
                                spreadRadius: isEditing
                                    ? _pulseAnim.value * 2
                                    : 0,
                              ),
                            ]
                          : null,
                    ),
                    child: child!,
                  ),
                ),
                // ── Confirmation badge ──
                if (isConfirmed)
                  Positioned(
                    top: -8,
                    right: -8,
                    child: Container(
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.green,
                        border:
                            Border.all(color: AppColors.surface, width: 2),
                      ),
                      child: const Icon(
                        Icons.check_rounded,
                        color: Colors.white,
                        size: 11,
                      ),
                    ),
                  ),
                // ── Editing badge (pulses with animation) ──
                if (isEditing)
                  Positioned(
                    top: -8,
                    right: -8,
                    child: AnimatedBuilder(
                      animation: _pulseAnim,
                      builder: (_, __) => Container(
                        width: 20,
                        height: 20,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.amber.withValues(
                            alpha: 0.6 + _pulseAnim.value * 0.4,
                          ),
                          border: Border.all(
                            color: AppColors.surface,
                            width: 2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.amber.withValues(
                                alpha: _pulseAnim.value * 0.6,
                              ),
                              blurRadius: 6,
                              spreadRadius: 1,
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.edit_rounded,
                          color: Colors.white,
                          size: 10,
                        ),
                      ),
                    ),
                  ),
              ],
            );
          },
          child: _buildBody(context),
        ),
      ),
    );
  }

  Widget _buildBody(BuildContext context) {
    final node = widget.node;
    switch (node.type) {
      case NodeType.join:
        return JoinNodeBody(node: node);
      case NodeType.output:
        return OutputNodeBody(node: node);
      default:
        return SourceNodeBody(node: node);
    }
  }
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// TOP BAR (same as HTML .topbar)
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
