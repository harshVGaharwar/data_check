import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../models/pipeline_models.dart';
import '../controllers/pipeline_controller.dart';
import 'nodes/join_node_body.dart' show JoinVennIcon;

// ── UniMailing mandatory field list ──────────────────────────────────────────
const _kMandatoryFields = [
  'Mail To',
  'Mail CC',
  'Mail BCC',
  'Subject',
  'Attachment',
  'SMS To',
  'Barcode',
];

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
    widget.ctrl.addListener(_onCtrlChange);
  }

  void _onCtrlChange() => setState(() {});

  @override
  void dispose() {
    widget.ctrl.removeListener(_onCtrlChange);
    _scrollCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ctrl = widget.ctrl;
    final sourceNodes = widget.sourceNodes;
    final templateName = ctrl.sidebarTemplate;
    final templateId = ctrl.sidebarTemplateId;
    final deptName = ctrl.sidebarDept;
    final deptId = ctrl.sidebarDeptId;
    final joinNodes = ctrl.nodes.where((n) => n.type == NodeType.join).toList();

    final srcIndex = {
      for (var i = 0; i < sourceNodes.length; i++) sourceNodes[i].id: i,
    };

    final sourcesWithCols = sourceNodes
        .where((n) => n.cols.isNotEmpty)
        .toList();
    // Section turns blue + submit enabled when every source with cols has ≥1 col selected
    // (selected cols always carry priorities via auto-defaults, alias is optional)
    final allPrioritiesProvided =
        sourcesWithCols.isNotEmpty &&
        sourcesWithCols.every((n) => n.selectedCols.isNotEmpty);

    // UniMailing section — shown only for Static + UniMailing templates
    final isStaticUniMailing =
        ctrl.templateType.toLowerCase().contains('static') &&
        ctrl.outputFormats.any((f) => f.toLowerCase().contains('unimailing'));
    final uniMailingComplete =
        !isStaticUniMailing ||
        _kMandatoryFields.every(
          (f) => (ctrl.uniMailingMandatory[f] ?? '').isNotEmpty,
        );

    // Context-aware validation message for SnackBar
    final String validationMessage;
    if (!allPrioritiesProvided) {
      validationMessage = 'Select at least one output column for every source';
    } else if (!uniMailingComplete) {
      validationMessage =
          'Map all 7 mandatory UniMailing fields before submitting';
    } else {
      validationMessage = '';
    }

    final confirmEnabled = allPrioritiesProvided && uniMailingComplete;

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
                      deptName: deptName,
                      deptId: deptId,
                      outputFormats: ctrl.outputFormats,
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

            // ── Scrollable body ───────────────────────────────────────────────
            Expanded(
              child: SingleChildScrollView(
                controller: _scrollCtrl,
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
                child: _buildBody(
                  sourceNodes,
                  joinNodes,
                  srcIndex,
                  ctrl,
                  confirmEnabled,
                  allPrioritiesProvided,
                  isStaticUniMailing,
                  uniMailingComplete,
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
                validationMessage: validationMessage,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(
    List<PipelineNode> sourceNodes,
    List<PipelineNode> joinNodes,
    Map<String, int> srcIndex,
    PipelineController ctrl,
    bool confirmEnabled,
    bool allPrioritiesProvided,
    bool isStaticUniMailing,
    bool uniMailingComplete,
  ) {
    // Priority shown only when Static + User Defined
    final isStaticUserDefined =
        ctrl.templateType.toLowerCase().contains('static') &&
        ctrl.outputFormats.any(
          (f) => f.toLowerCase().replaceAll(' ', '').contains('userdefined'),
        );

    final mandatoryFilled = _kMandatoryFields
        .where((f) => (ctrl.uniMailingMandatory[f] ?? '').isNotEmpty)
        .length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (sourceNodes.any((n) => n.cols.isNotEmpty)) ...[
          _SectionCard(
            title: 'Column Selection',
            icon: Icons.checklist_rounded,
            accentColor: allPrioritiesProvided ? AppColors.blue : AppColors.red,
            badge:
                '${sourceNodes.where((n) => n.cols.isNotEmpty).length} sources',
            selected: true,
            child: Column(
              children: [
                for (final src in sourceNodes.where(
                  (n) => n.cols.isNotEmpty,
                )) ...[
                  _OutputFormatCard(
                    node: src,
                    ctrl: ctrl,
                    hidePriority: !isStaticUserDefined,
                  ),
                  if (src != sourceNodes.where((n) => n.cols.isNotEmpty).last)
                    const SizedBox(height: 12),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],
        if (sourceNodes.length > 1) ...[
          for (final j in joinNodes) ...[
            _SectionCard(
              title: 'Join Operation',
              icon: Icons.merge_type_rounded,
              accentColor: AppColors.violet,
              badge: '${j.mappings.where((m) => m.isValid).length} conditions',
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
        if (isStaticUniMailing) ...[
          _SectionCard(
            title: 'UniMailing Format',
            icon: Icons.email_rounded,
            accentColor: uniMailingComplete ? AppColors.blue : AppColors.amber,
            badge: '$mandatoryFilled / 7 required',
            selected: true,
            child: _UniMailingSection(ctrl: ctrl, sourceNodes: sourceNodes),
          ),
          const SizedBox(height: 16),
        ],
      ],
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
  final String deptName;
  final String deptId;
  final List<String> outputFormats;
  const _Header({
    required this.templateName,
    required this.templateId,
    required this.deptName,
    required this.deptId,
    this.outputFormats = const [],
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
                  '${deptName.isNotEmpty ? deptName : deptId}  ·  Template: ${templateName.isNotEmpty ? templateName : 'ID $templateId'}',
                  style: const TextStyle(
                    color: Color(0xFF64748B),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),

          // ── Output format badges + review badge ──
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (outputFormats.isNotEmpty) ...[
                Wrap(
                  spacing: 4,
                  children: outputFormats
                      .map(
                        (f) => Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            color: AppColors.amber.withValues(alpha: 0.12),
                            border: Border.all(
                              color: AppColors.amber.withValues(alpha: 0.30),
                            ),
                          ),
                          child: Text(
                            f,
                            style: const TextStyle(
                              color: AppColors.amber,
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      )
                      .toList(),
                ),
                const SizedBox(height: 6),
              ],
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
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
                    Icon(
                      Icons.checklist_rounded,
                      size: 13,
                      color: Colors.white,
                    ),
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
            // connector line — all connectors green since we're at the last step
            final done = true;
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
        // Row(
        //   children: [
        //     for (var i = 0; i < sourceNodes.length; i++) ...[
        //       if (i > 0)
        //         Expanded(
        //           child: Stack(
        //             alignment: Alignment.center,
        //             children: [
        //               Container(height: 1.5, color: AppColors.border2),
        //               Container(
        //                 padding: const EdgeInsets.symmetric(
        //                   horizontal: 6,
        //                   vertical: 3,
        //                 ),
        //                 decoration: BoxDecoration(
        //                   color: AppColors.surface,
        //                   borderRadius: BorderRadius.circular(6),
        //                   border: Border.all(
        //                     color: AppColors.violet.withValues(alpha: 0.35),
        //                   ),
        //                 ),
        //                 child: const Text(
        //                   'JOIN',
        //                   style: TextStyle(
        //                     color: AppColors.violet,
        //                     fontSize: 7,
        //                     fontWeight: FontWeight.w800,
        //                     letterSpacing: 0.6,
        //                   ),
        //                 ),
        //               ),
        //             ],
        //           ),
        //         ),
        //       _sourceNode(sourceNodes[i], _srcColor(i)),
        //     ],
        //   ],
        // ),

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
    final op = mapping.joinType;

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

          // Join type Venn + operator badge
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                JoinVennIcon(joinLabel: mapping.joinType, size: 26),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 9,
                    vertical: 4,
                  ),
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
              ],
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
  final bool hidePriority;
  const _OutputFormatCard({
    required this.node,
    required this.ctrl,
    this.hidePriority = false,
  });

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
                _CountBadge(node: node, ctrl: ctrl),
              ],
            ),
          ),
          // ── Selector body ──
          Padding(
            padding: const EdgeInsets.all(14),
            child: _OutputColumnSelector(
              node: node,
              ctrl: ctrl,
              hidePriority: hidePriority,
            ),
          ),
        ],
      ),
    );
  }
}

class _CountBadge extends StatefulWidget {
  final PipelineNode node;
  final PipelineController ctrl;
  const _CountBadge({required this.node, required this.ctrl});

  @override
  State<_CountBadge> createState() => _CountBadgeState();
}

class _CountBadgeState extends State<_CountBadge> {
  @override
  void initState() {
    super.initState();
    widget.ctrl.addListener(_rebuild);
  }

  void _rebuild() => setState(() {});

  @override
  void dispose() {
    widget.ctrl.removeListener(_rebuild);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final sel = widget.node.selectedCols.length;
    final total = widget.node.cols.length;
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
  final bool hidePriority;

  const _OutputColumnSelector({
    required this.node,
    required this.ctrl,
    this.hidePriority = false,
  });

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

    // Global unique default priorities across all source nodes (prevents duplicate defaults)
    final allSrcNodes = ctrl.nodes
        .where((n) => n.type != NodeType.join)
        .toList();
    int _g = 0;
    final _globalDefault = <String, int>{};
    for (final n in allSrcNodes) {
      for (final c in n.selectedCols) {
        _g++;
        _globalDefault['${n.id}_$c'] = _g;
      }
    }
    final totalSelected = _g > 0 ? _g : 1;

    // Effective priority = user-set OR unique global default
    int effPri(PipelineNode n, String c) => n.columnPriorities.containsKey(c)
        ? n.columnPriorities[c]!
        : (_globalDefault['${n.id}_$c'] ?? 1);

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

        // ── Alias + Priority table ──
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
                      const Expanded(
                        child: Text(
                          'Source column',
                          style: TextStyle(
                            color: AppColors.textMuted,
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.4,
                          ),
                        ),
                      ),
                      if (!widget.hidePriority) ...[
                        const SizedBox(width: 8),
                        const SizedBox(
                          width: 64,
                          child: Text(
                            'Priority',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: AppColors.violet,
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.4,
                            ),
                          ),
                        ),
                      ],
                      const SizedBox(width: 8),
                      const SizedBox(
                        width: 130,
                        child: Text(
                          'Output alias',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: AppColors.textMuted,
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                // Table rows
                ...node.selectedCols.asMap().entries.map((e) {
                  final i = e.key;
                  final col = e.value;
                  final isLast = i == node.selectedCols.length - 1;

                  // All 1..N options shown; swap on conflict
                  final available = List.generate(
                    totalSelected,
                    (idx) => idx + 1,
                  );
                  final myPri = effPri(node, col);
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
                        if (!widget.hidePriority) ...[
                          const SizedBox(width: 8),
                          // Priority dropdown — only shows slots not taken by other columns
                          SizedBox(
                            width: 64,
                            height: 30,
                            child: Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                  color: AppColors.violet.withValues(
                                    alpha: 0.30,
                                  ),
                                ),
                                color: AppColors.violet.withValues(alpha: 0.05),
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 4,
                              ),
                              child: DropdownButton<int>(
                                value: available.contains(myPri)
                                    ? myPri
                                    : available.first,
                                items: available
                                    .map(
                                      (p) => DropdownMenuItem(
                                        value: p,
                                        child: Text(
                                          '$p',
                                          style: const TextStyle(
                                            color: AppColors.violet,
                                            fontSize: 12,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ),
                                    )
                                    .toList(),
                                onChanged: (v) {
                                  if (v == null) return;
                                  // Recompute fresh inside onChanged — avoids stale closures
                                  final freshNodes = ctrl.nodes
                                      .where((n) => n.type != NodeType.join)
                                      .toList();
                                  int gi = 0;
                                  final freshDefault = <String, int>{};
                                  for (final n in freshNodes) {
                                    for (final c in n.selectedCols) {
                                      gi++;
                                      freshDefault['${n.id}_$c'] = gi;
                                    }
                                  }
                                  int fp(PipelineNode n, String c) =>
                                      n.columnPriorities.containsKey(c)
                                      ? n.columnPriorities[c]!
                                      : (freshDefault['${n.id}_$c'] ?? 1);

                                  final oldPri = fp(node, col);
                                  if (oldPri == v) return; // no-op

                                  // Find conflicting column and swap — labeled break
                                  search:
                                  for (final n2 in freshNodes) {
                                    for (final c2 in n2.selectedCols) {
                                      if (n2.id == node.id && c2 == col)
                                        continue;
                                      if (fp(n2, c2) == v) {
                                        ctrl.setColumnPriority(
                                          n2.id,
                                          c2,
                                          oldPri,
                                        );
                                        break search;
                                      }
                                    }
                                  }
                                  ctrl.setColumnPriority(node.id, col, v);
                                },
                                underline: const SizedBox.shrink(),
                                isDense: true,
                                isExpanded: true,
                                icon: const Icon(
                                  Icons.arrow_drop_down_rounded,
                                  size: 16,
                                  color: AppColors.violet,
                                ),
                              ),
                            ),
                          ),
                        ], // end if (!widget.hidePriority)
                        const SizedBox(width: 8),
                        SizedBox(
                          width: 130,
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
  final String validationMessage;
  const _ActionRow({
    required this.onEdit,
    required this.onConfirm,
    required this.confirmEnabled,
    this.validationMessage = 'Please complete all required fields',
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
          // Confirm button — always tappable; shows SnackBar if validation fails
          Expanded(
            flex: 2,
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 200),
              opacity: confirmEnabled ? 1.0 : 0.55,
              child: InkWell(
                onTap: () {
                  if (!confirmEnabled) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Row(
                          children: [
                            const Icon(
                              Icons.warning_amber_rounded,
                              color: Colors.white,
                              size: 16,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                validationMessage,
                                style: const TextStyle(fontSize: 12),
                              ),
                            ),
                          ],
                        ),
                        backgroundColor: AppColors.red,
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        margin: const EdgeInsets.all(16),
                        duration: const Duration(seconds: 3),
                      ),
                    );
                    return;
                  }
                  onConfirm();
                },
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
        ],
      ),
    );
  }
}

// ── UniMailing section ────────────────────────────────────────────────────────

class _UniMailingSection extends StatefulWidget {
  final PipelineController ctrl;
  final List<PipelineNode> sourceNodes;
  const _UniMailingSection({required this.ctrl, required this.sourceNodes});

  @override
  State<_UniMailingSection> createState() => _UniMailingSectionState();
}

class _UniMailingSectionState extends State<_UniMailingSection> {
  late int _customCount;

  @override
  void initState() {
    super.initState();
    widget.ctrl.addListener(_onCtrlChange);
    _customCount = _deriveCustomCount();
  }

  void _onCtrlChange() => setState(() {});

  @override
  void dispose() {
    widget.ctrl.removeListener(_onCtrlChange);
    super.dispose();
  }

  int _deriveCustomCount() {
    if (widget.ctrl.uniMailingCustom.isEmpty) return 0;
    return widget.ctrl.uniMailingCustom.keys
        .map((k) => int.tryParse(k.substring(1)) ?? 0)
        .reduce((a, b) => a > b ? a : b);
  }

  // Build flat list: nodeId::colName  →  display label
  ({List<String> keys, Map<String, String> labels}) _buildAvailable() {
    final srcNodes = widget.sourceNodes
        .where((n) => n.selectedCols.isNotEmpty)
        .toList();
    final multi = srcNodes.length > 1;
    final keys = <String>[];
    final labels = <String, String>{};
    for (final n in srcNodes) {
      for (final c in n.selectedCols) {
        final k = '${n.id}::$c';
        keys.add(k);
        labels[k] = multi ? '${n.name} › $c' : c;
      }
    }
    return (keys: keys, labels: labels);
  }

  @override
  Widget build(BuildContext context) {
    final ctrl = widget.ctrl;
    final avail = _buildAvailable();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Mandatory Fields ──────────────────────────────────────────────
        _uniSubHeader('MANDATORY FIELDS', Icons.star_rounded, AppColors.red),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            children: _kMandatoryFields.asMap().entries.map((e) {
              final idx = e.key;
              final field = e.value;
              final isLast = idx == _kMandatoryFields.length - 1;
              final current = ctrl.uniMailingMandatory[field] ?? '';
              final isMapped = avail.keys.contains(current);
              return _UniMappingRow(
                label: field,
                labelColor: AppColors.red,
                currentKey: isMapped ? current : null,
                availableKeys: avail.keys,
                colLabels: avail.labels,
                isLast: isLast,
                isRequired: true,
                isMapped: isMapped,
                onChanged: (v) => ctrl.setUniMailingMandatory(field, v ?? ''),
              );
            }).toList(),
          ),
        ),

        const SizedBox(height: 16),

        // ── Custom Columns ────────────────────────────────────────────────
        Row(
          children: [
            _uniSubHeader(
              'CUSTOM COLUMNS (C1–C50)',
              Icons.add_box_outlined,
              AppColors.violet,
            ),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(4),
                color: AppColors.violet.withValues(alpha: 0.08),
              ),
              child: const Text(
                'optional',
                style: TextStyle(
                  color: AppColors.violet,
                  fontSize: 8,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const Spacer(),
            if (_customCount < 50)
              GestureDetector(
                onTap: () => setState(() => _customCount++),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(7),
                    color: AppColors.violet.withValues(alpha: 0.10),
                    border: Border.all(
                      color: AppColors.violet.withValues(alpha: 0.30),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.add_rounded,
                        size: 12,
                        color: AppColors.violet,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Add C${_customCount + 1}',
                        style: const TextStyle(
                          color: AppColors.violet,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),

        const SizedBox(height: 8),

        if (_customCount == 0)
          Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              color: AppColors.surface2,
              border: Border.all(color: AppColors.border),
            ),
            child: const Center(
              child: Text(
                'No custom columns added — tap Add C1 to begin',
                style: TextStyle(color: AppColors.textMuted, fontSize: 11),
              ),
            ),
          )
        else
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              children: List.generate(_customCount, (i) {
                final slot = i + 1;
                final key = 'C$slot';
                final current = ctrl.uniMailingCustom[key] ?? '';
                final isMapped = avail.keys.contains(current);
                final isLast = slot == _customCount;
                return _UniMappingRow(
                  label: key,
                  labelColor: AppColors.violet,
                  currentKey: isMapped ? current : null,
                  availableKeys: avail.keys,
                  colLabels: avail.labels,
                  isLast: isLast,
                  isRequired: false,
                  isMapped: isMapped,
                  onChanged: (v) => ctrl.setUniMailingCustom(key, v ?? ''),
                  onDelete: isLast
                      ? () {
                          ctrl.setUniMailingCustom(key, '');
                          setState(() => _customCount--);
                        }
                      : null,
                );
              }),
            ),
          ),
      ],
    );
  }

  Widget _uniSubHeader(String title, IconData icon, Color color) {
    return Row(
      children: [
        Icon(icon, size: 11, color: color),
        const SizedBox(width: 5),
        Text(
          title,
          style: TextStyle(
            color: color,
            fontSize: 9,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.9,
          ),
        ),
      ],
    );
  }
}

