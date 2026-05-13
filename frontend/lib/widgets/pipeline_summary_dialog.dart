import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

// ── Entry point ───────────────────────────────────────────────────────────────

Future<void> showPipelineSummaryDialog(
  BuildContext context, {
  required Map<String, dynamic> config,
  required String templateName,
  required String deptName,
}) {
  return showDialog<void>(
    context: context,
    barrierColor: Colors.black.withValues(alpha: 0.55),
    builder: (_) => PipelineSummaryDialog(
      config: config,
      templateName: templateName,
      deptName: deptName,
    ),
  );
}

// ── Loading overlay ───────────────────────────────────────────────────────────

class PipelineSummaryLoadingOverlay extends StatelessWidget {
  const PipelineSummaryLoadingOverlay({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Material(
        borderRadius: BorderRadius.circular(14),
        color: Colors.white,
        child: const Padding(
          padding: EdgeInsets.symmetric(horizontal: 32, vertical: 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(strokeWidth: 2, color: AppColors.blue),
              SizedBox(height: 16),
              Text(
                'Loading pipeline…',
                style: TextStyle(fontSize: 13, color: AppColors.textDim),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Pipeline summary dialog ───────────────────────────────────────────────────

class PipelineSummaryDialog extends StatefulWidget {
  final Map<String, dynamic> config;
  final String templateName;
  final String deptName;

  const PipelineSummaryDialog({
    super.key,
    required this.config,
    required this.templateName,
    required this.deptName,
  });

  @override
  State<PipelineSummaryDialog> createState() => _PipelineSummaryDialogState();
}

class _PipelineSummaryDialogState extends State<PipelineSummaryDialog>
    with SingleTickerProviderStateMixin {
  final Set<int> _expanded = {};

  late final AnimationController _animCtrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 300),
  );
  late final Animation<double> _fade = CurvedAnimation(
    parent: _animCtrl,
    curve: Curves.easeOutCubic,
  );
  late final Animation<Offset> _slide = Tween<Offset>(
    begin: const Offset(0, 0.06),
    end: Offset.zero,
  ).animate(CurvedAnimation(parent: _animCtrl, curve: Curves.easeOutCubic));

  @override
  void initState() {
    super.initState();
    _animCtrl.forward();
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    super.dispose();
  }

  List<Map<String, dynamic>> get _sources {
    final raw = widget.config['Sources'];
    if (raw is List) return raw.whereType<Map<String, dynamic>>().toList();
    return [];
  }

  List<Map<String, dynamic>> get _joins {
    final raw = widget.config['JoinMappings'];
    if (raw is List) return raw.whereType<Map<String, dynamic>>().toList();
    return [];
  }

  Map<String, Map<String, String>> get _aliasMap {
    final raw = widget.config['outputColumns'];
    if (raw is! List) return {};
    final map = <String, Map<String, String>>{};
    for (final oc in raw.whereType<Map<String, dynamic>>()) {
      final srcName = oc['sourceName']?.toString() ?? '';
      final srcCol = oc['SourceColName']?.toString() ?? '';
      final colName = oc['ColumnName']?.toString() ?? '';
      if (srcName.isEmpty || srcCol.isEmpty) continue;
      map.putIfAbsent(srcName, () => {})[srcCol] = colName;
    }
    return map;
  }

  String _sourceTypeName(int id) {
    switch (id) {
      case 1:
        return 'Manual';
      case 2:
        return 'QRS';
      case 3:
        return 'FC';
      default:
        return 'Database';
    }
  }

  String _normalizeJoinType(String raw) {
    switch (raw.toLowerCase().replaceAll('_', ' ').trim()) {
      case 'left join':
      case 'left_join':
        return 'LEFT JOIN';
      case 'right join':
      case 'right_join':
        return 'RIGHT JOIN';
      case 'inner join':
      case 'inner_join':
        return 'INNER JOIN';
      default:
        return raw.toUpperCase();
    }
  }

  @override
  Widget build(BuildContext context) {
    final sources = _sources;
    final joins = _joins;
    int totalCols = 0;
    for (final src in sources) {
      totalCols += (src['SelectedColumns']?.toString() ?? '')
          .split(',')
          .where((c) => c.trim().isNotEmpty)
          .length;
    }

    return SlideTransition(
      position: _slide,
      child: FadeTransition(
        opacity: _fade,
        child: Dialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          backgroundColor: Colors.white,
          insetPadding:
              const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 700, maxHeight: 720),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Header ──
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 22, 24, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'VIEW PIPELINE',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textMuted,
                      letterSpacing: 1.0,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Pipeline summary',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: AppColors.text,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _infoCard(
                          label: 'DEPARTMENT',
                          value: widget.deptName,
                          icon: Icons.apartment_outlined,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _infoCard(
                          label: 'TEMPLATE',
                          value: widget.templateName,
                          icon: Icons.table_chart_outlined,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),

            const Divider(height: 1, color: AppColors.border),

            // ── Scrollable body ──
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 18, 24, 4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Sources row
                    if (sources.isNotEmpty) ...[
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Sources',
                            style: TextStyle(
                              fontSize: 13,
                              color: AppColors.textDim,
                            ),
                          ),
                          const Spacer(),
                          Flexible(
                            child: Text(
                              sources
                                  .map((s) => s['SourceName']?.toString() ?? '')
                                  .where((s) => s.isNotEmpty)
                                  .join(' · '),
                              textAlign: TextAlign.right,
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.textDim,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      const Divider(color: AppColors.border),
                      const SizedBox(height: 16),
                    ],

                    // Join conditions
                    Row(
                      children: [
                        const Text(
                          'Join conditions',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppColors.text,
                          ),
                        ),
                        const Spacer(),
                        if (joins.isNotEmpty)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 9,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.blue.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '${joins.length} ${joins.length == 1 ? 'condition' : 'conditions'}',
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: AppColors.blue,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    if (joins.isEmpty)
                      const Text(
                        'No join conditions defined',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textMuted,
                        ),
                      )
                    else
                      ...joins.map(_buildJoinRow),

                    const SizedBox(height: 16),
                    const Divider(color: AppColors.border),
                    const SizedBox(height: 16),

                    // Output columns
                    Row(
                      children: [
                        const Text(
                          'Output columns',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppColors.text,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          '$totalCols ${totalCols == 1 ? 'column' : 'columns'} from ${sources.length} ${sources.length == 1 ? 'source' : 'sources'}',
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.textDim,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: AppColors.border),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Column(
                          children: sources.asMap().entries.map((e) {
                            return _buildOutputSourceRow(e.key, e.value);
                          }).toList(),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
            ),

            // ── Footer ──
            Container(
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 16),
              decoration: const BoxDecoration(
                border: Border(top: BorderSide(color: AppColors.border)),
              ),
              child: SizedBox(
                width: double.infinity,
                height: 46,
                child: ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.blue,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text(
                    'Close',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
        ),
      ),
    );
  }

  Widget _infoCard({
    required String label,
    required String value,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
        color: AppColors.bg,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 12, color: AppColors.textMuted),
              const SizedBox(width: 5),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textMuted,
                  letterSpacing: 0.8,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            value.isNotEmpty ? value : '—',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.text,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildJoinRow(Map<String, dynamic> jm) {
    final leftSrc = jm['LeftSourceName']?.toString() ?? '';
    final leftCol = jm['LeftColumn']?.toString() ?? '';
    final rightSrc = jm['RightSourceName']?.toString() ?? '';
    final rightCol = jm['RightColumn']?.toString() ?? '';
    final joinType = _normalizeJoinType(jm['JoinType']?.toString() ?? '');

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
        color: Colors.white,
      ),
      child: Row(
        children: [
          Expanded(
            child: RichText(
              overflow: TextOverflow.ellipsis,
              text: TextSpan(
                children: [
                  TextSpan(
                    text: leftSrc,
                    style: const TextStyle(
                      color: AppColors.blue,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                  TextSpan(
                    text: '.$leftCol',
                    style: const TextStyle(color: AppColors.text, fontSize: 12),
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.blue.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: AppColors.blue.withValues(alpha: 0.22),
                ),
              ),
              child: Text(
                joinType,
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  color: AppColors.blue,
                ),
              ),
            ),
          ),
          Expanded(
            child: RichText(
              textAlign: TextAlign.right,
              overflow: TextOverflow.ellipsis,
              text: TextSpan(
                children: [
                  TextSpan(
                    text: rightSrc,
                    style: const TextStyle(
                      color: AppColors.blue,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                  TextSpan(
                    text: '.$rightCol',
                    style: const TextStyle(color: AppColors.text, fontSize: 12),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOutputSourceRow(int index, Map<String, dynamic> src) {
    final srcName = src['SourceName']?.toString() ?? '—';
    final srcTypeId = int.tryParse(src['SourceType']?.toString() ?? '') ?? 0;
    final srcTypeName = _sourceTypeName(srcTypeId);
    final selCols = (src['SelectedColumns']?.toString() ?? '')
        .split(',')
        .where((c) => c.trim().isNotEmpty)
        .toList();
    final colCount = selCols.length;
    final isExpanded = _expanded.contains(index);
    final isLast = index == _sources.length - 1;
    final aliases = _aliasMap[srcName] ?? {};

    return Column(
      children: [
        InkWell(
          onTap: () => setState(() {
            if (isExpanded) {
              _expanded.remove(index);
            } else {
              _expanded.add(index);
            }
          }),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 11, horizontal: 12),
            decoration: BoxDecoration(
              border: (!isExpanded && !isLast)
                  ? const Border(bottom: BorderSide(color: AppColors.border))
                  : null,
              color: isExpanded
                  ? AppColors.blue.withValues(alpha: 0.03)
                  : Colors.white,
            ),
            child: Row(
              children: [
                Icon(
                  isExpanded
                      ? Icons.arrow_drop_down_rounded
                      : Icons.arrow_right_rounded,
                  size: 20,
                  color: AppColors.textDim,
                ),
                const SizedBox(width: 4),
                Text(
                  srcName,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.blue,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '$srcTypeName source',
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textMuted,
                  ),
                ),
                const Spacer(),
                Text(
                  '$colCount ${colCount == 1 ? 'column' : 'columns'}',
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textDim,
                  ),
                ),
              ],
            ),
          ),
        ),
        if (isExpanded) ...[
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(38, 10, 12, 12),
            decoration: BoxDecoration(
              color: AppColors.bg,
              border: isLast
                  ? null
                  : const Border(bottom: BorderSide(color: AppColors.border)),
            ),
            child: selCols.isEmpty
                ? const Text(
                    'No columns selected',
                    style: TextStyle(
                      fontSize: 11,
                      color: AppColors.textMuted,
                      fontStyle: FontStyle.italic,
                    ),
                  )
                : Table(
                    columnWidths: const {
                      0: IntrinsicColumnWidth(),
                      1: FlexColumnWidth(),
                    },
                    defaultVerticalAlignment: TableCellVerticalAlignment.middle,
                    children: [
                      TableRow(
                        children: [
                          const Padding(
                            padding: EdgeInsets.only(bottom: 8),
                            child: Text(
                              'SOURCE COLUMN',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textMuted,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                          const Padding(
                            padding: EdgeInsets.only(bottom: 8),
                            child: Text(
                              'OUTPUT AS',
                              textAlign: TextAlign.right,
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textMuted,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                      ...selCols.map((col) {
                        final trimmed = col.trim();
                        final alias = aliases[trimmed];
                        return TableRow(
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(bottom: 6),
                              child: Text(
                                trimmed,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.text,
                                ),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.only(bottom: 6),
                              child: Text(
                                alias ?? trimmed,
                                textAlign: TextAlign.right,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.blue,
                                  fontFamily: AppTextStyles.monoFamily,
                                ),
                              ),
                            ),
                          ],
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
