
// ─────────────────────────────────────────────────────────────────────────────
// CONFIG PREVIEW BOTTOM SHEET  (Static + UserDefined)
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:vizualizer/presentation/controllers/pipeline_controller.dart';
import 'package:vizualizer/core/theme/app_theme.dart';
import 'package:vizualizer/data/models/pipeline_models.dart';
import 'package:vizualizer/presentation/providers/pipeline_master_provider.dart';
import 'package:vizualizer/presentation/widgets/pipeline/mapping_preview_dialog.dart';

class ConfigPreviewSheet extends StatelessWidget {
  final PipelineController ctrl;
  final PipelineMasterProvider master;
  final List<PipelineNode> sourceNodes;
  final List<PipelineNode> joinNodes;
  final bool isUniMailing;
  final bool isDynamicUniMailing;
  final String caseTitle;
  final VoidCallback onConfirm;

  const ConfigPreviewSheet({super.key, 
    required this.ctrl,
    required this.master,
    required this.sourceNodes,
    required this.joinNodes,
    required this.onConfirm,
    this.isUniMailing = false,
    this.isDynamicUniMailing = false,
    this.caseTitle = '',
  });

  static const _cellStyle = TextStyle(fontSize: 10.5, color: AppColors.text);
  static const _headerStyle = TextStyle(
    fontSize: 9.5,
    color: AppColors.textMuted,
    fontWeight: FontWeight.w700,
    letterSpacing: 0.4,
  );