// ── UniMailing mapping row ────────────────────────────────────────────────────

class _UniMappingRow extends StatelessWidget {
  final String label;
  final Color labelColor;
  final String? currentKey;
  final List<String> availableKeys;
  final Map<String, String> colLabels;
  final bool isLast;
  final bool isRequired;
  final bool isMapped;
  final ValueChanged<String?> onChanged;
  final VoidCallback? onDelete;

  const _UniMappingRow({
    required this.label,
    required this.labelColor,
    required this.currentKey,
    required this.availableKeys,
    required this.colLabels,
    required this.isLast,
    required this.isRequired,
    required this.isMapped,
    required this.onChanged,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final borderColor = !isMapped && isRequired
        ? AppColors.red.withValues(alpha: 0.45)
        : isMapped
        ? labelColor.withValues(alpha: 0.28)
        : AppColors.border2;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: isLast
            ? const BorderRadius.vertical(bottom: Radius.circular(10))
            : null,
        border: isLast
            ? null
            : const Border(
                bottom: BorderSide(color: AppColors.border, width: 0.8),
              ),
        color: isMapped
            ? labelColor.withValues(alpha: 0.03)
            : AppColors.surface,
      ),
      child: Row(
        children: [
          // Label badge
          Container(
            constraints: const BoxConstraints(minWidth: 70),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(6),
              color: isMapped
                  ? labelColor.withValues(alpha: 0.12)
                  : AppColors.surface2,
              border: Border.all(
                color: isMapped
                    ? labelColor.withValues(alpha: 0.28)
                    : AppColors.border2,
              ),
            ),
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: isMapped ? labelColor : AppColors.textMuted,
                fontSize: 10,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Icon(
            Icons.arrow_forward_rounded,
            size: 12,
            color: AppColors.textMuted,
          ),
          const SizedBox(width: 8),

          // Dropdown
          Expanded(
            child: Container(
              height: 32,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(7),
                border: Border.all(color: borderColor),
                color: isMapped
                    ? labelColor.withValues(alpha: 0.04)
                    : AppColors.bg,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: DropdownButton<String?>(
                value: currentKey,
                hint: Text(
                  isRequired ? '— required —' : '— optional —',
                  style: TextStyle(
                    color: isRequired
                        ? AppColors.red.withValues(alpha: 0.65)
                        : AppColors.textMuted,
                    fontSize: 10,
                    fontStyle: FontStyle.italic,
                  ),
                ),
                isExpanded: true,
                isDense: true,
                underline: const SizedBox.shrink(),
                icon: Icon(
                  Icons.arrow_drop_down_rounded,
                  size: 16,
                  color: isMapped ? labelColor : AppColors.textDim,
                ),
                onChanged: onChanged,
                items: [
                  DropdownMenuItem<String?>(
                    value: null,
                    child: Text(
                      '— clear —',
                      style: TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 10,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                  ...availableKeys.map(
                    (k) => DropdownMenuItem<String?>(
                      value: k,
                      child: Text(
                        colLabels[k] ?? k,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppColors.text,
                          fontSize: 10,
                          fontFamily: AppTextStyles.monoFamily,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(width: 8),

          // Status dot (required) or delete button (optional last row)
          if (onDelete != null)
            GestureDetector(
              onTap: onDelete,
              child: const Icon(
                Icons.remove_circle_outline_rounded,
                size: 17,
                color: AppColors.red,
              ),
            )
          else
            Container(
              width: 7,
              height: 7,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isMapped ? AppColors.green : AppColors.red,
              ),
            ),
        ],
      ),
    );
  }
}
