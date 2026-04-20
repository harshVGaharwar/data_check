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

class _MappingPreviewDialog extends StatefulWidget {
  final PipelineController ctrl;
  final List<PipelineNode> sourceNodes;

  const _MappingPreviewDialog({required this.ctrl, required this.sourceNodes});

  @override
  State<_MappingPreviewDialog> createState() => _MappingPreviewDialogState();
}

class _MappingPreviewDialogState extends State<_MappingPreviewDialog> {
  final _scrollCtrl = ScrollController();
  bool _headerVisible = true;

  @override
  void initState() {
    super.initState();
    _scrollCtrl.addListener(() {
      final shouldShow = _scrollCtrl.offset < 10;
      if (shouldShow != _headerVisible) {
        setState(() => _headerVisible = shouldShow);
      }
    });
  }

  @override
  void dispose() {
    _scrollCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ctrl = widget.ctrl;
    final sourceNodes = widget.sourceNodes;
    final templateName = ctrl.sidebarTemplate;
    final templateId = ctrl.sidebarTemplateId;
    final deptId = ctrl.sidebarDeptId;
    final joinNodes = ctrl.nodes.where((n) => n.type == NodeType.join).toList();

    // Source index map for consistent color lookup
    final srcIndex = {
      for (var i = 0; i < sourceNodes.length; i++) sourceNodes[i].id: i,
    };

    final confirmEnabled = sourceNodes
        .where((n) => n.cols.isNotEmpty)
        .any((n) => n.columnAliases.values.any((v) => v.trim().isNotEmpty));

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.zero,
      child: Container(
        width: double.infinity,
        height: double.infinity,
        color: AppColors.bg,
        child: Column(
          children: [
            // ── Top bar ──────────────────────────────────────────────────────
            Container(
              color: AppColors.surface,
              child: Column(
                children: [
                  AnimatedCrossFade(
                    firstChild: _Header(
                      templateName: templateName,
                      templateId: templateId,
                      deptId: deptId,
                    ),
                    secondChild: const SizedBox(width: double.infinity),
                    crossFadeState: _headerVisible
                        ? CrossFadeState.showFirst
                        : CrossFadeState.showSecond,
                    duration: const Duration(milliseconds: 220),
                    sizeCurve: Curves.easeInOut,
                  ),
                  const _StepTracker(),
                ],
              ),
            ),

            // ── Scrollable page body ──────────────────────────────────────────
            Expanded(
              child: SingleChildScrollView(
                controller: _scrollCtrl,
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // ── Output Format section ──
                    if (sourceNodes.any((n) => n.cols.isNotEmpty)) ...[
                      _SectionCard(
                        title: 'Output Format Selection',
                        icon: Icons.tune_rounded,
                        accentColor: confirmEnabled
                            ? AppColors.blue
                            : AppColors.red,
                        badge:
                            '${sourceNodes.where((n) => n.cols.isNotEmpty).length} sources',
                        selected: true,
                        child: Column(
                          children: [
                            for (final src in sourceNodes.where(
                              (n) => n.cols.isNotEmpty,
                            )) ...[
                              _OutputFormatCard(node: src, ctrl: ctrl),
                              if (src !=
                                  sourceNodes
                                      .where((n) => n.cols.isNotEmpty)
                                      .last)
                                const SizedBox(height: 12),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],

                    // ── Source Nodes section ──
                    _SectionCard(
                      title: 'Source Nodes',
                      icon: Icons.storage_rounded,
                      accentColor: AppColors.green,
                      badge: '${sourceNodes.length} sources',
                      child: SizedBox(
                        height: 218,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: sourceNodes.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(width: 14),
                          itemBuilder: (_, i) => _SourceCard(
                            node: sourceNodes[i],
                            color: _srcColor(i),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // ── Join Operation section ──
                    for (final j in joinNodes) ...[
                      _SectionCard(
                        title: 'Join Operation',
                        icon: Icons.merge_type_rounded,
                        accentColor: AppColors.violet,
                        badge:
                            '${j.mappings.where((m) => m.isValid).length} conditions',
                        child: _JoinCard(
                          joinNode: j,
                          sourceNodes: sourceNodes,
                          srcIndex: srcIndex,
                          ctrl: ctrl,
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                  ],
                ),
              ),
            ),

            // ── Bottom action bar ─────────────────────────────────────────────
            Container(
              color: AppColors.surface,
              child: _ActionRow(
                onEdit: () => Navigator.of(context).pop(false),
                onConfirm: () => Navigator.of(context).pop(true),
                confirmEnabled: confirmEnabled,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Section card ─────────────────────────────────────────────────────────────

class _SectionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color accentColor;
  final Widget child;
  final String? badge;
  final bool selected;
  final VoidCallback? onTap;

  const _SectionCard({
    required this.title,
    required this.icon,
    required this.accentColor,
    required this.child,
    this.badge,
    this.onTap,
    this.selected = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: selected
              ? accentColor.withValues(alpha: 0.04)
              : AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? accentColor : AppColors.border,
            width: selected ? 1.8 : 1.0,
          ),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: accentColor.withValues(alpha: 0.18),
                    blurRadius: 14,
                    offset: const Offset(0, 4),
                  ),
                ]
              : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Section header ──
            Container(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(16),
                ),
                color: accentColor.withValues(alpha: 0.05),
                border: Border(bottom: BorderSide(color: AppColors.border)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: accentColor.withValues(alpha: 0.13),
                    ),
                    child: Icon(icon, size: 15, color: accentColor),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    title,
                    style: const TextStyle(
                      color: AppColors.text,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (badge != null) ...[
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 9,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        color: accentColor.withValues(alpha: 0.10),
                        border: Border.all(
                          color: accentColor.withValues(alpha: 0.25),
                        ),
                      ),
                      child: Text(
                        badge!,
                        style: TextStyle(
                          color: accentColor,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            // ── Section body ──
            Padding(padding: const EdgeInsets.all(16), child: child),
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
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // ── Icon ──
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: AppColors.violet.withValues(alpha: 0.12),
              border: Border.all(
                color: AppColors.violet.withValues(alpha: 0.22),
              ),
            ),
            child: const Icon(
              Icons.account_tree_rounded,
              color: AppColors.violet,
              size: 20,
            ),
          ),
          const SizedBox(width: 14),

          // ── Titles ──
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Page purpose label
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 7,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(5),
                        color: AppColors.violet.withValues(alpha: 0.10),
                      ),
                      child: const Text(
                        'MAPPING PREVIEW',
                        style: TextStyle(
                          color: AppColors.violet,
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 5),
                // Template name — main heading
                Text(
                  templateName.isNotEmpty ? templateName : 'Unnamed Template',
                  style: const TextStyle(
                    color: Color(0xFF0F172A),
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 3),
                // Meta info
                Text(
                  'Template ID: $templateId  ·  Dept: $deptId',
                  style: const TextStyle(
                    color: Color(0xFF64748B),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),

          // ── Review badge ──
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              color: AppColors.violet,
              boxShadow: [
                BoxShadow(
                  color: AppColors.violet.withValues(alpha: 0.30),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.checklist_rounded, size: 13, color: Colors.white),
                SizedBox(width: 5),
                Text(
                  'Review & Submit',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 11,
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

// ── Step tracker ──────────────────────────────────────────────────────────────

class _StepTracker extends StatelessWidget {
  const _StepTracker();

  @override
  Widget build(BuildContext context) {
    const steps = [
      'Output Format',
      'Data Sources',
      'Column Selection',
      'Join Conditions',
      'Review & Submit',
    ];
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
    final initial = node.name.isNotEmpty ? node.name[0].toUpperCase() : '?';
    final sepLabel = _sepLabel(node.separator);
    final hasFile = node.fileName != null;
    final hasQuery = node.queryFileName != null;
    final typeLabel = node.sourceTypeName.isNotEmpty
        ? node.sourceTypeName
        : node.type.label;

    return Container(
      width: 200,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: AppColors.surface,
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.12),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Left accent bar ──
          Container(
            width: 4,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [color, color.withValues(alpha: 0.45)],
              ),
            ),
          ),

          // ── Card body ──
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(11, 12, 11, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Header: avatar + name + sep badge ──
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: color.withValues(alpha: 0.14),
                          border: Border.all(
                            color: color.withValues(alpha: 0.30),
                            width: 1.5,
                          ),
                        ),
                        child: Center(
                          child: Text(
                            initial,
                            style: TextStyle(
                              color: color,
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              node.name,
                              style: const TextStyle(
                                color: AppColors.text,
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              typeLabel,
                              style: const TextStyle(
                                color: AppColors.textMuted,
                                fontSize: 9,
                                fontWeight: FontWeight.w500,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 6),

                  // Sep badge — right-aligned
                  Align(
                    alignment: Alignment.centerRight,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 7,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(6),
                        color: color.withValues(alpha: 0.10),
                        border: Border.all(
                          color: color.withValues(alpha: 0.28),
                        ),
                      ),
                      child: Text(
                        sepLabel,
                        style: TextStyle(
                          color: color,
                          fontSize: 8,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.2,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 8),
                  Container(height: 1, color: AppColors.border),
                  const SizedBox(height: 8),

                  // ── File metadata ──
                  _fileRow(
                    icon: Icons.table_rows_rounded,
                    filename: hasFile ? node.fileName! : 'No file uploaded',
                    badge: hasFile ? '${node.cols.length} cols' : null,
                    active: hasFile,
                    color: color,
                  ),
                  const SizedBox(height: 5),
                  _fileRow(
                    icon: Icons.code_rounded,
                    filename: hasQuery ? node.queryFileName! : 'No query file',
                    active: hasQuery,
                    color: color,
                  ),

                  // ── Column chips ──
                  if (node.selectedCols.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Container(height: 1, color: AppColors.border),
                    const SizedBox(height: 7),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(6),
                            color: color,
                          ),
                          child: Text(
                            '${node.selectedCols.length} selected',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 8,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        if (node.cols.length > node.selectedCols.length) ...[
                          const SizedBox(width: 5),
                          Text(
                            'of ${node.cols.length}',
                            style: const TextStyle(
                              color: AppColors.textMuted,
                              fontSize: 8,
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 5),
                    Wrap(
                      spacing: 3,
                      runSpacing: 3,
                      children: [
                        ...node.selectedCols
                            .take(3)
                            .map(
                              (c) => Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 5,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(5),
                                  color: color.withValues(alpha: 0.09),
                                  border: Border.all(
                                    color: color.withValues(alpha: 0.22),
                                  ),
                                ),
                                child: Text(
                                  c,
                                  style: TextStyle(
                                    color: color,
                                    fontSize: 8,
                                    fontFamily: AppTextStyles.monoFamily,
                                  ),
                                ),
                              ),
                            ),
                        if (node.selectedCols.length > 3)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 5,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(5),
                              color: AppColors.surface2,
                              border: Border.all(color: AppColors.border2),
                            ),
                            child: Text(
                              '+${node.selectedCols.length - 3}',
                              style: const TextStyle(
                                color: AppColors.textMuted,
                                fontSize: 8,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _fileRow({
    required IconData icon,
    required String filename,
    required bool active,
    required Color color,
    String? badge,
  }) {
    return Row(
      children: [
        Icon(
          icon,
          size: 11,
          color: active ? color.withValues(alpha: 0.8) : AppColors.textMuted,
        ),
        const SizedBox(width: 5),
        Expanded(
          child: Text(
            filename,
            style: TextStyle(
              color: active ? AppColors.textDim : AppColors.textMuted,
              fontSize: 9,
              fontStyle: active ? FontStyle.normal : FontStyle.italic,
              fontFamily: active ? AppTextStyles.monoFamily : null,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        if (badge != null) ...[
          const SizedBox(width: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(4),
              color: color.withValues(alpha: 0.12),
            ),
            child: Text(
              badge,
              style: TextStyle(
                color: color,
                fontSize: 8,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Source connector row ──
        Row(
          children: [
            for (var i = 0; i < sourceNodes.length; i++) ...[
              if (i > 0)
                Expanded(
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Container(height: 1.5, color: AppColors.border2),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: AppColors.violet.withValues(alpha: 0.35),
                          ),
                        ),
                        child: const Text(
                          'JOIN',
                          style: TextStyle(
                            color: AppColors.violet,
                            fontSize: 7,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.6,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              _sourceNode(sourceNodes[i], _srcColor(i)),
            ],
          ],
        ),

        // ── Condition rows ──
        if (validMappings.isNotEmpty) ...[
          const SizedBox(height: 16),
          Row(
            children: [
              const Text(
                'CONDITIONS',
                style: TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 8,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.9,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(child: Container(height: 1, color: AppColors.border)),
            ],
          ),
          const SizedBox(height: 10),
          ...validMappings.asMap().entries.map(
            (e) => _MappingRow(
              idx: e.key,
              mapping: e.value,
              srcIndex: srcIndex,
              ctrl: ctrl,
            ),
          ),
        ] else ...[
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              color: AppColors.surface2,
              border: Border.all(color: AppColors.border),
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.info_outline_rounded,
                  size: 14,
                  color: AppColors.textMuted,
                ),
                SizedBox(width: 6),
                Text(
                  'No join conditions defined',
                  style: TextStyle(color: AppColors.textMuted, fontSize: 11),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _sourceNode(PipelineNode src, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: color.withValues(alpha: 0.10),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(shape: BoxShape.circle, color: color),
          ),
          const SizedBox(width: 5),
          Text(
            src.name,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w700,
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

    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        color: AppColors.bg,
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          // Index badge
          Container(
            width: 20,
            height: 20,
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
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),

          // Left side: col + source label
          Expanded(
            child: Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: lColor,
                  ),
                ),
                const SizedBox(width: 4),
                Flexible(child: _colChip(mapping.leftCol, lColor)),
                const SizedBox(width: 4),
                _srcBadge(lSrc?.name ?? '?', lColor),
              ],
            ),
          ),

          // Operator badge
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 8),
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(6),
              color: AppColors.violet.withValues(alpha: 0.10),
              border: Border.all(
                color: AppColors.violet.withValues(alpha: 0.30),
              ),
            ),
            child: Text(
              op,
              style: const TextStyle(
                color: AppColors.violet,
                fontSize: 10,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),

          // Right side: source label + col
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                _srcBadge(rSrc?.name ?? '?', rColor),
                const SizedBox(width: 4),
                Flexible(child: _colChip(mapping.rightCol, rColor)),
                const SizedBox(width: 4),
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: rColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _colChip(String col, Color color) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(5),
      color: color.withValues(alpha: 0.10),
      border: Border.all(color: color.withValues(alpha: 0.30)),
    ),
    child: Text(
      col,
      overflow: TextOverflow.ellipsis,
      style: TextStyle(
        color: color,
        fontSize: 9,
        fontWeight: FontWeight.w700,
        fontFamily: AppTextStyles.monoFamily,
      ),
    ),
  );

  Widget _srcBadge(String name, Color color) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(4),
      color: color.withValues(alpha: 0.06),
      border: Border.all(color: color.withValues(alpha: 0.20)),
    ),
    child: Text(
      name,
      style: TextStyle(
        color: color.withValues(alpha: 0.8),
        fontSize: 8,
        fontWeight: FontWeight.w600,
      ),
    ),
  );
}

// ── Data flow funnel (commented out) ─────────────────────────────────────────

// class _DataFlowFunnel extends StatelessWidget {
//   final List<PipelineNode> sourceNodes;
//   final Map<String, int> srcIndex;
//   const _DataFlowFunnel({required this.sourceNodes, required this.srcIndex});
//
//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       padding: const EdgeInsets.all(14),
//       decoration: BoxDecoration(
//         borderRadius: BorderRadius.circular(12),
//         color: AppColors.bg,
//         border: Border.all(color: AppColors.border2),
//       ),
//       child: Column(
//         children: [
//           Row(
//             mainAxisAlignment: MainAxisAlignment.spaceEvenly,
//             children: sourceNodes.asMap().entries.map((e) {
//               final color = _srcColor(e.key);
//               return Column(
//                 mainAxisSize: MainAxisSize.min,
//                 children: [
//                   Container(
//                     padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
//                     decoration: BoxDecoration(
//                       borderRadius: BorderRadius.circular(8),
//                       color: color.withValues(alpha: 0.1),
//                       border: Border.all(color: color.withValues(alpha: 0.4)),
//                     ),
//                     child: Text(e.value.name, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w700)),
//                   ),
//                   Container(width: 2, height: 20, color: color.withValues(alpha: 0.4)),
//                 ],
//               );
//             }).toList(),
//           ),
//           CustomPaint(size: const Size(double.infinity, 20), painter: _FunnelLinePainter(count: sourceNodes.length)),
//           const SizedBox(height: 4),
//           Container(
//             padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
//             decoration: BoxDecoration(
//               borderRadius: BorderRadius.circular(10),
//               color: AppColors.violet.withValues(alpha: 0.12),
//               border: Border.all(color: AppColors.violet.withValues(alpha: 0.4)),
//             ),
//             child: const Row(
//               mainAxisSize: MainAxisSize.min,
//               children: [
//                 Icon(Icons.link_rounded, color: AppColors.violet, size: 14),
//                 SizedBox(width: 6),
//                 Text('Join', style: TextStyle(color: AppColors.violet, fontSize: 12, fontWeight: FontWeight.w700)),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }
//
// class _FunnelLinePainter extends CustomPainter {
//   final int count;
//   const _FunnelLinePainter({required this.count});
//
//   @override
//   void paint(Canvas canvas, Size size) {
//     if (count == 0) return;
//     final paint = Paint()
//       ..color = AppColors.violet.withValues(alpha: 0.35)
//       ..strokeWidth = 1.5
//       ..style = PaintingStyle.stroke;
//     final centerX = size.width / 2;
//     final step = count > 1 ? size.width / count : 0.0;
//     for (int i = 0; i < count; i++) {
//       final srcX = step * i + step / 2;
//       final path = Path()
//         ..moveTo(srcX, 0)
//         ..quadraticBezierTo(srcX, size.height * 0.6, centerX, size.height);
//       canvas.drawPath(path, paint);
//     }
//   }
//
//   @override
//   bool shouldRepaint(_FunnelLinePainter old) => old.count != count;
// }

// ── Output format card ────────────────────────────────────────────────────────

class _OutputFormatCard extends StatelessWidget {
  final PipelineNode node;
  final PipelineController ctrl;
  const _OutputFormatCard({required this.node, required this.ctrl});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: AppColors.surface,
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: AppColors.blue.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ──
          Container(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
            decoration: BoxDecoration(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(16),
              ),
              gradient: LinearGradient(
                colors: [
                  AppColors.blue.withValues(alpha: 0.09),
                  AppColors.blue.withValues(alpha: 0.02),
                ],
              ),
              border: Border(
                bottom: BorderSide(
                  color: AppColors.blue.withValues(alpha: 0.12),
                ),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.blue.withValues(alpha: 0.12),
                    border: Border.all(
                      color: AppColors.blue.withValues(alpha: 0.25),
                    ),
                  ),
                  child: const Icon(
                    Icons.table_chart_rounded,
                    color: AppColors.blue,
                    size: 16,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        node.name,
                        style: const TextStyle(
                          color: AppColors.text,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 1),
                      const Text(
                        'Select columns for output',
                        style: TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ),
                _CountBadge(node: node),
              ],
            ),
          ),
          // ── Selector body ──
          Padding(
            padding: const EdgeInsets.all(14),
            child: _OutputColumnSelector(node: node, ctrl: ctrl),
          ),
        ],
      ),
    );
  }
}

class _CountBadge extends StatelessWidget {
  final PipelineNode node;
  const _CountBadge({required this.node});

  @override
  Widget build(BuildContext context) {
    final sel = node.selectedCols.length;
    final total = node.cols.length;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: sel > 0 ? AppColors.blue : AppColors.surface2,
        boxShadow: sel > 0
            ? [
                BoxShadow(
                  color: AppColors.blue.withValues(alpha: 0.30),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ]
            : null,
      ),
      child: Text(
        '$sel / $total',
        style: TextStyle(
          color: sel > 0 ? Colors.white : AppColors.textMuted,
          fontSize: 10,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

// ── Output column selector ────────────────────────────────────────────────────

class _OutputColumnSelector extends StatefulWidget {
  final PipelineNode node;
  final PipelineController ctrl;

  const _OutputColumnSelector({required this.node, required this.ctrl});

  @override
  State<_OutputColumnSelector> createState() => _OutputColumnSelectorState();
}

class _OutputColumnSelectorState extends State<_OutputColumnSelector> {
  final TextEditingController _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    widget.ctrl.addListener(_onCtrlChange);
  }

  void _onCtrlChange() => setState(() {});

  @override
  void dispose() {
    widget.ctrl.removeListener(_onCtrlChange);
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final node = widget.node;
    final ctrl = widget.ctrl;
    final query = _searchCtrl.text.toLowerCase();
    final filtered = node.cols
        .where((c) => query.isEmpty || c.toLowerCase().contains(query))
        .toList();
    final total = node.cols.length;
    final selCount = node.selectedCols.length;
    final progress = total > 0 ? selCount / total : 0.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Toolbar: search + select-all / clear ──
        Row(
          children: [
            Expanded(
              child: SizedBox(
                height: 34,
                child: TextField(
                  controller: _searchCtrl,
                  onChanged: (_) => setState(() {}),
                  style: const TextStyle(color: AppColors.text, fontSize: 12),
                  decoration: InputDecoration(
                    hintText: 'Search columns…',
                    hintStyle: const TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 11,
                    ),
                    prefixIcon: const Icon(
                      Icons.search_rounded,
                      size: 15,
                      color: AppColors.textDim,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 0,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: AppColors.border2),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: AppColors.border2),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(
                        color: AppColors.blue,
                        width: 1.5,
                      ),
                    ),
                    filled: true,
                    fillColor: AppColors.bg,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            // Select All
            _ToolbarBtn(
              label: 'All',
              icon: Icons.done_all_rounded,
              onTap: () {
                for (final c in node.cols) {
                  if (!node.selectedCols.contains(c)) {
                    ctrl.toggleColumn(node.id, c);
                  }
                }
              },
            ),
            const SizedBox(width: 4),
            // Clear
            _ToolbarBtn(
              label: 'Clear',
              icon: Icons.close_rounded,
              destructive: true,
              onTap: () {
                for (final c in List<String>.from(node.selectedCols)) {
                  ctrl.toggleColumn(node.id, c);
                }
              },
            ),
          ],
        ),

        const SizedBox(height: 10),

        // ── Progress bar ──
        Row(
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 5,
                  backgroundColor: AppColors.border,
                  valueColor: const AlwaysStoppedAnimation<Color>(
                    AppColors.blue,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '$selCount / $total',
              style: const TextStyle(
                color: AppColors.textDim,
                fontSize: 10,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),

        const SizedBox(height: 10),

        // ── Column chips (Wrap) ──
        filtered.isEmpty
            ? Container(
                padding: const EdgeInsets.symmetric(
                  vertical: 12,
                  horizontal: 10,
                ),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  color: AppColors.bg,
                  border: Border.all(color: AppColors.border),
                ),
                child: const Center(
                  child: Text(
                    'No columns match',
                    style: TextStyle(color: AppColors.textMuted, fontSize: 11),
                  ),
                ),
              )
            : Wrap(
                spacing: 6,
                runSpacing: 6,
                children: filtered.map((col) {
                  final sel = node.selectedCols.contains(col);
                  return GestureDetector(
                    onTap: () => ctrl.toggleColumn(node.id, col),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        color: sel ? AppColors.blue : AppColors.bg,
                        border: Border.all(
                          color: sel ? AppColors.blue : AppColors.border2,
                          width: sel ? 1.5 : 1,
                        ),
                        boxShadow: sel
                            ? [
                                BoxShadow(
                                  color: AppColors.blue.withValues(alpha: 0.25),
                                  blurRadius: 5,
                                  offset: const Offset(0, 2),
                                ),
                              ]
                            : null,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (sel) ...[
                            const Icon(
                              Icons.check_rounded,
                              size: 11,
                              color: Colors.white,
                            ),
                            const SizedBox(width: 4),
                          ],
                          Text(
                            col,
                            style: TextStyle(
                              color: sel ? Colors.white : AppColors.textDim,
                              fontSize: 11,
                              fontFamily: AppTextStyles.monoFamily,
                              fontWeight: sel
                                  ? FontWeight.w600
                                  : FontWeight.w400,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),

        // ── Alias table ──
        if (node.selectedCols.isNotEmpty) ...[
          const SizedBox(height: 14),
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              children: [
                // Table header
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(10),
                    ),
                    color: AppColors.bg,
                    border: const Border(
                      bottom: BorderSide(color: AppColors.border),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.drive_file_rename_outline_rounded,
                        size: 12,
                        color: AppColors.blue,
                      ),
                      const SizedBox(width: 6),
                      const Text(
                        'Source column',
                        style: TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.4,
                        ),
                      ),
                      const Spacer(),
                      const Text(
                        'Output alias',
                        style: TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.4,
                        ),
                      ),
                      const SizedBox(width: 4),
                    ],
                  ),
                ),
                // Table rows
                ...node.selectedCols.asMap().entries.map((e) {
                  final i = e.key;
                  final col = e.value;
                  final isLast = i == node.selectedCols.length - 1;
                  return Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      borderRadius: isLast
                          ? const BorderRadius.vertical(
                              bottom: Radius.circular(10),
                            )
                          : null,
                      border: isLast
                          ? null
                          : const Border(
                              bottom: BorderSide(
                                color: AppColors.border,
                                width: 0.8,
                              ),
                            ),
                      color: i.isEven
                          ? AppColors.surface
                          : AppColors.surface2.withValues(alpha: 0.5),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.blue.withValues(alpha: 0.6),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            col,
                            style: TextStyle(
                              color: AppColors.textDim,
                              fontSize: 10,
                              fontFamily: AppTextStyles.monoFamily,
                              fontWeight: FontWeight.w500,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 12),
                        SizedBox(
                          width: 160,
                          height: 30,
                          child: TextFormField(
                            key: ValueKey('dlg_alias_${node.id}_$col'),
                            initialValue: node.columnAliases[col] ?? '',
                            onChanged: (v) =>
                                ctrl.setColumnAlias(node.id, col, v),
                            style: TextStyle(
                              color: AppColors.text,
                              fontSize: 10.5,
                              fontFamily: AppTextStyles.monoFamily,
                            ),
                            decoration: InputDecoration(
                              hintText: col,
                              hintStyle: const TextStyle(
                                color: AppColors.textMuted,
                                fontSize: 10,
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 0,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(6),
                                borderSide: const BorderSide(
                                  color: AppColors.border2,
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(6),
                                borderSide: const BorderSide(
                                  color: AppColors.border2,
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(6),
                                borderSide: const BorderSide(
                                  color: AppColors.blue,
                                  width: 1.5,
                                ),
                              ),
                              filled: true,
                              fillColor: AppColors.surface,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

// ── Toolbar button ────────────────────────────────────────────────────────────

class _ToolbarBtn extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final bool destructive;

  const _ToolbarBtn({
    required this.label,
    required this.icon,
    required this.onTap,
    this.destructive = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = destructive ? AppColors.red : AppColors.blue;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          color: color.withValues(alpha: 0.08),
          border: Border.all(color: color.withValues(alpha: 0.22)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 12, color: color),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 10,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Action buttons ────────────────────────────────────────────────────────────

class _ActionRow extends StatelessWidget {
  final VoidCallback onEdit;
  final VoidCallback onConfirm;
  final bool confirmEnabled;
  const _ActionRow({
    required this.onEdit,
    required this.onConfirm,
    required this.confirmEnabled,
  });

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
            child: Tooltip(
              message: confirmEnabled
                  ? ''
                  : 'Please provide at least one output column rename',
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 200),
                opacity: confirmEnabled ? 1.0 : 0.45,
                child: InkWell(
                  onTap: confirmEnabled ? onConfirm : null,
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 11),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      gradient: LinearGradient(
                        colors: confirmEnabled
                            ? [
                                AppColors.green,
                                AppColors.green.withValues(alpha: 0.8),
                              ]
                            : [AppColors.border2, AppColors.border2],
                      ),
                      boxShadow: confirmEnabled
                          ? [
                              BoxShadow(
                                color: AppColors.green.withValues(alpha: 0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 3),
                              ),
                            ]
                          : null,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.check_circle_rounded,
                          size: 15,
                          color: confirmEnabled
                              ? Colors.white
                              : AppColors.textMuted,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Confirm & Submit',
                          style: TextStyle(
                            color: confirmEnabled
                                ? Colors.white
                                : AppColors.textMuted,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
