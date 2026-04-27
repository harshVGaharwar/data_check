import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../theme/app_theme.dart';
import '../../models/pipeline_models.dart';
import '../../controllers/pipeline_controller.dart';
import '../shimmer_button.dart';

class SourceNodeBody extends StatelessWidget {
  final PipelineNode node;
  const SourceNodeBody({super.key, required this.node});

  @override
  Widget build(BuildContext context) {
    final color = node.type.color;
    final hasCols = node.cols.isNotEmpty;
    final isManual = node.type == NodeType.manual;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Container(
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
          decoration: const BoxDecoration(
            border: Border(bottom: BorderSide(color: AppColors.border)),
            borderRadius: BorderRadius.vertical(top: Radius.circular(10)),
          ),
          child: Row(
            children: [
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  color: color.withValues(alpha: 0.12),
                ),
                child: Icon(node.type.icon, color: color, size: 14),
              ),
              const SizedBox(width: 8),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  node.sourceTypeName.isNotEmpty
                      ? node.sourceTypeName.toUpperCase()
                      : node.type.label.toUpperCase(),
                  style: AppTextStyles.nodeName,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              InkWell(
                onTap: () =>
                    context.read<PipelineController>().deleteNode(node.id),
                child: const Icon(
                  Icons.delete_outline,
                  color: AppColors.red,
                  size: 16,
                ),
              ),
            ],
          ),
        ),

        // Body stats — only after node is configured (confirmed or editing)
        if (node.confirmState != NodeConfirmState.notConfigured)
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
            child: Column(
              children: [
                _sourceNameRow(),
                _statBadgeRow(
                  'Columns',
                  hasCols
                      ? '${node.cols.length} cols'
                      : isManual
                      ? 'No data'
                      : 'No file',
                  hasCols ? AppColors.blue : AppColors.amber,
                ),
                if (node.rows.isNotEmpty)
                  _statRow('Rows', '${node.rows.length}'),
              ],
            ),
          )
        else
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
            child: ShimmerButton(
              label: 'Click to configure',
              icon: Icons.settings_outlined,
              animating:
                  context.watch<PipelineController>().selectedNodeId != node.id,
            ),
          ),

        // Footer — delete only
        // Container(
        //   padding: const EdgeInsets.fromLTRB(12, 6, 12, 8),
        //   decoration: const BoxDecoration(
        //     border: Border(top: BorderSide(color: AppColors.border)),
        //   ),
        //   child: Row(
        //     mainAxisAlignment: MainAxisAlignment.end,
        //     children: [
        //       InkWell(
        //         onTap: () =>
        //             context.read<PipelineController>().deleteNode(node.id),
        //         child: const Icon(Icons.delete_outline, color: Colors.red),
        //       ),
        //     ],
        //   ),
        // ),
      ],
    );
  }

  Widget _sourceNameRow() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text('Source Name', style: AppTextStyles.statLabel),
          if (node.name.isEmpty)
            Row(
              mainAxisSize: MainAxisSize.min,
              children: const [
                Icon(Icons.error_outline, color: Colors.red, size: 10),
                SizedBox(width: 3),
                Text(
                  'Define Source Name',
                  style: TextStyle(
                    color: Colors.red,
                    fontSize: 9,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            )
          else
            Flexible(
              child: Text(
                node.name,
                style: AppTextStyles.statValue,
                overflow: TextOverflow.ellipsis,
              ),
            ),
        ],
      ),
    );
  }

  Widget _statRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: AppTextStyles.statLabel),
          Flexible(
            child: Text(
              value,
              style: AppTextStyles.statValue,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _statBadgeRow(String label, String badge, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: AppTextStyles.statLabel),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              color: color.withValues(alpha: 0.12),
              border: Border.all(color: color.withValues(alpha: 0.2)),
            ),
            child: Text(
              badge,
              style: TextStyle(
                color: color,
                fontSize: 9.5,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// JOIN NODE BODY (same as HTML join-node card with inline mapping)
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
