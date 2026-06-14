// ─────────────────────────────────────────────────────────────────────────────
// CONFIG PREVIEW BOTTOM SHEET  (Static + UserDefined)
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:vizualizer/presentation/controllers/pipeline_controller.dart';
import 'package:vizualizer/core/theme/app_theme.dart';
import 'package:vizualizer/data/models/pipeline_models.dart';
import 'package:vizualizer/data/services/master_data_service.dart';
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
  final bool readOnly;

  const ConfigPreviewSheet({
    super.key,
    required this.ctrl,
    required this.master,
    required this.sourceNodes,
    required this.joinNodes,
    required this.onConfirm,
    this.isUniMailing = false,
    this.isDynamicUniMailing = false,
    this.caseTitle = '',
    this.readOnly = false,
  });

  static const _cellStyle = TextStyle(fontSize: 10.5, color: AppColors.text);
  static const _headerStyle = TextStyle(
    fontSize: 9.5,
    color: AppColors.textMuted,
    fontWeight: FontWeight.w700,
    letterSpacing: 0.4,
  );

  static Widget _tableHeader(List<String> cols, List<int> flex) => Container(
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

  static Widget _tableRow(
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
                e.value.trim().isEmpty ? '—' : e.value,
                style: e.value.trim().isEmpty
                    ? _cellStyle.copyWith(color: AppColors.textMuted)
                    : _cellStyle,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          )
          .toList(),
    ),
  );

  static Widget _tile({
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
        final resolvedJoin = _fmtJoinType(m.joinType);
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

  static Widget _chip(String label, Color color, {bool bold = false}) =>
      Container(
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

    const headers = ['Source Name', 'Column Name', 'Output Name', 'Status'];
    const flex = [3, 3, 3, 2];

    final allRows = [
      ...mandatoryRows.asMap().entries.map((e) {
        final i = e.key;
        final r = e.value;
        final isLast = i == mandatoryRows.length - 1 && sortedCustom.isEmpty;
        return _tableRow(
          [r.source, r.column, r.field, r.mapped ? '✓ mapped' : '✗ empty'],
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
            [
              resolveSourceName(val),
              resolveCol(val),
              _slotLabel(entry.key),
              '✓ mapped',
            ],
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
        final leftSrc =
            m['leftSourceName']?.toString() ??
            m['leftSourceId']?.toString() ??
            '';
        final leftCol = m['leftCol']?.toString() ?? '';
        final joinType = _fmtJoinType(m['joinType']?.toString() ?? '');
        final rightSrc =
            m['rightSourceName']?.toString() ??
            m['rightSourceId']?.toString() ??
            '';
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
    List<({String source, String column, bool isUnique})> cols,
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
    const headers = ['Source Name', 'Column Name', 'Output Name'];
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

  /// Formats a raw join-type operationName for display.
  /// e.g. "1 - All from First" → "All from First", "left_join" → "Left Join"
  static String _fmtJoinType(String raw) {
    final cleaned = raw.replaceFirst(RegExp(r'^\d+\s*-\s*'), '');
    return cleaned
        .split('_')
        .map((w) => w.isEmpty ? w : '${w[0].toUpperCase()}${w.substring(1)}')
        .join(' ');
  }

  static String _slotLabel(String slot) {
    if (slot.length > 1 && slot[0] == 'C') {
      final n = int.tryParse(slot.substring(1));
      if (n != null) return 'Column $n';
    }
    return slot;
  }

  Widget _dynKeySection(String key, Map<String, dynamic>? cfg) {
    // ── Unconfigured key — canvas was cleared or never set up ──
    if (cfg == null) {
      return Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.red.withValues(alpha: 0.35)),
          color: AppColors.red.withValues(alpha: 0.04),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.red.withValues(alpha: 0.12),
              ),
              child: const Icon(
                Icons.vpn_key_rounded,
                size: 13,
                color: AppColors.red,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                key,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.red,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(5),
                color: AppColors.red.withValues(alpha: 0.08),
                border: Border.all(
                  color: AppColors.red.withValues(alpha: 0.25),
                ),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.warning_amber_rounded,
                    size: 10,
                    color: AppColors.red,
                  ),
                  SizedBox(width: 4),
                  Text(
                    'Not Configured',
                    style: TextStyle(
                      fontSize: 9.5,
                      fontWeight: FontWeight.w700,
                      color: AppColors.red,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    final keyType = cfg['KeyType'] as String? ?? '—';
    final isStatic = keyType == 'Static';
    final typeColor = isStatic ? AppColors.blue : AppColors.green;

    // Per-key canvas snapshot (accurate after canvas is cleared for next key)
    final snapSrcs = (cfg['_snapshotSources'] as List? ?? [])
        .whereType<Map<dynamic, dynamic>>()
        .toList();
    final snapJoinMappings = (cfg['_snapshotJoinMappings'] as List? ?? [])
        .whereType<Map<dynamic, dynamic>>()
        .toList();
    final perKeyHasJoins = snapJoinMappings.isNotEmpty;
    final perKeyJoinCount = snapJoinMappings.length;

    // Fallback: derive source info from SelectedColumns if no snapshot yet
    final savedSelCols = (cfg['SelectedColumns'] as List? ?? [])
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

    // Selected Columns tile — ALL Step-A selections saved in config.
    // Built directly from SelectedColumns so it never misses columns that
    // were selected but not yet mapped to an output slot.
    final selCols = savedSelCols
        .map(
          (sc) => (
            source: sc['NodeName']?.toString() ?? '',
            column: sc['ColName']?.toString() ?? '',
            isUnique: sc['isUniqueField'] as bool? ?? false,
          ),
        )
        .where((c) => c.source.isNotEmpty && c.column.isNotEmpty)
        .toList();

    // Output Configuration rows — built from the mapping config only.
    final outRows = <List<String>>[];
    {
      if (isStatic) {
        for (final f in (cfg['MandatoryFields'] as List? ?? [])) {
          final src = f['SourceName'] as String? ?? '';
          final col = f['ColumnName'] as String? ?? '';
          outRows.add([
            src.isNotEmpty ? src : '—',
            col.isNotEmpty ? col : '—',
            f['Field'] as String? ?? '—',
          ]);
        }
        for (final c in (cfg['CustomColumns'] as List? ?? [])) {
          final src = c['SourceName'] as String? ?? '';
          final col = c['ColumnName'] as String? ?? '';
          outRows.add([
            src.isNotEmpty ? src : '—',
            col.isNotEmpty ? col : '—',
            _slotLabel(c['Slot'] as String? ?? '—'),
          ]);
        }
      } else {
        for (final slot in ['C0', 'C1']) {
          final cm = cfg[slot] as Map? ?? {};
          final src = cm['SourceName'] as String? ?? '';
          final col = cm['ColumnName'] as String? ?? '';
          if (src.isNotEmpty && col.isNotEmpty) {
            outRows.add([src, col, _slotLabel(slot)]);
          }
        }
        for (final c in (cfg['CustomColumns'] as List? ?? [])) {
          final cs = c['SourceName'] as String? ?? '';
          final cc = c['ColumnName'] as String? ?? '';
          if (cs.isNotEmpty && cc.isNotEmpty) {
            outRows.add([cs, cc, _slotLabel(c['Slot'] as String? ?? '—')]);
          }
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
          initiallyExpanded: true,
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
                    initiallyExpanded: true,
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
                    initiallyExpanded: true,
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
                    subtitle: () {
                      // Count only truly mapped rows (source is not '—').
                      final mapped =
                          outRows.where((r) => r[0] != '—').length;
                      return '$mapped field${mapped == 1 ? '' : 's'} mapped';
                    }(),
                    initiallyExpanded: true,
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

  // ── Read-only view from raw checker config ──────────────────────────────────

  static void showFromRaw(
    BuildContext context,
    Map<String, dynamic> config, {
    String templateName = '',
  }) {
    final rawOutputCols = (config['outputColumns'] as List? ?? [])
        .whereType<Map>()
        .map((m) => m.map((k, v) => MapEntry(k.toString(), v)))
        .toList();

    final rawSources = (config['Sources'] as List? ?? [])
        .whereType<Map>()
        .map((m) => m.map((k, v) => MapEntry(k.toString(), v)))
        .toList();

    final sourceNodes = rawSources.map((src) {
      final name = src['SourceName']?.toString() ?? '';
      final sourceType = src['SourceType']?.toString() ?? '';

      final colsForSource = rawOutputCols
          .where((oc) => oc['sourceName']?.toString() == name)
          .toList();

      final selectedCols = colsForSource
          .map((oc) => oc['SourceColName']?.toString() ?? '')
          .where((c) => c.isNotEmpty)
          .toList();

      final columnAliases = <String, String>{};
      for (final oc in colsForSource) {
        final orig = oc['SourceColName']?.toString() ?? '';
        final alias = oc['ColumnName']?.toString() ?? '';
        if (orig.isNotEmpty) columnAliases[orig] = alias;
      }

      final node = PipelineNode(
        id: name,
        type: NodeType.manual,
        name: name,
        position: Offset.zero,
        sourceTypeName: sourceType,
        selectedCols: selectedCols,
        cols: selectedCols,
        columnAliases: columnAliases,
      );
      for (var i = 0; i < selectedCols.length; i++) {
        node.columnPriorities[selectedCols[i]] = i + 1;
      }
      return node;
    }).toList();

    final rawJoins = (config['JoinMappings'] as List? ?? [])
        .whereType<Map>()
        .map((m) => m.map((k, v) => MapEntry(k.toString(), v)))
        .toList();

    final mappings = rawJoins
        .map(
          (jm) => ColumnMapping(
            leftSourceId: jm['LeftSourceName']?.toString() ?? '',
            leftCol: jm['LeftColumn']?.toString() ?? '',
            joinType: jm['JoinType']?.toString() ?? '',
            rightSourceId: jm['RightSourceName']?.toString() ?? '',
            rightCol: jm['RightColumn']?.toString() ?? '',
          ),
        )
        .toList();

    final joinNodes = mappings.isEmpty
        ? <PipelineNode>[]
        : [
            PipelineNode(
              id: '_raw_join',
              type: NodeType.join,
              name: 'Join',
              position: Offset.zero,
              mappings: mappings,
            ),
          ];

    final ctrl = PipelineController();
    final master = PipelineMasterProvider(context.read<MasterDataService>());

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      constraints: BoxConstraints(
        maxWidth: MediaQuery.of(context).size.width * 0.72,
      ),
      builder: (_) => ConfigPreviewSheet(
        ctrl: ctrl,
        master: master,
        sourceNodes: sourceNodes,
        joinNodes: joinNodes,
        caseTitle: templateName,
        readOnly: true,
        onConfirm: () => Navigator.of(context, rootNavigator: true).pop(),
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
                  if (!readOnly)
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
                          initiallyExpanded: true,
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
                          initiallyExpanded: true,
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
                              ? '${ctrl.uniMailingMandatory.values.where((v) => v.isNotEmpty).length} / ${kMandatoryFields.length} UniMailing fields mapped'
                              : '$totalSelected column${totalSelected == 1 ? '' : 's'} selected',
                          initiallyExpanded: true,
                          child: isUniMailing
                              ? _uniMailingOutputSection()
                              : _outputSection(),
                        ),
                        const SizedBox(height: 16),
                      ],
              ),
            ),

            // Action buttons — Close + Submit (hidden in read-only/checker mode)
            if (!readOnly)
              Container(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 20),
                decoration: const BoxDecoration(
                  color: AppColors.surface,
                  border: Border(top: BorderSide(color: AppColors.border)),
                ),
                child: Row(
                  children: [
                    // Close button
                    Expanded(
                      child: InkWell(
                        onTap: () => Navigator.of(context).pop(),
                        borderRadius: BorderRadius.circular(10),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 13),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: AppColors.border2),
                            color: AppColors.surface,
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.close_rounded,
                                size: 16,
                                color: AppColors.textDim,
                              ),
                              SizedBox(width: 8),
                              Text(
                                'Close',
                                style: TextStyle(
                                  color: AppColors.textDim,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    // Submit button — blocked if any dynamic key is unconfigured
                    Builder(
                      builder: (context) {
                        final blocked = isDynamicUniMailing &&
                            ctrl.dynamicUniMailingOutputKeys.any(
                              (k) => !ctrl.savedOutputKeyConfigs.containsKey(k),
                            );
                        return Expanded(
                          flex: 2,
                          child: InkWell(
                            onTap: blocked ? null : onConfirm,
                            borderRadius: BorderRadius.circular(10),
                            child: Opacity(
                              opacity: blocked ? 0.45 : 1.0,
                              child: Container(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 13),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(10),
                                  gradient: const LinearGradient(
                                    colors: [
                                      AppColors.green,
                                      Color(0xFF059669),
                                    ],
                                  ),
                                  boxShadow: blocked
                                      ? null
                                      : [
                                          BoxShadow(
                                            color: AppColors.green.withValues(
                                              alpha: 0.30,
                                            ),
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
                        );
                      },
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  // ── Read-only per-key view for Dynamic+Unimailing from checker tray ─────────

  static void showFromRawDynamic(
    BuildContext context,
    List<Map<String, dynamic>> keyConfigs, {
    String templateName = '',
  }) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      constraints: BoxConstraints(
        maxWidth: MediaQuery.of(context).size.width * 0.72,
      ),
      builder: (_) => _RawDynamicPreviewSheet(
        keyConfigs: keyConfigs,
        templateName: templateName,
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Read-only bottom sheet: Dynamic+Unimailing per-key preview (checker tray)
// ─────────────────────────────────────────────────────────────────────────────

class _RawDynamicPreviewSheet extends StatelessWidget {
  final List<Map<String, dynamic>> keyConfigs;
  final String templateName;

  const _RawDynamicPreviewSheet({
    required this.keyConfigs,
    required this.templateName,
  });

  // ── per-key sections ──────────────────────────────────────────────────────

  Widget _sourcesSection(List<Map<String, dynamic>> sources) {
    if (sources.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(14),
        child: Text(
          'No sources configured.',
          style: TextStyle(fontSize: 10, color: AppColors.textMuted),
        ),
      );
    }
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
        ConfigPreviewSheet._tableHeader(headers, flex),
        ...sources.asMap().entries.map((e) {
          final i = e.key;
          final s = e.value;
          final colsStr = s['Columns']?.toString() ?? '';
          final colCount = colsStr.isEmpty
              ? 0
              : colsStr.split(',').where((c) => c.trim().isNotEmpty).length;
          return ConfigPreviewSheet._tableRow(
            [
              s['SourceName']?.toString() ?? '—',
              s['SourceType']?.toString() ?? '—',
              s['ColumnFile']?.toString().isNotEmpty == true
                  ? s['ColumnFile'].toString()
                  : '—',
              s['QueryFile']?.toString().isNotEmpty == true
                  ? s['QueryFile'].toString()
                  : '—',
              s['Separator']?.toString().isNotEmpty == true
                  ? s['Separator'].toString()
                  : '—',
              '$colCount',
            ],
            flex,
            isLast: i == sources.length - 1,
            isEven: i.isEven,
          );
        }),
      ],
    );
  }

  Widget _operationsSection(List<Map<String, dynamic>> joins) {
    if (joins.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: Text(
          'No join operations configured.',
          style: TextStyle(fontSize: 11, color: AppColors.textMuted),
        ),
      );
    }
    return Column(
      children: joins.asMap().entries.map((e) {
        final i = e.key;
        final jm = e.value;
        final leftSrc = jm['LeftSourceName']?.toString() ?? '';
        final leftCol = jm['LeftColumn']?.toString() ?? '';
        final joinType = ConfigPreviewSheet._fmtJoinType(
          jm['JoinType']?.toString() ?? '',
        );
        final rightSrc = jm['RightSourceName']?.toString() ?? '';
        final rightCol = jm['RightColumn']?.toString() ?? '';
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: i.isEven
                ? AppColors.surface
                : AppColors.surface2.withValues(alpha: 0.4),
            border: i == joins.length - 1
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
              ConfigPreviewSheet._chip('$leftSrc.$leftCol', AppColors.blue),
              ConfigPreviewSheet._chip(joinType, AppColors.violet, bold: true),
              ConfigPreviewSheet._chip('$rightSrc.$rightCol', AppColors.green),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _outputConfigSection(List<Map<String, dynamic>> outputCols) {
    if (outputCols.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(14),
        child: Text(
          'No fields configured.',
          style: TextStyle(fontSize: 10, color: AppColors.textMuted),
        ),
      );
    }
    const headers = ['Source Name', 'Column Name', 'Output Name'];
    const flex = [3, 3, 3];
    return Column(
      children: [
        ConfigPreviewSheet._tableHeader(headers, flex),
        ...outputCols.asMap().entries.map((e) {
          final i = e.key;
          final oc = e.value;
          return ConfigPreviewSheet._tableRow(
            [
              oc['sourceName']?.toString() ?? '—',
              oc['SourceColName']?.toString() ?? '—',
              oc['ColumnName']?.toString() ?? '—',
            ],
            flex,
            isLast: i == outputCols.length - 1,
            isEven: i.isEven,
          );
        }),
      ],
    );
  }

  Widget _keySection(
    BuildContext context,
    int index,
    Map<String, dynamic> cfg,
  ) {
    final dynamicId = cfg['DymanicId'];
    final dynamicIdInt = dynamicId is int
        ? dynamicId
        : int.tryParse(dynamicId?.toString() ?? '') ?? 0;
    final isStatic = dynamicIdInt == 0;
    final keyType = isStatic ? 'Static' : 'Dynamic';
    final typeColor = isStatic ? AppColors.blue : AppColors.green;

    final sources = (cfg['Sources'] as List? ?? [])
        .whereType<Map>()
        .map((m) => m.map((k, v) => MapEntry(k.toString(), v)))
        .toList();
    final joins = (cfg['JoinMappings'] as List? ?? [])
        .whereType<Map>()
        .map((m) => m.map((k, v) => MapEntry(k.toString(), v)))
        .toList();
    final outputCols = (cfg['outputColumns'] as List? ?? [])
        .whereType<Map>()
        .map((m) => m.map((k, v) => MapEntry(k.toString(), v)))
        .toList();

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: Theme(
        data: ThemeData(dividerColor: Colors.transparent),
        child: ExpansionTile(
          initiallyExpanded: true,
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
                  'Key ${index + 1}',
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
                  ConfigPreviewSheet._tile(
                    icon: Icons.storage_rounded,
                    color: AppColors.blue,
                    title: 'Sources',
                    subtitle:
                        '${sources.length} source${sources.length == 1 ? '' : 's'} configured',
                    initiallyExpanded: true,
                    child: _sourcesSection(sources),
                  ),
                  const SizedBox(height: 8),
                  ConfigPreviewSheet._tile(
                    icon: Icons.merge_type_rounded,
                    color: AppColors.violet,
                    title: 'Operation Details',
                    subtitle: joins.isEmpty
                        ? 'No join operations'
                        : '${joins.length} join condition${joins.length == 1 ? '' : 's'}',
                    initiallyExpanded: true,
                    child: _operationsSection(joins),
                  ),
                  const SizedBox(height: 8),
                  ConfigPreviewSheet._tile(
                    icon: Icons.email_rounded,
                    color: AppColors.green,
                    title: 'Output Configuration',
                    subtitle:
                        '${outputCols.length} field${outputCols.length == 1 ? '' : 's'} mapped',
                    initiallyExpanded: true,
                    child: _outputConfigSection(outputCols),
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
                        if (templateName.isNotEmpty) ...[
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
                              templateName,
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
                ],
              ),
            ),
            const Divider(height: 1, color: AppColors.border),
            Expanded(
              child: ListView(
                controller: scrollCtrl,
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                children: [
                  for (var i = 0; i < keyConfigs.length; i++) ...[
                    _keySection(context, i, keyConfigs[i]),
                    if (i < keyConfigs.length - 1) const SizedBox(height: 16),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