  Widget _tableHeader(List<String> cols, List<int> flex) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
    decoration: const BoxDecoration(
      color: AppColors.bg,
      border: Border(bottom: BorderSide(color: AppColors.border)),
    ),
    child: Row(
      children: cols
          .asMap()
          .entries
          .map(
            (e) => Expanded(
              flex: flex[e.key],
              child: Text(e.value, style: _headerStyle),
            ),
          )
          .toList(),
    ),
  );

  Widget _tableRow(
    List<String> cells,
    List<int> flex, {
    bool isLast = false,
    bool isEven = false,
  }) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    decoration: BoxDecoration(
      color: isEven
          ? AppColors.surface
          : AppColors.surface2.withValues(alpha: 0.4),
      border: isLast
          ? null
          : const Border(
              bottom: BorderSide(color: AppColors.border, width: 0.6),
            ),
    ),
    child: Row(
      children: cells
          .asMap()
          .entries
          .map(
            (e) => Expanded(
              flex: flex[e.key],
              child: Text(
                e.value,
                style: _cellStyle,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          )
          .toList(),
    ),
  );

  Widget _tile({
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
    required bool initiallyExpanded,
    required Widget child,
  }) => Container(
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(10),
      border: Border.all(color: AppColors.border),
    ),
    child: Theme(
      data: ThemeData(dividerColor: Colors.transparent),
      child: ExpansionTile(
        initiallyExpanded: initiallyExpanded,
        tilePadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
        childrenPadding: EdgeInsets.zero,
        leading: Container(
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color.withValues(alpha: 0.12),
          ),
          child: Icon(icon, size: 15, color: color),
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: AppColors.text,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: const TextStyle(fontSize: 10, color: AppColors.textMuted),
        ),
        children: [
          const Divider(height: 1, color: AppColors.border),
          child,
        ],
      ),
    ),
  );

  Widget _sourcesSection() {
    const headers = [
      'Source',
      'Type',
      'Col File',
      'Query File',
      'Separator',
      'Cols',
    ];
    const flex = [3, 2, 3, 3, 2, 2];
    return Column(
      children: [
        _tableHeader(headers, flex),
        ...sourceNodes.asMap().entries.map((e) {
          final i = e.key;
          final s = e.value;
          return _tableRow(
            [
              s.name,
              s.sourceTypeName.isNotEmpty
                  ? s.sourceTypeName
                  : s.sourceTypeValue,
              s.fileName?.isNotEmpty == true ? s.fileName! : '—',
              s.queryFileName?.isNotEmpty == true ? s.queryFileName! : '—',
              s.separator,
              '${s.cols.length}',
            ],
            flex,
            isLast: i == sourceNodes.length - 1,
            isEven: i.isEven,
          );
        }),
      ],
    );
  }

  Widget _operationSection() {
    final mappings =
        <
          ({
            String leftSrc,
            String leftCol,
            String joinType,
            String rightSrc,
            String rightCol,
          })
        >[];

    for (final j in joinNodes) {
      for (final m in j.mappings.where((m) => m.isValid)) {
        final lSrc = sourceNodes
            .where((n) => n.id == m.leftSourceId)
            .firstOrNull;
        final rSrc = sourceNodes
            .where((n) => n.id == m.rightSourceId)
            .firstOrNull;
        final resolvedJoin =
            master.operations
                .where((o) => o.operationName == m.joinType)
                .map((o) => o.operationValue)
                .firstOrNull ??
            m.joinType;
        mappings.add((
          leftSrc: lSrc?.name ?? m.leftSourceId,
          leftCol: m.leftCol,
          joinType: resolvedJoin,
          rightSrc: rSrc?.name ?? m.rightSourceId,
          rightCol: m.rightCol,
        ));
      }
    }

    if (mappings.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: Text(
          'No join operations configured.',
          style: TextStyle(fontSize: 11, color: AppColors.textMuted),
        ),
      );
    }

    return Column(
      children: mappings.asMap().entries.map((e) {
        final i = e.key;
        final m = e.value;
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: i.isEven
                ? AppColors.surface
                : AppColors.surface2.withValues(alpha: 0.4),
            border: i == mappings.length - 1
                ? null
                : const Border(
                    bottom: BorderSide(color: AppColors.border, width: 0.6),
                  ),
          ),
          child: Wrap(
            spacing: 8,
            runSpacing: 6,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              _chip('${m.leftSrc}.${m.leftCol}', AppColors.blue),
              _chip(m.joinType, AppColors.violet, bold: true),
              _chip('${m.rightSrc}.${m.rightCol}', AppColors.green),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _chip(String label, Color color, {bool bold = false}) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(5),
      color: color.withValues(alpha: 0.09),
      border: Border.all(color: color.withValues(alpha: 0.22)),
    ),
    child: Text(
      label,
      style: TextStyle(
        fontSize: 10,
        fontFamily: bold ? null : 'monospace',
        color: color,
        fontWeight: bold ? FontWeight.w700 : FontWeight.w600,
        letterSpacing: bold ? 0.3 : 0,
      ),
    ),
  );

  Widget _outputSection() {
    int autoRank = 1;
    final cols =
        <
          ({
            String source,
            String colName,
            String alias,
            int priority,
            bool isUnique,
          })
        >[];

    for (final s in sourceNodes) {
      for (final col in s.selectedCols) {
        final alias = (s.columnAliases[col] ?? '').isNotEmpty
            ? s.columnAliases[col]!
            : col;
        cols.add((
          source: s.name,
          colName: col,
          alias: alias,
          priority: s.columnPriorities[col] ?? autoRank,
          isUnique: s.columnUniqueFields[col] ?? false,
        ));
        autoRank++;
      }
    }
    cols.sort((a, b) => a.priority.compareTo(b.priority));

    const headers = ['Priority', 'Source', 'Column', 'Output Name', 'Unique'];
    const flex = [2, 3, 3, 3, 2];

    return Column(
      children: [
        _tableHeader(headers, flex),
        ...cols.asMap().entries.map((e) {
          final i = e.key;
          final c = e.value;
          return _tableRow(
            [
              '${c.priority}',
              c.source,
              c.colName,
              c.alias != c.colName ? c.alias : '—',
              c.isUnique ? '✓' : '—',
            ],
            flex,
            isLast: i == cols.length - 1,
            isEven: i.isEven,
          );
        }),
      ],
    );
  }

  Widget _uniMailingOutputSection() {
    String resolveCol(String key) =>
        key.contains('::') ? key.split('::')[1] : key;

    PipelineNode? resolveNode(String key) {
      if (!key.contains('::')) return null;
      final nodeId = key.split('::')[0];
      return sourceNodes.where((n) => n.id == nodeId).firstOrNull;
    }

    String resolveSourceName(String key) =>
        resolveNode(key)?.name ?? (key.isNotEmpty ? key : '—');

    bool resolveUnique(String key) {
      final node = resolveNode(key);
      final col = resolveCol(key);
      return node?.columnUniqueFields[col] ?? false;
    }

    // Mandatory fields
    final mandatoryRows = kMandatoryFields.map((f) {
      final val = ctrl.uniMailingMandatory[f] ?? '';
      return (
        field: f,
        source: val.isNotEmpty ? resolveSourceName(val) : '—',
        column: val.isNotEmpty ? resolveCol(val) : '—',
        isUnique: val.isNotEmpty ? resolveUnique(val) : false,
        mapped: val.isNotEmpty,
      );
    }).toList();

    // Custom columns
    final sortedCustom =
        ctrl.uniMailingCustom.entries.where((e) => e.value.isNotEmpty).toList()
          ..sort((a, b) {
            final ai = int.tryParse(a.key.substring(1)) ?? 0;
            final bi = int.tryParse(b.key.substring(1)) ?? 0;
            return ai.compareTo(bi);
          });

    const headers = ['Field', 'Source', 'Column', 'Status'];
    const flex = [3, 3, 3, 2];

    final allRows = [
      ...mandatoryRows.asMap().entries.map((e) {
        final i = e.key;
        final r = e.value;
        final isLast = i == mandatoryRows.length - 1 && sortedCustom.isEmpty;
        return _tableRow(
          [r.field, r.source, r.column, r.mapped ? '✓ mapped' : '✗ empty'],
          flex,
          isLast: isLast,
          isEven: i.isEven,
        );
      }),
    ];

    if (sortedCustom.isNotEmpty) {
      allRows.addAll(
        sortedCustom.asMap().entries.map((e) {
          final i = e.key;
          final entry = e.value;
          final val = entry.value;
          return _tableRow(
            [entry.key, resolveSourceName(val), resolveCol(val), '✓ mapped'],
            flex,
            isLast: i == sortedCustom.length - 1,
            isEven: (mandatoryRows.length + i).isEven,
          );
        }),
      );
    }

    return Column(children: [_tableHeader(headers, flex), ...allRows]);
  }

  // ── Helpers for Dynamic UniMailing per-key preview ───────────────────────

  Widget _perKeySnapshotSourcesSection(List<Map<dynamic, dynamic>> snapSrcs) {
    if (snapSrcs.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(14),
        child: Text(
          'No sources configured.',
          style: TextStyle(fontSize: 10, color: AppColors.textMuted),
        ),
      );
    }
    const headers = ['Source', 'Type', 'Col File', 'Cols'];
    const flex = [3, 2, 3, 2];
    return Column(
      children: [
        _tableHeader(headers, flex),
        ...snapSrcs.asMap().entries.map((e) {
          final i = e.key;
          final s = e.value;
          final cols = s['cols'] as List? ?? [];
          final fn = s['fileName']?.toString() ?? '';
          return _tableRow(
            [
              s['name']?.toString() ?? '—',
              s['sourceTypeValue']?.toString() ?? '—',
              fn.isNotEmpty ? fn : '—',
              '${cols.length}',
            ],
            flex,
            isLast: i == snapSrcs.length - 1,
            isEven: i.isEven,
          );
        }),
      ],
    );
  }

  Widget _perKeySnapshotOperationsSection(
    List<Map<dynamic, dynamic>> snapJoinMappings,
  ) {
    if (snapJoinMappings.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: Text(
          'No join operations configured.',
          style: TextStyle(fontSize: 11, color: AppColors.textMuted),
        ),
      );
    }
    return Column(
      children: snapJoinMappings.asMap().entries.map((e) {
        final i = e.key;
        final m = e.value;
        final leftSrc = m['leftSourceName']?.toString() ??
            m['leftSourceId']?.toString() ?? '';
        final leftCol = m['leftCol']?.toString() ?? '';
        final joinType = master.operations
                .where((o) => o.operationName == m['joinType']?.toString())
                .map((o) => o.operationValue)
                .firstOrNull ??
            m['joinType']?.toString() ??
            '';
        final rightSrc = m['rightSourceName']?.toString() ??
            m['rightSourceId']?.toString() ?? '';
        final rightCol = m['rightCol']?.toString() ?? '';
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: i.isEven
                ? AppColors.surface
                : AppColors.surface2.withValues(alpha: 0.4),
            border: i == snapJoinMappings.length - 1
                ? null
                : const Border(
                    bottom: BorderSide(color: AppColors.border, width: 0.6),
                  ),
          ),
          child: Wrap(
            spacing: 8,
            runSpacing: 6,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              _chip('$leftSrc.$leftCol', AppColors.blue),
              _chip(joinType, AppColors.violet, bold: true),
              _chip('$rightSrc.$rightCol', AppColors.green),
            ],
          ),
        );
      }).toList(),
    );
  }

  /// Fallback: shows sources derived from cfg['SelectedColumns'] (no snapshot).
  Widget _perKeySourcesSection(List<Map<String, dynamic>> savedSelCols) {
    // Group selected columns by source name
    final sourceMap = <String, int>{};
    for (final sc in savedSelCols) {
      final name = sc['NodeName']?.toString() ?? '';
      if (name.isNotEmpty) sourceMap[name] = (sourceMap[name] ?? 0) + 1;
    }

    if (sourceMap.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(14),
        child: Text(
          'No sources configured.',
          style: TextStyle(fontSize: 10, color: AppColors.textMuted),
        ),
      );
    }

    const headers = ['Source', 'Columns Used'];
    const flex = [4, 2];
    final entries = sourceMap.entries.toList();
    return Column(
      children: [
        _tableHeader(headers, flex),
        ...entries.asMap().entries.map(
          (e) => _tableRow(
            [
              e.value.key,
              '${e.value.value} col${e.value.value == 1 ? '' : 's'}',
            ],
            flex,
            isLast: e.key == entries.length - 1,
            isEven: e.key.isEven,
          ),
        ),
      ],
    );
  }

  Widget _dynKeySelectedCols(
    List<({
String source, String column, bool isUnique})> cols,
  ) {
    if (cols.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(14),
        child: Text(
          'No columns selected.',
          style: TextStyle(fontSize: 10, color: AppColors.textMuted),
        ),
      );
    }
    const headers = ['Source', 'Column', 'isUnique'];
    const flex = [4, 4, 2];
    return Column(
      children: [
        _tableHeader(headers, flex),
        ...cols.asMap().entries.map(
          (e) => _tableRow(
            [e.value.source, e.value.column, e.value.isUnique ? '✓' : '—'],
            flex,
            isLast: e.key == cols.length - 1,
            isEven: e.key.isEven,
          ),
        ),
      ],
    );
  }

  Widget _dynKeyOutputConfig(List<List<String>> rows) {
    if (rows.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(14),
        child: Text(
          'No fields configured.',
          style: TextStyle(fontSize: 10, color: AppColors.textMuted),
        ),
      );
    }
    const headers = ['Field', 'Source', 'Column'];
    const flex = [3, 3, 3];
    return Column(
      children: [
        _tableHeader(headers, flex),
        ...rows.asMap().entries.map(
          (e) => _tableRow(
            e.value,
            flex,
            isLast: e.key == rows.length - 1,
            isEven: e.key.isEven,
          ),
        ),
      ],
    );
  }

  Widget _dynKeySection(String key, Map<String, dynamic>? cfg) {
    final keyType = cfg?['KeyType'] as String? ?? '—';
    final isStatic = keyType == 'Static';
    final typeColor = isStatic ? AppColors.blue : AppColors.green;

    // Per-key canvas snapshot (accurate after canvas is cleared for next key)
    final snapSrcs = (cfg?['_snapshotSources'] as List? ?? [])
        .whereType<Map<dynamic, dynamic>>()
        .toList();
    final snapJoinMappings = (cfg?['_snapshotJoinMappings'] as List? ?? [])
        .whereType<Map<dynamic, dynamic>>()
        .toList();
    final perKeyHasJoins = snapJoinMappings.isNotEmpty;
    final perKeyJoinCount = snapJoinMappings.length;

    // Fallback: derive source info from SelectedColumns if no snapshot yet
    final savedSelCols = (cfg?['SelectedColumns'] as List? ?? [])
        .whereType<Map>()
        .map((m) => m.map((k, v) => MapEntry(k.toString(), v)))
        .toList();
    final perKeySrcCount = snapSrcs.isNotEmpty
        ? snapSrcs.length
        : savedSelCols
            .map((m) => m['NodeName']?.toString() ?? '')
            .where((s) => s.isNotEmpty)
            .toSet()
            .length;

    bool resolveUnique(String src, String col) {
      // Prefer the saved isUniqueField from SelectedColumns (accurate per-key).
      final saved = savedSelCols
          .where((m) => m['NodeName'] == src && m['ColName'] == col)
          .firstOrNull;
      if (saved != null) return saved['isUniqueField'] as bool? ?? false;
      // Fallback: look up current canvas node (may be wrong after canvas clear).
      final node = sourceNodes.where((n) => n.name == src).firstOrNull;
      return node?.columnUniqueFields[col] ?? false;
    }

    final seen = <String>{};
    final selCols = <({
String source, String column, bool isUnique})>[];
    void addCol(String src, String col) {
      final k = '$src::$col';
      if (src.isNotEmpty && src != '—' && seen.add(k)) {
        selCols.add((
          source: src,
          column: col,
          isUnique: resolveUnique(src, col),
        ));
      }
    }

    final outRows = <List<String>>[];
    if (cfg != null) {
      if (isStatic) {
        for (final f in (cfg['MandatoryFields'] as List? ?? [])) {
          final src = f['SourceName'] as String? ?? '—';
          final col = f['ColumnName'] as String? ?? '—';
          addCol(src, col);
          outRows.add([f['Field'] as String? ?? '—', src, col]);
        }
        for (final c in (cfg['CustomColumns'] as List? ?? [])) {
          final src = c['SourceName'] as String? ?? '—';
          final col = c['ColumnName'] as String? ?? '—';
          addCol(src, col);
          outRows.add([c['Slot'] as String? ?? '—', src, col]);
        }
      } else {
        final c1 = cfg['C1'] as Map? ?? {};
        final src = c1['SourceName'] as String? ?? '—';
        final col = c1['ColumnName'] as String? ?? '—';
        addCol(src, col);
        if (src.isNotEmpty && src != '—') {
          outRows.add(['C1', src, col]);
        }
        for (final c in (cfg['CustomColumns'] as List? ?? [])) {
          final cs = c['SourceName'] as String? ?? '—';
          final cc = c['ColumnName'] as String? ?? '—';
          addCol(cs, cc);
          outRows.add([c['Slot'] as String? ?? '—', cs, cc]);
        }
      }
    }

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: Theme(
        data: ThemeData(dividerColor: Colors.transparent),
        child: ExpansionTile(
          initiallyExpanded: false,
          tilePadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
          childrenPadding: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          collapsedShape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          backgroundColor: typeColor.withValues(alpha: 0.04),
          collapsedBackgroundColor: typeColor.withValues(alpha: 0.04),
          leading: Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: typeColor.withValues(alpha: 0.12),
            ),
            child: Icon(Icons.vpn_key_rounded, size: 13, color: typeColor),
          ),
          title: Row(
            children: [
              Flexible(
                child: Text(
                  key,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: typeColor,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(5),
                  color: typeColor.withValues(alpha: 0.10),
                  border: Border.all(color: typeColor.withValues(alpha: 0.22)),
                ),
                child: Text(
                  keyType,
                  style: TextStyle(
                    fontSize: 9.5,
                    fontWeight: FontWeight.w700,
                    color: typeColor,
                  ),
                ),
              ),
            ],
          ),
          children: [
            const Divider(height: 1, color: AppColors.border),
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                children: [
                  _tile(
                    icon: Icons.storage_rounded,
                    color: AppColors.blue,
                    title: 'Sources',
                    subtitle:
                        '$perKeySrcCount source${perKeySrcCount == 1 ? '' : 's'} configured',
                    initiallyExpanded: false,
                    child: snapSrcs.isNotEmpty
                        ? _perKeySnapshotSourcesSection(snapSrcs)
                        : _perKeySourcesSection(savedSelCols),
                  ),
                  const SizedBox(height: 8),
                  _tile(
                    icon: Icons.merge_type_rounded,
                    color: AppColors.violet,
                    title: 'Operation Details',
                    subtitle: perKeyHasJoins
                        ? '$perKeyJoinCount join condition${perKeyJoinCount == 1 ? '' : 's'}'
                        : 'No join operations',
                    initiallyExpanded: false,
                    child: _perKeySnapshotOperationsSection(snapJoinMappings),
                  ),
                  const SizedBox(height: 8),
                  _tile(
                    icon: Icons.view_column_rounded,
                    color: AppColors.blue,
                    title: 'Selected Columns',
                    subtitle:
                        '${selCols.length} column${selCols.length == 1 ? '' : 's'} used',
                    initiallyExpanded: true,
                    child: _dynKeySelectedCols(selCols),
                  ),
                  const SizedBox(height: 8),
                  _tile(
                    icon: isStatic
                        ? Icons.email_rounded
                        : Icons.dynamic_feed_rounded,
                    color: AppColors.green,
                    title: 'Output Configuration',
                    subtitle:
                        '${outRows.length} field${outRows.length == 1 ? '' : 's'} mapped',
                    initiallyExpanded: false,
                    child: _dynKeyOutputConfig(outRows),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasJoins = joinNodes.any((j) => j.mappings.any((m) => m.isValid));
    final joinCount = joinNodes.fold<int>(
      0,
      (s, j) => s + j.mappings.where((m) => m.isValid).length,
    );
    final totalSelected = sourceNodes.fold<int>(
      0,
      (s, n) => s + n.selectedCols.length,
    );

    return DraggableScrollableSheet(
      initialChildSize: 0.92,
      minChildSize: 0.5,
      maxChildSize: 0.98,
      builder: (_, scrollCtrl) => Container(
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            // Drag handle
            Center(
              child: Container(
                margin: const EdgeInsets.only(top: 12, bottom: 4),
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(2),
                  color: AppColors.border2,
                ),
              ),
            ),

            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 14),
              child: Row(
                children: [
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.blue.withValues(alpha: 0.12),
                    ),
                    child: const Icon(
                      Icons.preview_rounded,
                      size: 17,
                      color: AppColors.blue,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Review Configuration',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: AppColors.text,
                          ),
                        ),
                        if (caseTitle.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.violet.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              caseTitle,
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: AppColors.violet,
                              ),
                            ),
                          ),
                        ] else
                          const Text(
                            'Verify your setup before submitting',
                            style: TextStyle(
                              fontSize: 11,
                              color: AppColors.textMuted,
                            ),
                          ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () =>
                        Navigator.of(context, rootNavigator: true).pop(),
                    icon: const Icon(
                      Icons.close_rounded,
                      size: 18,
                      color: AppColors.textDim,
                    ),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            ),

            const Divider(height: 1, color: AppColors.border),

            Expanded(
              child: ListView(
                controller: scrollCtrl,
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                children: isDynamicUniMailing
                    ? [
                        ...ctrl.dynamicUniMailingOutputKeys.expand(
                          (key) => [
                            _dynKeySection(
                              key,
                              ctrl.savedOutputKeyConfigs[key],
                            ),
                            const SizedBox(height: 16),
                          ],
                        ),
                      ]
                    : [
                        _tile(
                          icon: Icons.storage_rounded,
                          color: AppColors.blue,
                          title: 'Sources',
                          subtitle:
                              '${sourceNodes.length} source${sourceNodes.length == 1 ? '' : 's'} configured',
                          initiallyExpanded: false,
                          child: _sourcesSection(),
                        ),
                        const SizedBox(height: 10),
                        _tile(
                          icon: Icons.merge_type_rounded,
                          color: AppColors.violet,
                          title: 'Operation Details',
                          subtitle: hasJoins
                              ? '$joinCount join condition${joinCount == 1 ? '' : 's'}'
                              : 'No join operations',
                          initiallyExpanded: false,
                          child: _operationSection(),
                        ),
                        const SizedBox(height: 10),
                        _tile(
                          icon: isUniMailing
                              ? Icons.email_rounded
                              : Icons.table_chart_rounded,
                          color: AppColors.green,
                          title: 'Output Configuration',
                          subtitle: isUniMailing
                              ? '${ctrl.uniMailingMandatory.values.where((v) => v.isNotEmpty).length} / ${kMandatoryFields.length} mandatory fields mapped'
                              : '$totalSelected column${totalSelected == 1 ? '' : 's'} selected',
                          initiallyExpanded: false,
                          child: isUniMailing
                              ? _uniMailingOutputSection()
                              : _outputSection(),
                        ),
                        const SizedBox(height: 16),
                      ],
              ),
            ),

            // Confirm button
            Container(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 20),
              decoration: const BoxDecoration(
                color: AppColors.surface,
                border: Border(top: BorderSide(color: AppColors.border)),
              ),
              child: InkWell(
                onTap: onConfirm,
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    gradient: const LinearGradient(
                      colors: [AppColors.green, Color(0xFF059669)],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.green.withValues(alpha: 0.30),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.check_circle_rounded,
                        size: 16,
                        color: Colors.white,
                      ),
                      SizedBox(width: 8),
                      Text(
                        'Submit',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 13,
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
    );
  }
}
