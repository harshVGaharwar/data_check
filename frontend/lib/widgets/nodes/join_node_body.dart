import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../theme/app_theme.dart';
import '../../models/pipeline_models.dart';
import '../../models/pipeline_config.dart';
import '../../controllers/pipeline_controller.dart';
import '../../providers/pipeline_master_provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/pipeline_service.dart';
import '../mapping_preview_dialog.dart';

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
    final isSingleSourceReady =
        ctrl.requiredSourceCount == 1 &&
        connectedSources.length == 1 &&
        connectedSources[0].selectedCols.isNotEmpty;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Header ──
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: AppColors.violet.withValues(alpha: 0.12),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(10)),
            border: Border(
              bottom: BorderSide(
                color: AppColors.violet.withValues(alpha: 0.2),
              ),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 26,
                height: 26,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(6),
                  color: AppColors.violet.withValues(alpha: 0.2),
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
                  color: Colors.white.withValues(alpha: 0.1),
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
                  color: AppColors.red.withValues(alpha: 0.6),
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
                        color: color.withValues(alpha: 0.08),
                        border: Border.all(color: color.withValues(alpha: 0.2)),
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

                // ── Single-source output column selector ──
                if (ctrl.requiredSourceCount == 1 &&
                    connectedSources.length == 1 &&
                    connectedSources[0].cols.isNotEmpty) ...[
                  _SingleSourceColumnSelector(source: connectedSources[0]),
                  const SizedBox(height: 10),
                ],
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
                                      .withValues(alpha: 0.7),
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
                                color: AppColors.violet.withValues(alpha: 0.15),
                                border: Border.all(
                                  color: AppColors.violet.withValues(
                                    alpha: 0.3,
                                  ),
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
                                color: AppColors.amber.withValues(alpha: 0.12),
                                border: Border.all(
                                  color: AppColors.amber.withValues(alpha: 0.3),
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
                                      .withValues(alpha: 0.7),
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
              if (validMappings.isNotEmpty || isSingleSourceReady) ...[
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
                          AppColors.green.withValues(alpha: 0.8),
                        ],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.green.withValues(alpha: 0.3),
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
    final authUser = context.read<AuthProvider>().user?.user;
    final userName = authUser?.employeeCode ?? '';
    debugPrint(
      '[SUBMIT] authUser=$authUser name=${authUser?.name} empCode=${authUser?.employeeCode}',
    );

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
                  color: AppColors.amber.withValues(alpha: 0.15),
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

    // ── Build sourceNodes early (needed for preview dialog) ──
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

    // ── Show preview dialog — only proceed if user confirms ──
    final confirmed = await showMappingPreview(
      context,
      ctrl: ctrl,
      sourceNodes: sourceNodes,
    );
    if (confirmed != true) return;

    if (!context.mounted) return;

    final templateId = ctrl.sidebarTemplateId;
    final deptId = ctrl.sidebarDeptId;
    final templateName = ctrl.sidebarTemplate;

    // ── 1. Sources (only those connected to a join node via edges) ──
    const sourceTypeValueToId = {'Manual': 1, 'QRS': 2, 'FC': 3};
    final sources = sourceNodes.asMap().entries.map((entry) {
      final s = entry.value;
      final sourceId = sourceTypeValueToId[s.sourceTypeValue] ?? 0;
      return {
        'TemplateId': templateId,
        'SourceId': s.sourceTypeId > 0 ? s.sourceTypeId.toString() : "",

        /// jo source master se ID mil rahi hai wo
        'SourceName': s.name,
        'SourceType': sourceId.toString(),

        /// jo drag kiye ho wo pass hoga
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

    // ── 5. Output Columns (source col → user-defined output col name) ──
    final deptIdInt = int.tryParse(deptId) ?? 0;
    final outputColumns = <Map<String, dynamic>>[];
    for (final s in sourceNodes) {
      for (final col in s.selectedCols) {
        final outputName = (s.columnAliases[col] ?? '').isNotEmpty
            ? s.columnAliases[col]!
            : col;
        outputColumns.add({
          'template_id': templateId,
          'department': deptIdInt.toString(),
          'sourceid': sourceTypeValueToId[s.sourceTypeValue].toString(),
          'sourceName': s.name,
          'SourceColName': col,
          'ColumnName': outputName,
        });
      }
    }

    // ── Full payload ──
    final payload = {
      'TemplateId': templateId,
      'createdBy': userName,
      'Sources': sources,
      'JoinMappings': joinMappings,
      'Edges': edgeList,
      'connectedSources': connectedSourcesData,
      'outputColumns': outputColumns,
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
                // ── Top banner with icon ──
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
                                  color: AppColors.green.withValues(
                                    alpha: 0.45,
                                  ),
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

                // ── Body ──
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                  child: Column(
                    children: [
                      if (submitTemplateId != null) ...[
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
                                  color: AppColors.green.withValues(
                                    alpha: 0.14,
                                  ),
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
                                    submitTemplateId.toString(),
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
                                  color: AppColors.green.withValues(
                                    alpha: 0.15,
                                  ),
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

                      // Done button
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
                                  letterSpacing: 0.3,
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

  @override
  Widget build(BuildContext context) {
    final leftCols = _colsFor(leftSourceId);
    final rightCols = _colsFor(rightSourceId);

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.violet.withValues(alpha: 0.2)),
        color: AppColors.violet.withValues(alpha: 0.04),
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
                        color: AppColors.amber.withValues(alpha: 0.4),
                      ),
                      color: AppColors.amber.withValues(alpha: 0.08),
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
                  rightCol == null) {
                return;
              }
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
                color: AppColors.violet.withValues(alpha: 0.15),
                border: Border.all(
                  color: AppColors.violet.withValues(alpha: 0.3),
                ),
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
              ? AppColors.violet.withValues(alpha: 0.3)
              : AppColors.border2,
        ),
        color: isRelation
            ? AppColors.violet.withValues(alpha: 0.12)
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
// SINGLE-SOURCE OUTPUT COLUMN SELECTOR
// Shown inside the join node when requiredSourceCount == 1 and the one source
// is connected. Lets the user pick which columns go to the output before submit.
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

class _SingleSourceColumnSelector extends StatefulWidget {
  final PipelineNode source;
  const _SingleSourceColumnSelector({required this.source});

  @override
  State<_SingleSourceColumnSelector> createState() =>
      _SingleSourceColumnSelectorState();
}

class _SingleSourceColumnSelectorState
    extends State<_SingleSourceColumnSelector> {
  final _searchCtrl = TextEditingController();

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ctrl = context.watch<PipelineController>();
    final src = ctrl.findNode(widget.source.id) ?? widget.source;
    final query = _searchCtrl.text.toLowerCase();
    final filtered = src.cols
        .where((c) => query.isEmpty || c.toLowerCase().contains(query))
        .toList();
    final total = src.cols.length;
    final selCount = src.selectedCols.length;
    final progress = total > 0 ? selCount / total : 0.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Divider + label
        Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(7),
            color: AppColors.violet.withValues(alpha: 0.06),
            border: Border.all(color: AppColors.violet.withValues(alpha: 0.18)),
          ),
          child: Row(
            children: [
              const Icon(Icons.edit, size: 12, color: AppColors.violet),
              const SizedBox(width: 6),
              const Expanded(
                child: Text(
                  'DEFINE OUTPUT COLUMNS',
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    color: AppColors.violet,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  color: selCount > 0 ? AppColors.violet : AppColors.surface2,
                ),
                child: Text(
                  '$selCount / $total',
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    color: selCount > 0 ? Colors.white : AppColors.textMuted,
                  ),
                ),
              ),
            ],
          ),
        ),

        // Search + All / Clear
        Row(
          children: [
            Expanded(
              child: SizedBox(
                height: 28,
                child: TextField(
                  controller: _searchCtrl,
                  onChanged: (_) => setState(() {}),
                  style: const TextStyle(color: AppColors.text, fontSize: 11),
                  decoration: InputDecoration(
                    hintText: 'Search columns…',
                    hintStyle: const TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 10,
                    ),
                    prefixIcon: const Icon(
                      Icons.search_rounded,
                      size: 13,
                      color: AppColors.textDim,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 0,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(6),
                      borderSide: const BorderSide(color: AppColors.border2),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(6),
                      borderSide: const BorderSide(color: AppColors.border2),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(6),
                      borderSide: const BorderSide(
                        color: AppColors.violet,
                        width: 1.5,
                      ),
                    ),
                    filled: true,
                    fillColor: AppColors.bg,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 5),
            _ColToolBtn(
              label: 'All',
              icon: Icons.done_all_rounded,
              color: AppColors.violet,
              onTap: () {
                for (final c in src.cols) {
                  if (!src.selectedCols.contains(c)) {
                    ctrl.toggleColumn(src.id, c);
                  }
                }
              },
            ),
            const SizedBox(width: 3),
            _ColToolBtn(
              label: 'Clear',
              icon: Icons.close_rounded,
              color: AppColors.red,
              onTap: () {
                for (final c in List<String>.from(src.selectedCols)) {
                  ctrl.toggleColumn(src.id, c);
                }
              },
            ),
          ],
        ),

        const SizedBox(height: 6),

        // Progress bar
        ClipRRect(
          borderRadius: BorderRadius.circular(3),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 4,
            backgroundColor: AppColors.border,
            valueColor: const AlwaysStoppedAnimation<Color>(AppColors.violet),
          ),
        ),

        const SizedBox(height: 8),

        // Column chips
        filtered.isEmpty
            ? Container(
                padding: const EdgeInsets.symmetric(
                  vertical: 8,
                  horizontal: 10,
                ),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(6),
                  color: AppColors.bg,
                  border: Border.all(color: AppColors.border),
                ),
                child: const Center(
                  child: Text(
                    'No columns match',
                    style: TextStyle(color: AppColors.textMuted, fontSize: 10),
                  ),
                ),
              )
            : Wrap(
                spacing: 5,
                runSpacing: 5,
                children: filtered.map((col) {
                  final sel = src.selectedCols.contains(col);
                  return GestureDetector(
                    onTap: () => ctrl.toggleColumn(src.id, col),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(6),
                        color: sel ? AppColors.violet : AppColors.bg,
                        border: Border.all(
                          color: sel ? AppColors.violet : AppColors.border2,
                          width: sel ? 1.5 : 1,
                        ),
                        boxShadow: sel
                            ? [
                                BoxShadow(
                                  color: AppColors.violet.withValues(
                                    alpha: 0.25,
                                  ),
                                  blurRadius: 4,
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
                              size: 10,
                              color: Colors.white,
                            ),
                            const SizedBox(width: 3),
                          ],
                          Text(
                            col,
                            style: TextStyle(
                              color: sel ? Colors.white : AppColors.textDim,
                              fontSize: 10,
                              fontFamily: 'monospace',
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

        // Alias table
        if (src.selectedCols.isNotEmpty) ...[
          const SizedBox(height: 10),
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(8),
                    ),
                    color: AppColors.bg,
                    border: Border(
                      bottom: BorderSide(
                        color: AppColors.violet.withValues(alpha: 0.2),
                      ),
                    ),
                  ),
                  child: const Row(
                    children: [
                      Icon(
                        Icons.drive_file_rename_outline_rounded,
                        size: 11,
                        color: AppColors.violet,
                      ),
                      SizedBox(width: 5),
                      Text(
                        'Source column',
                        style: TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 8.5,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.4,
                        ),
                      ),
                      Spacer(),
                      Text(
                        'Output alias',
                        style: TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 8.5,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.4,
                        ),
                      ),
                      SizedBox(width: 4),
                    ],
                  ),
                ),
                ...src.selectedCols.asMap().entries.map((e) {
                  final i = e.key;
                  final col = e.value;
                  final isLast = i == src.selectedCols.length - 1;
                  final initAlias = src.columnAliases[col] ?? '';
                  return _AliasRow(
                    sourceId: src.id,
                    col: col,
                    initialAlias: initAlias,
                    isLast: isLast,
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

class _ColToolBtn extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  const _ColToolBtn({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 5),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(6),
          color: color.withValues(alpha: 0.08),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 10, color: color),
            const SizedBox(width: 3),
            Text(
              label,
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AliasRow extends StatefulWidget {
  final String sourceId;
  final String col;
  final String initialAlias;
  final bool isLast;
  const _AliasRow({
    required this.sourceId,
    required this.col,
    required this.initialAlias,
    required this.isLast,
  });

  @override
  State<_AliasRow> createState() => _AliasRowState();
}

class _AliasRowState extends State<_AliasRow> {
  late final TextEditingController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: widget.initialAlias);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        borderRadius: widget.isLast
            ? const BorderRadius.vertical(bottom: Radius.circular(8))
            : null,
        border: widget.isLast
            ? null
            : const Border(
                bottom: BorderSide(color: AppColors.border, width: 0.8),
              ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              widget.col,
              style: const TextStyle(
                color: AppColors.text,
                fontSize: 10,
                fontFamily: 'monospace',
                fontWeight: FontWeight.w500,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: SizedBox(
              height: 26,
              child: TextField(
                controller: _ctrl,
                onChanged: (v) => context
                    .read<PipelineController>()
                    .setColumnAlias(widget.sourceId, widget.col, v),
                style: const TextStyle(fontSize: 10, color: AppColors.text),
                decoration: InputDecoration(
                  hintText: widget.col,
                  hintStyle: const TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 9.5,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 7,
                    vertical: 0,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(5),
                    borderSide: const BorderSide(color: AppColors.border2),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(5),
                    borderSide: const BorderSide(color: AppColors.border2),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(5),
                    borderSide: const BorderSide(
                      color: AppColors.violet,
                      width: 1.5,
                    ),
                  ),
                  filled: true,
                  fillColor: AppColors.bg,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// OUTPUT NODE BODY (same as HTML output-node with result table)
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
