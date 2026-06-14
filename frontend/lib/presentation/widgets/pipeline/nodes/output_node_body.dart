import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:vizualizer/presentation/controllers/pipeline_controller.dart';
import 'package:vizualizer/core/theme/app_theme.dart';
import 'package:vizualizer/data/models/pipeline_models.dart';
import 'package:vizualizer/presentation/providers/auth_provider.dart';
import 'package:vizualizer/presentation/providers/pipeline_master_provider.dart';
import 'package:vizualizer/data/services/pipeline_service.dart';

import 'package:vizualizer/presentation/widgets/pipeline/nodes/output_node/config_preview_sheet.dart';
import 'package:vizualizer/presentation/widgets/pipeline/nodes/output_node/dynamic_uni_mailing_output_section.dart';
import 'package:vizualizer/presentation/widgets/pipeline/nodes/output_node/uni_mapping_row.dart';
import 'package:vizualizer/presentation/widgets/pipeline/config_panel.dart';

part 'output_node/output_format_card.dart';
part 'output_node/output_column_selector.dart';
part 'output_node/unimailing_section.dart';

// ── UniMailing mandatory fields ──────────────────────────────────────────────
const kMandatoryFields = [
  'Mail To',
  'Mail CC',
  'Mail BCC',
  'Subject',
  'Attachment',
  'SMS To',
  'Barcode',
];

// ─────────────────────────────────────────────────────────────────────────────
// OUTPUT NODE BODY
// Rendered as a canvas node when Submit Mapping is clicked on a join node.
// ─────────────────────────────────────────────────────────────────────────────

class OutputNodeBody extends StatefulWidget {
  final PipelineNode node;
  const OutputNodeBody({super.key, required this.node});

  @override
  State<OutputNodeBody> createState() => _OutputNodeBodyState();
}

class _OutputNodeBodyState extends State<OutputNodeBody> {
  bool _submitting = false;
  final _scrollCtrl = ScrollController();

  static String _slotLabel(String slot) {
    if (slot.length > 1 && slot[0] == 'C') {
      final n = int.tryParse(slot.substring(1));
      if (n != null) return 'Column $n';
    }
    return slot;
  }

