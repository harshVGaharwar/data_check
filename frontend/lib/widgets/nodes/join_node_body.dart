import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../theme/app_theme.dart';
import '../../models/pipeline_models.dart';
import '../../models/pipeline_config.dart';
import '../../controllers/pipeline_controller.dart';
import '../../providers/pipeline_master_provider.dart';
import '../../services/pipeline_service.dart';

class JoinNodeBody extends StatelessWidget {
  final PipelineNode node;
  const JoinNodeBody({super.key, required this.node});

  @override
  Widget build(BuildContext context) {
    final ctrl = context.watch<PipelineController>();

    // All source nodes connected to this JOIN
    final inEdges = ctrl.edges.where((e) => e.toNodeId == node.id).toList();
    final connectedSources = inEdges
        .map((e) => ctrl.findNode(e.fromNodeId))
        .where((n) => n != null)
        .cast<PipelineNode>()
        .toList();

    final validMappings = node.mappings.where((m) => m.isValid).toList();

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Header ──
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: AppColors.violet.withOpacity(0.12),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(10)),
            border: Border(
              bottom: BorderSide(color: AppColors.violet.withOpacity(0.2)),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 26,
                height: 26,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(6),
                  color: AppColors.violet.withOpacity(0.2),
                ),
                child: const Icon(
                  Icons.link_rounded,
                  color: AppColors.violet,
                  size: 14,
                ),
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
              // Connected count badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(4),
                  color: Colors.white.withOpacity(0.1),
                ),
                child: Text(
                  '${connectedSources.length} sources',
                  style: const TextStyle(
                    color: AppColors.textDim,
                    fontSize: 9,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              InkWell(
                onTap: () => ctrl.deleteNode(node.id),
                child: Icon(
                  Icons.delete_outline,
                  color: AppColors.textDim.withOpacity(0.6),
                  size: 16,
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
              // ── Connected source badges ──
              if (connectedSources.isNotEmpty) ...[
                const Text(
                  'CONNECTED SOURCES',
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textMuted,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 5),
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: connectedSources.map((s) {
                    final color = s.type.color;
                    return Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(6),
                        color: color.withOpacity(0.08),
                        border: Border.all(color: color.withOpacity(0.2)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(s.type.icon, color: color, size: 11),
                          const SizedBox(width: 4),
                          Text(
                            s.name,
                            style: TextStyle(
                              color: color,
                              fontSize: 9.5,
                              fontWeight: FontWeight.w600,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 10),
              ] else ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(7),
                    border: Border.all(color: AppColors.border2),
                    color: AppColors.surface2,
                  ),
                  child: const Text(
                    'Connect sources to configure',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppColors.textDim, fontSize: 10.5),
                  ),
                ),
                const SizedBox(height: 10),
              ],

              // ── Saved mappings (read-only) ──
              if (validMappings.isNotEmpty) ...[
                Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Text(
                    'COLUMN MAPPINGS (${validMappings.length})',
                    style: const TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textMuted,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                ...validMappings.map((m) {
                  final idx = node.mappings.indexOf(m);
                  final lSrc = ctrl.findNode(m.leftSourceId);
                  final rSrc = ctrl.findNode(m.rightSourceId);
                  return Container(
                    margin: const EdgeInsets.only(bottom: 4),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.surface2,
                      borderRadius: BorderRadius.circular(7),
                      border: Border.all(color: AppColors.border2),
                    ),
                    child: Row(
                      children: [
                        // Left: source.column
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                lSrc?.name ?? '?',
                                style: TextStyle(
                                  color: (lSrc?.type.color ?? AppColors.violet)
                                      .withOpacity(0.7),
                                  fontSize: 8,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Text(
                                m.leftCol,
                                style: const TextStyle(
                                  color: Color(0xFFA78BFA),
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  fontFamily: 'monospace',
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Relation + Operation
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              margin: const EdgeInsets.symmetric(horizontal: 4),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(4),
                                color: AppColors.violet.withOpacity(0.15),
                                border: Border.all(
                                  color: AppColors.violet.withOpacity(0.3),
                                ),
                              ),
                              child: Text(
                                m.joinType,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 7,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Container(
                              margin: const EdgeInsets.symmetric(horizontal: 4),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(4),
                                color: AppColors.amber.withOpacity(0.12),
                                border: Border.all(
                                  color: AppColors.amber.withOpacity(0.3),
                                ),
                              ),
                              child: Text(
                                m.operationValue,
                                style: const TextStyle(
                                  color: AppColors.amber,
                                  fontSize: 9,
                                  fontWeight: FontWeight.w700,
                                  fontFamily: 'monospace',
                                ),
                              ),
                            ),
                          ],
                        ),
                        // Right: dep_source.column
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                rSrc?.name ?? '?',
                                style: TextStyle(
                                  color: (rSrc?.type.color ?? AppColors.blue)
                                      .withOpacity(0.7),
                                  fontSize: 8,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Text(
                                m.rightCol,
                                style: const TextStyle(
                                  color: Color(0xFF93C5FD),
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  fontFamily: 'monospace',
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 6),
                        InkWell(
                          onTap: () => ctrl.removeMappingFromJoin(node.id, idx),
                          borderRadius: BorderRadius.circular(4),
                          child: Container(
                            padding: const EdgeInsets.all(2),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(color: AppColors.border2),
                            ),
                            child: const Icon(
                              Icons.close,
                              size: 12,
                              color: AppColors.textDim,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }),
                const SizedBox(height: 8),
              ],

              // ── Input form ──
              if (connectedSources.length >= 2)
                _JoinMappingInputRow(
                  nodeId: node.id,
                  connectedSources: connectedSources,
                  defaultJoinType: node.joinType,
                ),

              // ── Submit Mapping Button ──
              if (validMappings.isNotEmpty) ...[
                const SizedBox(height: 10),
                InkWell(
                  onTap: () => _submitMapping(context, ctrl, node),
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      gradient: LinearGradient(
                        colors: [
                          AppColors.green,
                          AppColors.green.withOpacity(0.8),
                        ],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.green.withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.send_rounded, size: 16, color: Colors.white),
                        SizedBox(width: 8),
                        Text(
                          'Submit Mapping',
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
              ],
            ],
          ),
        ),
      ],
    );
  }

  void _submitMapping(
    BuildContext context,
    PipelineController ctrl,
    PipelineNode node,
  ) async {
    final master = Provider.of<PipelineMasterProvider>(context, listen: false);
    final validMappings = node.mappings.where((m) => m.isValid).toList();

    // ── Validate: all required source nodes must be connected ──
    final inEdges = ctrl.edges.where((e) => e.toNodeId == node.id).toList();
    final connectedSources = inEdges
        .map((e) => ctrl.findNode(e.fromNodeId))
        .where((n) => n != null)
        .cast<PipelineNode>()
        .toList();
    final required = ctrl.requiredSourceCount;
    if (required > 0 && connectedSources.length != required) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: AppColors.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.amber.withOpacity(0.15),
                ),
                child: const Icon(
                  Icons.warning_amber_rounded,
                  color: AppColors.amber,
                  size: 40,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Incomplete Connections',
                style: const TextStyle(
                  color: AppColors.text,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'This join node requires $required source(s) to be connected, but only ${connectedSources.length} are connected.',
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.textDim, fontSize: 12),
              ),
              const SizedBox(height: 16),
              InkWell(
                onTap: () => Navigator.of(ctx).pop(),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    color: AppColors.amber,
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
      return;
    }

    final templateId = ctrl.sidebarTemplateId;
    final deptId = ctrl.sidebarDeptId;
    final templateName = ctrl.sidebarTemplate;

    // ── 1. Sources (only those connected to a join node via edges) ──
    final connectedSourceIds = ctrl.edges
        .where(
          (e) => ctrl.nodes.any(
            (n) => n.id == e.toNodeId && n.type == NodeType.join,
          ),
        )
        .map((e) => e.fromNodeId)
        .toSet();
    final sourceNodes = ctrl.nodes
        .where((n) => n.type.isSource && connectedSourceIds.contains(n.id))
        .toList();
    final sources = sourceNodes.asMap().entries.map((entry) {
      final s = entry.value;
      return {
        'TemplateId': templateId,
        'SourceId': s.sourceId ?? 0,
        'SourceName': s.sourceTypeValue.isNotEmpty ? s.sourceTypeValue : s.name,
        'SourceType': s.sourceTypeValue.toLowerCase().isNotEmpty
            ? s.sourceTypeValue.toLowerCase()
            : s.type.name,
        'Department': deptId,
        'Template': templateName,
        'Separator': s.separator,
        'ColumnFile': s.fileName ?? '',
        'QueryFile': s.queryFileName ?? '',
        'Columns': s.cols.join(','),
        'SelectedColumns': s.selectedCols.join(','),
        'SourceSeqNo': null,
      };
    }).toList();

    // ── 2. Join Mappings (flat list across all join nodes) ──
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

    // ── 4. Connected Sources (join node ↔ source node pairs) ──
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

    // ── Full payload ──
    final payload = {
      'TemplateId': templateId,
      'Sources': sources,
      'JoinMappings': joinMappings,
      'Edges': edgeList,
      'connectedSources': connectedSourcesData,
    };

    // ── Collect file entries (column files + query files) ──
    final fileEntries = <({String key, List<int> bytes, String filename})>[];
    for (final s in sourceNodes) {
      if (s.columnFileBytes != null && s.fileName != null) {
        fileEntries.add((
          key: 'Files',
          bytes: s.columnFileBytes!,
          filename: s.fileName!,
        ));
      }
      if (s.queryFileBytes != null && s.queryFileName != null) {
        fileEntries.add((
          key: 'Files',
          bytes: s.queryFileBytes!,
          filename: s.queryFileName!,
        ));
      }
    }

    // ── Print full log ──
    final jsonStr = const JsonEncoder.withIndent('  ').convert(payload);
    debugPrint('═══════════════════════════════════════════════');
    debugPrint('SUBMIT MAPPING — FULL PIPELINE CONFIGURATION');
    debugPrint('═══════════════════════════════════════════════');
    debugPrint(jsonStr);
    debugPrint('Files: ${fileEntries.map((f) => f.filename).toList()}');
    debugPrint('═══════════════════════════════════════════════');

    // Show loader
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(
        child: CircularProgressIndicator(color: AppColors.green),
      ),
    );

    // Call API
    bool submitSuccess = false;
    String submitMessage = '';
    try {
      final service = context.read<PipelineService>();
      final response = await service.submitMapping(
        payload,
        fileEntries: fileEntries,
      );
      submitSuccess = response.success;
      submitMessage = response.message;
      debugPrint(
        '[SUBMIT MAPPING] Response: status=${response.success}, templateId=${response.data?.templateId}, configId=${response.data?.configId}',
      );
    } catch (e) {
      submitSuccess = false;
      submitMessage = 'Network error. Please try again.';
      debugPrint('[SUBMIT MAPPING] Exception: $e');
    }

    await Future.delayed(const Duration(milliseconds: 800));
    if (context.mounted) Navigator.of(context).pop();

    if (!context.mounted) return;

    if (submitSuccess) {
      // Success dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
          backgroundColor: AppColors.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.green.withOpacity(0.15),
                ),
                child: const Icon(
                  Icons.check_circle_rounded,
                  color: AppColors.green,
                  size: 40,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Success',
                style: TextStyle(
                  color: AppColors.text,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 16),
              InkWell(
                onTap: () => Navigator.of(ctx).pop(),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    color: AppColors.green,
                  ),
                  child: const Center(
                    child: Text(
                      'Done',
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
    } else {
      // Error dialog
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: AppColors.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.red.withOpacity(0.15),
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
              if (submitMessage.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  submitMessage,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: AppColors.textDim,
                    fontSize: 12,
                  ),
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
}

class _JoinMappingInputRow extends StatefulWidget {
  final String nodeId;
  final List<PipelineNode> connectedSources;
  final String defaultJoinType;

  const _JoinMappingInputRow({
    required this.nodeId,
    required this.connectedSources,
    required this.defaultJoinType,
  });

  @override
  State<_JoinMappingInputRow> createState() => _JoinMappingInputRowState();
}

class _JoinMappingInputRowState extends State<_JoinMappingInputRow> {
  String? leftSourceId;
  String? leftCol;
  late String joinType;
  String operationValue = '=';
  String? rightSourceId;
  String? rightCol;

  @override
  void initState() {
    super.initState();
    joinType = widget.defaultJoinType;
    // Default: first 2 sources
    if (widget.connectedSources.length >= 2) {
      leftSourceId = widget.connectedSources[0].id;
      rightSourceId = widget.connectedSources[1].id;
    }
  }

  @override
  void didUpdateWidget(_JoinMappingInputRow oldWidget) {
    super.didUpdateWidget(oldWidget);
    final ids = widget.connectedSources.map((s) => s.id).toSet();
    if (leftSourceId != null && !ids.contains(leftSourceId)) {
      leftSourceId = null;
      leftCol = null;
    }
    if (rightSourceId != null && !ids.contains(rightSourceId)) {
      rightSourceId = null;
      rightCol = null;
    }
  }

  List<String> _colsFor(String? sourceId) {
    if (sourceId == null) return [];
    final src = widget.connectedSources.where((s) => s.id == sourceId).toList();
    return src.isNotEmpty ? src.first.cols : [];
  }

  String _nameFor(String? sourceId) {
    if (sourceId == null) return '?';
    final src = widget.connectedSources.where((s) => s.id == sourceId).toList();
    return src.isNotEmpty ? src.first.name : '?';
  }

  @override
  Widget build(BuildContext context) {
    final leftCols = _colsFor(leftSourceId);
    final rightCols = _colsFor(rightSourceId);

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.violet.withOpacity(0.2)),
        color: AppColors.violet.withOpacity(0.04),
      ),
      child: Column(
        children: [
          const Text(
            'COLUMN MAPPING CONFIGURATION',
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w700,
              color: AppColors.textMuted,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 8),

          // ── Row 1: Source + Column (LEFT) ──
          Row(
            children: [
              const Text(
                'SOURCE',
                style: TextStyle(
                  fontSize: 8,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFFA78BFA),
                  letterSpacing: 0.3,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _sourceDd(widget.connectedSources, leftSourceId, (id) {
                  setState(() {
                    leftSourceId = id;
                    leftCol = null;
                  });
                }),
              ),
              const SizedBox(width: 6),
              const Text(
                'COLUMN',
                style: TextStyle(
                  fontSize: 8,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFFA78BFA),
                  letterSpacing: 0.3,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _dd(
                  leftCols,
                  leftCol,
                  (v) => setState(() => leftCol = v),
                  isMono: true,
                ),
              ),
            ],
          ),

          const SizedBox(height: 6),

          // ── Row 2: Join type + Operation ──
          Consumer<PipelineMasterProvider>(
            builder: (_, master, __) {
              final ops = master.operations;
              // API operationName drives join type options; fallback to static list
              final joinTypeItems = ops.isNotEmpty
                  ? ops.map((o) => o.operationName).toList()
                  : PipelineConfig.joinTypes;
              // Keep joinType in sync when items load
              if (joinTypeItems.isNotEmpty &&
                  !joinTypeItems.contains(joinType)) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (mounted) setState(() => joinType = joinTypeItems.first);
                });
              }
              return Row(
                children: [
                  const Text(
                    '↕',
                    style: TextStyle(color: AppColors.violet, fontSize: 16),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: _dd(
                      joinTypeItems,
                      joinType,
                      (v) => setState(() => joinType = v ?? joinType),
                      isRelation: true,
                    ),
                  ),
                  const SizedBox(width: 6),
                  // operationValue is always '=' per API — show as fixed badge
                  Container(
                    height: 30,
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: AppColors.amber.withOpacity(0.4),
                      ),
                      color: AppColors.amber.withOpacity(0.08),
                    ),
                    child: const Center(
                      child: Text(
                        '=',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.amber,
                          fontWeight: FontWeight.w700,
                          fontFamily: 'monospace',
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  const Text(
                    '↕',
                    style: TextStyle(color: AppColors.violet, fontSize: 16),
                  ),
                ],
              );
            },
          ),

          const SizedBox(height: 6),

          // ── Row 3: Dependent Source + Column (RIGHT) ──
          Row(
            children: [
              const Text(
                'DEP SOURCE',
                style: TextStyle(
                  fontSize: 8,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF93C5FD),
                  letterSpacing: 0.3,
                ),
              ),
              const SizedBox(width: 4),
              Expanded(
                child: _sourceDd(widget.connectedSources, rightSourceId, (id) {
                  setState(() {
                    rightSourceId = id;
                    rightCol = null;
                  });
                }),
              ),
              const SizedBox(width: 6),
              const Text(
                'COLUMN',
                style: TextStyle(
                  fontSize: 8,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF93C5FD),
                  letterSpacing: 0.3,
                ),
              ),
              const SizedBox(width: 4),
              Expanded(
                child: _dd(
                  rightCols,
                  rightCol,
                  (v) => setState(() => rightCol = v),
                  isMono: true,
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          // ── Add button ──
          InkWell(
            onTap: () {
              if (leftSourceId == null ||
                  leftCol == null ||
                  rightSourceId == null ||
                  rightCol == null)
                return;
              context.read<PipelineController>().addMappingToJoin(
                widget.nodeId,
                ColumnMapping(
                  leftSourceId: leftSourceId!,
                  leftCol: leftCol!,
                  joinType: joinType,
                  operationValue: operationValue,
                  rightSourceId: rightSourceId!,
                  rightCol: rightCol!,
                ),
              );
              setState(() {
                leftCol = null;
                rightCol = null;
              });
            },
            borderRadius: BorderRadius.circular(7),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 7),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(7),
                color: AppColors.violet.withOpacity(0.15),
                border: Border.all(color: AppColors.violet.withOpacity(0.3)),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.add, size: 14, color: AppColors.violet),
                  SizedBox(width: 4),
                  Text(
                    'Add Mapping',
                    style: TextStyle(
                      color: AppColors.violet,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Source dropdown — uses node.id as value (unique), shows node.name as label
  Widget _sourceDd(
    List<PipelineNode> sources,
    String? selectedId,
    ValueChanged<String?> onChanged,
  ) {
    return Container(
      height: 30,
      padding: const EdgeInsets.symmetric(horizontal: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: AppColors.border2),
        color: AppColors.surface2,
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          isExpanded: true,
          isDense: true,
          value: sources.any((s) => s.id == selectedId) ? selectedId : null,
          hint: const Text(
            '-- select --',
            style: TextStyle(fontSize: 9, color: AppColors.textDim),
          ),
          dropdownColor: AppColors.surface2,
          style: const TextStyle(
            fontSize: 10,
            color: AppColors.text,
            fontWeight: FontWeight.w600,
          ),
          icon: const Icon(
            Icons.keyboard_arrow_down,
            size: 14,
            color: AppColors.textDim,
          ),
          items: sources
              .map(
                (s) => DropdownMenuItem<String>(
                  value: s.id, // unique ID as value
                  child: Text(
                    s.name,
                    overflow: TextOverflow.ellipsis,
                  ), // name as display
                ),
              )
              .toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _dd(
    List<String> items,
    String? value,
    ValueChanged<String?> onChanged, {
    bool isRelation = false,
    bool isMono = false,
  }) {
    return Container(
      height: 30,
      padding: const EdgeInsets.symmetric(horizontal: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: isRelation
              ? AppColors.violet.withOpacity(0.3)
              : AppColors.border2,
        ),
        color: isRelation
            ? AppColors.violet.withOpacity(0.12)
            : AppColors.surface2,
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          isExpanded: true,
          isDense: true,
          value: items.contains(value) ? value : null,
          hint: const Text(
            '-- select --',
            style: TextStyle(fontSize: 9, color: AppColors.textDim),
          ),
          dropdownColor: AppColors.surface2,
          style: TextStyle(
            fontSize: 10,
            color: isRelation ? AppColors.violet : AppColors.text,
            fontFamily: isMono ? 'monospace' : null,
            fontWeight: FontWeight.w600,
          ),
          icon: Icon(
            Icons.keyboard_arrow_down,
            size: 14,
            color: isRelation ? Colors.white54 : AppColors.textDim,
          ),
          items: items
              .map(
                (s) => DropdownMenuItem(
                  value: s,
                  child: Text(s, overflow: TextOverflow.ellipsis),
                ),
              )
              .toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// OUTPUT NODE BODY (same as HTML output-node with result table)
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
