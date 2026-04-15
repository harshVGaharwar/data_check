import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../models/pipeline_models.dart';
import '../controllers/pipeline_controller.dart';

// ── Source color palette ─────────────────────────────────────────────────────
const _palette = [
  Color(0xFF10B981),
  Color(0xFF3B82F6),
  Color(0xFFEF4444),
  Color(0xFFEC4899),
  Color(0xFFF59E0B),
  Color(0xFF8B5CF6),
  Color(0xFF06B6D4),
];

Color _srcColor(int index) => _palette[index % _palette.length];

// ── Operator → human label ───────────────────────────────────────────────────
const _opLabel = {
  '=': 'equals',
  '!=': 'not equal',
  '>': 'greater',
  '<': 'less',
  '>=': 'gte',
  '<=': 'lte',
  'LIKE': 'like',
  'contains': 'contains',
  'startsWith': 'starts with',
};

// ── Entry point ──────────────────────────────────────────────────────────────

/// Shows the mapping preview dialog.
/// Returns `true` if user confirmed, `false`/`null` if they pressed Edit.
Future<bool?> showMappingPreview(
  BuildContext context, {
  required PipelineController ctrl,
  required List<PipelineNode> sourceNodes,
}) {
  return showDialog<bool>(
    context: context,
    barrierColor: Colors.black.withValues(alpha: 0.6),
    builder: (_) => _MappingPreviewDialog(ctrl: ctrl, sourceNodes: sourceNodes),
  );
}

// ── Dialog shell ─────────────────────────────────────────────────────────────

class _MappingPreviewDialog extends StatelessWidget {
  final PipelineController ctrl;
  final List<PipelineNode> sourceNodes;

  const _MappingPreviewDialog({required this.ctrl, required this.sourceNodes});

