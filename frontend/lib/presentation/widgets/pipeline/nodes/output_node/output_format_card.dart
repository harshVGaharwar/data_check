part of 'package:vizualizer/presentation/widgets/pipeline/nodes/output_node_body.dart';

// ─────────────────────────────────────────────────────────────────────────────
// OUTPUT FORMAT CARD (column selector per source)
// ─────────────────────────────────────────────────────────────────────────────

class _OutputFormatCard extends StatelessWidget {
  final PipelineNode node;
  final PipelineController ctrl;
  final bool hidePriority;
  final bool hideAlias;

  const _OutputFormatCard({
    required this.node,
    required this.ctrl,
    this.hidePriority = false,
    this.hideAlias = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: AppColors.surface,
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
            decoration: BoxDecoration(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(12),
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
                const Icon(
                  Icons.table_chart_rounded,
                  color: AppColors.blue,
                  size: 14,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    node.name,
                    style: const TextStyle(
                      color: AppColors.text,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                _CountBadge(node: node, ctrl: ctrl),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(10),
            child: _OutputColumnSelector(
              node: node,
              ctrl: ctrl,
              hidePriority: hidePriority,
              hideAlias: hideAlias,
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
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
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
          fontSize: 9,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