  @override
  void dispose() {
    _scrollCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ctrl = context.watch<PipelineController>();
    final master = context.watch<PipelineMasterProvider>();

    // All source nodes connected to any join node
    final joinNodes = ctrl.nodes.where((n) => n.type == NodeType.join).toList();
    final sourceNodeIds = <String>{};
    for (final j in joinNodes) {
      for (final e in ctrl.edges.where((e) => e.toNodeId == j.id)) {
        sourceNodeIds.add(e.fromNodeId);
      }
    }
    // Also include direct edges to single-source scenarios
    if (joinNodes.isNotEmpty) {
      final joinId = joinNodes.first.id;
      for (final e in ctrl.edges.where((e) => e.toNodeId == joinId)) {
        sourceNodeIds.add(e.fromNodeId);
      }
    }
    // Fallback: all source nodes on canvas
    final sourceNodes = ctrl.nodes
        .where((n) => n.type.isSource && sourceNodeIds.contains(n.id))
        .toList();
    final allSourceNodes = sourceNodes.isNotEmpty
        ? sourceNodes
        : ctrl.nodes.where((n) => n.type.isSource).toList();

    final isStaticUserDefined =
        ctrl.templateType == '1' ||
        (ctrl.templateType.toLowerCase().contains('static') &&
            ctrl.outputFormats.any(
              (f) =>
                  f.toLowerCase().replaceAll(' ', '').contains('userdefined'),
            ));
    final isStaticUniMailing =
        ctrl.templateType == '2' ||
        (ctrl.templateType.toLowerCase().contains('static') &&
            ctrl.outputFormats.any(
              (f) => f.toLowerCase().contains('unimailing'),
            ));
    final isDynamicUniMailing = ctrl.isDynamicUniMailing;

    final sourcesWithCols = allSourceNodes
        .where((n) => n.cols.isNotEmpty)
        .toList();
    final allPrioritiesProvided =
        sourcesWithCols.isNotEmpty &&
        sourcesWithCols.every((n) => n.selectedCols.isNotEmpty);

    // UniMailing unimailing fields are optional; all added custom columns must be filled
    final customCount = ctrl.uniMailingCustomCount;
    final customFilled = ctrl.uniMailingCustom.length;
    final uniMailingComplete =
        !isStaticUniMailing || customCount == 0 || customFilled >= customCount;

    // 3rd case overrides canSubmit entirely
    final bool canSubmit;
    final String validationMessage;
    if (isDynamicUniMailing) {
      canSubmit = ctrl.allDynamicUniMailingKeysConfigured && !_submitting;
      if (!ctrl.allDynamicUniMailingKeysConfigured) {
        final done = ctrl.savedOutputKeyConfigs.length;
        final total = ctrl.dynamicUniMailingOutputKeys.length;
        validationMessage = 'Configure all output keys ($done / $total done)';
      } else {
        validationMessage = '';
      }
    } else {
      canSubmit = allPrioritiesProvided && uniMailingComplete && !_submitting;
      if (!allPrioritiesProvided) {
        validationMessage =
            'Select at least one output column for every source';
      } else if (!uniMailingComplete) {
        validationMessage =
            'All added custom columns must be mapped ($customFilled / $customCount filled)';
      } else {
        validationMessage = '';
      }
    }

    final mandatoryFilled = kMandatoryFields
        .where((f) => (ctrl.uniMailingMandatory[f] ?? '').isNotEmpty)
        .length;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Header — also the drag handle for moving the node ──
        MouseRegion(
          cursor: SystemMouseCursors.grab,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onPanUpdate: (d) => ctrl.moveNode(widget.node.id, d.delta),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.green.withValues(alpha: 0.12),
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(10),
                ),
                border: Border(
                  bottom: BorderSide(
                    color: AppColors.green.withValues(alpha: 0.2),
                  ),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.drag_indicator_rounded,
                    color: AppColors.green.withValues(alpha: 0.5),
                    size: 16,
                  ),
                  const SizedBox(width: 6),
                  Container(
                    width: 26,
                    height: 26,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(6),
                      color: AppColors.green.withValues(alpha: 0.2),
                    ),
                    child: const Icon(
                      Icons.table_chart_rounded,
                      color: AppColors.green,
                      size: 14,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Output Selection ',
                      style: TextStyle(
                        color: AppColors.green,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  InkWell(
                    onTap: () => confirmDeleteNode(
                      context,
                      ctrl,
                      widget.node.id,
                      widget.node.name,
                      widget.node.type,
                    ),
                    child: Icon(
                      Icons.delete_outline,
                      color: AppColors.red.withValues(alpha: 0.6),
                      size: 16,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),

        // ── Scrollable body ──
        // GestureDetector sits deeper than InteractiveViewer in the tree and
        // wins the gesture arena, manually driving _scrollCtrl so that
        // InteractiveViewer's PanGestureRecognizer never steals the drag.
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onVerticalDragUpdate: (d) {
            final pos = _scrollCtrl.position;
            final next = (_scrollCtrl.offset - (d.primaryDelta ?? 0)).clamp(
              pos.minScrollExtent,
              pos.maxScrollExtent,
            );
            _scrollCtrl.jumpTo(next);
          },
          onVerticalDragEnd: (d) {
            final velocity = -(d.primaryVelocity ?? 0);
            if (velocity.abs() < 50) return;
            final pos = _scrollCtrl.position;
            final target = (_scrollCtrl.offset + velocity * 0.3).clamp(
              pos.minScrollExtent,
              pos.maxScrollExtent,
            );
            _scrollCtrl.animateTo(
              target,
              duration: const Duration(milliseconds: 350),
              curve: Curves.decelerate,
            );
          },
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 600),
            child: RawScrollbar(
              controller: _scrollCtrl,
              thumbVisibility: false,
              interactive: true,
              thickness: 5,
              radius: const Radius.circular(3),
              child: SingleChildScrollView(
                controller: _scrollCtrl,
                physics: const NeverScrollableScrollPhysics(),
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Template / dept info ──
                    if (ctrl.sidebarTemplate.isNotEmpty &&
                        !isDynamicUniMailing) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 7,
                        ),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          color: AppColors.green.withValues(alpha: 0.06),
                          border: Border.all(
                            color: AppColors.green.withValues(alpha: 0.2),
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.assignment_rounded,
                              size: 13,
                              color: AppColors.green,
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Template',
                                    style: TextStyle(
                                      fontSize: 9,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.textMuted,
                                      letterSpacing: 0.4,
                                    ),
                                  ),
                                  Text(
                                    ctrl.sidebarTemplate,
                                    style: const TextStyle(
                                      color: AppColors.text,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 6),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                const Text(
                                  'Dept',
                                  style: TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textMuted,
                                    letterSpacing: 0.4,
                                  ),
                                ),
                                Text(
                                  ctrl.sidebarDept,
                                  style: const TextStyle(
                                    color: AppColors.textMuted,
                                    fontSize: 10,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],

                    // ── Column Selection (hidden for 3rd case – per-key selection used instead) ──
                    if (!isDynamicUniMailing && sourcesWithCols.isNotEmpty) ...[
                      _sectionHeader(
                        'COLUMN SELECTION',
                        Icons.checklist_rounded,
                        allPrioritiesProvided ? AppColors.blue : AppColors.red,
                        '${sourcesWithCols.length} sources',
                      ),
                      const SizedBox(height: 8),
                      for (final src in sourcesWithCols) ...[
                        _OutputFormatCard(
                          node: src,
                          ctrl: ctrl,
                          hidePriority: !isStaticUserDefined,
                          hideAlias: isStaticUniMailing,
                        ),
                        if (src != sourcesWithCols.last)
                          const SizedBox(height: 8),
                      ],
                      const SizedBox(height: 12),
                    ],

                    // ── Static UniMailing section ──
                    if (isStaticUniMailing) ...[
                      _sectionHeader(
                        'UNIMAILING FORMAT',
                        Icons.email_rounded,
                        uniMailingComplete ? AppColors.blue : AppColors.amber,
                        '$mandatoryFilled / 7 mapped',
                      ),
                      const SizedBox(height: 8),
                      UniMailingSection(
                        ctrl: ctrl,
                        sourceNodes: allSourceNodes,
                      ),
                      const SizedBox(height: 12),
                    ],

                    // ── Dynamic UniMailing section (3rd case) ──
                    if (isDynamicUniMailing) ...[
                      DynamicUniMailingOutputSection(
                        ctrl: ctrl,
                        sourceNodes: allSourceNodes,
                        onShowPreview: (lastKey) => _showConfigPreview(
                          context,
                          ctrl,
                          master,
                          allSourceNodes,
                          isDynamicUniMailing: true,
                          caseTitle: 'Dynamic & Unimailing',
                          lastKey: lastKey,
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],

                    // ── Submit button (hidden for Dynamic UniMailing — preview shown inline) ──
                    if (!isDynamicUniMailing)
                      AnimatedOpacity(
                        duration: const Duration(milliseconds: 200),
                        opacity: canSubmit ? 1.0 : 0.55,
                        child: InkWell(
                          onTap: () {
                            if (!canSubmit) {
                              if (validationMessage.isNotEmpty) {
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
                                            style: const TextStyle(
                                              fontSize: 12,
                                            ),
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
                              }
                              return;
                            }
                            if (isStaticUserDefined) {
                              _showConfigPreview(
                                context,
                                ctrl,
                                master,
                                allSourceNodes,
                                caseTitle: 'Static & User Defined',
                              );
                            } else if (isStaticUniMailing) {
                              _showConfigPreview(
                                context,
                                ctrl,
                                master,
                                allSourceNodes,
                                isUniMailing: true,
                                caseTitle: 'static & Unimaling ',
                              );
                            } else if (isDynamicUniMailing) {
                              _showConfigPreview(
                                context,
                                ctrl,
                                master,
                                allSourceNodes,
                                isDynamicUniMailing: true,
                                caseTitle: 'Dynamic & Unimailing',
                              );
                            } else {
                              _submit(context, ctrl, master);
                            }
                          },
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(vertical: 11),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8),
                              gradient: LinearGradient(
                                colors: canSubmit
                                    ? [
                                        AppColors.green,
                                        AppColors.green.withValues(alpha: 0.8),
                                      ]
                                    : [AppColors.border2, AppColors.border2],
                              ),
                              boxShadow: canSubmit
                                  ? [
                                      BoxShadow(
                                        color: AppColors.green.withValues(
                                          alpha: 0.3,
                                        ),
                                        blurRadius: 8,
                                        offset: const Offset(0, 2),
                                      ),
                                    ]
                                  : null,
                            ),
                            child: _submitting
                                ? const Center(
                                    child: SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 2,
                                      ),
                                    ),
                                  )
                                : Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.check_circle_rounded,
                                        size: 15,
                                        color: canSubmit
                                            ? Colors.white
                                            : AppColors.textMuted,
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        'Confirm',
                                        style: TextStyle(
                                          color: canSubmit
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
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _sectionHeader(
    String title,
    IconData icon,
    Color color,
    String? badge,
  ) {
    return Row(
      children: [
        Icon(icon, size: 12, color: color),
        const SizedBox(width: 5),
        Text(
          title,
          style: TextStyle(
            color: color,
            fontSize: 9,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.7,
          ),
        ),
        if (badge != null) ...[
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              color: color.withValues(alpha: 0.10),
              border: Border.all(color: color.withValues(alpha: 0.25)),
            ),
            child: Text(
              badge,
              style: TextStyle(
                color: color,
                fontSize: 9,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ],
    );
  }

  Future<void> _showConfigPreview(
    BuildContext context,
    PipelineController ctrl,
    PipelineMasterProvider master,
    List<PipelineNode> sourceNodes, {
    bool isUniMailing = false,
    bool isDynamicUniMailing = false,
    String caseTitle = '',
    String lastKey = '',
  }) async {
    final joinNodes = ctrl.nodes.where((n) => n.type == NodeType.join).toList();

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useRootNavigator: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      constraints: BoxConstraints(
        maxWidth: MediaQuery.of(context).size.width * 0.72,
      ),
      builder: (ctx) => ConfigPreviewSheet(
        ctrl: ctrl,
        master: master,
        sourceNodes: sourceNodes,
        joinNodes: joinNodes,
        isUniMailing: isUniMailing,
        isDynamicUniMailing: isDynamicUniMailing,
        caseTitle: caseTitle,
        onConfirm: () {
          Navigator.of(ctx, rootNavigator: true).pop();
          _submit(context, ctrl, master);
        },
      ),
    );

    // After sheet is dismissed, restore the last configured key so its
    // selected columns and mandatory field details are shown in the node body.
    if (isDynamicUniMailing && lastKey.isNotEmpty && context.mounted) {
      ctrl.setSelectedOutputKey(lastKey);
    }
  }

  Future<void> _submit(
    BuildContext context,
    PipelineController ctrl,
    PipelineMasterProvider master,
  ) async {
    if (_submitting) return;
    setState(() => _submitting = true);

    // Always derive sourceNodes fresh at submit time so that any edits made
    // after the preview sheet was opened are included in the payload.
    final _submitJoinNodes = ctrl.nodes
        .where((n) => n.type == NodeType.join)
        .toList();
    final submitSourceNodeIds = <String>{};
    for (final j in _submitJoinNodes) {
      for (final e in ctrl.edges.where((e) => e.toNodeId == j.id)) {
        submitSourceNodeIds.add(e.fromNodeId);
      }
    }
    if (_submitJoinNodes.isNotEmpty) {
      final joinId = _submitJoinNodes.first.id;
      for (final e in ctrl.edges.where((e) => e.toNodeId == joinId)) {
        submitSourceNodeIds.add(e.fromNodeId);
      }
    }
    final filteredSources = ctrl.nodes
        .where((n) => n.type.isSource && submitSourceNodeIds.contains(n.id))
        .toList();
    final sourceNodes = filteredSources.isNotEmpty
        ? filteredSources
        : ctrl.nodes.where((n) => n.type.isSource).toList();

    final templateId = ctrl.sidebarTemplateId;
    final deptId = ctrl.sidebarDeptId;
    final templateName = ctrl.sidebarTemplate;
    final userName = context.read<AuthProvider>().user?.user.employeeCode ?? '';

    // ── 1. Sources ──
    const sourceTypeValueToId = {'Manual': 1, 'QRS': 2, 'FC': 3};
    final sources = sourceNodes.asMap().entries.map((entry) {
      final s = entry.value;
      final sourceId = sourceTypeValueToId[s.sourceTypeValue] ?? 0;
      final uniqueCols = s.columnUniqueFields.entries
          .where((e) => e.value)
          .map((e) => e.key)
          .join(',');
      return {
        'TemplateId': templateId,
        'SourceId': s.sourceTypeId > 0 ? s.sourceTypeId.toString() : '',
        'SourceName': s.name,
        'SourceType': sourceId.toString(),
        'Department': deptId,
        'Template': templateName,
        'Separator': s.separator,
        'ColumnFile': s.fileName ?? '',
        'QueryFile': s.queryFileName ?? '',
        'Columns': s.cols.join(','),
        'SelectedColumns': s.selectedCols.join(','),
        'SourceSeqNo': (entry.key + 1).toString(),
        'uniquefield': uniqueCols,
      };
    }).toList();

    // ── 2. Join Mappings ──
    final joinMappings = <Map<String, dynamic>>[];
    int mappingIdx = 0;
    for (final j in ctrl.nodes.where((n) => n.type == NodeType.join)) {
      for (final m in j.mappings.where((m) => m.isValid)) {
        final lSrc = ctrl.findNode(m.leftSourceId);
        final rSrc = ctrl.findNode(m.rightSourceId);
        joinMappings.add({
          'Id': mappingIdx++,
          'TemplateId': templateId,
          'Department': deptId,
          'JoinNodeId': j.id,
          'LeftSourceId': m.leftSourceId,
          'LeftSourceName': lSrc?.name ?? '',
          'LeftColumn': m.leftCol,
          'JoinType': master.operations
              .where((o) => o.operationName == m.joinType)
              .map((o) => o.operationValue)
              .firstOrNull,
          'RightSourceId': m.rightSourceId,
          'RightSourceName': rSrc?.name ?? '',
          'RightColumn': m.rightCol,
          'CreatedOn':
              '${DateTime.now().toIso8601String().split('T').first}T00:00:00',
        });
      }
    }

    // ── 3. Edges ──
    final edgeList = ctrl.edges
        .map(
          (e) => {
            'template_id': templateId,
            'department': deptId,
            'From': e.fromNodeId,
            'To': e.toNodeId,
          },
        )
        .toList();

    // ── 4. Connected Sources ──
    final connectedSourcesData = <Map<String, dynamic>>[];
    for (final j in ctrl.nodes.where((n) => n.type == NodeType.join)) {
      for (final edge in ctrl.edges.where((e) => e.toNodeId == j.id)) {
        connectedSourcesData.add({
          'TemplateId': templateId,
          'Department': deptId,
          'JoinNodeId': j.id,
          'SourceId': edge.fromNodeId,
        });
      }
    }

    // ── 5. Output Columns ──
    final isStaticUserDefined =
        (ctrl.templateType == '1' ||
        (ctrl.templateType.toLowerCase().contains('static') &&
            ctrl.outputFormats.any(
              (f) =>
                  f.toLowerCase().replaceAll(' ', '').contains('userdefined'),
            )));
    final isStaticUniMailing =
        ctrl.templateType == '2' ||
        (ctrl.templateType.toLowerCase().contains('static') &&
            ctrl.outputFormats.any(
              (f) => f.toLowerCase().contains('unimailing'),
            ));
    final isDynamicUniMailing = ctrl.isDynamicUniMailing;

    final deptIdInt = int.tryParse(deptId) ?? 0;
    final outputColumns = <Map<String, dynamic>>[];
    // Dynamic UniMailing uses per-key snapshot-based output columns built in payload section.
    if (!isStaticUniMailing && !isDynamicUniMailing) {
      int autoRank = 1;
      for (final s in sourceNodes) {
        for (final col in s.selectedCols) {
          final outputName = (s.columnAliases[col] ?? '').isNotEmpty
              ? s.columnAliases[col]!
              : col;
          final priority = isStaticUserDefined
              ? (s.columnPriorities[col] ?? autoRank)
              : autoRank;
          outputColumns.add({
            'template_id': templateId,
            'department': deptIdInt.toString(),
            'sourceid': sourceTypeValueToId[s.sourceTypeValue].toString(),
            'sourceName': s.name,
            'SourceColName': col,
            'ColumnName': outputName,
            'Priority': priority,
          });
          autoRank++;
        }
      }
      if (isStaticUserDefined) {
        outputColumns.sort(
          (a, b) => (a['Priority'] as int).compareTo(b['Priority'] as int),
        );
      }
    }

    // ── 6. UniMailing config (Static case) → outputColumns entries ──
    if (isStaticUniMailing) {
      String resolveCol(String key) =>
          key.contains('::') ? key.split('::')[1] : key;
      PipelineNode? resolveNode(String key) {
        if (!key.contains('::')) return null;
        final nodeId = key.split('::')[0];
        return sourceNodes.where((n) => n.id == nodeId).firstOrNull;
      }

      // Always send all 7 UniMailing fields; use empty strings for unmapped ones
      for (final field in kMandatoryFields) {
        final val = ctrl.uniMailingMandatory[field] ?? '';
        final node = val.isNotEmpty ? resolveNode(val) : null;
        final srcCol = val.isNotEmpty ? resolveCol(val) : '';
        outputColumns.add({
          'template_id': templateId,
          'department': deptIdInt.toString(),
          'sourceid': (sourceTypeValueToId[node?.sourceTypeValue] ?? 0)
              .toString(),
          'sourceName': node?.name ?? '',
          'SourceColName': srcCol,
          'ColumnName': field,
          'Priority': 0,
        });
      }

      final sortedCustom =
          ctrl.uniMailingCustom.entries
              .where((e) => e.value.isNotEmpty)
              .toList()
            ..sort((a, b) {
              final ai = int.tryParse(a.key.substring(1)) ?? 0;
              final bi = int.tryParse(b.key.substring(1)) ?? 0;
              return ai.compareTo(bi);
            });
      for (final e in sortedCustom) {
        final node = resolveNode(e.value);
        final srcCol = resolveCol(e.value);
        outputColumns.add({
          'template_id': templateId,
          'department': deptIdInt.toString(),
          'sourceid': (sourceTypeValueToId[node?.sourceTypeValue] ?? 0)
              .toString(),
          'sourceName': node?.name ?? '',
          'SourceColName': srcCol,
          'ColumnName': _slotLabel(e.key),
          'Priority': 0,
        });
      }
    }

    // Build ordered list of dynamicTemplate ids matching dynamicUniMailingOutputKeys order:
    // [srno==0 entry id, then srno>0 entries in order]
    int dynEntryId(Map<String, dynamic> dt) {
      final v = dt['id'];
      if (v is int) return v;
      if (v is num) return v.toInt();
      return int.tryParse('$v') ?? 0;
    }

    int srnoOf(Map<String, dynamic> dt) {
      final v = dt['srno'];
      if (v is int) return v;
      if (v is num) return v.toInt();
      return int.tryParse('$v') ?? 0;
    }

    final dynTemplateIds = <int>[];
    if (ctrl.dynamicTemplates.isNotEmpty) {
      for (final dt in ctrl.dynamicTemplates.where((dt) => srnoOf(dt) == 0)) {
        dynTemplateIds.add(dynEntryId(dt));
      }
      for (final dt in ctrl.dynamicTemplates.where((dt) => srnoOf(dt) > 0)) {
        dynTemplateIds.add(dynEntryId(dt));
      }
    }

    final templateTypeInt = isDynamicUniMailing
        ? 3
        : isStaticUniMailing
        ? 2
        : 1;

    final singlePayload = {
      'TemplateId': templateId,
      'TemplateType': templateTypeInt,
      'DymanicId': 0,
      'createdBy': userName,
      'templateMode': ctrl.templateMode.value,
      'Sources': sources,
      'JoinMappings': joinMappings,
      'Edges': edgeList,
      'connectedSources': connectedSourcesData,
      'outputColumns': outputColumns,
      'Jsondata': null,
    };

    // Always an array: static → [{...}], dynamic → one element per output key with its own canvas data
    final dynamic payload = isDynamicUniMailing
        ? ctrl.dynamicUniMailingOutputKeys.asMap().entries.map((entry) {
            final key = entry.value;
            final config = ctrl.savedOutputKeyConfigs[key];

            // Per-key canvas snapshot saved at configure time
            final snapSrcs = (config?['_snapshotSources'] as List? ?? [])
                .whereType<Map<dynamic, dynamic>>()
                .toList();
            final snapJoinMaps =
                (config?['_snapshotJoinMappings'] as List? ?? [])
                    .whereType<Map<dynamic, dynamic>>()
                    .toList();
            final snapEdges = (config?['_snapshotEdges'] as List? ?? [])
                .whereType<Map<dynamic, dynamic>>()
                .toList();
            final snapConn = (config?['_snapshotConnected'] as List? ?? [])
                .whereType<Map<dynamic, dynamic>>()
                .toList();

            // Build per-key Sources
            final keySources = snapSrcs.asMap().entries.map((se) {
              final s = se.value;
              final tv = s['sourceTypeValue']?.toString() ?? '';
              final srcId = sourceTypeValueToId[tv] ?? 0;
              final ucols = (s['columnUniqueFields'] as Map? ?? {});
              final uniqueCols = ucols.entries
                  .where((e) => e.value == true)
                  .map((e) => e.key.toString())
                  .join(',');
              final stId = s['sourceTypeId'];
              final stIdInt = stId is num
                  ? stId.toInt()
                  : (int.tryParse('$stId') ?? 0);
              return {
                'TemplateId': templateId,
                'SourceId': stIdInt > 0 ? stIdInt.toString() : '',
                'SourceName': s['name']?.toString() ?? '',
                'SourceType': srcId.toString(),
                'Department': deptId,
                'Template': templateName,
                'Separator': s['separator']?.toString() ?? '',
                'ColumnFile': s['fileName']?.toString() ?? '',
                'QueryFile': s['queryFileName']?.toString() ?? '',
                'Columns': (s['cols'] as List? ?? []).join(','),
                'SelectedColumns': (s['selectedCols'] as List? ?? []).join(','),
                'SourceSeqNo': (se.key + 1).toString(),
                'uniquefield': uniqueCols,
              };
            }).toList();

            // Build per-key JoinMappings
            final keyJoinMappings = <Map<String, dynamic>>[];
            int jIdx = 0;
            for (final m in snapJoinMaps) {
              keyJoinMappings.add({
                'Id': jIdx++,
                'TemplateId': templateId,
                'Department': deptId,
                'JoinNodeId': m['joinNodeId']?.toString() ?? '',
                'LeftSourceId': m['leftSourceId']?.toString() ?? '',
                'LeftSourceName': m['leftSourceName']?.toString() ?? '',
                'LeftColumn': m['leftCol']?.toString() ?? '',
                'JoinType': master.operations
                    .where((o) => o.operationName == m['joinType']?.toString())
                    .map((o) => o.operationValue)
                    .firstOrNull,
                'RightSourceId': m['rightSourceId']?.toString() ?? '',
                'RightSourceName': m['rightSourceName']?.toString() ?? '',
                'RightColumn': m['rightCol']?.toString() ?? '',
                'CreatedOn':
                    '${DateTime.now().toIso8601String().split('T').first}T00:00:00',
              });
            }

            // Build per-key Edges and connectedSources
            final keyEdges = snapEdges
                .map(
                  (e) => {
                    'template_id': templateId,
                    'department': deptId,
                    'From': e['fromNodeId']?.toString() ?? '',
                    'To': e['toNodeId']?.toString() ?? '',
                  },
                )
                .toList();

            final keyConnected = snapConn
                .map(
                  (cs) => {
                    'TemplateId': templateId,
                    'Department': deptId,
                    'JoinNodeId': cs['joinNodeId']?.toString() ?? '',
                    'SourceId': cs['sourceId']?.toString() ?? '',
                  },
                )
                .toList();

            // Build per-key outputColumns using snapshot source for sourceTypeValue lookup
            String snapLookupSrcId(String sourceName) {
              final snap = snapSrcs
                  .where((s) => s['name']?.toString() == sourceName)
                  .firstOrNull;
              final tv = snap?['sourceTypeValue']?.toString() ?? '';
              return (sourceTypeValueToId[tv] ?? 0).toString();
            }

            final keyOutputCols = <Map<String, dynamic>>[];
            final keyType = config?['KeyType'] as String? ?? '';
            if (keyType == 'Static') {
              for (final f in (config?['MandatoryFields'] as List? ?? [])) {
                final sn = f['SourceName'] as String? ?? '';
                keyOutputCols.add({
                  'template_id': templateId,
                  'department': deptIdInt.toString(),
                  'sourceid': snapLookupSrcId(sn),
                  'sourceName': sn,
                  'SourceColName': f['ColumnName'] as String? ?? '',
                  'ColumnName': f['Field'] as String? ?? '',
                  'Priority': 0,
                });
              }
              for (final c in (config?['CustomColumns'] as List? ?? [])) {
                final sn = c['SourceName'] as String? ?? '';
                keyOutputCols.add({
                  'template_id': templateId,
                  'department': deptIdInt.toString(),
                  'sourceid': snapLookupSrcId(sn),
                  'sourceName': sn,
                  'SourceColName': c['ColumnName'] as String? ?? '',
                  'ColumnName': _slotLabel(c['Slot'] as String? ?? ''),
                  'Priority': 0,
                });
              }
            } else {
              final c0 = config?['C0'] as Map? ?? {};
              final c0Src = c0['SourceName'] as String? ?? '';
              if (c0Src.isNotEmpty) {
                keyOutputCols.add({
                  'template_id': templateId,
                  'department': deptIdInt.toString(),
                  'sourceid': snapLookupSrcId(c0Src),
                  'sourceName': c0Src,
                  'SourceColName': c0['ColumnName'] as String? ?? '',
                  'ColumnName': 'Column 0',
                  'Priority': 0,
                });
              }
              final c1 = config?['C1'] as Map? ?? {};
              final c1Src = c1['SourceName'] as String? ?? '';
              if (c1Src.isNotEmpty) {
                keyOutputCols.add({
                  'template_id': templateId,
                  'department': deptIdInt.toString(),
                  'sourceid': snapLookupSrcId(c1Src),
                  'sourceName': c1Src,
                  'SourceColName': c1['ColumnName'] as String? ?? '',
                  'ColumnName': 'Column 1',
                  'Priority': 0,
                });
              }
              for (final c in (config?['CustomColumns'] as List? ?? [])) {
                final sn = c['SourceName'] as String? ?? '';
                keyOutputCols.add({
                  'template_id': templateId,
                  'department': deptIdInt.toString(),
                  'sourceid': snapLookupSrcId(sn),
                  'sourceName': sn,
                  'SourceColName': c['ColumnName'] as String? ?? '',
                  'ColumnName': _slotLabel(c['Slot'] as String? ?? ''),
                  'Priority': 0,
                });
              }
            }

            final dymanicId = entry.key < dynTemplateIds.length
                ? dynTemplateIds[entry.key]
                : entry.key;
            return {
              'TemplateId': templateId,
              'TemplateType': 3,
              'DymanicId': dymanicId,
              'createdBy': userName,
              'templateMode': ctrl.templateMode.value,
              'Sources': keySources,
              'JoinMappings': keyJoinMappings,
              'Edges': keyEdges,
              'connectedSources': keyConnected,
              'outputColumns': keyOutputCols,
              'Jsondata': null,
            };
          }).toList()
        : [singlePayload];

    // Collect file entries: per-key snapshots for Dynamic, current canvas for Static.
    final fileEntries = <({String key, List<int> bytes, String filename})>[];
    if (isDynamicUniMailing) {
      for (final k in ctrl.dynamicUniMailingOutputKeys) {
        final cfg = ctrl.savedOutputKeyConfigs[k];
        for (final s
            in (cfg?['_snapshotSources'] as List? ?? []).whereType<Map>()) {
          final fn = s['fileName']?.toString() ?? '';
          final qfn = s['queryFileName']?.toString() ?? '';
          final bytes = s['columnFileBytes'] as List<int>?;
          final qbytes = s['queryFileBytes'] as List<int>?;
          if (fn.isNotEmpty && bytes != null && bytes.isNotEmpty) {
            fileEntries.add((key: 'Files', bytes: bytes, filename: fn));
          }
          if (qfn.isNotEmpty && qbytes != null && qbytes.isNotEmpty) {
            fileEntries.add((key: 'Files', bytes: qbytes, filename: qfn));
          }
        }
      }
    } else {
      for (final s in sourceNodes) {
        if (s.fileName != null && s.fileName!.isNotEmpty) {
          fileEntries.add((
            key: 'Files',
            bytes: s.columnFileBytes ?? [],
            filename: s.fileName!,
          ));
        }
        if (s.queryFileName != null && s.queryFileName!.isNotEmpty) {
          fileEntries.add((
            key: 'Files',
            bytes: s.queryFileBytes ?? [],
            filename: s.queryFileName!,
          ));
        }
      }
    }

    final jsonStr = const JsonEncoder.withIndent('  ').convert(payload);
    debugPrint('SUBMIT MAPPING — OUTPUT NODE');
    debugPrint(jsonStr);

    bool submitSuccess = false;
    String submitMessage = '';
    int? submitTemplateId;
    try {
      final service = context.read<PipelineService>();
      final response = await service.submitMapping(
        payload,
        fileEntries: fileEntries,
      );
      submitSuccess = response.success;
      submitMessage = response.message;
      submitTemplateId = response.data?.templateId;
    } catch (e) {
      submitSuccess = false;
      submitMessage = 'Network error. Please try again.';
    }

    if (!context.mounted) return;
    setState(() => _submitting = false);

    if (submitSuccess) {
      _showSuccessDialog(context, ctrl, submitTemplateId);
    } else {
      _showErrorDialog(context, submitMessage);
    }
  }

  void _showSuccessDialog(
    BuildContext context,
    PipelineController ctrl,
    int? templateId,
  ) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          width: 340,
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: AppColors.green.withValues(alpha: 0.18),
                blurRadius: 48,
                offset: const Offset(0, 16),
              ),
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.35),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 28),
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(24),
                  ),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppColors.green.withValues(alpha: 0.18),
                      AppColors.green.withValues(alpha: 0.05),
                    ],
                  ),
                ),
                child: Column(
                  children: [
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        Container(
                          width: 92,
                          height: 92,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.green.withValues(alpha: 0.07),
                          ),
                        ),
                        Container(
                          width: 72,
                          height: 72,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.green.withValues(alpha: 0.12),
                          ),
                        ),
                        Container(
                          width: 54,
                          height: 54,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                AppColors.green,
                                AppColors.green.withValues(alpha: 0.7),
                              ],
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.green.withValues(alpha: 0.45),
                                blurRadius: 18,
                                offset: const Offset(0, 5),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.check_rounded,
                            color: Colors.white,
                            size: 30,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    const Text(
                      'Mapping Submitted!',
                      style: TextStyle(
                        color: AppColors.text,
                        fontSize: 19,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      'Pipeline configuration saved successfully.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: AppColors.textDim.withValues(alpha: 0.8),
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                child: Column(
                  children: [
                    if (templateId != null) ...[
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          color: AppColors.green.withValues(alpha: 0.06),
                          border: Border.all(
                            color: AppColors.green.withValues(alpha: 0.22),
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(8),
                                color: AppColors.green.withValues(alpha: 0.14),
                              ),
                              child: const Icon(
                                Icons.tag_rounded,
                                color: AppColors.green,
                                size: 18,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Template Request ID',
                                  style: TextStyle(
                                    color: AppColors.textDim,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 1),
                                Text(
                                  templateId.toString(),
                                  style: const TextStyle(
                                    color: AppColors.green,
                                    fontSize: 20,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ],
                            ),
                            const Spacer(),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(6),
                                color: AppColors.green.withValues(alpha: 0.15),
                              ),
                              child: const Text(
                                'SAVED',
                                style: TextStyle(
                                  color: AppColors.green,
                                  fontSize: 8,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.8,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                    InkWell(
                      onTap: () {
                        Navigator.of(ctx).pop();
                        ctrl.clearCanvas();
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          gradient: LinearGradient(
                            colors: [
                              AppColors.green,
                              AppColors.green.withValues(alpha: 0.72),
                            ],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.green.withValues(alpha: 0.38),
                              blurRadius: 14,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.check_circle_outline_rounded,
                              color: Colors.white,
                              size: 18,
                            ),
                            SizedBox(width: 8),
                            Text(
                              'Done',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showErrorDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.red.withValues(alpha: 0.15),
              ),
              child: const Icon(
                Icons.error_rounded,
                color: AppColors.red,
                size: 40,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Submission Failed',
              style: TextStyle(
                color: AppColors.text,
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),
            if (message.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.textDim, fontSize: 12),
              ),
            ],
            const SizedBox(height: 16),
            InkWell(
              onTap: () => Navigator.of(ctx).pop(),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  color: AppColors.red,
                ),
                child: const Center(
                  child: Text(
                    'OK',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
