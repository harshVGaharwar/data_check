part of 'package:vizualizer/presentation/widgets/pipeline/nodes/output_node_body.dart';

// ─────────────────────────────────────────────────────────────────────────────
// OUTPUT COLUMN SELECTOR
// ─

class _OutputColumnSelector extends StatefulWidget {
  final PipelineNode node;
  final PipelineController ctrl;
  final bool hidePriority;
  final bool hideAlias;

  const _OutputColumnSelector({
    super.key,
    required this.node,
    
    required this.ctrl,
    this.hidePriority = false,
    this.hideAlias = false,
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

  @override
  void didUpdateWidget(_OutputColumnSelector oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.ctrl != widget.ctrl) {
      oldWidget.ctrl.removeListener(_onCtrlChange);
      widget.ctrl.addListener(_onCtrlChange);
    }
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

    final allSrcNodes = ctrl.nodes
        .where((n) => n.type != NodeType.join)
        .toList();
    int g = 0;
    final globalDefault = <String, int>{};
    for (final n in allSrcNodes) {
      for (final c in n.selectedCols) {
        g++;
        globalDefault['${n.id}_$c'] = g;
      }
    }
    final totalSelected = g > 0 ? g : 1;

    int effPri(PipelineNode n, String c) => n.columnPriorities.containsKey(c)
        ? n.columnPriorities[c]!
        : (globalDefault['${n.id}_$c'] ?? 1);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Toolbar
        Row(
          children: [
            Expanded(
              child: SizedBox(
                height: 30,
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
                      horizontal: 8,
                      vertical: 0,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(7),
                      borderSide: const BorderSide(color: AppColors.border2),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(7),
                      borderSide: const BorderSide(color: AppColors.border2),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(7),
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
            const SizedBox(width: 6),
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
        const SizedBox(height: 8),

        // Progress bar
        Row(
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 4,
                  backgroundColor: AppColors.border,
                  valueColor: const AlwaysStoppedAnimation<Color>(
                    AppColors.blue,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 6),
            Text(
              '$selCount / $total',
              style: const TextStyle(
                color: AppColors.textDim,
                fontSize: 9,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),

        // Column chips
        filtered.isEmpty
            ? Container(
                padding: const EdgeInsets.symmetric(
                  vertical: 10,
                  horizontal: 8,
                ),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
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
                  final sel = node.selectedCols.contains(col);
                  return GestureDetector(
                    onTap: () => ctrl.toggleColumn(node.id, col),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(7),
                        color: sel ? AppColors.blue : AppColors.bg,
                        border: Border.all(
                          color: sel ? AppColors.blue : AppColors.border2,
                          width: sel ? 1.5 : 1,
                        ),
                        boxShadow: sel
                            ? [
                                BoxShadow(
                                  color: AppColors.blue.withValues(alpha: 0.22),
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

        // Alias + priority table
        if (node.selectedCols.isNotEmpty) ...[
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
                    border: const Border(
                      bottom: BorderSide(color: AppColors.border),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.drive_file_rename_outline_rounded,
                        size: 11,
                        color: AppColors.blue,
                      ),
                      const SizedBox(width: 5),
                      const Expanded(
                        child: Text(
                          'Column',
                          style: TextStyle(
                            color: AppColors.textMuted,
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      if (!widget.hidePriority) ...[
                        const SizedBox(width: 6),
                        const SizedBox(
                          width: 56,
                          child: Text(
                            'Priority',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: AppColors.violet,
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                      if (!widget.hideAlias) ...[
                        const SizedBox(width: 6),
                        const SizedBox(
                          width: 110,
                          child: Text(
                            'Output alias',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: AppColors.textMuted,
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                      const SizedBox(width: 6),
                      const SizedBox(
                        width: 60,
                        child: Text(
                          'Unique Field',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: AppColors.amber,
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                ...node.selectedCols.asMap().entries.map((e) {
                  final i = e.key;
                  final col = e.value;
                  final isLast = i == node.selectedCols.length - 1;
                  final available = List.generate(
                    totalSelected,
                    (idx) => idx + 1,
                  );
                  final myPri = effPri(node, col);
                  return Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      borderRadius: isLast
                          ? const BorderRadius.vertical(
                              bottom: Radius.circular(8),
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
                          width: 5,
                          height: 5,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.blue.withValues(alpha: 0.6),
                          ),
                        ),
                        const SizedBox(width: 5),
                        Expanded(
                          child: Text(
                            col,
                            style: TextStyle(
                              color: AppColors.textDim,
                              fontSize: 9,
                              fontFamily: AppTextStyles.monoFamily,
                              fontWeight: FontWeight.w500,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (!widget.hidePriority) ...[
                          const SizedBox(width: 6),
                          SizedBox(
                            width: 56,
                            height: 26,
                            child: Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(5),
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
                                            fontSize: 11,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ),
                                    )
                                    .toList(),
                                onChanged: (v) {
                                  if (v == null) return;
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
                                  if (oldPri == v) return;
                                  search:
                                  for (final n2 in freshNodes) {
                                    for (final c2 in n2.selectedCols) {
                                      if (n2.id == node.id && c2 == col) {
                                        continue;
                                      }
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
                                  size: 14,
                                  color: AppColors.violet,
                                ),
                              ),
                            ),
                          ),
                        ],
                        if (!widget.hideAlias) ...[
                          const SizedBox(width: 6),
                          SizedBox(
                            width: 110,
                            height: 26,
                            child: TextFormField(
                              key: ValueKey('out_alias_${node.id}_$col'),
                              initialValue: node.columnAliases[col] ?? '',
                              onChanged: (v) =>
                                  ctrl.setColumnAlias(node.id, col, v),
                              style: TextStyle(
                                color: AppColors.text,
                                fontSize: 9.5,
                                fontFamily: AppTextStyles.monoFamily,
                              ),
                              decoration: InputDecoration(
                                hintText: col,
                                hintStyle: const TextStyle(
                                  color: AppColors.textMuted,
                                  fontSize: 9,
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 0,
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(5),
                                  borderSide: const BorderSide(
                                    color: AppColors.border2,
                                  ),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(5),
                                  borderSide: const BorderSide(
                                    color: AppColors.border2,
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(5),
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
                        const SizedBox(width: 6),
                        SizedBox(
                          width: 60,
                          child: Checkbox(
                            value: node.columnUniqueFields[col] ?? false,
                            onChanged: (v) => ctrl.setColumnUniqueField(
                              node.id,
                              col,
                              v ?? false,
                            ),
                            materialTapTargetSize:
                                MaterialTapTargetSize.shrinkWrap,
                            visualDensity: VisualDensity.compact,
                            activeColor: AppColors.amber,
                            side: const BorderSide(
                              color: AppColors.border2,
                              width: 1.2,
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

// ─────────────────────────────────────────────────────────────────────────────
// TOOLBAR BUTTON
// ─────────────────────────────────────────────────────────────────────────────

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
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 5),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(7),
          color: color.withValues(alpha: 0.08),
          border: Border.all(color: color.withValues(alpha: 0.22)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 11, color: color),
            const SizedBox(width: 3),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 9,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
