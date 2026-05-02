import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../models/pipeline_models.dart';
import '../controllers/pipeline_controller.dart';
import '../services/master_data_service.dart';
import 'edge_painter.dart';
import 'nodes/source_node_body.dart';
import 'nodes/join_node_body.dart';
import 'edit_sidebar.dart';
import 'config_panel.dart';
import 'status_bar.dart';

class EditPipelineCanvasPage extends StatefulWidget {
  const EditPipelineCanvasPage({super.key});

  @override
  State<EditPipelineCanvasPage> createState() => _EditPipelineCanvasPageState();
}

class _EditPipelineCanvasPageState extends State<EditPipelineCanvasPage>
    with TickerProviderStateMixin {
  final _transformCtrl = TransformationController();
  late final AnimationController _pulseCtrl;
  late final Animation<double> _pulseAnim;

  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..repeat(reverse: true);
    _pulseAnim = Tween<double>(
      begin: 0.25,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    _transformCtrl.dispose();
    super.dispose();
  }

  Future<void> _fetchAndLoad(int templateId, int deptId) async {
    final ctrl = context.read<PipelineController>();
    final service = context.read<MasterDataService>();

    setState(() => _errorMessage = null);

    final config = await service.getTemplateConfig(
      templateId: templateId,
      deptId: deptId,
    );

    if (!mounted) return;

    if (config == null) {
      setState(
        () => _errorMessage =
            'Could not load configuration. Please check the template and try again.',
      );
      return;
    }

    ctrl.loadConfiguration(config);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: Row(
            children: [
              Flexible(
                flex: 0,
                child: EditSidebar(onFetchConfig: _fetchAndLoad),
              ),
              Expanded(child: _buildCanvas()),
              Consumer<PipelineController>(
                builder: (_, ctrl, __) => ctrl.selectedNodeId != null
                    ? const Flexible(flex: 0, child: ConfigPanel())
                    : const SizedBox.shrink(),
              ),
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
            // ── Canvas ──
            DragTarget<DragNodeData>(
              onWillAcceptWithDetails: (_) => true,
              onAcceptWithDetails: (details) {
                final box = context.findRenderObject() as RenderBox;
                final localPos = box.globalToLocal(details.offset);
                final inv = Matrix4.inverted(_transformCtrl.value);
                final canvasPos = MatrixUtils.transformPoint(inv, localPos);
                ctrl.addNode(details.data.type, canvasPos);
              },
              builder: (ctx2, _, __) => GestureDetector(
                onTapDown: isConnecting
                    ? null
                    : (d) {
                        final box = ctx2.findRenderObject() as RenderBox;
                        final lp = box.globalToLocal(d.globalPosition);
                        final cp = MatrixUtils.transformPoint(
                          Matrix4.inverted(_transformCtrl.value),
                          lp,
                        );
                        final did = edgePainter.hitTestDisconnect(cp);
                        if (did != null) {
                          ctrl.removeEdge(did);
                          return;
                        }
                        final eid = edgePainter.hitTestEdge(cp);
                        if (eid != null) {
                          ctrl.selectEdge(eid);
                          return;
                        }
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
                            (n) =>
                                _CanvasEditNode(key: ValueKey(n.id), node: n),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // ── Port overlay ──
            AnimatedBuilder(
              animation: _transformCtrl,
              builder: (_, __) => Stack(children: _buildPortOverlay(ctrl)),
            ),

            // ── Empty state / error banner ──
            if (ctrl.nodes.isEmpty && _errorMessage == null)
              _EmptyHint(pulseAnim: _pulseAnim),

            if (_errorMessage != null)
              _ErrorBanner(
                message: _errorMessage!,
                onDismiss: () => setState(() => _errorMessage = null),
              ),

            // ── Connecting banner ──
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

  List<Widget> _buildPortOverlay(PipelineController ctrl) {
    final matrix = _transformCtrl.value;
    final connecting = ctrl.portDragFromNodeId != null;
    final dots = <Widget>[];

    for (final node in ctrl.nodes) {
      // OUT port
      {
        final sp = MatrixUtils.transformPoint(matrix, node.outPortCenter);
        final isActive = ctrl.portDragFromNodeId == node.id;
        dots.add(
          Positioned(
            left: sp.dx - 18,
            top: sp.dy - 18,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () {
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
                  child: Container(
                    width: isActive ? 20 : 14,
                    height: isActive ? 20 : 14,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isActive ? AppColors.amber : AppColors.blue,
                      border: Border.all(color: AppColors.bg, width: 2),
                      boxShadow: isActive
                          ? [
                              BoxShadow(
                                color: AppColors.amber.withValues(alpha: 0.7),
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

      // IN port
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

// ── Grid painter ──
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
  bool shouldRepaint(covariant CustomPainter _) => false;
}

// ── Empty state hint ──
class _EmptyHint extends StatelessWidget {
  final Animation<double> pulseAnim;
  const _EmptyHint({required this.pulseAnim});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: AnimatedBuilder(
        animation: pulseAnim,
        builder: (_, __) => Opacity(
          opacity: 0.4 + pulseAnim.value * 0.4,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.cloud_download_outlined,
                size: 48,
                color: AppColors.blue.withValues(alpha: 0.6),
              ),
              const SizedBox(height: 12),
              const Text(
                'Select a department and template,\nthen tap Load Configuration.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  color: AppColors.textDim,
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Error banner ──
class _ErrorBanner extends StatelessWidget {
  final String message;
  final VoidCallback onDismiss;
  const _ErrorBanner({required this.message, required this.onDismiss});

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 12,
      left: 24,
      right: 24,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.red.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.red.withValues(alpha: 0.4)),
        ),
        child: Row(
          children: [
            const Icon(Icons.error_outline, color: AppColors.red, size: 16),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  color: AppColors.red,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            InkWell(
              onTap: onDismiss,
              child: const Icon(Icons.close, color: AppColors.red, size: 14),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Canvas node (mirrors PipelineCanvasPage._CanvasNode with typed PipelineNode) ──
class _CanvasEditNode extends StatefulWidget {
  final PipelineNode node;
  const _CanvasEditNode({super.key, required this.node});

  @override
  State<_CanvasEditNode> createState() => _CanvasEditNodeState();
}

class _CanvasEditNodeState extends State<_CanvasEditNode>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseCtrl;
  late final Animation<double> _pulseAnim;
  late NodeConfirmState _lastConfirmState;

  @override
  void initState() {
    super.initState();
    _lastConfirmState = widget.node.confirmState;
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _pulseAnim = Tween<double>(
      begin: 0.15,
      end: 0.55,
    ).animate(CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));
    _maybeStartPulse();
  }

  @override
  void didUpdateWidget(_CanvasEditNode old) {
    super.didUpdateWidget(old);
    if (_lastConfirmState != widget.node.confirmState) {
      _lastConfirmState = widget.node.confirmState;
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
              }
            : null,
        onPanUpdate: ctrl.portDragFromNodeId == null
            ? (d) {
                nodeDragged = true;
                ctrl.moveNode(node.id, d.delta);
              }
            : null,
        onPanEnd: ctrl.portDragFromNodeId == null
            ? (_) {
                Future.delayed(
                  const Duration(milliseconds: 100),
                  () => nodeDragged = false,
                );
              }
            : null,
        child: AnimatedBuilder(
          animation: _pulseAnim,
          builder: (context, child) {
            final glowAlpha = isEditing
                ? _pulseAnim.value
                : (isSelected || isConfirmed ? 0.2 : 0.0);
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
                      ctrl.selectNode(node.id);
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
                        border: Border.all(color: AppColors.surface, width: 2),
                      ),
                      child: const Icon(
                        Icons.check_rounded,
                        color: Colors.white,
                        size: 11,
                      ),
                    ),
                  ),
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
      default:
        return SourceNodeBody(node: node);
    }
  }
}