  @override
  Widget build(BuildContext context) {
    final templateName = ctrl.sidebarTemplate;
    final templateId = ctrl.sidebarTemplateId;
    final deptId = ctrl.sidebarDeptId;
    final joinNodes = ctrl.nodes.where((n) => n.type == NodeType.join).toList();

    // Source index map for consistent color lookup
    final srcIndex = {
      for (var i = 0; i < sourceNodes.length; i++) sourceNodes[i].id: i,
    };

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: Container(
        width: double.infinity,
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.88,
        ),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Header ──────────────────────────────────────────────────────
            _Header(
              templateName: templateName,
              templateId: templateId,
              deptId: deptId,
            ),

            // ── Step tracker ─────────────────────────────────────────────────
            const _StepTracker(),

            // ── Scrollable body ───────────────────────────────────────────────
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Source cards
                    const _SectionLabel('SOURCE NODES'),
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 200,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: sourceNodes.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 10),
                        itemBuilder: (_, i) => _SourceCard(
                          node: sourceNodes[i],
                          color: _srcColor(i),
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Join operation card
                    for (final j in joinNodes) ...[
                      const _SectionLabel('JOIN OPERATION'),
                      const SizedBox(height: 8),
                      _JoinCard(
                        joinNode: j,
                        sourceNodes: sourceNodes,
                        srcIndex: srcIndex,
                        ctrl: ctrl,
                      ),
                      const SizedBox(height: 12),
                    ],

                    // Data flow funnel
                    const _SectionLabel('DATA FLOW'),
                    const SizedBox(height: 8),
                    _DataFlowFunnel(
                      sourceNodes: sourceNodes,
                      srcIndex: srcIndex,
                    ),
                  ],
                ),
              ),
            ),

            // ── Action buttons ────────────────────────────────────────────────
            _ActionRow(
              onEdit: () => Navigator.of(context).pop(false),
              onConfirm: () => Navigator.of(context).pop(true),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Header ────────────────────────────────────────────────────────────────────

class _Header extends StatelessWidget {
  final String templateName;
  final int templateId;
  final String deptId;
  const _Header({
    required this.templateName,
    required this.templateId,
    required this.deptId,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 14),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              color: AppColors.violet.withValues(alpha: 0.15),
            ),
            child: const Icon(
              Icons.account_tree_rounded,
              color: AppColors.violet,
              size: 18,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  templateName.isNotEmpty
                      ? templateName
                      : 'Template Configuration',
                  style: const TextStyle(
                    color: AppColors.text,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'ID: $templateId  ·  Dept: $deptId',
                  style: const TextStyle(
                    color: AppColors.textDim,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              color: AppColors.violet.withValues(alpha: 0.12),
              border: Border.all(
                color: AppColors.violet.withValues(alpha: 0.25),
              ),
            ),
            child: const Text(
              'Review',
              style: TextStyle(
                color: AppColors.violet,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Step tracker ──────────────────────────────────────────────────────────────

class _StepTracker extends StatelessWidget {
  const _StepTracker();

  @override
  Widget build(BuildContext context) {
    const steps = ['Sources', 'Columns', 'Join', 'Review'];
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        children: List.generate(steps.length * 2 - 1, (i) {
          if (i.isOdd) {
            // connector line
            final done = i < 6; // steps 0-2 done
            return Expanded(
              child: Container(
                height: 2,
                color: done
                    ? AppColors.green.withValues(alpha: 0.5)
                    : AppColors.border2,
              ),
            );
          }
          final idx = i ~/ 2;
          final isLast = idx == steps.length - 1;
          final isDone = idx < steps.length - 1;
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 26,
                height: 26,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isLast
                      ? AppColors.violet
                      : isDone
                      ? AppColors.green
                      : AppColors.surface2,
                  border: Border.all(
                    color: isLast
                        ? AppColors.violet
                        : isDone
                        ? AppColors.green
                        : AppColors.border2,
                  ),
                ),
                child: Center(
                  child: isDone
                      ? const Icon(Icons.check, color: Colors.white, size: 13)
                      : Text(
                          '${idx + 1}',
                          style: TextStyle(
                            color: isLast ? Colors.white : AppColors.textDim,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                steps[idx],
                style: TextStyle(
                  color: isLast
                      ? AppColors.violet
                      : isDone
                      ? AppColors.green
                      : AppColors.textMuted,
                  fontSize: 9,
                  fontWeight: isLast ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            ],
          );
        }),
      ),
    );
  }
}

// ── Source card ───────────────────────────────────────────────────────────────

class _SourceCard extends StatelessWidget {
  final PipelineNode node;
  final Color color;
  const _SourceCard({required this.node, required this.color});

  @override
  Widget build(BuildContext context) {
    final sepLabel = _sepLabel(node.separator);
    return Container(
      width: 190,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: AppColors.bg,
        border: Border.all(color: AppColors.border2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Color-coded top bar
          Container(
            height: 4,
            decoration: BoxDecoration(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(12),
              ),
              color: color,
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Name row
                Row(
                  children: [
                    Container(
                      width: 7,
                      height: 7,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: color,
                      ),
                    ),
                    const SizedBox(width: 5),
                    Expanded(
                      child: Text(
                        node.name,
                        style: const TextStyle(
                          color: AppColors.text,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 5,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(4),
                        color: color.withValues(alpha: 0.12),
                        border: Border.all(color: color.withValues(alpha: 0.3)),
                      ),
                      child: Text(
                        sepLabel,
                        style: TextStyle(
                          color: color,
                          fontSize: 8,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                _infoRow(
                  Icons.storage_rounded,
                  'Type',
                  node.sourceTypeName.isNotEmpty
                      ? node.sourceTypeName
                      : node.type.label,
                ),
                const SizedBox(height: 4),
                _infoRow(
                  Icons.attach_file_rounded,
                  'Column file',
                  node.fileName ?? 'Not uploaded',
                  mono: true,
                ),
                const SizedBox(height: 4),
                _infoRow(
                  Icons.description_outlined,
                  'Query file',
                  node.queryFileName ?? 'Not configured',
                  dim: node.queryFileName == null,
                ),
                const SizedBox(height: 8),
                // Column chips
                if (node.selectedCols.isNotEmpty) ...[
                  Text(
                    '${node.selectedCols.length} cols selected',
                    style: const TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 9,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Wrap(
                    spacing: 3,
                    runSpacing: 3,
                    children: node.selectedCols
                        .take(6)
                        .map(
                          (c) => Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 5,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(4),
                              color: color.withValues(alpha: 0.1),
                              border: Border.all(
                                color: color.withValues(alpha: 0.25),
                              ),
                            ),
                            child: Text(
                              c,
                              style: TextStyle(
                                color: color,
                                fontSize: 8,
                                fontFamily: 'monospace',
                              ),
                            ),
                          ),
                        )
                        .toList(),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoRow(
    IconData icon,
    String label,
    String value, {
    bool mono = false,
    bool dim = false,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 10, color: AppColors.textMuted),
        const SizedBox(width: 4),
        Expanded(
          child: RichText(
            text: TextSpan(
              children: [
                TextSpan(
                  text: '$label  ',
                  style: const TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 9,
                  ),
                ),
                TextSpan(
                  text: value,
                  style: TextStyle(
                    color: dim ? AppColors.textMuted : AppColors.textDim,
                    fontSize: 9,
                    fontStyle: dim ? FontStyle.italic : FontStyle.normal,
                    fontFamily: mono ? 'monospace' : null,
                  ),
                ),
              ],
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  String _sepLabel(String sep) {
    switch (sep) {
      case ',':
        return 'comma ,';
      case '|':
        return 'pipe |';
      case '\t':
        return 'tab \\t';
      case ';':
        return 'semi ;';
      case ' ':
        return 'space';
      default:
        return sep;
    }
  }
}

// ── Join card ─────────────────────────────────────────────────────────────────

class _JoinCard extends StatelessWidget {
  final PipelineNode joinNode;
  final List<PipelineNode> sourceNodes;
  final Map<String, int> srcIndex;
  final PipelineController ctrl;

  const _JoinCard({
    required this.joinNode,
    required this.sourceNodes,
    required this.srcIndex,
    required this.ctrl,
  });

  @override
  Widget build(BuildContext context) {
    final validMappings = joinNode.mappings.where((m) => m.isValid).toList();

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: AppColors.bg,
        border: Border.all(color: AppColors.violet.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Card header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(12),
              ),
              color: AppColors.violet.withValues(alpha: 0.08),
              border: Border(
                bottom: BorderSide(
                  color: AppColors.violet.withValues(alpha: 0.15),
                ),
              ),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.link_rounded,
                  color: AppColors.violet,
                  size: 16,
                ),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'Join Operation',
                    style: TextStyle(
                      color: AppColors.violet,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                Text(
                  joinNode.id,
                  style: const TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Source pills row
                Wrap(
                  spacing: 4,
                  runSpacing: 4,
                  children: [
                    for (var i = 0; i < sourceNodes.length; i++) ...[
                      if (i > 0)
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 2),
                          child: Text(
                            'ON',
                            style: TextStyle(
                              color: AppColors.textMuted,
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      _sourcePill(sourceNodes[i], _srcColor(i)),
                    ],
                  ],
                ),

                if (validMappings.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  const Divider(color: AppColors.border2, height: 1),
                  const SizedBox(height: 10),
                  ...validMappings.asMap().entries.map(
                    (e) => _MappingRow(
                      idx: e.key,
                      mapping: e.value,
                      srcIndex: srcIndex,
                      ctrl: ctrl,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _sourcePill(PipelineNode src, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: color.withValues(alpha: 0.1),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(shape: BoxShape.circle, color: color),
          ),
          const SizedBox(width: 5),
          Text(
            src.name,
            style: TextStyle(
              color: color,
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Mapping row ───────────────────────────────────────────────────────────────

class _MappingRow extends StatelessWidget {
  final int idx;
  final ColumnMapping mapping;
  final Map<String, int> srcIndex;
  final PipelineController ctrl;

  const _MappingRow({
    required this.idx,
    required this.mapping,
    required this.srcIndex,
    required this.ctrl,
  });

  @override
  Widget build(BuildContext context) {
    final lSrc = ctrl.findNode(mapping.leftSourceId);
    final rSrc = ctrl.findNode(mapping.rightSourceId);
    final lColor = _srcColor(srcIndex[lSrc?.id] ?? 0);
    final rColor = _srcColor(srcIndex[rSrc?.id] ?? 1);
    final op = mapping.operationValue;
    final opText = _opLabel[op] ?? op;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          // Index
          Container(
            width: 18,
            height: 18,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.violet.withValues(alpha: 0.12),
            ),
            child: Center(
              child: Text(
                '${idx + 1}',
                style: const TextStyle(
                  color: AppColors.violet,
                  fontSize: 8,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          const SizedBox(width: 6),

          // Left column chip
          _colChip(mapping.leftCol, lColor),
          const SizedBox(width: 4),
          // Left source tag
          _srcTag(lSrc?.name ?? '?', lColor),

          const SizedBox(width: 6),
          // Operator badge
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.violet,
                ),
                child: Center(
                  child: Text(
                    op,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                opText,
                style: const TextStyle(color: AppColors.textMuted, fontSize: 8),
              ),
            ],
          ),
          const SizedBox(width: 6),

          // Right source tag
          _srcTag(rSrc?.name ?? '?', rColor),
          const SizedBox(width: 4),
          // Right column chip
          _colChip(mapping.rightCol, rColor),
        ],
      ),
    );
  }

  Widget _colChip(String col, Color color) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(5),
      color: color.withValues(alpha: 0.12),
      border: Border.all(color: color.withValues(alpha: 0.3)),
    ),
    child: Text(
      col,
      style: TextStyle(
        color: color,
        fontSize: 9,
        fontWeight: FontWeight.w600,
        fontFamily: 'monospace',
      ),
    ),
  );

  Widget _srcTag(String name, Color color) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(4),
      color: AppColors.surface2,
      border: Border.all(color: AppColors.border2),
    ),
    child: Text(
      name,
      style: const TextStyle(
        color: AppColors.textDim,
        fontSize: 8,
        fontWeight: FontWeight.w500,
      ),
    ),
  );
}

// ── Data flow funnel ──────────────────────────────────────────────────────────

class _DataFlowFunnel extends StatelessWidget {
  final List<PipelineNode> sourceNodes;
  final Map<String, int> srcIndex;
  const _DataFlowFunnel({required this.sourceNodes, required this.srcIndex});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: AppColors.bg,
        border: Border.all(color: AppColors.border2),
      ),
      child: Column(
        children: [
          // Source boxes row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: sourceNodes.asMap().entries.map((e) {
              final color = _srcColor(e.key);
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      color: color.withValues(alpha: 0.1),
                      border: Border.all(color: color.withValues(alpha: 0.4)),
                    ),
                    child: Text(
                      e.value.name,
                      style: TextStyle(
                        color: color,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  Container(
                    width: 2,
                    height: 20,
                    color: color.withValues(alpha: 0.4),
                  ),
                ],
              );
            }).toList(),
          ),

          // Converging line + join box
          CustomPaint(
            size: const Size(double.infinity, 20),
            painter: _FunnelLinePainter(count: sourceNodes.length),
          ),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              color: AppColors.violet.withValues(alpha: 0.12),
              border: Border.all(
                color: AppColors.violet.withValues(alpha: 0.4),
              ),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.link_rounded, color: AppColors.violet, size: 14),
                SizedBox(width: 6),
                Text(
                  'Join',
                  style: TextStyle(
                    color: AppColors.violet,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FunnelLinePainter extends CustomPainter {
  final int count;
  const _FunnelLinePainter({required this.count});

  @override
  void paint(Canvas canvas, Size size) {
    if (count == 0) return;
    final paint = Paint()
      ..color = AppColors.violet.withValues(alpha: 0.35)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    final centerX = size.width / 2;
    final step = count > 1 ? size.width / count : 0.0;

    for (int i = 0; i < count; i++) {
      final srcX = step * i + step / 2;
      final path = Path()
        ..moveTo(srcX, 0)
        ..quadraticBezierTo(srcX, size.height * 0.6, centerX, size.height);
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(_FunnelLinePainter old) => old.count != count;
}

// ── Action buttons ────────────────────────────────────────────────────────────

class _ActionRow extends StatelessWidget {
  final VoidCallback onEdit;
  final VoidCallback onConfirm;
  const _ActionRow({required this.onEdit, required this.onConfirm});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        children: [
          // Edit button
          Expanded(
            child: InkWell(
              onTap: onEdit,
              borderRadius: BorderRadius.circular(10),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 11),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.border2),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.edit_rounded,
                      size: 14,
                      color: AppColors.textDim,
                    ),
                    SizedBox(width: 6),
                    Text(
                      'Edit Mappings',
                      style: TextStyle(
                        color: AppColors.textDim,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          // Confirm button
          Expanded(
            flex: 2,
            child: InkWell(
              onTap: onConfirm,
              borderRadius: BorderRadius.circular(10),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 11),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  gradient: LinearGradient(
                    colors: [
                      AppColors.green,
                      AppColors.green.withValues(alpha: 0.8),
                    ],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.green.withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.check_circle_rounded,
                      size: 15,
                      color: Colors.white,
                    ),
                    SizedBox(width: 6),
                    Text(
                      'Confirm & Submit',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Helpers ───────────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) => Text(
    text,
    style: const TextStyle(
      color: AppColors.textMuted,
      fontSize: 9,
      fontWeight: FontWeight.w700,
      letterSpacing: 0.8,
    ),
  );
}
